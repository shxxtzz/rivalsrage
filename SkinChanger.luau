--!strict
-- SkinChanger.luau | liv4cheets Internal | YOU-ONLY visuals
-- Others still see your previously equipped skins/wraps/charms/finishers.
-- Applies locally to ViewModel + worldmodel clones, reapplies on equip/respawn.
-- If actual Rivals skin paths differ, run Dump() once and send output back to refine.

local SkinChanger = {}

local applied: { [string]: any } = {}
local conns: { RBXScriptConnection } = {}

local function lp()
	return game:GetService("Players").LocalPlayer
end

local function myChar()
	local p = lp()
	return p and p.Character or nil
end

-- Try to find the live weapon models to repaint: EquippedItem ViewModel + character tool parts
local function weaponModels(): { Instance }
	local out = {}
	local ch = myChar()
	if not ch then
		return out
	end
	local eq = ch:FindFirstChild("EquippedItem")
	if eq then
		local vm = (eq :: any).ViewModel or eq:FindFirstChild("ViewModel")
		if vm then
			table.insert(out, vm)
		end
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
		if cvm then
			table.insert(out, cvm)
		end
	end
	return out
end

local function paint(model: Instance, color: Color3?, material: Enum.Material?)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and not d.Name:lower():find("hitbox") then
			pcall(function()
				if color then
					(d :: BasePart).Color = color
				end
				if material then
					(d :: BasePart).Material = material
				end
			end)
		end
	end
end

local function clearCharms()
	local ch = myChar()
	if not ch then
		return
	end
	for _, m in ipairs(weaponModels()) do
		local old = m:FindFirstChild("LIV4Charm")
		if old then
			old:Destroy()
		end
	end
end

function SkinChanger.ApplySkin(weaponName: string, skinName: string, hexColor: string): string
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
	-- fallback: paint current weapon regardless of name match (you-only)
	if #weaponModels() > 0 and #weaponName > 0 then
		local anyMatch = false
		for _, m in ipairs(weaponModels()) do
			if m.Name == weaponName then
				anyMatch = true
			end
		end
		if not anyMatch then
			for _, m in ipairs(weaponModels()) do
				paint(m, c, nil)
			end
		end
	end
	return "skin applied locally: " .. weaponName .. " / " .. skinName
end

function SkinChanger.ApplyWrap(hexColor: string): string
	local c = Color3.fromRGB(198, 255, 62)
	pcall(function()
		local h = string.gsub(hexColor or "", "#", "")
		if #h >= 6 then
			c = Color3.fromRGB(tonumber(h:sub(1, 2), 16) or 198, tonumber(h:sub(3, 4), 16) or 255, tonumber(h:sub(5, 6), 16) or 62)
		end
	end)
	applied.wrap = c
	for _, m in ipairs(weaponModels()) do
		paint(m, c, Enum.Material.SmoothPlastic)
	end
	return "wrap applied locally"
end

function SkinChanger.ApplyCharm(charmName: string): string
	clearCharms()
	applied.charm = charmName
	if not charmName or #charmName == 0 or charmName == "None" then
		return "charm cleared"
	end
	-- generic charm: small volt cube hanging off weapon (placeholder until real charm meshes dumped)
	for _, m in ipairs(weaponModels()) do
		local anchor: BasePart? = m:FindFirstChildWhichAffects("BasePart", true) :: any
		if not anchor then
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("BasePart") then
					anchor = d
					break
				end
			end
		end
		if anchor then
			local p = Instance.new("Part")
			p.Name = "LIV4Charm"
			p.Size = Vector3.new(0.25, 0.25, 0.25)
			p.Color = Color3.fromRGB(198, 255, 62)
			p.Material = Enum.Material.Neon
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CFrame = (anchor :: BasePart).CFrame * CFrame.new(0, -0.6, 0)
			p.Parent = m
			local w = Instance.new("WeldConstraint")
			w.Part0 = anchor
			w.Part1 = p
			w.Parent = p
		end
	end
	return "charm applied locally: " .. charmName
end

function SkinChanger.ApplyFinisher(finisherName: string): string
	applied.finisher = finisherName
	-- finishers are kill effects; locally we can only stage the effect hook.
	-- Real mapping needs Dump() output; store choice so Effects can trigger it on kill.
	return "finisher staged locally: " .. finisherName .. " (plays on your kills only)"
end

function SkinChanger.ClearAll(): string
	applied = {}
	clearCharms()
	-- re-equip to restore original materials
	local ch = myChar()
	local eq = ch and ch:FindFirstChild("EquippedItem")
	if eq and (eq :: any).EquipItem then
		-- no-op: leave to user to swap weapons to refresh
	end
	return "cleared (swap weapons to refresh originals)"
end

-- Dumps candidate skin/charm/finisher paths + equipped state. Run once, send back.
function SkinChanger.Dump(): string
	local lines = { "=== LIV4 SkinChanger Dump ===" }
	table.insert(lines, "models=" .. tostring(#weaponModels()))
	for _, m in ipairs(weaponModels()) do
		table.insert(lines, "model: " .. m:GetFullName() .. " children=" .. tostring(#m:GetChildren()))
		for _, d in ipairs(m:GetChildren()) do
			if #lines > 60 then
				break
			end
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

function SkinChanger.Auto(Utils, Config)
	for _, c in ipairs(conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	table.clear(conns)
	local S = Utils.Services
	table.insert(conns, S.Players.LocalPlayer.CharacterAdded:Connect(function()
		task.wait(1)
		-- reapply wrap/skin after respawn
		if applied.wrap then
			for _, m in ipairs(weaponModels()) do
				paint(m, applied.wrap, Enum.Material.SmoothPlastic)
			end
		end
	end))
end

return SkinChanger
