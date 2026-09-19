--!strict
-- Main.luau | liv4cheets - Internal | Documents/robloxrivalsluau/
-- Multi-file dev loader. For single copy-paste, use liv4cheets-Internal.lua (bundled).

local BASES = { "C:/Users/supa/Documents/robloxrivalsluau/", "robloxrivalsluau/", "./" }
local function tryRead(name: string): string?
	local rf = (getgenv() :: any).readfile
	if type(rf) ~= "function" then
		return nil
	end
	for _, b in ipairs(BASES) do
		local ok, out = pcall(rf, b .. name)
		if ok and type(out) == "string" and #out > 0 then
			return out
		end
	end
	return nil
end
local function loadMod(name: string): any
	local src = tryRead(name)
	if not src then
		warn("[liv4] missing " .. name)
		return nil
	end
	local fn, err = loadstring(src, "@" .. name)
	if not fn then
		warn("[liv4] compile " .. name .. ": " .. tostring(err))
		return nil
	end
	local ok, mod = pcall(fn)
	if not ok then
		warn("[liv4] run " .. name .. ": " .. tostring(mod))
		return nil
	end
	return mod
end

local allowed = { [17625359962] = true, [17720162456] = true }
if not allowed[game.PlaceId] then
	warn("[liv4] not Rivals PlaceId, continuing")
end

local Config = loadMod("Config.luau")
local Utils = loadMod("Utils.luau")
local UILib = loadMod("UI.luau")
local AimMod = loadMod("Aimbot.luau")
local SilentMod = loadMod("SilentAim.luau")
local TrigMod = loadMod("Triggerbot.luau")
local ESPMod = loadMod("ESP.luau")
local MoveMod = loadMod("Movement.luau")
local FXMod = loadMod("Effects.luau")
local RageMod = loadMod("Ragebot.luau")
local SpoofMod = loadMod("Spoofer.luau")
local CMMod = loadMod("ConfigManager.luau")
local SkinMod = loadMod("SkinChanger.luau")
if not Config or not Utils then
	error("[liv4] Config/Utils missing")
end

local C = (getgenv() :: any).LIV4Config
if AimMod then
	AimMod.Start(Utils, Config)
end
if SilentMod then
	SilentMod.Start(Utils, Config, function() return AimMod and AimMod.SilentTarget() end)
end
if TrigMod then
	TrigMod.Start(Utils, Config, nil)
end
if ESPMod then
	ESPMod.Start(Utils, Config)
end
if MoveMod then
	MoveMod.Start(Utils, Config)
end
if FXMod then
	FXMod.Start(Utils, Config)
end
if RageMod then
	RageMod.Start(Utils, Config)
end
if CMMod then
	CMMod.Ensure()
end
if SkinMod and SkinMod.Auto then
	SkinMod.Auto(Utils, Config)
end

