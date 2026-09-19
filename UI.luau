|--!strict
|-- UI.luau | liv4cheets - Internal | ClickGUI
|-- Style refs: LinoriaLib tab/groupbox pattern (tabs + sections + controls),
|-- custom Electron-ish dark shell. No external deps. Themes: Default (volt) / Onyx.

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

local FONTS: { [string]: Enum.Font } = {
	Gotham = Enum.Font.Gotham,
	GothamMedium = Enum.Font.GothamMedium,
	GothamBold = Enum.Font.GothamBold,
	GothamBlack = Enum.Font.GothamBlack,
	Code = Enum.Font.Code,
	Montserrat = Enum.Font.Montserrat,
	Arial = Enum.Font.Arial,
}

local function cref<T>(i: T): T
	local f = (getgenv() :: any).cloneref
	if type(f) == "function" then
		local ok, o = pcall(f, i)
		if ok and o then
			return o
		end
	end
	return i
end

local Players = cref(game:GetService("Players"))
local UIS = cref(game:GetService("UserInputService"))
local Tween = cref(game:GetService("TweenService"))

local function protect(gui: ScreenGui)
	local gethui = (getgenv() :: any).gethui
	if type(gethui) == "function" then
		local ok, h = pcall(gethui)
		if ok and h then
			gui.Parent = h
			return
		end
	end
	pcall(function()
		gui.Parent = game:GetService("CoreGui")
	end)
	if gui.Parent == nil then
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
end

local function mk(class: string, props: any, parent: Instance?): any
	local o: any = Instance.new(class)
	for k, v in pairs(props) do
		if k ~= "Parent" then
			pcall(function()
				o[k] = v
			end)
		end
	end
	o.Parent = parent
	return o
end

local function animsOn(): boolean
	local c = (getgenv() :: any).LIV4Config
	if c and c.Misc and c.Misc.Anims == false then
		return false
	end
	return true
end

