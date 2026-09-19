--!strict
-- Aimbot.luau | liv4cheets Internal | Combat tab
-- v2: sticky target, velocity prediction, working wallcheck, dummy/NPC targets
-- (dummies let you test in the shooting range — players-only can't aim there).

local Aimbot = {}

function Aimbot.Start(Utils, Config)
	local S = Utils.Services
	local Players, RS, UIS = S.Players, S.RunService, S.UserInputService

	local function C()
		return (getgenv() :: any).LIV4Config or (getgenv() :: any).RivalsConfig or Config.Current
	end
	local function combat()
		local c = C()
		if c.Combat then
			return c.Combat
		end
		return { AimbotEnabled = c.Aimbot.Enabled, AimFOV = c.Aimbot.FOV, AimSmoothing = c.Aimbot.Smoothing, AimPart = c.Aimbot.HitPart }
	end

	local fov = Drawing.new("Circle") :: any
	fov.Thickness = 1
	fov.Filled = false
	local sFov = Drawing.new("Circle") :: any
	sFov.Thickness = 1
	sFov.Filled = false
	local dot = Drawing.new("Circle") :: any
	dot.Radius = 3
	dot.Filled = true
	dot.Visible = false

	local sticky: BasePart? = nil

	local function center(): Vector2
		local cam = S.Workspace.CurrentCamera
		local vs = cam and cam.ViewportSize or Vector2.new(1920, 1080)
		return Vector2.new(vs.X / 2, vs.Y / 2)
	end

	local function partVelocity(part: BasePart): Vector3
		local ok, v = pcall(function()
			return (part :: any).AssemblyLinearVelocity
		end)
		if ok and typeof(v) == "Vector3" then
			return v
		end
		local hrp = part.Parent and (part.Parent :: any):FindFirstChild("HumanoidRootPart")
		if hrp then
			local ok2, v2 = pcall(function()
				return (hrp :: any).AssemblyLinearVelocity
			end)
			if ok2 and typeof(v2) == "Vector3" then
				return v2
			end
		end
		return Vector3.zero
	end

	local function visible(from: Vector3, part: BasePart): boolean
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local lp = Players.LocalPlayer
		local ignore = { lp and lp.Character, workspace.CurrentCamera }
		params.FilterDescendantsInstances = ignore
		local dir = part.Position - from
		local dist = dir.Magnitude
		local res = S.Workspace:Raycast(from, dir, params)
		if not res then
			return true
		end
		-- If the raycast hit something, check if it's part of the target model
		local hitModel = res.Instance:FindFirstAncestorOfClass("Model")
		if not hitModel then
			return false
		end
		-- Allow hit if it's the target's model or a descendant
		if hitModel == part.Parent then
			return true
		end
		-- Check if we hit the actual part or a descendant of the target
		if res.Instance == part or part:IsDescendantOf(hitModel) then
			return true
		end
		return false
	end

	local function validChar(ch: Instance): boolean
		local hum = (ch :: any):FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then
			return false
		end
		if Utils.IsAlly(ch) then
			return false
		end
		return true
	end

	-- gather player chars + (optional) range dummies / NPC models
	local function targets(wantDummies: boolean): { Model }
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
			-- generic fallback: models grouped under a "Dummies"/"Targets" folder
			for _, n in ipairs({ "Dummies", "Targets", "Bots" }) do
				local f = S.Workspace:FindFirstChild(n)
				if f then
					for _, m in ipairs(f:GetChildren()) do
						if m:IsA("Model") and validChar(m) then
							table.insert(out, m)
						end
					end
				end
			end
		end
		return out
	end

	local function acquire(px: number, mode: string, wantDummies: boolean, wall: boolean): BasePart?
		local cam = S.Workspace.CurrentCamera
		if not cam then
			return nil
		end
		-- sticky: keep current part while held and still good (with margin)
		if sticky and sticky.Parent then
			local m = (sticky :: BasePart).Parent
			if m and validChar(m) then
				local s, on = cam:WorldToViewportPoint((sticky :: BasePart).Position)
				if on and (Vector2.new(s.X, s.Y) - center()).Magnitude < px * 1.5 then
					if not wall or visible(cam.CFrame.Position, sticky) then
						return sticky
					end
				end
			end
			sticky = nil
		end
		local cc = center()
		-- Collect all valid targets with their screen positions
		local candidates: { [BasePart]: number } = {}
		for _, ch in ipairs(targets(wantDummies)) do
			local part = Utils.GetHitPart(ch, mode)
			if not part then
				continue
			end
			local s, on = cam:WorldToViewportPoint(part.Position)
			if not on then
				continue
			end
			local d = (Vector2.new(s.X, s.Y) - cc).Magnitude
			-- Only consider targets within FOV
			if d <= px then
				if wall and not visible(cam.CFrame.Position, part) then
					continue
				end
				candidates[part] = d
			end
		end
		-- Find the closest target
		local best, bd = nil, px
		for part, d in pairs(candidates) do
			if d < bd then
				bd, best = d, part
			end
		end
		sticky = best
		return best
	end

	-- ROOT FIX: default camera scripts overwrite Camera.CFrame every frame.
	-- A plain RenderStepped:Connect runs BEFORE that update, so our aim gets
	-- stomped (aimbot feels dead, esp. in first person). Camera.Value+1 runs
	-- after, so our CFrame is the one that renders. Works 1st + 3rd person.
	-- Improved: better target sorting, raycast visibility check, smoother lerp.
	RS:BindToRenderStep("LIV4Aimbot", Enum.RenderPriority.Camera.Value + 1, function()
		local cb = combat()
		local cam = S.Workspace.CurrentCamera
		if not cam then
			return
		end
		local cc = center()
		fov.Visible = cb.AimbotEnabled
		fov.Position = cc
		fov.Radius = cb.AimFOV
		sFov.Visible = cb.SilentEnabled
		sFov.Position = cc
		sFov.Radius = cb.SilentFOV
		if not cb.AimbotEnabled then
			sticky = nil
			dot.Visible = false
			return
		end
		if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			sticky = nil
			dot.Visible = false
			return
		end
		local t = acquire(cb.AimFOV, cb.AimPart, cb.TargetDummies ~= false, cb.WallCheck == true)
		if not t then
			dot.Visible = false
			return
		end
		-- velocity prediction so fast strafes don't lag behind
		local pred = cb.Prediction or 0
		local aimPos = t.Position + partVelocity(t) * pred
		local s, on = cam:WorldToViewportPoint(aimPos)
		if on then
			dot.Position = Vector2.new(s.X, s.Y)
			dot.Visible = true
		else
			dot.Visible = false
		end
		-- Smooth camera movement toward aim point
		local targetCF = CFrame.lookAt(cam.CFrame.Position, aimPos)
		local lerpAmt = math.clamp(cb.AimSmoothing, 0.01, 1)
		cam.CFrame = cam.CFrame:Lerp(targetCF, lerpAmt)
	end)

	function Aimbot.SilentTarget(): Vector3?
		local cb = combat()
		if not cb.SilentEnabled then
			return nil
		end
		if math.random(100) > (cb.SilentChance or 100) then
			return nil
		end
		local t = acquire(cb.SilentFOV, cb.AimPart, false, false)
		if not t then
			return nil
		end
		return t.Position + partVelocity(t) * (cb.Prediction or 0)
	end

	function Aimbot.Destroy()
		pcall(function()
			RS:UnbindFromRenderStep("LIV4Aimbot")
		end)
		for _, d in ipairs({ fov, sFov, dot }) do
			pcall(function()
				d:Remove()
			end)
		end
		sticky = nil
	end
	(getgenv() :: any).LIV4Aim = Aimbot

	return Aimbot
end

return Aimbot
