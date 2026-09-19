--!strict
-- liv4cheets - Internal | Single-file launcher
-- All modules inline. Paste into Potassium and run.

----------------------------------------------------------------------
-- Config
----------------------------------------------------------------------
local Config = {}
Config.Defaults = {
	Combat = {
		AimbotEnabled = false,
		AimFOV = 120,
		AimSmoothing = 0.12,
		AimPart = "Head",
		TargetDummies = true,
		Prediction = 0.015,
		WallCheck = false,
		SilentEnabled = false,
		SilentFOV = 90,
		SilentChance = 100,
		TriggerEnabled = false,
		TriggerKey = Enum.KeyCode.T,
		TriggerDelay = 40,
		RageEnabled = false,
		RageVoidSpam = false,
		RageWeapon = "Assault Rifle",
		RageAntiAim = false,
	},
	Visual = {
		ESPEnabled = false,
		Box = true,
		FilledBox = false,
		FilledNoOutline = false,
		Skeleton = false,
		Chams = false,
		ChamsColor = Color3.fromRGB(198, 255, 62),
		Name = true,
		Distance = true,
		HealthBar = true,
		HealthBarThickness = 4,
		Weapon = false,
		ShowTeam = false,
		MaxDistance = 2000,
		TextSize = 13,
	},
	Exploits = {
		Fly = false,
		FlySpeed = 60,
		Noclip = false,
		AvatarUserId = "",
		LevelValue = "",
		StreakValue = "",
		BoardValue = "",
		RankedValue = "",
		AnimAssetId = "",
	},
	SkinChanger = {
		Weapon = "",
		Skin = "",
		ColorHex = "C6FF3E",
		WrapHex = "C6FF3E",
		Charm = "None",
		Finisher = "None",
	},
	Misc = {
		Theme = "Default",
		MenuFont = "GothamMedium",
		GameFontSize = 13,
		Anims = true,
		Watermark = "liv4cheets",
		ToggleKey = Enum.KeyCode.RightShift,
		UnloadKey = Enum.KeyCode.End,
	},
	Meta = {
		AllowedPlaceIds = { 17625359962, 17720162456 },
		Name = "liv4cheets - Internal",
		Version = "v1.0-internal",
	},
}

local function deepCopy(t)
	local out = {}
	for k, v in pairs(t) do
		if type(v) == "table" then out[k] = deepCopy(v)
		else out[k] = v end
	end
	return out
end

