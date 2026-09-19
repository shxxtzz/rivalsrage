--!strict
-- Movement.luau | liv4cheets Internal | Exploits tab (fly/noclip)

local Movement = {}

function Movement.Start(Utils, Config)
	local S = Utils.Services
	local function C()
		return (getgenv() :: any).LIV4Config or Config.Current
	end
	S.RunService.Heartbeat:Connect(function()
		local c = C()
		local ex = c.Exploits or c.Movement
		if not ex then
			return
		end
		local lp = S.Players.LocalPlayer
		local ch = lp and lp.Character
		local r = ch and ch:FindFirstChild("HumanoidRootPart") :: BasePart?
		local h = ch and ch:FindFirstChildOfClass("Humanoid")
		if not r or not h then
			return
		end
		local fly = ex.Fly
		local spd = ex.FlySpeed or 60
		if fly then
			h.PlatformStand = true
			local cam = S.Workspace.CurrentCamera
			local m = Vector3.zero
			local UIS = S.UserInputService
			if UIS:IsKeyDown(Enum.KeyCode.W) then
				m += cam.CFrame.LookVector
			end
			if UIS:IsKeyDown(Enum.KeyCode.S) then
				m -= cam.CFrame.LookVector
			end
			if UIS:IsKeyDown(Enum.KeyCode.A) then
				m -= cam.CFrame.RightVector
			end
			if UIS:IsKeyDown(Enum.KeyCode.D) then
				m += cam.CFrame.RightVector
			end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then
				m += Vector3.yAxis
			end
			r.AssemblyLinearVelocity = if m.Magnitude > 0 then m.Unit * spd else Vector3.zero
			r.AssemblyAngularVelocity = Vector3.zero
		end
	end)
	S.RunService.Stepped:Connect(function()
		local c = C()
		local ex = c.Exploits or c.Movement
		if not ex or not ex.Noclip then
			return
		end
		local ch = S.Players.LocalPlayer and S.Players.LocalPlayer.Character
		if not ch then
			return
		end
		for _, p in ipairs(ch:GetDescendants()) do
			if p:IsA("BasePart") then
				p.CanCollide = false
			end
		end
	end)
	return Movement
end

return Movement
