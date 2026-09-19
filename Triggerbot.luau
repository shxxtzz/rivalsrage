--!strict
-- Triggerbot.luau | liv4cheets Internal | Combat tab

local Triggerbot = {}

function Triggerbot.Start(Utils, Config, shootFn: (() -> ())?)
	local S = Utils.Services
	local cb = function()
		return (getgenv() :: any).LIV4Config or Config.Current
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local HIT = { HitboxBody = true, HitboxHead = true, HitboxHands = true }

	S.RunService.Heartbeat:Connect(function()
		local c = cb()
		local t = c.Combat or c.Triggerbot
		local en = t.TriggerEnabled ~= nil and t.TriggerEnabled or t.Enabled
		if not en then
			return
		end
		if not S.UserInputService:IsKeyDown(t.TriggerKey or Enum.KeyCode.T) then
			return
		end
		local cam = S.Workspace.CurrentCamera
		if not cam then
			return
		end
		local lp = S.Players.LocalPlayer
		params.FilterDescendantsInstances = { lp and lp.Character }
		local res = S.Workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 600, params)
		if not res or not HIT[res.Instance.Name] then
			return
		end
		local m = res.Instance:FindFirstAncestorOfClass("Model")
		if not m then
			return
		end
		local h = m:FindFirstChildOfClass("Humanoid")
		if not h or h.Health <= 0 or Utils.IsAlly(m) then
			return
		end
		task.delay((t.TriggerDelay or 40) / 1000, function()
			if shootFn then
				pcall(shootFn)
			else
				pcall(function()
					mouse1click()
				end)
			end
		end)
	end)
	return Triggerbot
end

return Triggerbot
