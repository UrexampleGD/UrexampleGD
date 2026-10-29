-- ODH TESTED

local _s = odh_shared_plugins
if not _s and getgenv then
	local _gv = getgenv()
	if type(_gv) == "table" and type(_gv.shared) == "table" then
		_s = _gv.shared
	end
end

if not _s or type(_s.CreateTab) ~= "function" then
	warn("[Firefly Timer] Load through the current Overdrive H plugin menu.")
	return
end

local _ok1, _t1 = pcall(function()
	return _s.CreateTab("Firefly Timer", "/Devon67retro/Debug/refs/heads/main/icon")
end)
if not _ok1 or not _t1 then return end

local _ok2, _t2 = pcall(function()
	return _t1:AddSection("Firefly Timer", "Countdown + auto jump")
end)
if not _ok2 or not _t2 then return end

local function _msg(m)
	pcall(function() _s.Notify(m, 4) end)
end

local _ui = {
	ready = false,
	d1 = false,
	d2 = false,
	d3 = false,
}

local function _exec(f, ...)
	if type(f) ~= "function" then return end
	local _ok, _err = pcall(f, ...)
	if not _ok then _msg("Error: " .. tostring(_err)) end
end

pcall(function()
	_t2:AddToggle("Enable Firefly Timer", function(b)
		_ui.d1 = b and true or false
		if _ui.ready then _exec(_ui.apply, _ui.d1) end
	end)
end)

pcall(function()
	_t2:AddToggle("Auto Get Firefly", function(b)
		_ui.d3 = b and true or false
		if _ui.ready then _exec(_ui.auto, _ui.d3) end
	end)
end)

pcall(function()
	_t2:AddToggle("Move Cooldown Window", function(b)
		_ui.d2 = b and true or false
		if _ui.ready then _exec(_ui.move, _ui.d2) end
	end)
end)

pcall(function()
	_t2:AddToggle("Save Cooldown Position", function(b)
		if b and _ui.ready then _exec(_ui.save) end
	end)
end)

pcall(function() _t2:AddLabel("Made by: SANGUINE 🤤🤤") end)

