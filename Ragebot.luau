--!strict
-- Ragebot.luau | liv4cheets Internal | Combat tab | HIGH BAN RISK, off by default

local Ragebot = {}

function Ragebot.Start(Utils, Config)
	local S = Utils.Services
	local function C()
		return (getgenv() :: any).LIV4Config or Config.Current
	end
	local function R()
		local c = C()
		return c.Combat or c.Ragebot
	end
	local n = 0
	local remote: RemoteEvent? = nil
	pcall(function()
		local rs = S.ReplicatedStorage:WaitForChild("Remotes", 2)
		local f = rs and (rs :: any):WaitForChild("Fighter", 2)
		remote = f and (f :: any):WaitForChild("UseItem", 2)
	end)
	S.RunService.Heartbeat:Connect(function()
		local r = R()
		local en = r.RageEnabled ~= nil and r.RageEnabled or r.Enabled
		local vs = r.RageVoidSpam ~= nil and r.RageVoidSpam or r.VoidSpam
		if not en or not vs or not remote then
			return
		end
		local my = S.Players.LocalPlayer and S.Players.LocalPlayer.Character
		if not my or not my:FindFirstChild("EquippedItem") then
			return
		end
		local cam = S.Workspace.CurrentCamera
		local best, bd = nil, math.huge
		for _, p in ipairs(S.Players:GetPlayers()) do
			if p == S.Players.LocalPlayer then
				continue
			end
			local ch = p.Character
			if not ch or not Utils.IsAlive(ch) or Utils.IsAlly(ch) then
				continue
			end
			local hrp = ch:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp and cam then
				local d = (hrp.Position - cam.CFrame.Position).Magnitude
				if d < bd then
					bd, best = d, ch
				end
			end
		end
		if not best then
			return
		end
		local hb = Utils.GetHitPart(best, "Head")
		if not hb then
			return
		end
		n += 1
		pcall(function()
			(remote :: RemoteEvent):FireServer({ id = game:GetService("HttpService"):GenerateGUID(false), item = r.RageWeapon or r.WeaponName, position = hb.Position, attackNum = n })
		end)
	end)
	return Ragebot
end

return Ragebot
