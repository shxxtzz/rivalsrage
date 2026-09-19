--!strict
-- ESP.luau | liv4cheets Internal | Visual tab
-- ROOT FIX for stuck drawings: central registry + destroy on teleport/leave/remove/unload.
-- Drawings are overlay-level: they survive teleports unless WE remove them.

local ESP = {}

function ESP.Start(Utils, Config)
	local S = Utils.Services
	local Players, RS = S.Players, S.RunService
	local function C()
		return (getgenv() :: any).LIV4Config or Config.Current
	end
	local function V()
		local c = C()
		return c.Visual or {}
	end

	local allDrawings: { any } = {}
	local conns: { RBXScriptConnection } = {}
	local function track(d: any)
		table.insert(allDrawings, d)
		return d
	end
	local function on(c: RBXScriptConnection)
		table.insert(conns, c)
	end

	type E = { box: any, fill: any, name: any, dist: any, hpBG: any, hp: any, skel: { any } }
	local cache: { [Player]: E } = {}
	local function get(p: Player): E
		local e = cache[p]
		if e then
			return e
		end
		local function sq(f: boolean): any
			return track(Drawing.new("Square") :: any)
		end
		local function tx(): any
			local t = track(Drawing.new("Text") :: any) :: any
			t.Center = true
			t.Outline = true
			return t
		end
		local b1 = sq(false)
		b1.Filled = false
		b1.Thickness = 1
		local f1 = sq(true)
		f1.Filled = true
		local n1, d1 = tx(), tx()
		local bg, hp = sq(true), sq(true)
		bg.Filled = true
		hp.Filled = true
		local sk: { any } = {}
		for _ = 1, 6 do
			local l = track(Drawing.new("Line") :: any) :: any
			l.Thickness = 1
			table.insert(sk, l)
		end
		e = { box = b1, fill = f1, name = n1, dist = d1, hpBG = bg, hp = hp, skel = sk }
		hide(e)
		cache[p] = e
		return e
	end
	function hide(e: E)
		e.box.Visible = false
		e.fill.Visible = false
		e.name.Visible = false
		e.dist.Visible = false
		e.hpBG.Visible = false
		e.hp.Visible = false
		for _, l in ipairs(e.skel) do
			l.Visible = false
		end
	end
	local function hideAll()
		for _, e in pairs(cache) do
			hide(e)
		end
	end
	local function dropPlayer(p: Player)
		local e = cache[p]
		if not e then
			return
		end
		hide(e)
		pcall(function()
			e.box:Remove()
		end)
		pcall(function()
			e.fill:Remove()
		end)
		pcall(function()
			e.name:Remove()
		end)
		pcall(function()
			e.dist:Remove()
		end)
		pcall(function()
			e.hpBG:Remove()
		end)
		pcall(function()
			e.hp:Remove()
		end)
		for _, l in ipairs(e.skel) do
			pcall(function()
				l:Remove()
			end)
		end
		cache[p] = nil
	end

	function ESP.Destroy()
		for _, c in ipairs(conns) do
			pcall(function()
				c:Disconnect()
			end)
		end
		table.clear(conns)
		for _, e in pairs(cache) do
			hide(e)
		end
		for _, d in ipairs(allDrawings) do
			pcall(function()
				d:Remove()
			end)
		end
		table.clear(allDrawings)
		table.clear(cache)
	end
	-- root fix: nuke overlay the moment we leave / teleport / get unloaded
	on(game:GetService("TeleportService").TeleportInit:Connect(function()
		hideAll()
		ESP.Destroy()
	end))
	on(Players.PlayerRemoving:Connect(dropPlayer))
	do
		local lp = Players.LocalPlayer
		if lp then
			on(lp.OnTeleport:Connect(function()
				hideAll()
				ESP.Destroy()
			end))
			if lp.Character then
				on(lp.CharacterRemoving:Connect(hideAll))
			end
			on(lp.CharacterAdded:Connect(function(ch)
				ch.AncestryChanged:Connect(function()
					if not ch:IsDescendantOf(game) then
						hideAll()
					end
				end)
			end))
		end
	end
	on(Players.PlayerAdded:Connect(function(p)
		on(p.CharacterRemoving:Connect(function()
			local e = cache[p]
			if e then
				hide(e)
			end
		end))
	end))
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= Players.LocalPlayer then
			on(p.CharacterRemoving:Connect(function()
				local e = cache[p]
				if e then
					hide(e)
				end
			end))
		end
	end

	local function chamsOn(ch: Model, color: Color3, on: boolean)
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
		elseif h then
			h:Destroy()
		end
	end

	on(RS.RenderStepped:Connect(function()
		local v = V()
		local cam = S.Workspace.CurrentCamera
		if not cam then
			hideAll()
			return
		end
		if not v.ESPEnabled then
			hideAll()
			return
		end
		for _, p in ipairs(Players:GetPlayers()) do
			if p == Players.LocalPlayer then
				continue
			end
			local e = get(p)
			local ch = p.Character
			-- root fix: character gone from hierarchy (teleport/leave) -> drop, don't draw stale box
			if not ch or not ch:IsDescendantOf(game) then
				hide(e)
				continue
			end
			local hrp = ch:FindFirstChild("HumanoidRootPart") :: BasePart?
			local hum = ch:FindFirstChildOfClass("Humanoid")
			if not hrp or not hum or hum.Health <= 0 then
				hide(e)
				chamsOn(ch, Color3.new(1, 1, 1), false)
				continue
			end
			if Utils.IsAlly(ch) and not v.ShowTeam then
				hide(e)
				chamsOn(ch, Color3.new(1, 1, 1), false)
				continue
			end
			chamsOn(ch, v.ChamsColor or Color3.fromRGB(198, 255, 62), v.Chams)
			local d3 = (hrp.Position - cam.CFrame.Position).Magnitude
			if d3 > (v.MaxDistance or 2000) then
				hide(e)
				continue
			end
			local t, onT = cam:WorldToViewportPoint((hrp.CFrame * CFrame.new(0, 2.5, 0)).Position)
			local b, onB = cam:WorldToViewportPoint((hrp.CFrame * CFrame.new(0, -3.5, 0)).Position)
			if not onT or not onB then
				hide(e)
				continue
			end
			local h = math.max(12, (Vector2.new(t.X, t.Y) - Vector2.new(b.X, b.Y)).Magnitude)
			local w = h * 0.6
			local x, y = b.X - w / 2, b.Y - h
			local ts = v.GameFontSize or v.TextSize or 13
			local hbT = v.HealthBarThickness or 4

			if v.FilledBox then
				e.fill.Size = Vector2.new(w, h)
				e.fill.Position = Vector2.new(x, y)
				e.fill.Transparency = 0.5
				e.fill.Visible = true
				e.box.Size = Vector2.new(w, h)
				e.box.Position = Vector2.new(x, y)
				e.box.Visible = v.Box
			elseif v.FilledNoOutline then
				e.fill.Size = Vector2.new(w, h)
				e.fill.Position = Vector2.new(x, y)
				e.fill.Transparency = 0.5
				e.fill.Visible = true
				e.box.Visible = false
			else
				e.fill.Visible = false
				e.box.Size = Vector2.new(w, h)
				e.box.Position = Vector2.new(x, y)
				e.box.Visible = v.Box
			end

			e.name.Size = ts
			e.name.Text = p.Name
			e.name.Position = Vector2.new(b.X, y - ts - 2)
			e.name.Visible = v.Name
			e.dist.Size = ts
			e.dist.Text = "[" .. math.round(d3) .. "m]"
			e.dist.Position = Vector2.new(b.X, b.Y + 2)
			e.dist.Visible = v.Distance

			if v.HealthBar then
				local r = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
				e.hpBG.Size = Vector2.new(hbT, h)
				e.hpBG.Position = Vector2.new(x - hbT - 2, y)
				e.hpBG.Visible = true
				e.hp.Size = Vector2.new(hbT, h * r)
				e.hp.Position = Vector2.new(x - hbT - 2, y + h * (1 - r))
				e.hp.Color = Color3.fromRGB(255 - math.round(255 * r), math.round(255 * r), 60)
				e.hp.Visible = true
			else
				e.hpBG.Visible = false
				e.hp.Visible = false
			end

			if v.Skeleton then
				local head = ch:FindFirstChild("Head")
				local la = ch:FindFirstChild("LeftHand") or ch:FindFirstChild("LeftUpperArm")
				local ra = ch:FindFirstChild("RightHand") or ch:FindFirstChild("RightUpperArm")
				local ll = ch:FindFirstChild("LeftFoot") or ch:FindFirstChild("LeftLowerLeg")
				local rl = ch:FindFirstChild("RightFoot") or ch:FindFirstChild("RightLowerLeg")
				local pts = { head, hrp, la, ra, ll, rl }
				local sp: { Vector2? } = {}
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
					if a and bb then
						L.From, L.To, L.Visible = a, bb, true
					else
						L.Visible = false
					end
				end
				for i = 6, #e.skel do
					e.skel[i].Visible = false
				end
			else
				for _, L in ipairs(e.skel) do
					L.Visible = false
				end
			end
		end
	end))
	-- expose for Main unload path
	(getgenv() :: any).LIV4ESP = ESP
	return ESP
end

return ESP