local function _init()
	local _plr = game:GetService("Players")
	local _rs = game:GetService("RunService")
	local _uis = game:GetService("UserInputService")
	local _cas = game:GetService("ContextActionService")
	local _http = game:GetService("HttpService")
	local _lp = _plr.LocalPlayer
	local _pg = _lp:WaitForChild("PlayerGui")

	local _cd1 = 2.5             
	local _cd2 = 21.2            -- Changed to 21.2
	local _fjr = 0.24 
	local _jg = 0.40             

	local _pf = "FireflyTimer_CDPos.json"

	local _id = tostring(os.clock()) .. tostring(math.random(1000, 9999))
	pcall(function() _lp:SetAttribute("FireflyRunId", _id) end)
	
	local function _curr()
		local _o, _v = pcall(function() return _lp:GetAttribute("FireflyRunId") end)
		if not _o then return true end
		return _v == _id
	end

	local _en = false
	local _mv = false
	local _ag = false
	local _hc = false        
	local _jd = false 
	local _tk = 0
	local _c1, _c2 = 0, 0
	local _cn, _hk = {}, {}
	local _st = 0
	local _g, _l1, _l2

	local _sp = nil

	local function _bj()
		_cas:BindAction("_x1", function()
			return Enum.ContextActionResult.Sink
		end, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
	end
	
	local function _ubj()
		_cas:UnbindAction("_x1")
	end

	_uis.JumpRequest:Connect(function()
		if _jd then
			local _ch = _lp.Character
			local _hm = _ch and _ch:FindFirstChildOfClass("Humanoid")
			if _hm then
				_hm.Jump = false
			end
		end
	end)

	_ui.auto = function(b)
		if not _curr() then return end
		_ag = b
		if _ag then
			task.spawn(function()
				while _ag and _curr() do
					local _ch = _lp.Character
					local _bp = _lp:FindFirstChildOfClass("Backpack")
					local _ht = (_ch and _ch:FindFirstChild("Fireflies")) or (_bp and _bp:FindFirstChild("Fireflies"))
					
					if not _ht then
						pcall(function()
							game:GetService("ReplicatedStorage").Remotes.Extras.ReplicateToy:InvokeServer("Fireflies")
						end)
					end
					task.wait(1)
				end
			end)
		end
	end

	local function _lp2()
		pcall(function()
			if isfile and readfile and isfile(_pf) then
				local _d = _http:JSONDecode(readfile(_pf))
				if type(_d) == "table" and type(_d.x) == "number" and type(_d.y) == "number" then
					_sp = UDim2.fromScale(math.clamp(_d.x, 0, 0.95), math.clamp(_d.y, 0, 0.95))
				end
			end
		end)
	end
	_lp2()

	for _, _n in ipairs({ "FireflyLiteGui", "FireflyTimerGui", "FireflyCooldownGui", "FireflySettingsGui" }) do
		pcall(function()
			local _o = _pg:FindFirstChild(_n)
			if _o then _o:Destroy() end
		end)
	end

	local function _ml(_p, _po, _sz, _ts)
		local _l = Instance.new("TextLabel")
		_l.Position = _po
		_l.Size = _sz
		_l.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		_l.BackgroundTransparency = 0.5
		_l.TextColor3 = Color3.fromRGB(255, 255, 255)
		_l.Font = Enum.Font.GothamBold
		_l.TextSize = _ts
		_l.Text = ""
		_l.Visible = false
		_l.Parent = _p
		pcall(function() Instance.new("UICorner", _l) end)
		return _l
	end

	local function _sd(_l)
		local _dr, _ds, _sps = false, nil, nil
		_l.InputBegan:Connect(function(_in)
			if not _mv or not _curr() then return end
			if _in.UserInputType == Enum.UserInputType.Touch or _in.UserInputType == Enum.UserInputType.MouseButton1 then
				_dr = true
				_ds = _in.Position
				_sps = _l.Position
				_in.Changed:Connect(function()
					if _in.UserInputState == Enum.UserInputState.End then _dr = false end
				end)
			end
		end)
		_uis.InputChanged:Connect(function(_in)
			if not _dr or not _mv or not _curr() then return end
			if _in.UserInputType == Enum.UserInputType.Touch or _in.UserInputType == Enum.UserInputType.MouseMovement then
				local _d = _in.Position - _ds
				_l.Position = UDim2.new(_sps.X.Scale, _sps.X.Offset + _d.X, _sps.Y.Scale, _sps.Y.Offset + _d.Y)
			end
		end)
	end

	local function _bg()
		if _g and _g.Parent then return end
		_g = Instance.new("ScreenGui")
		_g.Name = "FireflyLiteGui"
		_g.ResetOnSpawn = false
		_g.IgnoreGuiInset = true
		_g.DisplayOrder = 999
		_g.Parent = _pg
		_l1 = _ml(_g, UDim2.new(0.5, -50, 0.4, 0), UDim2.fromOffset(100, 50), 32)
		_l2 = _ml(_g, _sp or UDim2.new(0, 20, 0.5, 0), UDim2.fromOffset(110, 44), 26)
		_l2.Active = false
		_sd(_l2)
	end

	local function _hg()
		if _l1 then _l1.Visible = false end
		if _l2 then
			if _mv then
				_l2.Visible = true
				_l2.Text = _hc and "Active" or "CD 0.0"
			elseif _hc then
				_l2.Visible = true
				_l2.Text = "Active"
			else
				_l2.Visible = false
			end
		end
	end

	local function _fj()
		local _ch = _lp.Character
		local _hm = _ch and _ch:FindFirstChildOfClass("Humanoid")
		if not _hm or _hm.Health <= 0 then return end
		_hm.Jump = true
		_hm:ChangeState(Enum.HumanoidStateType.Jumping)
	end

	local function _oa()
		if not _en or not _curr() then return end
		local _nw = os.clock()
		if _nw < _c2 then return end

		_jd = true
		_bj()

		_tk = _tk + 1
		local _my = _tk
		_c1, _c2 = _nw, _nw + _cd2
		_hc = true

		local _og, _eg = pcall(_bg)
		if not _og then _msg("GUI error: " .. tostring(_eg)) end

		local _tl = _cd1
		local _j1 = false
		task.spawn(function()
			while _en and _curr() and _my == _tk do
				local _dt = _rs.Heartbeat:Wait()
				_tl = _tl - _dt
				if _tl < 0 then _tl = 0 end

				if not _j1 and _tl <= _fjr then
					_j1 = true
					_fj()
					task.delay(_jg, function()
						if _en and _curr() and _my == _tk then _fj() end
					end)
				end

				if _tl <= 0 then
					_jd = false
					_ubj()
				end

				local _t = os.clock()
				local _k = _c2 - _t
				
				if _l1 then
					_l1.Visible = _tl > 0
					if _tl > 0 then _l1.Text = string.format("%.1f", _tl) end
				end
				if _l2 then
					if _k > 0 then
						_l2.Visible = true
						_l2.Text = string.format("CD %.1f", _k) 
					end
				end
				if _tl <= 0 and _k <= 0 then break end
			end
			if _my == _tk then _hg() end
		end)
	end

	local function _scn()
		local _ps = { _lp:FindFirstChildOfClass("Backpack"), _lp.Character }
		for i = 1, 2 do
			local _p = _ps[i]
			if _p then
				for _, _c in ipairs(_p:GetChildren()) do
					if _c:IsA("Tool") and _c.Name == "Fireflies" and not _hk[_c] then
						_hk[_c] = true
						table.insert(_cn, _c.Activated:Connect(function() _oa() end))
					end
				end
			end
		end
	end

	local function _rc()
		_tk = _tk + 1
		_c2 = 0
		_hc = true
		_jd = false
		_ubj()
		_hg()
	end

	local function _s()
		_bg()
		_st = _st + 1
		local _my = _st
		table.insert(_cn, _lp.CharacterAdded:Connect(function()
			if _en and _curr() then _rc() end
		end))
		task.spawn(function()
			while _en and _curr() and _my == _st do
				pcall(_scn)
				task.wait(0.5)
			end
		end)
	end

	local function _stp()
		_st = _st + 1
		_tk = _tk + 1
		_c2 = 0
		_hc = false
		_jd = false
		_ubj()
		_hg()
		for _, _c in ipairs(_cn) do pcall(function() _c:Disconnect() end) end
		table.clear(_cn)
		table.clear(_hk)
	end

	_ui.apply = function(b)
		if not _curr() then return end
		_en = b
		if _en then
			local _os, _es = pcall(_s)
			if _os then _msg("Firefly Timer enabled")
			else _msg("Start error: " .. tostring(_es)) end
		else
			pcall(_stp)
			_msg("Firefly Timer disabled")
		end
	end

	_ui.move = function(b)
		if not _curr() then return end
		_mv = b
		_bg()
		_l2.Active = b
		if os.clock() >= _c2 then _hg() end
	end

	_ui.save = function()
		if not _curr() then return end
		_bg()
		local _sz = _g.AbsoluteSize
		if _sz.X <= 0 or _sz.Y <= 0 then return end
		local _lpos = _l2.Position
		local _x = math.clamp(_lpos.X.Scale + _lpos.X.Offset / _sz.X, 0, 0.95)
		local _y = math.clamp(_lpos.Y.Scale + _lpos.Y.Offset / _sz.Y, 0, 0.95)
		_sp = UDim2.fromScale(_x, _y)
		local _wr = false
		pcall(function()
			if writefile then
				writefile(_pf, _http:JSONEncode({ x = _x, y = _y }))
				_wr = true
			end
		end)
		if _wr then
			_msg("Cooldown position saved")
		else
			_msg("Position kept for this session (executor can't save files)")
		end
	end
end

local _ok3, _err3 = xpcall(_init, function(e) return tostring(e) end)
if not _ok3 then
	_msg("Init error: " .. tostring(_err3))
	warn("[Firefly Timer] init failed: " .. tostring(_err3))
else
	_ui.ready = true
	if _ui.d1 then _exec(_ui.apply, true) end
	if _ui.d2 then _exec(_ui.move, true) end
	if _ui.d3 then _exec(_ui.auto, true) end
end