function UI.New(): any
	if (getgenv() :: any).LIV4UI then
		pcall(function()
			(getgenv() :: any).LIV4UI:Destroy()
		end)
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
	local rootStroke: any = mk("UIStroke", { Color = T.Stroke, Thickness = 1 }, root)
	do
		local sc = mk("UIScale", { Scale = 0.97 }, root)
		local cfg0 = (getgenv() :: any).LIV4Config
		if not cfg0 or cfg0.Misc.Anims ~= false then
			pcall(function()
				Tween:Create(sc, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			end)
		else
			sc.Scale = 1
		end
	end

	-- titlebar
	local bar = mk("Frame", { Name = "PanelBG", Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = T.Panel, BorderSizePixel = 0 }, root)
	mk("UICorner", { CornerRadius = UDim.new(0, 12) }, bar)
	mk("Frame", { Name = "PanelBG", Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 1, -16), BorderSizePixel = 0, BackgroundColor3 = T.Panel }, bar)

	-- favicon
	local fav = mk("Frame", { Name = "AccentBG", Size = UDim2.fromOffset(26, 26), Position = UDim2.new(0, 14, 0.5, -13), BackgroundColor3 = T.Accent, BorderSizePixel = 0 }, bar)
	mk("UICorner", { CornerRadius = UDim.new(0, 8) }, fav)
	mk("TextLabel", { Name = "AccentLabel", Text = "L4", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = T.AccentText, Font = Enum.Font.GothamBlack, TextSize = 13 }, fav)

	mk("TextLabel", { Name = "MainText", Text = "liv4cheets - Internal", Size = UDim2.new(0, 220, 1, 0), Position = UDim2.new(0, 48, 0, 0), BackgroundTransparency = 1, TextColor3 = T.Text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, bar)
	mk("TextLabel", { Name = "DimText", Text = "v1.0-internal", Size = UDim2.new(0, 110, 1, 0), Position = UDim2.new(0, 232, 0, 0), BackgroundTransparency = 1, TextColor3 = T.Dim, Font = Enum.Font.Code, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, bar)
	mk("TextLabel", { Name = "DimText", Text = "RShift", Size = UDim2.new(0, 80, 1, 0), Position = UDim2.new(1, -90, 0, 0), BackgroundTransparency = 1, TextColor3 = T.Dim, Font = Enum.Font.Code, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right }, bar)

	-- sidebar + content
	local side = mk("Frame", { Name = "PanelBG", Size = UDim2.new(0, 160, 1, -42), Position = UDim2.new(0, 0, 0, 42), BackgroundColor3 = T.Panel, BorderSizePixel = 0 }, root)
	mk("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, side)
	mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, side)

	local content = mk("Frame", { Size = UDim2.new(1, -160, 1, -42), Position = UDim2.new(0, 160, 0, 42), BackgroundTransparency = 1 }, root)
	mk("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14) }, content)

	-- status bar
	local foot = mk("TextLabel", { Name = "DimText", Text = "liv4cheets  •  connected", Size = UDim2.new(1, -170, 0, 16), Position = UDim2.new(0, 166, 1, -24), BackgroundTransparency = 1, TextColor3 = T.Dim, Font = Enum.Font.Code, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, root)

	-- drag
	do
		local drag, s, sp = false, nil, nil
		bar.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				drag, s, sp = true, i.Position, root.Position
			end
		end)
		UIS.InputChanged:Connect(function(i)
			if drag and i.UserInputType == Enum.UserInputType.MouseMovement and s then
				local d = i.Position - s
				root.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
			end
		end)
		UIS.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				drag = false
			end
		end)
	end

	local win: any = { Gui = gui, Root = root, _pages = {}, _tabBtns = {} }

	function win:ApplyTheme(name: string)
		local th = THEMES[name] or THEMES.Default
		root.BackgroundColor3 = th.BG
		rootStroke.Color = th.Stroke
		for _, d in ipairs(root:GetDescendants()) do
			if d.Name == "PanelBG" and d:IsA("GuiObject") then
				(d :: any).BackgroundColor3 = th.Panel
			elseif d.Name == "CardBG" and d:IsA("GuiObject") then
				(d :: any).BackgroundColor3 = th.Card
			elseif d.Name == "AccentBG" and d:IsA("GuiObject") then
				(d :: any).BackgroundColor3 = th.Accent
			elseif d.Name == "MainText" and d:IsA("TextLabel") then
				(d :: any).TextColor3 = th.Text
			elseif d.Name == "DimText" and d:IsA("TextLabel") then
				(d :: any).TextColor3 = th.Dim
			elseif d.Name == "AccentLabel" then
				(d :: any).TextColor3 = th.AccentText
			end
		end
	end

	function win:SetMenuFont(name: string)
		local f = FONTS[name] or Enum.Font.GothamMedium
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
				if (d :: any).Font ~= Enum.Font.Code then
					(d :: any).Font = f
				end
			end
		end
	end

	local function hover(btn: any, base: Color3)
		if not animsOn() then
			return
		end
		local hoverColor = base:Lerp(Color3.new(1, 1, 1), 0.12)
		btn.MouseEnter:Connect(function()
			pcall(function()
				Tween:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = hoverColor }):Play()
			end)
		end)
		btn.MouseLeave:Connect(function()
			pcall(function()
				Tween:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = base }):Play()
			end)
		end)
	end

	function win:Tab(name: string): any
		local btn = mk("TextButton", { Name = "CardBG", Text = name, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = T.Card, TextColor3 = T.Text, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, BorderSizePixel = 0 }, side)
		mk("UICorner", { CornerRadius = UDim.new(0, 10) }, btn)
		mk("UIPadding", { PaddingLeft = UDim.new(0, 20) }, btn)
		local sel = mk("Frame", { Name = "AccentBG", Size = UDim2.new(0, 3, 0, 22), Position = UDim2.new(0, 6, 0.5, -11), BackgroundColor3 = T.Accent, BorderSizePixel = 0, Visible = false }, btn)
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, sel)
		hover(btn, T.Card)

		local page = mk("ScrollingFrame", { Size = UDim2.new(1, 0, 1, -8), BackgroundTransparency = 1, ScrollBarThickness = 2, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false }, content)
		mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)

		local function select()
			for _, p in ipairs(self._pages) do
				(p :: any).Visible = false
			end
			for _, b in ipairs(self._tabBtns) do
				((b :: any):FindFirstChildOfClass("Frame") :: any).Visible = false
				(b :: any).BackgroundColor3 = T.Card
			end
			page.Visible = true
			sel.Visible = true
			btn.BackgroundColor3 = T.Card:Lerp(T.Accent, 0.14)
		end
		btn.MouseButton1Click:Connect(select)
		if #self._pages == 0 then
			page.Visible = true
			sel.Visible = true
		end
		table.insert(self._pages, page)
		table.insert(self._tabBtns, btn)

		local tab: any = {}
		function tab:Section(t: string)
			local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, page)
			mk("Frame", { Name = "AccentBG", Size = UDim2.new(0, 3, 0, 14), Position = UDim2.new(0, 0, 0.5, -7), BackgroundColor3 = T.Accent, BorderSizePixel = 0 }, row)
			mk("TextLabel", { Name = "DimText", Text = string.upper(t), Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, TextColor3 = T.Dim, Font = Enum.Font.Code, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, row)
		end
		function tab:Toggle(label: string, default: boolean, cb: (boolean) -> ())
			local st = default
			local row = mk("Frame", { Name = "CardBG", Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = T.Card, BorderSizePixel = 0 }, page)
			mk("UICorner", { CornerRadius = UDim.new(0, 10) }, row)
			mk("TextLabel", { Name = "MainText", Text = label, Size = UDim2.new(1, -72, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, TextColor3 = T.Text, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, row)
			local pill = mk("TextButton", { Text = "", Size = UDim2.fromOffset(44, 24), Position = UDim2.new(1, -56, 0.5, -12), BackgroundColor3 = st and T.Accent or T.ToggleOff, AutoButtonColor = false, BorderSizePixel = 0 }, row)
			mk("UICorner", { CornerRadius = UDim.new(1, 0) }, pill)
			local knob = mk("Frame", { Size = UDim2.fromOffset(16, 16), Position = st and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 4, 0.5, -8), BackgroundColor3 = st and T.AccentText or Color3.new(1, 1, 1), BorderSizePixel = 0 }, pill)
			mk("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
			local function sync(animate: boolean)
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
		function tab:Slider(label: string, min: number, max: number, default: number, cb: (number) -> ())
			local val = default
			local lab = mk("TextLabel", { Name = "MainText", Text = label .. "  " .. tostring(math.round(val * 100) / 100), Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, TextColor3 = T.Text, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, page)
			local track = mk("TextButton", { Name = "Track", Text = "", Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = T.Stroke, AutoButtonColor = false, BorderSizePixel = 0 }, page)
			mk("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
			local fill = mk("Frame", { Name = "AccentBG", Size = UDim2.new((val - min) / math.max(max - min, 0.001), 0, 1, 0), BackgroundColor3 = T.Accent, BorderSizePixel = 0 }, track)
			mk("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
			local knobS = mk("Frame", { Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new((val - min) / math.max(max - min, 0.001), 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 2 }, track)
			mk("UICorner", { CornerRadius = UDim.new(1, 0) }, knobS)
			local function setX(x: number)
				local p = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
				val = min + (max - min) * p
				fill.Size = UDim2.new(p, 0, 1, 0)
				knobS.Position = UDim2.new(p, 0, 0.5, 0)
				lab.Text = label .. "  " .. tostring(math.round(val * 100) / 100)
				pcall(cb, val)
			end
			track.MouseButton1Down:Connect(function(x)
				setX(x)
				local c
				c = UIS.InputChanged:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseMovement then
						setX(i.Position.X)
					end
				end)
				UIS.InputEnded:Wait()
				if c then
					c:Disconnect()
				end
			end)
		end
		function tab:Dropdown(label: string, values: { string }, default: string, cb: (string) -> ())
			-- popup lives on the window root (never inside the scrolling canvas),
			-- positioned under the button, with an outside-click catcher.
			-- Pure dropdown list, no click-through cycling.
			local sel = default
			if not table.find(values, sel) then
				sel = values[1]
			end
			local lab = mk("TextLabel", { Name = "MainText", Text = label, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, TextColor3 = T.Text, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, page)
			local b = mk("TextButton", { Name = "CardBG", Text = "", Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.Card, AutoButtonColor = false, BorderSizePixel = 0 }, page)
			mk("UICorner", { CornerRadius = UDim.new(0, 10) }, b)
			mk("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, b)
			local bText = mk("TextLabel", { Name = "MainText", Text = sel, Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1, TextColor3 = T.Text, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, b)
			mk("TextLabel", { Name = "DimText", Text = "▾", Size = UDim2.new(0, 24, 1, 0), Position = UDim2.new(1, -24, 0, 0), BackgroundTransparency = 1, TextColor3 = T.Dim, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right }, b)
			hover(b, T.Card)
			b.MouseEnter:Connect(function()
				if animsOn() then
					pcall(function()
						Tween:Create(b, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = T.Hover }):Play()
					end)
				end
			end)
			b.MouseLeave:Connect(function()
				if animsOn() then
					pcall(function()
						Tween:Create(b, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = T.Card }):Play()
					end)
				end
			end)
			local catcher: any = nil
			local pop: any = nil
			local function close()
				if catcher then
					catcher:Destroy()
					catcher = nil
				end
				if pop then
					pop:Destroy()
					pop = nil
				end
			end
			b.MouseButton1Click:Connect(function()
				if pop then
					close()
					return
				end
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
						lab.Text = label  .. "  " .. v
						pcall(cb, v)
						close()
					end)
				end
			end)
		end
		function tab:Textbox(label: string, placeholder: string, default: string, cb: (string) -> ())
			mk("TextLabel", { Name = "MainText", Text = label, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, TextColor3 = T.Text, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, page)
			local box = mk("TextBox", { Name = "CardBG", Text = default or "", PlaceholderText = placeholder or "", Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = T.Card, TextColor3 = T.Text, PlaceholderColor3 = T.Dim, Font = Enum.Font.Code, TextSize = 12, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0 }, page)
			mk("UICorner", { CornerRadius = UDim.new(0, 10) }, box)
			mk("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, box)
			box.FocusLost:Connect(function(enter)
				if enter then
					pcall(cb, box.Text)
				end
			end)
		end
		function tab:Button(label: string, cb: () -> ())
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

	local vis = true
	UIS.InputBegan:Connect(function(i, gpe)
		if gpe then
			return
		end
		local cfg = (getgenv() :: any).LIV4Config
		if i.KeyCode == ((cfg and cfg.Misc and cfg.Misc.ToggleKey) or Enum.KeyCode.RightShift) then
			vis = not vis
			root.Visible = vis
		end
		if i.KeyCode == ((cfg and cfg.Misc and cfg.Misc.UnloadKey) or Enum.KeyCode.End) then
			pcall(function()
				gui:Destroy()
			end)
		end
	end)

	return win
end

return UI
