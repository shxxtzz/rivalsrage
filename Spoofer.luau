--!strict
-- Spoofer.luau | liv4cheets Internal | Exploits tab
-- Client-visual only unless the game trusts the client. Server values revert on respawn/round.

local Spoofer = {}
local animTrack: AnimationTrack? = nil

function Spoofer.Avatar(userIdStr: string): string
	local id = tonumber(userIdStr)
	if not id then
		return "invalid user id"
	end
	local lp = game:GetService("Players").LocalPlayer
	local ch = lp and lp.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not hum then
		return "no character"
	end
	local ok, desc = pcall(function()
		return game:GetService("Players"):GetHumanoidDescriptionFromUserId(id)
	end)
	if not ok or not desc then
		return "bad user id"
	end
	pcall(function()
		hum:ApplyDescription(desc)
	end)
	return "applied " .. tostring(id)
end

local function setLeaderstat(name: string, value: string): string
	local v = tonumber(value)
	if not v then
		return "invalid number"
	end
	local lp = game:GetService("Players").LocalPlayer
	local ls = lp and lp:FindFirstChild("leaderstats")
	if ls then
		for _, s in ipairs(ls:GetChildren()) do
			if string.lower(s.Name) == string.lower(name) or string.find(string.lower(s.Name), string.lower(name), 1, true) then
				pcall(function()
					if s:IsA("IntValue") or s:IsA("NumberValue") then
						(s :: any).Value = v
					elseif s:IsA("StringValue") then
						(s :: any).Value = tostring(v)
					end
				end)
			end
		end
	end
	-- also overwrite on-screen labels (visual)
	local n = 0
	for _, g in ipairs(lp.PlayerGui:GetDescendants()) do
		if g:IsA("TextLabel") and string.find(string.lower(g.Text), string.lower(name), 1, true) then
			g.Text = string.gsub(g.Text, "%d+", tostring(v))
			n += 1
			if n > 6 then
				break
			end
		end
	end
	return "spoofed " .. name .. " -> " .. tostring(v) .. " (visual)"
end

function Spoofer.Level(v: string)
	return setLeaderstat("level", v)
end
function Spoofer.Streak(v: string)
	local a = setLeaderstat("streak", v)
	local b = setLeaderstat("win", v)
	return a .. " / " .. b
end
function Spoofer.Board(v: string)
	return setLeaderstat("win", v)
end
function Spoofer.Ranked(v: string)
	return setLeaderstat("rank", v)
end

function Spoofer.PlayAnim(assetStr: string): string
	local id = tonumber(assetStr)
	if not id then
		return "invalid asset id"
	end
	local lp = game:GetService("Players").LocalPlayer
	local ch = lp and lp.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local anim = hum and hum:FindFirstChildOfClass("Animator") or hum
	if not hum then
		return "no humanoid"
	end
	if animTrack then
		pcall(function()
			(animTrack :: AnimationTrack):Stop()
		end)
		animTrack = nil
	end
	local a = Instance.new("Animation")
	a.AnimationId = "rbxassetid://" .. tostring(id)
	local ok, tr = pcall(function()
		return (hum :: Humanoid):LoadAnimation(a)
	end)
	if not ok or not tr then
		return "load failed"
	end
	animTrack = tr
	pcall(function()
		(animTrack :: AnimationTrack):Play()
	end)
	return "playing " .. tostring(id)
end

function Spoofer.StopAnim(): string
	if animTrack then
		pcall(function()
			(animTrack :: AnimationTrack):Stop()
		end)
		animTrack = nil
		return "stopped"
	end
	return "nothing playing"
end

return Spoofer
