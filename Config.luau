--!strict
-- Config.luau | liv4cheets - Internal | Documents/robloxrivalsluau/
-- Tabs: Combat | Visual | Exploits | Configs | Misc

local Config = {}

Config.Defaults = {
	Combat = {
		AimbotEnabled = false,
		AimFOV = 120,
		AimSmoothing = 0.12,
		AimPart = "Head",
		TargetDummies = true,
		Prediction = 0.015,
		WallCheck = false,
		SilentEnabled = false,
		SilentFOV = 90,
		SilentChance = 100,
		TriggerEnabled = false,
		TriggerKey = Enum.KeyCode.T,
		TriggerDelay = 40,
		RageEnabled = false, -- HIGH RISK, in Combat per spec
		RageVoidSpam = false,
		RageWeapon = "Assault Rifle",
		RageAntiAim = false,
	},
	Visual = {
		ESPEnabled = false,
		Box = true,
		FilledBox = false,
		FilledNoOutline = false,
		Skeleton = false,
		Chams = false,
		ChamsColor = Color3.fromRGB(198, 255, 62),
		Name = true,
		Distance = true,
		HealthBar = true,
		HealthBarThickness = 4,
		Weapon = false,
		ShowTeam = false,
		MaxDistance = 2000,
		TextSize = 13,
	},
	Exploits = {
		Fly = false,
		FlySpeed = 60,
		Noclip = false,
		AvatarUserId = "",
		LevelValue = "",
		StreakValue = "",
		BoardValue = "",
		RankedValue = "",
		AnimAssetId = "",
	},
	SkinChanger = {
		Weapon = "",
		Skin = "",
		ColorHex = "C6FF3E",
		WrapHex = "C6FF3E",
		Charm = "None",
		Finisher = "None",
	},
	Misc = {
		Theme = "Default", -- "Default" | "Onyx"
		MenuFont = "GothamMedium", -- Robox font name
		GameFontSize = 13,
		Anims = true, -- hover / tween animations
		Watermark = "liv4cheets",
		ToggleKey = Enum.KeyCode.RightShift,
		UnloadKey = Enum.KeyCode.End,
	},
	Meta = {
		AllowedPlaceIds = { 17625359962, 17720162456 },
		Name = "liv4cheets - Internal",
		Version = "v1.0-internal",
	},
}

local function deepCopy(t)
	local out = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			out[k] = deepCopy(v)
		else
			out[k] = v
		end
	end
	return out
end

local function deepMerge(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" and type(dst[k]) == "table" then
			deepMerge(dst[k], v)
		else
			dst[k] = v
		end
	end
	return dst
end

-- migrate legacy RivalsConfig shape (Aimbot/ESP/...) if present
local function migrate(t)
	if t.Aimbot then
		t.Combat = t.Combat or {}
		t.Combat.AimbotEnabled = t.Aimbot.Enabled
		t.Combat.AimFOV = t.Aimbot.FOV
		t.Aimbot = nil
	end
	if t.ESP then
		t.Visual = t.Visual or {}
		t.Visual.ESPEnabled = t.ESP.Enabled
		t.ESP = nil
	end
	return t
end

if getgenv().LIV4Config == nil and getgenv().RivalsConfig ~= nil then
	getgenv().LIV4Config = migrate(getgenv().RivalsConfig)
end
if getgenv().LIV4Config == nil then
	getgenv().LIV4Config = deepCopy(Config.Defaults)
else
	local user = getgenv().LIV4Config
	local merged = deepCopy(Config.Defaults)
	deepMerge(merged, user)
	getgenv().LIV4Config = merged
end
getgenv().RivalsConfig = getgenv().LIV4Config -- alias for ported modules

Config.Current = getgenv().LIV4Config

return Config
