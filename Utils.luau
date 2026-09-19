--!strict
-- Utils.luau | shared helpers (cloneref-safe, high UNC ok, no UNC required to load)

local Utils = {}

-- cloneref if available (Potassium/Wave), else passthrough
local function cref<T>(inst: T): T
	local f = (getgenv() :: any).cloneref or (rawget(_G, "cloneref") :: any)
	if type(f) == "function" then
		local ok, out = pcall(f, inst)
		if ok and out then
			return out
		end
	end
	return inst
end

Utils.cloneref = cref

Utils.Services = {
	Players = cref(game:GetService("Players")),
	RunService = cref(game:GetService("RunService")),
	UserInputService = cref(game:GetService("UserInputService")),
	Workspace = cref(game:GetService("Workspace")),
	TweenService = cref(game:GetService("TweenService")),
	ReplicatedStorage = cref(game:GetService("ReplicatedStorage")),
}

function Utils.LocalPlayer()
	return Utils.Services.Players.LocalPlayer
end

function Utils.Character(plr)
	plr = plr or Utils.LocalPlayer()
	return plr and plr.Character or nil
end

function Utils.Humanoid(char): Humanoid?
	if not char then
		return nil
	end
	return char:FindFirstChildOfClass("Humanoid")
end

function Utils.RootPart(char): BasePart?
	if not char then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart")
end

function Utils.IsAlive(char): boolean
	local hum = Utils.Humanoid(char)
	return hum ~= nil and hum.Health > 0
end

function Utils.IsAlly(char): boolean
	local flag = char and char:FindFirstChild("_is_ally")
	return flag ~= nil and (flag :: any).Value == true
end

function Utils.IsEnemy(player): boolean
	local lp = Utils.LocalPlayer()
	if player == lp then
		return false
	end
	local cfg = (getgenv() :: any).RivalsConfig
	-- team check for team modes
	if cfg and cfg.Aimbot and cfg.Aimbot.TeamCheck then
		if lp and lp.Team and player.Team and lp.Team == player.Team then
			return false
		end
	end
	local char = player.Character
	if not char then
		return false
	end
	if Utils.IsAlly(char) then
		return false
	end
	return Utils.IsAlive(char)
end

function Utils.GetHitPart(char, mode: string?): BasePart?
	if not char then
		return nil
	end
	mode = mode or "Head"
	if mode == "Closest" then
		local cam = Utils.Services.Workspace.CurrentCamera
		if not cam then
			return nil
		end
		local best, bestD = nil, math.huge
		for _, d in ipairs(char:GetChildren()) do
			if d:IsA("BasePart") then
				local m = (d.Position - cam.CFrame.Position).Magnitude
				if m < bestD then
					bestD = m
					best = d
				end
			end
		end
		return best
	end
	-- Rivals uses HitboxHead/HitboxBody alongside Head
	return char:FindFirstChild("HitboxHead")
		or char:FindFirstChild(mode)
		or char:FindFirstChild("Head")
		or char:FindFirstChild("HumanoidRootPart")
end

function Utils.IsVisible(from: Vector3, target: BasePart, ignoreChar: Model?): boolean
	local ws = Utils.Services.Workspace
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local f = { ignoreChar, Utils.Character() }
	params.FilterDescendantsInstances = f
	local dir = target.Position - from
	local res = ws:Raycast(from, dir, params)
	if not res then
		return true
	end
	return res.Instance:IsDescendantOf(target.Parent)
end

function Utils.ScreenCenter(): Vector2
	local cam = Utils.Services.Workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	return Vector2.new(vs.X / 2, vs.Y / 2)
end

return Utils