if UILib then
	local win = UILib.New()

	-- COMBAT (includes ragebot)
	local combat = win:Tab("Combat")
	combat:Section("Aimbot")
	combat:Toggle("Enabled", C.Combat.AimbotEnabled, function(v)
		C.Combat.AimbotEnabled = v
	end)
	combat:Slider("FOV", 30, 400, C.Combat.AimFOV, function(v)
		C.Combat.AimFOV = math.round(v)
	end)
	combat:Slider("Smoothing", 0.02, 1, C.Combat.AimSmoothing, function(v)
		C.Combat.AimSmoothing = v
	end)
	combat:Dropdown("Hit Part", { "Head", "HitboxHead", "HumanoidRootPart", "Closest" }, C.Combat.AimPart, function(v)
		C.Combat.AimPart = v
	end)
	combat:Toggle("Target Dummies (range)", C.Combat.TargetDummies ~= false, function(v)
		C.Combat.TargetDummies = v
	end)
	combat:Slider("Prediction", 0, 0.1, C.Combat.Prediction or 0.015, function(v)
		C.Combat.Prediction = v
	end)
	combat:Toggle("Wall Check", C.Combat.WallCheck == true, function(v)
		C.Combat.WallCheck = v
	end)
	combat:Section("Silent Aim")
	combat:Toggle("Silent Enabled", C.Combat.SilentEnabled, function(v)
		C.Combat.SilentEnabled = v
	end)
	combat:Slider("Silent FOV", 20, 300, C.Combat.SilentFOV, function(v)
		C.Combat.SilentFOV = math.round(v)
	end)
	combat:Slider("Hit Chance", 1, 100, C.Combat.SilentChance, function(v)
		C.Combat.SilentChance = math.round(v)
	end)
	combat:Section("Triggerbot")
	combat:Toggle("Trigger Enabled", C.Combat.TriggerEnabled, function(v)
		C.Combat.TriggerEnabled = v
	end)
	combat:Slider("Reaction ms", 0, 300, C.Combat.TriggerDelay, function(v)
		C.Combat.TriggerDelay = math.round(v)
	end)
	combat:Section("Ragebot [risky]")
	combat:Toggle("Rage Enabled", C.Combat.RageEnabled, function(v)
		C.Combat.RageEnabled = v
	end)
	combat:Toggle("Void Spam", C.Combat.RageVoidSpam, function(v)
		C.Combat.RageVoidSpam = v
	end)
	combat:Textbox("Weapon", "Assault Rifle", C.Combat.RageWeapon, function(v)
		C.Combat.RageWeapon = v
	end)
	combat:Toggle("Anti-Aim", C.Combat.RageAntiAim, function(v)
		C.Combat.RageAntiAim = v
	end)

	-- VISUAL
	local vis = win:Tab("Visual")
	vis:Section("ESP")
	vis:Toggle("Enabled", C.Visual.ESPEnabled, function(v)
		C.Visual.ESPEnabled = v
	end)
	vis:Toggle("Box", C.Visual.Box, function(v)
		C.Visual.Box = v
	end)
	vis:Toggle("Filled Box", C.Visual.FilledBox, function(v)
		if v then
			C.Visual.FilledNoOutline = false
		end
		C.Visual.FilledBox = v
	end)
	vis:Toggle("Filled No Outline", C.Visual.FilledNoOutline, function(v)
		if v then
			C.Visual.FilledBox = false
		end
		C.Visual.FilledNoOutline = v
	end)
	vis:Toggle("Skeleton", C.Visual.Skeleton, function(v)
		C.Visual.Skeleton = v
	end)
	vis:Toggle("Chams", C.Visual.Chams, function(v)
		C.Visual.Chams = v
	end)
	vis:Toggle("Name", C.Visual.Name, function(v)
		C.Visual.Name = v
	end)
	vis:Toggle("Distance", C.Visual.Distance, function(v)
		C.Visual.Distance = v
	end)
	vis:Toggle("Health Bar", C.Visual.HealthBar, function(v)
		C.Visual.HealthBar = v
	end)
	vis:Slider("HP Bar Thickness", 2, 10, C.Visual.HealthBarThickness or 4, function(v)
		C.Visual.HealthBarThickness = math.round(v)
	end)
	vis:Slider("Text Size", 8, 24, C.Visual.TextSize, function(v)
		C.Visual.TextSize = math.round(v)
	end)

	-- EXPLOITS
	local ex = win:Tab("Exploits")
	ex:Section("Movement")
	ex:Toggle("Fly", C.Exploits.Fly, function(v)
		C.Exploits.Fly = v
	end)
	ex:Slider("Fly Speed", 20, 200, C.Exploits.FlySpeed, function(v)
		C.Exploits.FlySpeed = math.round(v)
	end)
	ex:Toggle("No Clip", C.Exploits.Noclip, function(v)
		C.Exploits.Noclip = v
	end)
	ex:Section("Avatar Spoofer (user id)")
	ex:Textbox("User Id", "123456", C.Exploits.AvatarUserId, function(v)
		C.Exploits.AvatarUserId = v
	end)
	ex:Button("Apply Outfit", function()
		if SpoofMod then
			local m = SpoofMod.Avatar(C.Exploits.AvatarUserId)
			game:GetService("StarterGui"):SetCore("SendNotification", { Title = "liv4cheets", Text = m, Duration = 3 })
		end
	end)
	ex:Section("Game Spoofers (visual)")
	ex:Textbox("Level", "e.g. 100", C.Exploits.LevelValue, function(v)
		C.Exploits.LevelValue = v
	end)
	ex:Button("Spoof Level", function()
		if SpoofMod then
			SpoofMod.Level(C.Exploits.LevelValue)
		end
	end)
	ex:Textbox("Winstreak", "e.g. 50", C.Exploits.StreakValue, function(v)
		C.Exploits.StreakValue = v
	end)
	ex:Button("Spoof Winstreak", function()
		if SpoofMod then
			SpoofMod.Streak(C.Exploits.StreakValue)
		end
	end)
	ex:Textbox("Leaderboard Wins", "e.g. 999", C.Exploits.BoardValue, function(v)
		C.Exploits.BoardValue = v
	end)
	ex:Button("Spoof Leaderboard", function()
		if SpoofMod then
			SpoofMod.Board(C.Exploits.BoardValue)
		end
	end)
	ex:Textbox("Ranked Rating", "e.g. 3000", C.Exploits.RankedValue, function(v)
		C.Exploits.RankedValue = v
	end)
	ex:Button("Spoof Ranked", function()
		if SpoofMod then
			SpoofMod.Ranked(C.Exploits.RankedValue)
		end
	end)
	ex:Section("Animation Player (asset id)")
	ex:Textbox("Asset Id", "rbxassetid uid", C.Exploits.AnimAssetId, function(v)
		C.Exploits.AnimAssetId = v
	end)
	ex:Button("Play Animation", function()
		if SpoofMod then
			SpoofMod.PlayAnim(C.Exploits.AnimAssetId)
		end
	end)
	ex:Button("Stop Animation", function()
		if SpoofMod then
			SpoofMod.StopAnim()
		end
	end)
	ex:Section("Skin Changer (you-only)")
	ex:Textbox("Weapon", "Assault Rifle", C.SkinChanger.Weapon, function(v)
		C.SkinChanger.Weapon = v
	end)
	ex:Textbox("Skin", "e.g. Glacier", C.SkinChanger.Skin, function(v)
		C.SkinChanger.Skin = v
	end)
	ex:Textbox("Color Hex", "C6FF3E", C.SkinChanger.ColorHex, function(v)
		C.SkinChanger.ColorHex = v
	end)
	ex:Button("Apply Skin", function()
		if SkinMod then
			SkinMod.ApplySkin(C.SkinChanger.Weapon, C.SkinChanger.Skin, C.SkinChanger.ColorHex)
		end
	end)
	ex:Textbox("Wrap Hex", "C6FF3E", C.SkinChanger.WrapHex, function(v)
		C.SkinChanger.WrapHex = v
	end)
	ex:Button("Apply Wrap", function()
		if SkinMod then
			SkinMod.ApplyWrap(C.SkinChanger.WrapHex)
		end
	end)
	ex:Dropdown("Charm", { "None", "Volt Cube", "Star", "Skull" }, C.SkinChanger.Charm, function(v)
		C.SkinChanger.Charm = v
		if SkinMod then
			SkinMod.ApplyCharm(v)
		end
	end)
	ex:Dropdown("Finisher", { "None", "Volt Burst", "Ghost", "Fire" }, C.SkinChanger.Finisher, function(v)
		C.SkinChanger.Finisher = v
		if SkinMod then
			SkinMod.ApplyFinisher(v)
		end
	end)
	ex:Button("Clear Skins", function()
		if SkinMod then
			SkinMod.ClearAll()
		end
	end)
	ex:Button("Dump Skin Paths", function()
		if SkinMod then
			local s = SkinMod.Dump()
			print(s)
			if setclipboard then
				pcall(setclipboard, s)
			end
		end
	end)

	-- CONFIGS
	local cf = win:Tab("Configs")
	cf:Section("Local JSON configs")
	cf:Textbox("Config Name", "myconfig", "", function(v)
		(getgenv() :: any).LIV4ConfigName = v
	end)
	cf:Button("Save", function()
		if CMMod then
			CMMod.Save((getgenv() :: any).LIV4ConfigName or "default")
		end
	end)
	cf:Button("Load", function()
		if CMMod then
			CMMod.Load((getgenv() :: any).LIV4ConfigName or "default")
		end
	end)
	cf:Button("Delete", function()
		if CMMod then
			CMMod.Delete((getgenv() :: any).LIV4ConfigName or "default")
		end
	end)

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
	mi:Toggle("Hover / Animations", C.Misc.Anims, function(v)
		C.Misc.Anims = v
	end)
	mi:Textbox("Watermark", "liv4cheets", C.Misc.Watermark, function(v)
		C.Misc.Watermark = v
	end)
	mi:Button("Unload", function()
		local esp = (getgenv() :: any).LIV4ESP
		if esp and esp.Destroy then
			pcall(function()
				esp.Destroy()
			end)
		end
		local g = (getgenv() :: any).LIV4UI
		if g then
			pcall(function()
				g:Destroy()
			end)
		end
	end)
	win:ApplyTheme(C.Misc.Theme)
	win:SetMenuFont(C.Misc.MenuFont)
end

print("[liv4] loaded")
