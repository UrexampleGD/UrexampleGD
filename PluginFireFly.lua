local Success, Error = pcall(function()
    local Shared = odh_shared_plugins
    if not Shared and getgenv then
        local Genv = getgenv()
        if type(Genv) == "table" then
            if type(Genv.odh_shared_plugins) == "table" then
                Shared = Genv.odh_shared_plugins
            elseif type(Genv.shared) == "table" and type(Genv.shared.CreateTab) == "function" then
                Shared = Genv.shared
            end
        end
    end

    if not Shared or type(Shared.CreateTab) ~= "function" then
        return
    end

    local MyOwnTab
    local TabOk, TabResult = pcall(function()
        return Shared.CreateTab("Firefly Timer", "/Devon67retro/Test/refs/heads/main/icon")
    end)
    
    if TabOk and TabResult then
        MyOwnTab = TabResult
    else
        local FallbackOk, FallbackResult = pcall(function()
            return Shared.CreateTab("Firefly Timer")
        end)
        if FallbackOk and FallbackResult then
            MyOwnTab = FallbackResult
        end
    end

    if not MyOwnTab then return end

    local SecOk, MyOwnSection = pcall(function()
        return MyOwnTab:AddSection("Firefly Timer", "Countdown + auto jump")
    end)

    if not SecOk or not MyOwnSection then return end

    MyOwnSection:AddLabel("Made by: SANGUINE ⚡⚡ ")
    MyOwnSection:AddParagraph("Firefly Timer", "Jumps at 0.24s remaining, second jump 0.50s later.")

    local ENV
    if getgenv then ENV = getgenv() else ENV = _G end

    if ENV.__FireflyConnections then
        for _, Conn in ipairs(ENV.__FireflyConnections) do
            pcall(function() Conn:Disconnect() end)
        end
    end
    ENV.__FireflyConnections = {}

    if ENV.__FireflyJumpThread then
        pcall(function() task.cancel(ENV.__FireflyJumpThread) end)
        ENV.__FireflyJumpThread = nil
    end

    pcall(function()
        local CAS = game:GetService("ContextActionService")
        CAS:UnbindAction("FireflyAutoJump")
    end)

    local MY_ID = tick() .. math.random(1000, 9999)
    ENV.__FireflyInstanceID = MY_ID

    local function IsCurrent()
        return ENV.__FireflyInstanceID == MY_ID
    end

    local function RegConn(Conn)
        if Conn then table.insert(ENV.__FireflyConnections, Conn) end
        return Conn
    end

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ContextActionService = game:GetService("ContextActionService")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

    for _, Name in ipairs({"FireflySettingsGui", "FireflyTimerGui", "FireflyCooldownGui"}) do
        local Old = PlayerGui:FindFirstChild(Name)
        if Old then Old:Destroy() end
    end

    local CountdownDuration = 2.5
    local FrameSize = UDim2.new(0, 100, 0, 50)
    local FramePosition = UDim2.new(0.5, -50, 0.5, -100)
    local CdFontSize = 48

    local Enabled = false
    local FirstJumpTiming = 0.24
    local SecondJumpTiming = 0.50

    local IsCountingDown = false
    local CountdownConnection = nil
    local ToolConnection = nil
    local ScreenGui, Frame, Label, Stroke, Corner

    local CdScreenGui, CdFrame, CdLabel
    local CooldownConnection = nil
    local BlockConnection = nil
    local IsOnCooldown = false

    local JumpTriggered = false
    local JumpActionBound = false
    local RoundRewardsHooked = false

    local BackpackAddedConn, CharAddedConn
    local BackpackWatchConn, CharacterWatchConn

    local function BuildGui()
        if ScreenGui then return end
        ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "FireflyTimerGui"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.Parent = PlayerGui

        Frame = Instance.new("Frame")
        Frame.Name = "TimerFrame"
        Frame.Size = FrameSize
        Frame.Position = FramePosition
        Frame.BackgroundTransparency = 0.7
        Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Frame.BorderSizePixel = 0
        Frame.Visible = true -- Made visible so you can see it immediately
        Frame.Parent = ScreenGui

        Stroke = Instance.new("UIStroke")
        Stroke.Color = Color3.fromRGB(255, 0, 0)
        Stroke.Thickness = 1
        Stroke.Parent = Frame

        Label = Instance.new("TextLabel")
        Label.Name = "CountdownLabel"
        Label.Size = UDim2.new(1, 0, 1, 0)
        Label.BackgroundTransparency = 1
        Label.TextColor3 = Color3.fromRGB(0, 0, 0)
        Label.TextScaled = true
        Label.Font = Enum.Font.GothamBold
        Label.Text = "2.5"
        Label.Parent = Frame

        Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 6)
        Corner.Parent = Frame
    end

    local function BuildCooldownGui()
        if CdScreenGui then return end
        CdScreenGui = Instance.new("ScreenGui")
        CdScreenGui.Name = "FireflyCooldownGui"
        CdScreenGui.ResetOnSpawn = false
        CdScreenGui.Parent = PlayerGui

        CdFrame = Instance.new("Frame")
        CdFrame.Name = "CooldownFrame"
        CdFrame.Size = UDim2.new(0, 150, 0, 60)
        CdFrame.Position = UDim2.new(0, 20, 0.5, 0)
        CdFrame.BackgroundTransparency = 1
        CdFrame.BorderSizePixel = 0
        CdFrame.Active = true
        CdFrame.Visible = true -- Made visible so you can see it
        CdFrame.Parent = CdScreenGui

        CdLabel = Instance.new("TextLabel")
        CdLabel.Name = "CooldownLabel"
        CdLabel.Size = UDim2.new(1, 0, 1, 0)
        CdLabel.BackgroundTransparency = 1
        CdLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
        CdLabel.TextSize = CdFontSize
        CdLabel.Font = Enum.Font.GothamBold
        CdLabel.TextXAlignment = Enum.TextXAlignment.Left
        CdLabel.Text = "Ready"
        CdLabel.Parent = CdFrame

        local Dragging, DragStart, StartPos
        CdFrame.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                DragStart = Input.Position
                StartPos = CdFrame.Position
                Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        Dragging = false
                    end
                end)
            end
        end)
        CdFrame.InputChanged:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                if Dragging then
                    local Delta = Input.Position - DragStart
                    CdFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
                end
            end
        end)
    end

    local function BindJumpAction()
        if JumpActionBound then
            ContextActionService:UnbindAction("FireflyAutoJump")
            JumpActionBound = false
        end
        ContextActionService:BindAction("FireflyAutoJump", function(ActionName, InputState)
            if InputState == Enum.UserInputState.Begin then
                local Char = LocalPlayer.Character
                if Char then
                    local Humanoid = Char:FindFirstChildOfClass("Humanoid")
                    if Humanoid then
                        Humanoid.Jump = true
                    end
                end
            end
            return Enum.ContextActionResult.Pass
        end, false, Enum.KeyCode.Space)
        JumpActionBound = true
    end

    local function UnbindJumpAction()
        if not JumpActionBound then return end
        ContextActionService:UnbindAction("FireflyAutoJump")
        JumpActionBound = false
    end

    local function FireJump()
        if not IsCurrent() then return false end
        if not Enabled then return false end
        if not IsCountingDown then return false end
        local Char = LocalPlayer.Character
        if not Char then return false end
        local Humanoid = Char:FindFirstChildOfClass("Humanoid")
        if not Humanoid then return false end
        Humanoid.Jump = true
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        return true
    end

    local function FireTwoJumps()
        FireJump()
        if ENV.__FireflyJumpThread then
            pcall(function() task.cancel(ENV.__FireflyJumpThread) end)
            ENV.__FireflyJumpThread = nil
        end
        ENV.__FireflyJumpThread = task.delay(SecondJumpTiming, function()
            if not IsCurrent() then return end
            FireJump()
            ENV.__FireflyJumpThread = nil
        end)
    end

    local function StartCountdown()
        if not Enabled then return end
        BuildGui()
        if CountdownConnection then CountdownConnection:Disconnect() CountdownConnection = nil end

        JumpTriggered = false
        IsCountingDown = true
        Frame.Visible = true
        Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Frame.BackgroundTransparency = 0.7
        Stroke.Color = Color3.fromRGB(255, 0, 0)
        Label.TextColor3 = Color3.fromRGB(0, 0, 0)
        Label.Text = string.format("%.1f", CountdownDuration)

        local TimeLeft = CountdownDuration
        CountdownConnection = RunService.Heartbeat:Connect(function(DeltaTime)
            if not IsCurrent() then
                if CountdownConnection then CountdownConnection:Disconnect() CountdownConnection = nil end
                return
            end
            if not Enabled then
                if CountdownConnection then CountdownConnection:Disconnect() CountdownConnection = nil end
                Frame.Visible = false
                IsCountingDown = false
                return
            end
            TimeLeft -= DeltaTime
            if TimeLeft <= 0 then
                TimeLeft = 0
                Label.Text = "0.0"
                Frame.Visible = false
                IsCountingDown = false
                if CountdownConnection then CountdownConnection:Disconnect() CountdownConnection = nil end
                return
            end
            if IsCountingDown and not JumpTriggered and TimeLeft <= FirstJumpTiming then
                JumpTriggered = true
                FireTwoJumps()
            end
            Label.Text = string.format("%.1f", TimeLeft)
        end)
        RegConn(CountdownConnection)
    end

    local function StartCooldownPanel()
        BuildCooldownGui()
        if CooldownConnection then CooldownConnection:Disconnect() CooldownConnection = nil end
        CdFrame.Visible = true
        CdLabel.Text = "0.0"
        local Elapsed = 0
        CooldownConnection = RunService.Heartbeat:Connect(function(DeltaTime)
            if not IsCurrent() then
                if CooldownConnection then CooldownConnection:Disconnect() CooldownConnection = nil end
                return
            end
            Elapsed += DeltaTime
            if Elapsed >= 16 then
                Elapsed = 16
                CdLabel.Text = "Active"
                if CooldownConnection then CooldownConnection:Disconnect() CooldownConnection = nil end
                return
            end
            CdLabel.Text = string.format("%.1f", Elapsed)
        end)
        RegConn(CooldownConnection)
    end

    local function StartBlockTimer()
        IsOnCooldown = true
        if BlockConnection then BlockConnection:Disconnect() BlockConnection = nil end
        local Elapsed = 0
        BlockConnection = RunService.Heartbeat:Connect(function(DeltaTime)
            if not IsCurrent() then
                if BlockConnection then BlockConnection:Disconnect() BlockConnection = nil end
                return
            end
            Elapsed += DeltaTime
            if Elapsed >= 16 then
                IsOnCooldown = false
                if BlockConnection then BlockConnection:Disconnect() BlockConnection = nil end
            end
        end)
        RegConn(BlockConnection)
    end

    local function ConnectToTool(Tool)
        if ToolConnection then ToolConnection:Disconnect() ToolConnection = nil end
        ToolConnection = Tool.Activated:Connect(function()
            if not IsCurrent() then return end
            if not Enabled then return end
            if IsOnCooldown then return end
            StartCountdown()
            StartCooldownPanel()
            StartBlockTimer()
        end)
        RegConn(ToolConnection)
        Shared.Notify("Hooked to Fireflies Tool!", 2)
    end

    local function ResetCooldown()
        if CooldownConnection then CooldownConnection:Disconnect() CooldownConnection = nil end
        if BlockConnection then BlockConnection:Disconnect() BlockConnection = nil end
        IsOnCooldown = false
        if CdLabel then CdLabel.Text = "Active" end
        if CdFrame then CdFrame.Visible = true end
    end

    local function HookRoundRewards()
        if RoundRewardsHooked then return end
        local Rp = game:GetService("ReplicatedStorage")
        local Remotes = Rp:FindFirstChild("Remotes")
        local Gameplay = Remotes and Remotes:FindFirstChild("Gameplay")
        local Remote = Gameplay and Gameplay:FindFirstChild("GetLastRoundRewards")
        if not Remote then return end

        if hookfunction then
            local Ok = pcall(function()
                local Old
                Old = hookfunction(Remote.InvokeServer, function(Self, ...)
                    pcall(ResetCooldown)
                    return Old(Self, ...)
                end)
            end)
            if Ok then
                RoundRewardsHooked = true
                return
            end
        end

        if hookmetamethod and getrawmetatable and getnamecallmethod and setreadonly and newcclosure then
            local Ok = pcall(function()
                local Mt = getrawmetatable(game)
                local OldNamecall = Mt.__namecall
                setreadonly(Mt, false)
                Mt.__namecall = newcclosure(function(Self, ...)
                    if Self == Remote and getnamecallmethod() == "InvokeServer" then
                        pcall(ResetCooldown)
                    end
                    return OldNamecall(Self, ...)
                end)
                setreadonly(Mt, true)
            end)
            if Ok then
                RoundRewardsHooked = true
            end
        end
    end

    local function UnhookTool()
        if ToolConnection then ToolConnection:Disconnect() ToolConnection = nil end
        if CountdownConnection then CountdownConnection:Disconnect() CountdownConnection = nil end
        if CooldownConnection then CooldownConnection:Disconnect() CooldownConnection = nil end
        if BlockConnection then BlockConnection:Disconnect() BlockConnection = nil end
        if BackpackAddedConn then BackpackAddedConn:Disconnect() BackpackAddedConn = nil end
        if CharAddedConn then CharAddedConn:Disconnect() CharAddedConn = nil end
        if BackpackWatchConn then BackpackWatchConn:Disconnect() BackpackWatchConn = nil end
        if CharacterWatchConn then CharacterWatchConn:Disconnect() CharacterWatchConn = nil end
        if ENV.__FireflyJumpThread then
            pcall(function() task.cancel(ENV.__FireflyJumpThread) end)
            ENV.__FireflyJumpThread = nil
        end
        UnbindJumpAction()
        RoundRewardsHooked = false
        if Frame then Frame.Visible = false end
        if CdFrame then CdFrame.Visible = false end
        IsCountingDown = false
        IsOnCooldown = false
    end

    local function HookTool()
        UnhookTool()
        local function WatchContainer(Container)
            if not Container then return nil end
            
            -- Case-insensitive search for the tool
            for _, Child in ipairs(Container:GetChildren()) do
                if string.lower(Child.Name):find("fireflies") then
                    ConnectToTool(Child)
                end
            end
            
            return Container.ChildAdded:Connect(function(Child)
                if string.lower(Child.Name):find("fireflies") then 
                    ConnectToTool(Child) 
                end
            end)
        end
        
        BackpackWatchConn = WatchContainer(LocalPlayer:FindFirstChildOfClass("Backpack"))
        CharacterWatchConn = WatchContainer(LocalPlayer.Character)
        
        BackpackAddedConn = LocalPlayer.ChildAdded:Connect(function(Child)
            if Child:IsA("Backpack") then
                if BackpackWatchConn then BackpackWatchConn:Disconnect() end
                BackpackWatchConn = WatchContainer(Child)
            end
        end)
        
        CharAddedConn = LocalPlayer.CharacterAdded:Connect(function(Char)
            ResetCooldown()
            if CharacterWatchConn then CharacterWatchConn:Disconnect() end
            CharacterWatchConn = WatchContainer(Char)
        end)
        
        BindJumpAction()
        HookRoundRewards()
        task.spawn(function()
            for _ = 1, 20 do
                if RoundRewardsHooked then break end
                HookRoundRewards()
                task.wait(0.5)
            end
        end)
    end

    MyOwnSection:AddToggle("Enable Firefly Timer", function(Bool)
        Enabled = Bool

        if Bool then
            BuildGui()
            BuildCooldownGui()
            HookTool()
            Shared.Notify("Firefly Timer enabled", 2)
        else
            UnhookTool()
            Shared.Notify("Firefly Timer disabled", 2)
        end
    end)
end)

if not Success then
    warn("[Firefly Timer] Addon Error: " .. tostring(Error))
end