local function deepMerge(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" and type(dst[k]) == "table" then
			deepMerge(dst[k], v)
		else
			dst[k] = v
		end
	end
	return dst
end

if getgenv().LIV4Config == nil and getgenv().RivalsConfig ~= nil then
	getgenv().LIV4Config = deepCopy(getgenv().RivalsConfig)
end
if getgenv().LIV4Config == nil then
	getgenv().LIV4Config = deepCopy(Config.Defaults)
else
	local merged = deepCopy(Config.Defaults)
	deepMerge(merged, getgenv().LIV4Config)
	getgenv().LIV4Config = merged
end
getgenv().RivalsConfig = getgenv().LIV4Config
Config.Current = getgenv().LIV4Config

----------------------------------------------------------------------
-- Utils
----------------------------------------------------------------------
local Utils = {}
local function cref<T>(inst)
	local g = getgenv()
	local f = (g and (g :: any).cloneref) or rawget(_G, "cloneref")
	if type(f) == "function" then
		local ok, out = pcall(f, inst)
		if ok and out then return out end
	end
	return inst
end
Utils.Services = {
	Players = cref(game:GetService("Players")),
	RunService = cref(game:GetService("RunService")),
	UserInputService = cref(game:GetService("UserInputService")),
	Workspace = cref(game:GetService("Workspace")),
	TweenService = cref(game:GetService("TweenService")),
	ReplicatedStorage = cref(game:GetService("ReplicatedStorage")),
}
function Utils.LocalPlayer() return Utils.Services.Players.LocalPlayer end
function Utils.Character(plr) plr = plr or Utils.LocalPlayer(); return plr and plr.Character or nil end
function Utils.Humanoid(char) if not char then return nil end; return char:FindFirstChildOfClass("Humanoid") end
function Utils.RootPart(char) if not char then return nil end; return char:FindFirstChild("HumanoidRootPart") end
function Utils.IsAlive(char) local hum = Utils.Humanoid(char); return hum ~= nil and hum.Health > 0 end
function Utils.IsAlly(char) local flag = char and char:FindFirstChild("_is_ally"); return flag ~= nil and (flag :: any).Value == true end
function Utils.IsEnemy(player)
	local lp = Utils.LocalPlayer()
	if player == lp then return false end
	local cfg = (getgenv() :: any).RivalsConfig
	if cfg and cfg.Aimbot and cfg.Aimbot.TeamCheck then
		if lp and lp.Team and player.Team and lp.Team == player.Team then return false end
	end
	local char = player.Character
	if not char then return false end
	if Utils.IsAlly(char) then return false end
	return Utils.IsAlive(char)
end
function Utils.GetHitPart(char, mode)
	if not char then return nil end
	mode = mode or "Head"
	if mode == "Closest" then
		local cam = Utils.Services.Workspace.CurrentCamera
		if not cam then return nil end
		local best, bestD = nil, math.huge
		for _, d in ipairs(char:GetChildren()) do
			if d:IsA("BasePart") then
				local m = (d.Position - cam.CFrame.Position).Magnitude
				if m < bestD then bestD = m; best = d end
			end
		end
		return best
	end
	return char:FindFirstChild("HitboxHead") or char:FindFirstChild(mode) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end
function Utils.IsVisible(from, target, ignoreChar)
	local ws = Utils.Services.Workspace
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local f = { ignoreChar, Utils.Character() }
	params.FilterDescendantsInstances = f
	local dir = target.Position - from
	local res = ws:Raycast(from, dir, params)
	if not res then return true end
	return res.Instance:IsDescendantOf(target.Parent)
end
function Utils.ScreenCenter()
	local cam = Utils.Services.Workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	return Vector2.new(vs.X / 2, vs.Y / 2)
end

----------------------------------------------------------------------
-- UI
----------------------------------------------------------------------
local UI = {}
local THEMES = {
	Default = {
		BG = Color3.fromRGB(16, 18, 24),
		Panel = Color3.fromRGB(22, 25, 33),
		Card = Color3.fromRGB(28, 32, 42),
		Accent = Color3.fromRGB(198, 255, 62),
		AccentText = Color3.fromRGB(12, 14, 18),
		Text = Color3.fromRGB(245, 248, 240),
		Dim = Color3.fromRGB(155, 165, 148),
		Stroke = Color3.fromRGB(55, 65, 55),
		ToggleOff = Color3.fromRGB(55, 62, 55),
		Hover = Color3.fromRGB(35, 40, 52),
	},
	Onyx = {
		BG = Color3.fromRGB(0, 0, 0),
		Panel = Color3.fromRGB(8, 8, 8),
		Card = Color3.fromRGB(14, 14, 14),
		Accent = Color3.fromRGB(255, 255, 255),
		AccentText = Color3.fromRGB(0, 0, 0),
		Text = Color3.fromRGB(255, 255, 255),
		Dim = Color3.fromRGB(180, 180, 180),
		Stroke = Color3.fromRGB(50, 50, 50),
		ToggleOff = Color3.fromRGB(55, 55, 55),
		Hover = Color3.fromRGB(25, 25, 25),
	},
}
local FONTS = {
	Gotham = Enum.Font.Gotham,
	GothamMedium = Enum.Font.GothamMedium,
	GothamBold = Enum.Font.GothamBold,
	GothamBlack = Enum.Font.GothamBlack,
	Code = Enum.Font.Code,
	Montserrat = Enum.Font.Montserrat,
	Arial = Enum.Font.Arial,
}

local Players = cref(game:GetService("Players"))
local UIS = cref(game:GetService("UserInputService"))
local Tween = cref(game:GetService("TweenService"))

local function protect(gui)
	local gethui = (getgenv() :: any).gethui
	if type(gethui) == "function" then
		local ok, h = pcall(gethui)
		if ok and h then gui.Parent = h; return end
	end
	pcall(function() gui.Parent = game:GetService("CoreGui") end)
	if gui.Parent == nil then gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
end

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do
		if k ~= "Parent" then pcall(function() o[k] = v end) end
	end
	o.Parent = parent
	return o
end

local function animsOn()
	local c = (getgenv() :: any).LIV4Config
	if c and c.Misc and c.Misc.Anims == false then return false end
	return true
end

function UI.New()
	if (getgenv() :: any).LIV4UI then
		pcall(function() (getgenv() :: any).LIV4UI:Destroy() end)
	end
	local C = (getgenv() :: any).LIV4Config
	local T = THEMES[(C and C.Misc and C.Misc.Theme) or "Default"] or THEMES.Default

	local gui = Instance.new("ScreenGui")
	gui.Name = "liv4cheets"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = true
	protect(gui);
	(getgenv() :: any).LIV4UI = gui

	local root = mk("Frame", { Name = "Root", Size = UDim2.fromOffset(640, 440), Position = UDim2.new(0.5, -320, 0.5, -220), BackgroundColor3 = T.BG, BorderSizePixel = 0, Active = true }, gui)
	mk("UICorner", { CornerRadius = UDim.new(0, 12) }, root)
	local rootStroke = mk("UIStroke", { Color = T.Stroke, Thickness = 1 }, root)
	do
		local sc = mk("UIScale", { Scale = 0.97 }, root)
		if not (getgenv() :: any).LIV4Config or (getgenv() :: any).LIV4Config.Misc.Anims ~= false then
			pcall(function() Tween:Create(sc, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play() end)
		else
			sc.Scale = 1
		end
	end

	local bar = mk("Frame", { Name = "PanelBG", Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = T.Panel, BorderSizePixel = 0 }, root)
	mk("UICorner", { CornerRadius = UDim.new(0, 12) }, bar)
	mk("Frame", { Name = "PanelBG", Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 1, -16), BorderSizePixel = 0, BackgroundColor3 = T.Panel }, bar)

	local fav = mk("Frame", { Name = "AccentBG", Size = UDim2.fromOffset(26, 26), Position = UDim2.new(0, 14, 0.5, -13), BackgroundColor3 = T.Accent, BorderSizePixel = 0 }, bar)
	mk("UICorner", { CornerRadius = UDim.new(0, 8) }, fav)
	mk("TextLabel", { Name = "AccentLabel", Text = "L4", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = T.AccentText, Font = Enum.Font.GothamBlack, TextSize = 13 }, fav)

	mk("TextLabel", { Name = "MainText", Text = "liv4cheets - Internal", Size = UDim2.new(0, 220, 1, 0), Position = UDim2.new(0, 48, 0, 0), BackgroundTransparency = 1, TextColor3 = T.Text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, bar)
	mk("TextLabel", { Name = "DimText", Text = "v1.0-internal", Size = UDim2.new(0, 110, 1, 0), Position = UDim2.new(0, 232, 0, 0), BackgroundTransparency = 1, TextColor3 = T.Dim, Font = Enum.Font.Code, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, bar)
	mk("TextLabel", { Name = "DimText", Text = "RShift", Size = UDim2.new(0, 80, 1, 0), Position = UDim2.new(1, -90, 0, 0), BackgroundTransparency = 1, TextColor3 = T.Dim, Font = Enum.Font.Code, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right }, bar)

	local side = mk("Frame", { Name = "PanelBG", Size = UDim2.new(0, 160, 1, -42), Position = UDim2.new(0, 0, 0, 42), BackgroundColor3 = T.Panel, BorderSizePixel = 0 }, root)
	mk("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, side)
	mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, side)

	local content = mk("Frame", { Size = UDim2.new(1, -160, 1, -42), Position = UDim2.new(0, 160, 0, 42), BackgroundTransparency = 1 }, root)
	mk("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14) }, content)

	local foot = mk("TextLabel", { Name = "DimText", Text = "liv4cheets  •  connected", Size = UDim2.new(1, -170, 0, 16), Position = UDim2.new(0, 166, 1, -24), BackgroundTransparency = 1, TextColor3 = T.Dim, Font = Enum.Font.Code, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, root)

	do
		local drag, s, sp = false, nil, nil
		bar.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then drag, s, sp = true, i.Position, root.Position end
		end)
		UIS.InputChanged:Connect(function(i)
			if drag and i.UserInputType == Enum.UserInputType.MouseMovement and s then
				local d = i.Position - s
				root.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
			end
		end)
		UIS.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
		end)
	end

	local win = { Gui = gui, Root = root, _pages = {}, _tabBtns = {} }

	function win:ApplyTheme(name)
		local th = THEMES[name] or THEMES.Default
		root.BackgroundColor3 = th.BG
		rootStroke.Color = th.Stroke
		for _, d in ipairs(root:GetDescendants()) do
			if d.Name == "PanelBG" and d:IsA("GuiObject") then (d :: any).BackgroundColor3 = th.Panel
			elseif d.Name == "CardBG" and d:IsA("GuiObject") then (d :: any).BackgroundColor3 = th.Card
			elseif d.Name == "AccentBG" and d:IsA("GuiObject") then (d :: any).BackgroundColor3 = th.Accent
			elseif d.Name == "MainText" and d:IsA("TextLabel") then (d :: any).TextColor3 = th.Text
			elseif d.Name == "DimText" and d:IsA("TextLabel") then (d :: any).TextColor3 = th.Dim
			elseif d.Name == "AccentLabel" then (d :: any).TextColor3 = th.AccentText end
		end
	end

	function win:SetMenuFont(name)
		local f = FONTS[name] or Enum.Font.GothamMedium
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
				if (d :: any).Font ~= Enum.Font.Code then (d :: any).Font = f end
			end
		end
	end

	local function hover(btn, base)
		if not animsOn() then return end
		local hoverColor = base:Lerp(Color3.new(1, 1, 1), 0.12)
		btn.MouseEnter:Connect(function()
			pcall(function() Tween:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = hoverColor }):Play() end)
		end)
		btn.MouseLeave:Connect(function()
			pcall(function() Tween:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = base }):Play() end)
		end)
	end

	function win:Tab(name)
		local btn = mk("TextButton", { Name = "CardBG", Text = name, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = T.Card, TextColor3 = T.Text, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, BorderSizePixel = 0 }, side)
		mk("UICorner", { CornerRadius = UDim.new(0, 10) }, btn)
		mk("UIPadding", { PaddingLeft = UDim.new(0, 20) }, btn)
		local sel = mk("Frame", { Name = "AccentBG", Size = UDim2.new(0, 3, 0, 22), Position = UDim2.new(0, 6, 0.5, -11), BackgroundColor3 = T.Accent, BorderSizePixel = 0, Visible = false }, btn)
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, sel)
		hover(btn, T.Card)

		local page = mk("ScrollingFrame", { Size = UDim2.new(1, 0, 1, -8), BackgroundTransparency = 1, ScrollBarThickness = 2, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false }, content)
		mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)

		local function select()
			for _, p in ipairs(win._pages) do (p :: any).Visible = false end
			for _, b in ipairs(win._tabBtns) do
				((b :: any):FindFirstChildOfClass("Frame") :: any).Visible = false
				(b :: any).BackgroundColor3 = T.Card
			end
			page.Visible = true
			sel.Visible = true
			btn.BackgroundColor3 = T.Card:Lerp(T.Accent, 0.14)
		end
		btn.MouseButton1Click:Connect(select)
		if #win._pages == 0 then page.Visible = true; sel.Visible = true end
		table.insert(win._pages, page)
		table.insert(win._tabBtns, btn)

		local tab = {}
		function tab:Section(t)
			local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, page)
			mk("Frame", { Name = "AccentBG", Size = UDim2.new(0, 3, 0, 14), Position = UDim2.new(0, 0, 0.5, -7), BackgroundColor3 = T.Accent, BorderSizePixel = 0 }, row)
			mk("TextLabel", { Name = "DimText", Text = string.upper(t), Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, TextColor3 = T.Dim, Font = Enum.Font.Code, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, row)
		end
		function tab:Toggle(label, default, cb)
			local st = default
			local row = mk("Frame", { Name = "CardBG", Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = T.Card, BorderSizePixel = 0 }, page)
			mk("UICorner", { CornerRadius = UDim.new(0, 10) }, row)
			mk("TextLabel", { Name = "MainText", Text = label, Size = UDim2.new(1, -72, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, TextColor3 = T.Text, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, row)
			local pill = mk("TextButton", { Text = "", Size = UDim2.fromOffset(44, 24), Position = UDim2.new(1, -56, 0.5, -12), BackgroundColor3 = st and T.Accent or T.ToggleOff, AutoButtonColor = false, BorderSizePixel = 0 }, row)
			mk("UICorner", { CornerRadius = UDim.new(1, 0) }, pill)
			local knob = mk("Frame", { Size = UDim2.fromOffset(16, 16), Position = st and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 4, 0.5, -8), BackgroundColor3 = st and T.AccentText or Color3.new(1, 1, 1), BorderSizePixel = 0 }, pill)
			mk("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
			local function sync(animate)
				local c1 = st and T.Accent or T.ToggleOff
				if animate and animsOn() then
					pcall(function()
						Tween:Create(pill, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = c1 }):Play()
						Tween:Create(knob, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = st and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 4, 0.5, -8) }):Play()
					end)
				else
					pill.BackgroundColor3 = c1
					knob.Position = st and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 4, 0.5, -8)
				end
				knob.BackgroundColor3 = st and T.AccentText or Color3.new(1, 1, 1)
			end
			pill.MouseButton1Click:Connect(function()
				st = not st
				sync(true)
				pcall(cb, st)
			end)
			sync(false)
		end
		function tab:Slider(label, min, max, default, cb)
			local val = default
			local lab = mk("TextLabel", { Name = "MainText", Text = label .. "  " .. tostring(math.round(val * 100) / 100), Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, TextColor3 = T.Text, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, page)
			local track = mk("TextButton", { Name = "Track", Text = "", Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = T.Stroke, AutoButtonColor = false, BorderSizePixel = 0 }, page)
			mk("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
			local fill = mk("Frame", { Name = "AccentBG", Size = UDim2.new((val - min) / math.max(max - min, 0.001), 0, 1, 0), BackgroundColor3 = T.Accent, BorderSizePixel = 0 }, track)
			mk("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
			local knobS = mk("Frame", { Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new((val - min) / math.max(max - min, 0.001), 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 2 }, track)
			mk("UICorner", { CornerRadius = UDim.new(1, 0) }, knobS)
			local function setX(x)
				local p = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
				val = min + (max - min) * p
				fill.Size = UDim2.new(p, 0, 1, 0)
				knobS.Position = UDim2.new(p, 0, 0.5, 0)
				lab.Text = label .. "  " .. tostring(math.round(val * 100) / 100)
				pcall(cb, val)
			end
			track.MouseButton1Down:Connect(function(x)
				setX(x)
				local c = UIS.InputChanged:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseMovement then setX(i.Position.X) end
				end)
				UIS.InputEnded:Wait()
				if c then c:Disconnect() end
			end)
		end
		function tab:Dropdown(label, values, default, cb)
			local sel = default
			if not table.find(values, sel) then sel = values[1] end
			local lab = mk("TextLabel", { Name = "MainText", Text = label, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, TextColor3 = T.Text, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, page)
			local b = mk("TextButton", { Name = "CardBG", Text = "", Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.Card, AutoButtonColor = false, BorderSizePixel = 0 }, page)
			mk("UICorner", { CornerRadius = UDim.new(0, 10) }, b)
			mk("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, b)
			local bText = mk("TextLabel", { Name = "MainText", Text = sel, Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1, TextColor3 = T.Text, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, b)
			mk("TextLabel", { Name = "DimText", Text = "▾", Size = UDim2.new(0, 24, 1, 0), Position = UDim2.new(1, -24, 0, 0), BackgroundTransparency = 1, TextColor3 = T.Dim, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right }, b)
			hover(b, T.Card)
			b.MouseEnter:Connect(function()
				if animsOn() then pcall(function() Tween:Create(b, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = T.Hover }):Play() end) end
			end)
			b.MouseLeave:Connect(function()
				if animsOn() then pcall(function() Tween:Create(b, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = T.Card }):Play() end) end
			end)
			local catcher, pop
			local function close()
				if catcher then catcher:Destroy(); catcher = nil end
				if pop then pop:Destroy(); pop = nil end
			end
			b.MouseButton1Click:Connect(function()
				if pop then close(); return end
				local rp, bp = root.AbsolutePosition, b.AbsolutePosition
				catcher = mk("TextButton", { Text = "", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, AutoButtonColor = false, ZIndex = 90 }, root)
				catcher.MouseButton1Click:Connect(close)
				pop = mk("Frame", { Name = "CardBG", Position = UDim2.new(0, bp.X - rp.X, 0, bp.Y - rp.Y + 36), Size = UDim2.new(0, b.AbsoluteSize.X, 0, math.min(#values * 30 + 12, 240)), BackgroundColor3 = T.Card, BorderSizePixel = 0, ZIndex = 91 }, root)
				mk("UICorner", { CornerRadius = UDim.new(0, 10) }, pop)
				mk("UIStroke", { Color = T.Stroke, Thickness = 1, Transparency = 0.5 }, pop)
				mk("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, pop)
				local scroll = mk("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 2, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y }, pop)
				mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
				for _, v in ipairs(values) do
					local mark = (v == sel) and "✓  " or "    "
					local it = mk("TextButton", { Text = mark .. v, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, TextColor3 = (v == sel) and T.Accent or T.Text, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, BorderSizePixel = 0 }, scroll)
					mk("UICorner", { CornerRadius = UDim.new(0, 6) }, it)
					mk("UIPadding", { PaddingLeft = UDim.new(0, 10) }, it)
					it.MouseButton1Click:Connect(function()
						sel = v
						bText.Text = v
						lab.Text = label .. "  " .. v
						pcall(cb, v)
						close()
					end)
				end
			end)
		end
		function tab:Textbox(label, placeholder, default, cb)
			mk("TextLabel", { Name = "MainText", Text = label, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, TextColor3 = T.Text, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, page)
			local box = mk("TextBox", { Name = "CardBG", Text = default or "", PlaceholderText = placeholder or "", Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = T.Card, TextColor3 = T.Text, PlaceholderColor3 = T.Dim, Font = Enum.Font.Code, TextSize = 12, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0 }, page)
			mk("UICorner", { CornerRadius = UDim.new(0, 10) }, box)
			mk("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, box)
			box.FocusLost:Connect(function(enter)
				if enter then pcall(cb, box.Text) end
			end)
		end
		function tab:Button(label, cb)
			local b = mk("TextButton", { Name = "AccentBG", Text = label, Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.Accent, TextColor3 = T.AccentText, Font = Enum.Font.GothamBold, TextSize = 13, AutoButtonColor = false, BorderSizePixel = 0 }, page)
			mk("UICorner", { CornerRadius = UDim.new(0, 10) }, b)
			local bs = mk("UIStroke", { Color = T.Accent, Transparency = 0.5, Thickness = 1 }, b)
			hover(b, T.Accent)
			b.MouseButton1Click:Connect(function()
				if animsOn() then
					pcall(function()
						Tween:Create(b, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 32) }):Play()
						task.wait(0.07)
						Tween:Create(b, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 34) }):Play()
					end)
				end
				pcall(cb)
			end)
		end
		return tab
	end

	UIS.InputBegan:Connect(function(i, gpe)
		if gpe then return end
		local cfg = (getgenv() :: any).LIV4Config
		if i.KeyCode == ((cfg and cfg.Misc and cfg.Misc.ToggleKey) or Enum.KeyCode.RightShift) then
			root.Visible = not root.Visible
		end
		if i.KeyCode == ((cfg and cfg.Misc and cfg.Misc.UnloadKey) or Enum.KeyCode.End) then
			pcall(function() gui:Destroy() end)
		end
	end)

	return win
end

----------------------------------------------------------------------
-- Aimbot
----------------------------------------------------------------------
local Aimbot = {}
function Aimbot.Start(Utils, Config)
	local S = Utils.Services
	local Players, RS, UIS = S.Players, S.RunService, S.UserInputService

	local function C()
		return (getgenv() :: any).LIV4Config or (getgenv() :: any).RivalsConfig or Config.Current
	end
	local function combat()
		local c = C()
		if c.Combat then return c.Combat end
		return { AimbotEnabled = c.Aimbot.Enabled, AimFOV = c.Aimbot.FOV, AimSmoothing = c.Aimbot.Smoothing, AimPart = c.Aimbot.HitPart }
	end

	local fov = Drawing.new("Circle") :: any
	fov.Thickness = 1; fov.Filled = false
	local sFov = Drawing.new("Circle") :: any
	sFov.Thickness = 1; sFov.Filled = false
	local dot = Drawing.new("Circle") :: any
	dot.Radius = 3; dot.Filled = true; dot.Visible = false

	local sticky = nil

	local function center()
		local cam = S.Workspace.CurrentCamera
		local vs = cam and cam.ViewportSize or Vector2.new(1920, 1080)
		return Vector2.new(vs.X / 2, vs.Y / 2)
	end

	local function partVelocity(part)
		local ok, v = pcall(function() return (part :: any).AssemblyLinearVelocity end)
		if ok and typeof(v) == "Vector3" then return v end
		local hrp = part.Parent and (part.Parent :: any):FindFirstChild("HumanoidRootPart")
		if hrp then
			local ok2, v2 = pcall(function() return (hrp :: any).AssemblyLinearVelocity end)
			if ok2 and typeof(v2) == "Vector3" then return v2 end
		end
		return Vector3.zero
	end

	local function visible(from, part)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local lp = Players.LocalPlayer
		local ignore = { lp and lp.Character, workspace.CurrentCamera }
		params.FilterDescendantsInstances = ignore
		local dir = part.Position - from
		local res = S.Workspace:Raycast(from, dir, params)
		if not res then return true end
		local hitModel = res.Instance:FindFirstAncestorOfClass("Model")
		if not hitModel then return false end
		if hitModel == part.Parent then return true end
		if res.Instance == part or part:IsDescendantOf(hitModel) then return true end
		return false
	end

	local function validChar(ch)
		local hum = (ch :: any):FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then return false end
		if Utils.IsAlly(ch) then return false end
		return true
	end

	local function targets(wantDummies)
		local out = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= Players.LocalPlayer and p.Character and validChar(p.Character) then
				table.insert(out, p.Character)
			end
		end
		if wantDummies then
			for _, d in ipairs(S.Workspace:GetDescendants()) do
				if d:IsA("Model") and d.Name:lower():find("dummy") and validChar(d) then
					table.insert(out, d)
				end
			end
			for _, n in ipairs({ "Dummies", "Targets", "Bots" }) do
				local f = S.Workspace:FindFirstChild(n)
				if f then
					for _, m in ipairs(f:GetChildren()) do
						if m:IsA("Model") and validChar(m) then table.insert(out, m) end
					end
				end
			end
		end
		return out
	end

	local function acquire(px, mode, wantDummies, wall)
		local cam = S.Workspace.CurrentCamera
		if not cam then return nil end
		if sticky and sticky.Parent then
			local m = (sticky :: BasePart).Parent
			if m and validChar(m) then
				local s, on = cam:WorldToViewportPoint((sticky :: BasePart).Position)
				if on and (Vector2.new(s.X, s.Y) - center()).Magnitude < px * 1.5 then
					if not wall or visible(cam.CFrame.Position, sticky) then return sticky end
				end
			end
			sticky = nil
		end
		local cc = center()
		local candidates = {}
		for _, ch in ipairs(targets(wantDummies)) do
			local part = Utils.GetHitPart(ch, mode)
			if not part then continue end
			local s, on = cam:WorldToViewportPoint(part.Position)
			if not on then continue end
			local d = (Vector2.new(s.X, s.Y) - cc).Magnitude
			if d <= px then
				if wall and not visible(cam.CFrame.Position, part) then continue end
				candidates[part] = d
			end
		end
		local best, bd = nil, px
		for part, d in pairs(candidates) do
			if d < bd then bd, best = d, part end
		end
		sticky = best
		return best
	end

	RS:BindToRenderStep("LIV4Aimbot", Enum.RenderPriority.Camera.Value + 1, function()
		local cb = combat()
		local cam = S.Workspace.CurrentCamera
		if not cam then return end
		local cc = center()
		fov.Visible = cb.AimbotEnabled
		fov.Position = cc; fov.Radius = cb.AimFOV
		sFov.Visible = cb.SilentEnabled
		sFov.Position = cc; sFov.Radius = cb.SilentFOV
		if not cb.AimbotEnabled then sticky = nil; dot.Visible = false; return end
		if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then sticky = nil; dot.Visible = false; return end
		local t = acquire(cb.AimFOV, cb.AimPart, cb.TargetDummies ~= false, cb.WallCheck == true)
		if not t then dot.Visible = false; return end
		local pred = cb.Prediction or 0
		local aimPos = t.Position + partVelocity(t) * pred
		local s, on = cam:WorldToViewportPoint(aimPos)
		if on then dot.Position = Vector2.new(s.X, s.Y); dot.Visible = true else dot.Visible = false end
		local targetCF = CFrame.lookAt(cam.CFrame.Position, aimPos)
		local lerpAmt = math.clamp(cb.AimSmoothing, 0.01, 1)
		cam.CFrame = cam.CFrame:Lerp(targetCF, lerpAmt)
	end)

	function Aimbot.SilentTarget()
		local cb = combat()
		if not cb.SilentEnabled then return nil end
		if math.random(100) > (cb.SilentChance or 100) then return nil end
		local t = acquire(cb.SilentFOV, cb.AimPart, false, false)
		if not t then return nil end
		return t.Position + partVelocity(t) * (cb.Prediction or 0)
	end

	function Aimbot.Destroy()
		pcall(function() RS:UnbindFromRenderStep("LIV4Aimbot") end)
		for _, d in ipairs({ fov, sFov, dot }) do pcall(function() d:Remove() end) end
		sticky = nil
	end
	(getgenv() :: any).LIV4Aim = Aimbot
	return Aimbot
end

----------------------------------------------------------------------
-- SilentAim
----------------------------------------------------------------------
local SilentAim = {}
function SilentAim.Start(Utils, Config, getTarget)
	local g = getgenv() :: any
	if type(g.hookmetamethod) ~= "function" or type(g.getnamecallmethod) ~= "function" or type(g.checkcaller) ~= "function" or type(g.newcclosure) ~= "function" then
		warn("[liv4] silent: executor lacks hook fns, silent aim unavailable")
		return SilentAim
	end
	if g.LIV4SilentHooked then return SilentAim end
	g.LIV4SilentHooked = true

	local old = g.hookmetamethod(game, "__namecall", g.newcclosure(function(self, ...)
		local args = { ... }
		local okM, method = pcall(g.getnamecallmethod)
		if okM and method == "FireServer" then
			local okC, isCallerLocal = pcall(g.checkcaller)
			if okC and isCallerLocal and typeof(self) == "Instance" then
				local nm = ""
				pcall(function() nm = (self :: Instance).Name end)
				if nm == "UseItem" then
					local c = g.LIV4Config or Config.Current
					local cb = c and c.Combat
					if cb and cb.SilentEnabled then
						local okT, pos = pcall(getTarget)
						if okT and typeof(pos) == "Vector3" then
							for i, a in ipairs(args) do
								if type(a) == "table" and typeof(a.position) == "Vector3" then
									local cp = {}
									for k, v in pairs(a) do cp[k] = v end
									cp.position = pos
									args[i] = cp
									break
								end
							end
						end
					end
				end
			end
		end
		return old(self, unpack(args))
	end))
	return SilentAim
end

----------------------------------------------------------------------
-- Triggerbot
----------------------------------------------------------------------
local Triggerbot = {}
function Triggerbot.Start(Utils, Config, shootFn)
	local S = Utils.Services
	local cb = function() return (getgenv() :: any).LIV4Config or Config.Current end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local HIT = { HitboxBody = true, HitboxHead = true, HitboxHands = true }

	S.RunService.Heartbeat:Connect(function()
		local c = cb()
		local t = c.Combat or c.Triggerbot
		local en = t.TriggerEnabled ~= nil and t.TriggerEnabled or t.Enabled
		if not en then return end
		if not S.UserInputService:IsKeyDown(t.TriggerKey or Enum.KeyCode.T) then return end
		local cam = S.Workspace.CurrentCamera
		if not cam then return end
		local lp = S.Players.LocalPlayer
		params.FilterDescendantsInstances = { lp and lp.Character }
		local res = S.Workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 600, params)
		if not res or not HIT[res.Instance.Name] then return end
		local m = res.Instance:FindFirstAncestorOfClass("Model")
		if not m then return end
		local h = m:FindFirstChildOfClass("Humanoid")
		if not h or h.Health <= 0 or Utils.IsAlly(m) then return end
		task.delay((t.TriggerDelay or 40) / 1000, function()
			if shootFn then pcall(shootFn)
			else pcall(function() mouse1click() end)
			end
		end)
	end)
	return Triggerbot
end

----------------------------------------------------------------------
-- ESP
----------------------------------------------------------------------
local ESP = {}
function ESP.Start(Utils, Config)
	local S = Utils.Services
	local Players, RS = S.Players, S.RunService
	local function C() return (getgenv() :: any).LIV4Config or Config.Current end
	local function V() local c = C(); return c.Visual or {} end

	local allDrawings = {}
	local conns = {}
	local function track(d) table.insert(allDrawings, d); return d end
	local function on(c) table.insert(conns, c) end

	local cache = {}
	local function get(p)
		local e = cache[p]
		if e then return e end
		local function sq(f) return track(Drawing.new("Square") :: any) end
		local function tx()
			local t = track(Drawing.new("Text") :: any) :: any
			t.Center = true; t.Outline = true
			return t
		end
		local b1 = sq(false); b1.Filled = false; b1.Thickness = 1
		local f1 = sq(true); f1.Filled = true
		local n1, d1 = tx(), tx()
		local bg, hp = sq(true), sq(true)
		bg.Filled = true; hp.Filled = true
		local sk = {}
		for _ = 1, 6 do
			local l = track(Drawing.new("Line") :: any) :: any
			l.Thickness = 1
			table.insert(sk, l)
		end
		e = { box = b1, fill = f1, name = n1, dist = d1, hpBG = bg, hp = hp, skel = sk }
		e.box.Visible = false; e.fill.Visible = false; e.name.Visible = false; e.dist.Visible = false; e.hpBG.Visible = false; e.hp.Visible = false
		for _, l in ipairs(e.skel) do l.Visible = false end
		cache[p] = e
		return e
	end

	local function hide(e)
		e.box.Visible = false; e.fill.Visible = false; e.name.Visible = false; e.dist.Visible = false; e.hpBG.Visible = false; e.hp.Visible = false
		for _, l in ipairs(e.skel) do l.Visible = false end
	end
	local function hideAll()
		for _, e in pairs(cache) do hide(e) end
	end
	local function dropPlayer(p)
		local e = cache[p]
		if not e then return end
		hide(e)
		pcall(function() e.box:Remove() end)
		pcall(function() e.fill:Remove() end)
		pcall(function() e.name:Remove() end)
		pcall(function() e.dist:Remove() end)
		pcall(function() e.hpBG:Remove() end)
		pcall(function() e.hp:Remove() end)
		for _, l in ipairs(e.skel) do pcall(function() l:Remove() end) end
		cache[p] = nil
	end

	function ESP.Destroy()
		for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
		table.clear(conns)
		for _, e in pairs(cache) do hide(e) end
		for _, d in ipairs(allDrawings) do pcall(function() d:Remove() end) end
		table.clear(allDrawings); table.clear(cache)
	end
	pcall(function()
		local ts = game:GetService("TeleportService")
		if ts.TeleportInit then
			on(ts.TeleportInit:Connect(function() hideAll(); ESP.Destroy() end))
		end
	end)
		if Players then
			if Players.PlayerRemoving and Players.PlayerRemoving.Connect then
				local c = Players.PlayerRemoving:Connect(dropPlayer)
				if c then on(c) end
			end
			if Players.LocalPlayer then
				local lp = Players.LocalPlayer
				if lp then
					if lp.OnTeleport and lp.OnTeleport.Connect then
						local c = lp.OnTeleport:Connect(function() hideAll(); ESP.Destroy() end)
						if c then on(c) end
					end
					if lp.Character and lp.CharacterRemoving and lp.CharacterRemoving.Connect then
						local c = lp.CharacterRemoving:Connect(hideAll)
						if c then on(c) end
					end
					if lp.CharacterAdded and lp.CharacterAdded.Connect then
						local c = lp.CharacterAdded:Connect(function(ch)
							if ch.AncestryChanged and ch.AncestryChanged.Connect then
								ch.AncestryChanged:Connect(function()
									if not ch:IsDescendantOf(game) then hideAll() end
								end)
							end
						end)
						if c then on(c) end
					end
				end
			end
			if Players.PlayerAdded and Players.PlayerAdded.Connect then
				local c = Players.PlayerAdded:Connect(function(p)
					if p.CharacterRemoving and p.CharacterRemoving.Connect then
						local c2 = p.CharacterRemoving:Connect(function()
							local e = cache[p]
							if e then hide(e) end
						end)
						if c2 then on(c2) end
					end
				end)
				if c then on(c) end
			end
			if Players:GetPlayers() then
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= Players.LocalPlayer and p.CharacterRemoving and p.CharacterRemoving.Connect then
						local c = p.CharacterRemoving:Connect(function()
							local e = cache[p]
							if e then hide(e) end
						end)
						if c then on(c) end
					end
				end
			end
		end

	local function chamsOn(ch, color, on)
		local h = ch and ch:FindFirstChild("LIV4Chams")
		if on then
			if not h and ch:IsDescendantOf(game) then
				local hl = Instance.new("Highlight")
				hl.Name = "LIV4Chams"
				hl.FillColor = color
				hl.FillTransparency = 0.5
				hl.OutlineTransparency = 1
				hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				hl.Parent = ch
			end
		elseif h then h:Destroy() end
	end

	on(RS.RenderStepped:Connect(function()
		local v = V()
		local cam = S.Workspace.CurrentCamera
		if not cam then hideAll(); return end
		if not v.ESPEnabled then hideAll(); return end
		for _, p in ipairs(Players:GetPlayers()) do
			if p == Players.LocalPlayer then continue end
			local e = get(p)
			local ch = p.Character
			if not ch or not ch:IsDescendantOf(game) then hide(e); continue end
			local hrp = ch:FindFirstChild("HumanoidRootPart") :: BasePart?
			local hum = ch:FindFirstChildOfClass("Humanoid")
			if not hrp or not hum or hum.Health <= 0 then hide(e); chamsOn(ch, Color3.new(1, 1, 1), false); continue end
			if Utils.IsAlly(ch) and not v.ShowTeam then hide(e); chamsOn(ch, Color3.new(1, 1, 1), false); continue end
			chamsOn(ch, v.ChamsColor or Color3.fromRGB(198, 255, 62), v.Chams)
			local d3 = (hrp.Position - cam.CFrame.Position).Magnitude
			if d3 > (v.MaxDistance or 2000) then hide(e); continue end
			local t, onT = cam:WorldToViewportPoint((hrp.CFrame * CFrame.new(0, 2.5, 0)).Position)
			local b, onB = cam:WorldToViewportPoint((hrp.CFrame * CFrame.new(0, -3.5, 0)).Position)
			if not onT or not onB then hide(e); continue end
			local h = math.max(12, (Vector2.new(t.X, t.Y) - Vector2.new(b.X, b.Y)).Magnitude)
			local w = h * 0.6
			local x, y = b.X - w / 2, b.Y - h
			local ts = v.GameFontSize or v.TextSize or 13
			local hbT = v.HealthBarThickness or 4

			if v.FilledBox then
				e.fill.Size = Vector2.new(w, h); e.fill.Position = Vector2.new(x, y); e.fill.Transparency = 0.5; e.fill.Visible = true
				e.box.Size = Vector2.new(w, h); e.box.Position = Vector2.new(x, y); e.box.Visible = v.Box
			elseif v.FilledNoOutline then
				e.fill.Size = Vector2.new(w, h); e.fill.Position = Vector2.new(x, y); e.fill.Transparency = 0.5; e.fill.Visible = true
				e.box.Visible = false
			else
				e.fill.Visible = false
				e.box.Size = Vector2.new(w, h); e.box.Position = Vector2.new(x, y); e.box.Visible = v.Box
			end

			e.name.Size = ts; e.name.Text = p.Name; e.name.Position = Vector2.new(b.X, y - ts - 2); e.name.Visible = v.Name
			e.dist.Size = ts; e.dist.Text = "[" .. math.round(d3) .. "m]"; e.dist.Position = Vector2.new(b.X, b.Y + 2); e.dist.Visible = v.Distance

			if v.HealthBar then
				local r = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
				e.hpBG.Size = Vector2.new(hbT, h); e.hpBG.Position = Vector2.new(x - hbT - 2, y); e.hpBG.Visible = true
				e.hp.Size = Vector2.new(hbT, h * r); e.hp.Position = Vector2.new(x - hbT - 2, y + h * (1 - r))
				e.hp.Color = Color3.fromRGB(255 - math.round(255 * r), math.round(255 * r), 60); e.hp.Visible = true
			else
				e.hpBG.Visible = false; e.hp.Visible = false
			end

			if v.Skeleton then
				local head = ch:FindFirstChild("Head")
				local la = ch:FindFirstChild("LeftHand") or ch:FindFirstChild("LeftUpperArm")
				local ra = ch:FindFirstChild("RightHand") or ch:FindFirstChild("RightUpperArm")
				local ll = ch:FindFirstChild("LeftFoot") or ch:FindFirstChild("LeftLowerLeg")
				local rl = ch:FindFirstChild("RightFoot") or ch:FindFirstChild("RightLowerLeg")
				local pts = { head, hrp, la, ra, ll, rl }
				local sp = {}
				for i, part in ipairs(pts) do
					if part and (part :: any).Position then
						local s2, on2 = cam:WorldToViewportPoint((part :: any).Position)
						sp[i] = on2 and Vector2.new(s2.X, s2.Y) or nil
					end
				end
				local pairs = { { 1, 2 }, { 2, 3 }, { 2, 4 }, { 2, 5 }, { 2, 6 } }
				for i, pr in ipairs(pairs) do
					local a, bb = sp[pr[1]], sp[pr[2]]
					local L = e.skel[i]
					if a and bb then L.From, L.To, L.Visible = a, bb, true else L.Visible = false end
				end
				for i = 6, #e.skel do e.skel[i].Visible = false end
			else
				for _, L in ipairs(e.skel) do L.Visible = false end
			end
		end
	end));
	(getgenv() :: any).LIV4ESP = ESP
	return ESP
end

----------------------------------------------------------------------
-- Movement
----------------------------------------------------------------------
local Movement = {}
function Movement.Start(Utils, Config)
	local S = Utils.Services
	local function C() return (getgenv() :: any).LIV4Config or Config.Current end
	S.RunService.Heartbeat:Connect(function()
		local c = C()
		local ex = c.Exploits or c.Movement
		if not ex then return end
		local lp = S.Players.LocalPlayer
		local ch = lp and lp.Character
		local r = ch and ch:FindFirstChild("HumanoidRootPart") :: BasePart?
		local h = ch and ch:FindFirstChildOfClass("Humanoid")
		if not r or not h then return end
		local fly = ex.Fly
		local spd = ex.FlySpeed or 60
		if fly then
			h.PlatformStand = true
			local cam = S.Workspace.CurrentCamera
			local m = Vector3.zero
			local UIS = S.UserInputService
			if UIS:IsKeyDown(Enum.KeyCode.W) then m += cam.CFrame.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.S) then m -= cam.CFrame.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.A) then m -= cam.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.D) then m += cam.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then m += Vector3.yAxis end
			r.AssemblyLinearVelocity = if m.Magnitude > 0 then m.Unit * spd else Vector3.zero
			r.AssemblyAngularVelocity = Vector3.zero
		end
	end)
	S.RunService.Stepped:Connect(function()
		local c = C()
		local ex = c.Exploits or c.Movement
		if not ex or not ex.Noclip then return end
		local ch = S.Players.LocalPlayer and S.Players.LocalPlayer.Character
		if not ch then return end
		for _, p in ipairs(ch:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end)
	return Movement
end

----------------------------------------------------------------------
-- Effects
----------------------------------------------------------------------
local Effects = {}
function Effects.Start(Utils, Config)
	local S = Utils.Services
	function Effects.Hitmarker(ch, dmg)
		local c = (getgenv() :: any).LIV4Config or Config.Current
		local v = c.Visual
		local head = ch and (ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart"))
		if not head then return end
		local g = Instance.new("BillboardGui")
		g.Size = UDim2.fromScale(1, 1); g.AlwaysOnTop = true; g.Adornee = head; g.Parent = ch
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1); l.BackgroundTransparency = 1
		l.Text = tostring(math.round(dmg or 10)); l.Font = Enum.Font.GothamBlack; l.TextSize = 42; l.TextStrokeTransparency = 0; l.Parent = g
		task.delay(0.8, function() pcall(function() g:Destroy() end) end)
	end
	return Effects
end

----------------------------------------------------------------------
-- Ragebot
----------------------------------------------------------------------
local Ragebot = {}
function Ragebot.Start(Utils, Config)
	local S = Utils.Services
	local function C() return (getgenv() :: any).LIV4Config or Config.Current end
	local function R() local c = C(); return c.Combat or c.Ragebot end
	local n = 0
	local remote = nil
	pcall(function()
		local rs = S.ReplicatedStorage:WaitForChild("Remotes", 2)
		local f = rs and (rs :: any):WaitForChild("Fighter", 2)
		remote = f and (f :: any):WaitForChild("UseItem", 2)
	end)
	S.RunService.Heartbeat:Connect(function()
		local r = R()
		local en = r.RageEnabled ~= nil and r.RageEnabled or r.Enabled
		local vs = r.RageVoidSpam ~= nil and r.RageVoidSpam or r.VoidSpam
		if not en or not vs or not remote then return end
		local my = S.Players.LocalPlayer and S.Players.LocalPlayer.Character
		if not my or not my:FindFirstChild("EquippedItem") then return end
		local cam = S.Workspace.CurrentCamera
		local best, bd = nil, math.huge
		for _, p in ipairs(S.Players:GetPlayers()) do
			if p == S.Players.LocalPlayer then continue end
			local ch = p.Character
			if not ch or not Utils.IsAlive(ch) or Utils.IsAlly(ch) then continue end
			local hrp = ch:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp and cam then
				local d = (hrp.Position - cam.CFrame.Position).Magnitude
				if d < bd then bd, best = d, ch end
			end
		end
		if not best then return end
		local hb = Utils.GetHitPart(best, "Head")
		if not hb then return end
		n += 1
		local rf = (remote :: RemoteEvent).FireServer
		pcall(function()
			rf({ id = game:GetService("HttpService"):GenerateGUID(false), item = r.RageWeapon or r.WeaponName, position = hb.Position, attackNum = n })
		end)
	end)
	return Ragebot
end

----------------------------------------------------------------------
-- Spoofer
----------------------------------------------------------------------
local Spoofer = {}
local animTrack = nil
function Spoofer.Avatar(userIdStr)
	local id = tonumber(userIdStr)
	if not id then return "invalid user id" end
	local lp = game:GetService("Players").LocalPlayer
	local ch = lp and lp.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not hum then return "no character" end
	local ok, desc = pcall(function() return game:GetService("Players"):GetHumanoidDescriptionFromUserId(id) end)
	if not ok or not desc then return "bad user id" end
	pcall(function() hum:ApplyDescription(desc) end)
	return "applied " .. tostring(id)
end
local function setLeaderstat(name, value)
	local v = tonumber(value)
	if not v then return "invalid number" end
	local lp = game:GetService("Players").LocalPlayer
	local ls = lp and lp:FindFirstChild("leaderstats")
	if ls then
		for _, s in ipairs(ls:GetChildren()) do
			if string.lower(s.Name) == string.lower(name) or string.find(string.lower(s.Name), string.lower(name), 1, true) then
				pcall(function()
					if s:IsA("IntValue") or s:IsA("NumberValue") then (s :: any).Value = v
					elseif s:IsA("StringValue") then (s :: any).Value = tostring(v)
					end
				end)
			end
		end
	end
	local n = 0
	for _, g in ipairs(lp.PlayerGui:GetDescendants()) do
		if g:IsA("TextLabel") and string.find(string.lower(g.Text), string.lower(name), 1, true) then
			g.Text = string.gsub(g.Text, "%d+", tostring(v))
			n += 1
			if n > 6 then break end
		end
	end
	return "spoofed " .. name .. " -> " .. tostring(v) .. " (visual)"
end
function Spoofer.Level(v) return setLeaderstat("level", v) end
function Spoofer.Streak(v) return setLeaderstat("streak", v) .. " / " .. setLeaderstat("win", v) end
function Spoofer.Board(v) return setLeaderstat("win", v) end
function Spoofer.Ranked(v) return setLeaderstat("rank", v) end
function Spoofer.PlayAnim(assetStr)
	local id = tonumber(assetStr)
	if not id then return "invalid asset id" end
	local lp = game:GetService("Players").LocalPlayer
	local ch = lp and lp.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local anim = hum and hum:FindFirstChildOfClass("Animator") or hum
	if not hum then return "no humanoid" end
	if animTrack then pcall(function() (animTrack :: AnimationTrack):Stop() end); animTrack = nil end
	local a = Instance.new("Animation")
	a.AnimationId = "rbxassetid://" .. tostring(id)
	local ok, tr = pcall(function() return (hum :: Humanoid):LoadAnimation(a) end)
	if not ok or not tr then return "load failed" end
	animTrack = tr
	pcall(function() (animTrack :: AnimationTrack):Play() end)
	return "playing " .. tostring(id)
end
function Spoofer.StopAnim()
	if animTrack then pcall(function() (animTrack :: AnimationTrack):Stop() end); animTrack = nil; return "stopped" end
	return "nothing playing"
end

----------------------------------------------------------------------
-- ConfigManager
----------------------------------------------------------------------
local ConfigManager = {}
local HS = game:GetService("HttpService")
local FOLDER = "liv4cheets_configs"
local function hasFS() local g = getgenv() :: any; return type(g.writefile) == "function" and type(g.readfile) == "function" and type(g.listfiles) == "function" end
function ConfigManager.Ensure() if not hasFS() then return end; pcall(function() (getgenv() :: any).makefolder(FOLDER) end) end
local function serializable(v)
	if typeof(v) == "EnumItem" then return { __enum = tostring(v.EnumType) .. "." .. tostring(v.Name) }
	elseif typeof(v) == "Color3" then return { __color = { math.round(v.R * 255), math.round(v.G * 255), math.round(v.B * 255) } }
	elseif type(v) == "table" then
		local o = {}
		for k, vv in pairs(v) do o[k] = serializable(vv) end
		return o
	elseif type(v) == "number" or type(v) == "string" or type(v) == "boolean" then return v end
	return nil
end
local function restore(v)
	if type(v) == "table" then
		if v.__enum then
			local s = v.__enum
			local a, b = string.match(s, "Enum%.(%w+)%.(%w+)")
			local ok, e = pcall(function() return (Enum :: any)[a][b] end)
			return ok and e or nil
		end
		if v.__color then return Color3.fromRGB(v.__color[1], v.__color[2], v.__color[3]) end
		local o = {}
		for k, vv in pairs(v) do o[k] = restore(vv) end
		return o
	end
	return v
end
function ConfigManager.List()
	ConfigManager.Ensure()
	if not hasFS() then return {} end
	local ok, files = pcall(function() return (getgenv() :: any).listfiles(FOLDER) end)
	if not ok or type(files) ~= "table" then return {} end
	local out = {}
	for _, f in ipairs(files) do
		local n = string.match(f, "([^\\/]+)%.json$")
		if n then table.insert(out, n) end
	end
	return out
end
function ConfigManager.Save(name)
	if not hasFS() then return "no FS (writefile missing)" end
	name = string.gsub(name or "", "[^%w%-%_]", "")
	if #name == 0 then return "invalid name" end
	ConfigManager.Ensure()
	local c = (getgenv() :: any).LIV4Config
	local ok, j = pcall(function() return HS:JSONEncode(serializable(c)) end)
	if not ok then return "encode failed" end
	local ok2, err = pcall(function() (getgenv() :: any).writefile(FOLDER .. "/" .. name .. ".json", j) end)
	return ok2 and ("saved " .. name) or ("save failed: " .. tostring(err))
end
function ConfigManager.Load(name)
	if not hasFS() then return "no FS (readfile missing)" end
	local ok, j = pcall(function() return (getgenv() :: any).readfile(FOLDER .. "/" .. name .. ".json") end)
	if not ok then return "read failed" end
	local ok2, t = pcall(function() return HS:JSONDecode(j) end)
	if not ok2 or type(t) ~= "table" then return "decode failed" end
	(getgenv() :: any).LIV4Config = restore(t);
	(getgenv() :: any).RivalsConfig = (getgenv() :: any).LIV4Config
	return "loaded " .. name .. " (re-execute to apply fully)"
end
function ConfigManager.Delete(name)
	if not hasFS() then return "no FS" end
	pcall(function() (getgenv() :: any).delfile(FOLDER .. "/" .. name .. ".json") end)
	return "deleted " .. name
end

----------------------------------------------------------------------
-- SkinChanger
----------------------------------------------------------------------
local SkinChanger = {}
local applied = {}
local conns = {}
local function lp() return game:GetService("Players").LocalPlayer end
local function myChar() local p = lp(); return p and p.Character or nil end
local function weaponModels()
	local out = {}
	local ch = myChar()
	if not ch then return out end
	local eq = ch:FindFirstChild("EquippedItem")
	if eq then
		local vm = (eq :: any).ViewModel or eq:FindFirstChild("ViewModel")
		if vm then table.insert(out, vm) end
		table.insert(out, eq)
	end
	for _, d in ipairs(ch:GetChildren()) do
		if d:IsA("Model") and (d.Name == "ViewModel" or string.find(d.Name, "Weapon", 1, true)) then
			table.insert(out, d)
		end
	end
	local cam = workspace.CurrentCamera
	if cam then
		local cvm = cam:FindFirstChild("ViewModel")
		if cvm then table.insert(out, cvm) end
	end
	return out
end
local function paint(model, color, material)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and not d.Name:lower():find("hitbox") then
			pcall(function()
				if color then (d :: BasePart).Color = color end
				if material then (d :: BasePart).Material = material end
			end)
		end
	end
end
local function clearCharms()
	local ch = myChar()
	if not ch then return end
	for _, m in ipairs(weaponModels()) do
		local old = m:FindFirstChild("LIV4Charm")
		if old then old:Destroy() end
	end
end
function SkinChanger.ApplySkin(weaponName, skinName, hexColor)
	local c = Color3.fromRGB(198, 255, 62)
	if hexColor and #hexColor >= 6 then
		pcall(function()
			local h = string.gsub(hexColor, "#", "")
			c = Color3.fromRGB(tonumber(h:sub(1, 2), 16) or 198, tonumber(h:sub(3, 4), 16) or 255, tonumber(h:sub(5, 6), 16) or 62)
		end)
	end
	applied["skin:" .. weaponName] = { skin = skinName, color = c }
	for _, m in ipairs(weaponModels()) do
		if #weaponName == 0 or string.lower(m:GetFullName()):find(string.lower(weaponName), 1, true) or m.Name == weaponName or m.Parent and (m.Parent :: any).Name == weaponName then
			paint(m, c, nil)
		end
	end
	if #weaponModels() > 0 and #weaponName > 0 then
		local anyMatch = false
		for _, m in ipairs(weaponModels()) do
			if m.Name == weaponName then anyMatch = true end
		end
		if not anyMatch then
			for _, m in ipairs(weaponModels()) do paint(m, c, nil) end
		end
	end
	return "skin applied locally: " .. weaponName .. " / " .. skinName
end
function SkinChanger.ApplyWrap(hexColor)
	local c = Color3.fromRGB(198, 255, 62)
	pcall(function()
		local h = string.gsub(hexColor or "", "#", "")
		if #h >= 6 then c = Color3.fromRGB(tonumber(h:sub(1, 2), 16) or 198, tonumber(h:sub(3, 4), 16) or 255, tonumber(h:sub(5, 6), 16) or 62) end
	end)
	applied.wrap = c
	for _, m in ipairs(weaponModels()) do paint(m, c, Enum.Material.SmoothPlastic) end
	return "wrap applied locally"
end
function SkinChanger.ApplyCharm(charmName)
	clearCharms()
	applied.charm = charmName
	if not charmName or #charmName == 0 or charmName == "None" then return "charm cleared" end
	for _, m in ipairs(weaponModels()) do
		local anchor = m:FindFirstChildWhichAffects("BasePart", true) :: any
		if not anchor then
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("BasePart") then anchor = d; break end
			end
		end
		if anchor then
			local p = Instance.new("Part")
			p.Name = "LIV4Charm"; p.Size = Vector3.new(0.25, 0.25, 0.25); p.Color = Color3.fromRGB(198, 255, 62)
			p.Material = Enum.Material.Neon; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
			p.CFrame = (anchor :: BasePart).CFrame * CFrame.new(0, -0.6, 0); p.Parent = m
			local w = Instance.new("WeldConstraint"); w.Part0 = anchor; w.Part1 = p; w.Parent = p
		end
	end
	return "charm applied locally: " .. charmName
end
function SkinChanger.ApplyFinisher(finisherName)
	applied.finisher = finisherName
	return "finisher staged locally: " .. finisherName .. " (plays on your kills only)"
end
function SkinChanger.ClearAll()
	applied = {}
	clearCharms()
	return "cleared (swap weapons to refresh originals)"
end
function SkinChanger.Dump()
	local lines = { "=== LIV4 SkinChanger Dump ===" }
	table.insert(lines, "models=" .. tostring(#weaponModels()))
	for _, m in ipairs(weaponModels()) do
		table.insert(lines, "model: " .. m:GetFullName() .. " children=" .. tostring(#m:GetChildren()))
		for _, d in ipairs(m:GetChildren()) do
			if #lines > 60 then break end
			table.insert(lines, "  - " .. d.ClassName .. " " .. d.Name)
		end
	end
	local rs = game:GetService("ReplicatedStorage")
	for _, n in ipairs({ "Modules", "Items", "Weapons", "Skins", "Cosmetics" }) do
		local f = rs:FindFirstChild(n)
		table.insert(lines, n .. ": " .. (f and f:GetFullName() or "missing"))
	end
	local ch = myChar()
	local eq = ch and ch:FindFirstChild("EquippedItem")
	table.insert(lines, "equipped: " .. tostring(eq and eq.Name or "none"))
	return table.concat(lines, "\n")
end
function SkinChanger.Auto()
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	table.clear(conns)
	local S = Utils.Services
	table.insert(conns, S.Players.LocalPlayer.CharacterAdded:Connect(function()
		task.wait(1)
		if applied.wrap then
			for _, m in ipairs(weaponModels()) do paint(m, applied.wrap, Enum.Material.SmoothPlastic) end
		end
	end))
end

----------------------------------------------------------------------
-- Main: initialize everything and build the menu
----------------------------------------------------------------------
local C = (getgenv() :: any).LIV4Config

-- Start all modules directly (no file loading)
if Aimbot then Aimbot.Start(Utils, Config) end
if SilentAim then SilentAim.Start(Utils, Config, function() return Aimbot and Aimbot.SilentTarget() end) end
if Triggerbot then Triggerbot.Start(Utils, Config, nil) end
if ESP then ESP.Start(Utils, Config) end
if Movement then Movement.Start(Utils, Config) end
if Effects then Effects.Start(Utils, Config) end
if Ragebot then Ragebot.Start(Utils, Config) end
if ConfigManager then ConfigManager.Ensure() end
if SkinChanger and SkinChanger.Auto then SkinChanger.Auto() end

-- Build the UI
if UI then
	local win = UI.New()

	-- COMBAT
	local combat = win:Tab("Combat")
	combat:Section("Aimbot")
	combat:Toggle("Enabled", C.Combat.AimbotEnabled, function(v) C.Combat.AimbotEnabled = v end)
	combat:Slider("FOV", 30, 400, C.Combat.AimFOV, function(v) C.Combat.AimFOV = math.round(v) end)
	combat:Slider("Smoothing", 0.02, 1, C.Combat.AimSmoothing, function(v) C.Combat.AimSmoothing = v end)
	combat:Dropdown("Hit Part", { "Head", "HitboxHead", "HumanoidRootPart", "Closest" }, C.Combat.AimPart, function(v) C.Combat.AimPart = v end)
	combat:Toggle("Target Dummies (range)", C.Combat.TargetDummies ~= false, function(v) C.Combat.TargetDummies = v end)
	combat:Slider("Prediction", 0, 0.1, C.Combat.Prediction or 0.015, function(v) C.Combat.Prediction = v end)
	combat:Toggle("Wall Check", C.Combat.WallCheck == true, function(v) C.Combat.WallCheck = v end)
	combat:Section("Silent Aim")
	combat:Toggle("Silent Enabled", C.Combat.SilentEnabled, function(v) C.Combat.SilentEnabled = v end)
	combat:Slider("Silent FOV", 20, 300, C.Combat.SilentFOV, function(v) C.Combat.SilentFOV = math.round(v) end)
	combat:Slider("Hit Chance", 1, 100, C.Combat.SilentChance, function(v) C.Combat.SilentChance = math.round(v) end)
	combat:Section("Triggerbot")
	combat:Toggle("Trigger Enabled", C.Combat.TriggerEnabled, function(v) C.Combat.TriggerEnabled = v end)
	combat:Slider("Reaction ms", 0, 300, C.Combat.TriggerDelay, function(v) C.Combat.TriggerDelay = math.round(v) end)
	combat:Section("Ragebot [risky]")
	combat:Toggle("Rage Enabled", C.Combat.RageEnabled, function(v) C.Combat.RageEnabled = v end)
	combat:Toggle("Void Spam", C.Combat.RageVoidSpam, function(v) C.Combat.RageVoidSpam = v end)
	combat:Textbox("Weapon", "Assault Rifle", C.Combat.RageWeapon, function(v) C.Combat.RageWeapon = v end)
	combat:Toggle("Anti-Aim", C.Combat.RageAntiAim, function(v) C.Combat.RageAntiAim = v end)

	-- VISUAL
	local vis = win:Tab("Visual")
	vis:Section("ESP")
	vis:Toggle("Enabled", C.Visual.ESPEnabled, function(v) C.Visual.ESPEnabled = v end)
	vis:Toggle("Box", C.Visual.Box, function(v) C.Visual.Box = v end)
	vis:Toggle("Filled Box", C.Visual.FilledBox, function(v)
		if v then C.Visual.FilledNoOutline = false end
		C.Visual.FilledBox = v
	end)
	vis:Toggle("Filled No Outline", C.Visual.FilledNoOutline, function(v)
		if v then C.Visual.FilledBox = false end
		C.Visual.FilledNoOutline = v
	end)
	vis:Toggle("Skeleton", C.Visual.Skeleton, function(v) C.Visual.Skeleton = v end)
	vis:Toggle("Chams", C.Visual.Chams, function(v) C.Visual.Chams = v end)
	vis:Toggle("Name", C.Visual.Name, function(v) C.Visual.Name = v end)
	vis:Toggle("Distance", C.Visual.Distance, function(v) C.Visual.Distance = v end)
	vis:Toggle("Health Bar", C.Visual.HealthBar, function(v) C.Visual.HealthBar = v end)
	vis:Slider("HP Bar Thickness", 2, 10, C.Visual.HealthBarThickness or 4, function(v) C.Visual.HealthBarThickness = math.round(v) end)
	vis:Slider("Text Size", 8, 24, C.Visual.TextSize, function(v) C.Visual.TextSize = math.round(v) end)

	-- EXPLOITS
	local ex = win:Tab("Exploits")
	ex:Section("Movement")
	ex:Toggle("Fly", C.Exploits.Fly, function(v) C.Exploits.Fly = v end)
	ex:Slider("Fly Speed", 20, 200, C.Exploits.FlySpeed, function(v) C.Exploits.FlySpeed = math.round(v) end)
	ex:Toggle("No Clip", C.Exploits.Noclip, function(v) C.Exploits.Noclip = v end)
	ex:Section("Avatar Spoofer (user id)")
	ex:Textbox("User Id", "123456", C.Exploits.AvatarUserId, function(v) C.Exploits.AvatarUserId = v end)
	ex:Button("Apply Outfit", function()
		if Spoofer then
			local m = Spoofer.Avatar(C.Exploits.AvatarUserId)
			game:GetService("StarterGui"):SetCore("SendNotification", { Title = "liv4cheets", Text = m, Duration = 3 })
		end
	end)
	ex:Section("Game Spoofers (visual)")
	ex:Textbox("Level", "e.g. 100", C.Exploits.LevelValue, function(v) C.Exploits.LevelValue = v end)
	ex:Button("Spoof Level", function() if Spoofer then Spoofer.Level(C.Exploits.LevelValue) end end)
	ex:Textbox("Winstreak", "e.g. 50", C.Exploits.StreakValue, function(v) C.Exploits.StreakValue = v end)
	ex:Button("Spoof Winstreak", function() if Spoofer then Spoofer.Streak(C.Exploits.StreakValue) end end)
	ex:Textbox("Leaderboard Wins", "e.g. 999", C.Exploits.BoardValue, function(v) C.Exploits.BoardValue = v end)
	ex:Button("Spoof Leaderboard", function() if Spoofer then Spoofer.Board(C.Exploits.BoardValue) end end)
	ex:Textbox("Ranked Rating", "e.g. 3000", C.Exploits.RankedValue, function(v) C.Exploits.RankedValue = v end)
	ex:Button("Spoof Ranked", function() if Spoofer then Spoofer.Ranked(C.Exploits.RankedValue) end end)
	ex:Section("Animation Player (asset id)")
	ex:Textbox("Asset Id", "rbxassetid uid", C.Exploits.AnimAssetId, function(v) C.Exploits.AnimAssetId = v end)
	ex:Button("Play Animation", function() if Spoofer then Spoofer.PlayAnim(C.Exploits.AnimAssetId) end end)
	ex:Button("Stop Animation", function() if Spoofer then Spoofer.StopAnim() end end)
	ex:Section("Skin Changer (you-only)")
	ex:Textbox("Weapon", "Assault Rifle", C.SkinChanger.Weapon, function(v) C.SkinChanger.Weapon = v end)
	ex:Textbox("Skin", "e.g. Glacier", C.SkinChanger.Skin, function(v) C.SkinChanger.Skin = v end)
	ex:Textbox("Color Hex", "C6FF3E", C.SkinChanger.ColorHex, function(v) C.SkinChanger.ColorHex = v end)
	ex:Button("Apply Skin", function() if SkinChanger then SkinChanger.ApplySkin(C.SkinChanger.Weapon, C.SkinChanger.Skin, C.SkinChanger.ColorHex) end end)
	ex:Textbox("Wrap Hex", "C6FF3E", C.SkinChanger.WrapHex, function(v) C.SkinChanger.WrapHex = v end)
	ex:Button("Apply Wrap", function() if SkinChanger then SkinChanger.ApplyWrap(C.SkinChanger.WrapHex) end end)
	ex:Dropdown("Charm", { "None", "Volt Cube", "Star", "Skull" }, C.SkinChanger.Charm, function(v)
		C.SkinChanger.Charm = v
		if SkinChanger then SkinChanger.ApplyCharm(v) end
	end)
	ex:Dropdown("Finisher", { "None", "Volt Burst", "Ghost", "Fire" }, C.SkinChanger.Finisher, function(v)
		C.SkinChanger.Finisher = v
		if SkinChanger then SkinChanger.ApplyFinisher(v) end
	end)
	ex:Button("Clear Skins", function() if SkinChanger then SkinChanger.ClearAll() end end)
	ex:Button("Dump Skin Paths", function()
		if SkinChanger then
			local s = SkinChanger.Dump()
			print(s)
			if setclipboard then pcall(setclipboard, s) end
		end
	end)

	-- CONFIGS
	local cf = win:Tab("Configs")
	cf:Section("Local JSON configs")
	cf:Textbox("Config Name", "myconfig", "", function(v) (getgenv() :: any).LIV4ConfigName = v end)
	cf:Button("Save", function() if ConfigManager then ConfigManager.Save((getgenv() :: any).LIV4ConfigName or "default") end end)
	cf:Button("Load", function() if ConfigManager then ConfigManager.Load((getgenv() :: any).LIV4ConfigName or "default") end end)
	cf:Button("Delete", function() if ConfigManager then ConfigManager.Delete((getgenv() :: any).LIV4ConfigName or "default") end end)

	-- MISC
	local mi = win:Tab("Misc")
	mi:Section("Theme")
	mi:Dropdown("Theme", { "Default", "Onyx" }, C.Misc.Theme, function(v)
		C.Misc.Theme = v
		win:ApplyTheme(v)
	end)
	mi:Section("Fonts")
	mi:Dropdown("Menu Font", { "GothamMedium", "Gotham", "GothamBold", "GothamBlack", "Code", "Montserrat", "Arial" }, C.Misc.MenuFont, function(v)
		C.Misc.MenuFont = v
		win:SetMenuFont(v)
	end)
	mi:Slider("In-Game Text Size", 8, 24, C.Visual.TextSize, function(v)
		C.Visual.TextSize = math.round(v)
		C.Misc.GameFontSize = math.round(v)
	end)
	mi:Section("Behavior")
	mi:Toggle("Hover / Animations", C.Misc.Anims, function(v) C.Misc.Anims = v end)
	mi:Textbox("Watermark", "liv4cheets", C.Misc.Watermark, function(v) C.Misc.Watermark = v end)
	mi:Button("Unload", function()
		local esp = (getgenv() :: any).LIV4ESP
		if esp and esp.Destroy then pcall(function() esp.Destroy() end) end
		local g = (getgenv() :: any).LIV4UI
		if g then pcall(function() g:Destroy() end) end
	end)

	win:ApplyTheme(C.Misc.Theme)
	win:SetMenuFont(C.Misc.MenuFont)
end

print("[liv4] loaded")
