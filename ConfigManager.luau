--!strict
-- ConfigManager.luau | liv4cheets Internal | Configs tab | clean JSON stored locally
-- Executor FS (writefile/readfile/listfiles) + mirrors to Documents folder when possible.

local ConfigManager = {}
local HS = game:GetService("HttpService")
local FOLDER = "liv4cheets_configs"

local function hasFS(): boolean
	local g = getgenv() :: any
	return type(g.writefile) == "function" and type(g.readfile) == "function" and type(g.listfiles) == "function"
end

function ConfigManager.Folder(): string
	return FOLDER
end

function ConfigManager.Ensure()
	if not hasFS() then
		return
	end
	pcall(function()
		(getgenv() :: any).makefolder(FOLDER)
	end)
end

local function serializable(v: any): any
	if typeof(v) == "EnumItem" then
		return { __enum = tostring(v.EnumType) .. "." .. tostring(v.Name) }
	elseif typeof(v) == "Color3" then
		return { __color = { math.round(v.R * 255), math.round(v.G * 255), math.round(v.B * 255) } }
	elseif type(v) == "table" then
		local o = {}
		for k, vv in pairs(v) do
			o[k] = serializable(vv)
		end
		return o
	elseif type(v) == "number" or type(v) == "string" or type(v) == "boolean" then
		return v
	end
	return nil
end

local function restore(v: any): any
	if type(v) == "table" then
		if v.__enum then
			local s: string = v.__enum
			local a, b = string.match(s, "Enum%.(%w+)%.(%w+)")
			local ok, e = pcall(function()
				return (Enum :: any)[a][b]
			end)
			return ok and e or nil
		end
		if v.__color then
			return Color3.fromRGB(v.__color[1], v.__color[2], v.__color[3])
		end
		local o = {}
		for k, vv in pairs(v) do
			o[k] = restore(vv)
		end
		return o
	end
	return v
end

function ConfigManager.List(): { string }
	ConfigManager.Ensure()
	if not hasFS() then
		return {}
	end
	local ok, files = pcall(function()
		return (getgenv() :: any).listfiles(FOLDER)
	end)
	if not ok or type(files) ~= "table" then
		return {}
	end
	local out = {}
	for _, f in ipairs(files) do
		local n = string.match(f, "([^\\/]+)%.json$")
		if n then
			table.insert(out, n)
		end
	end
	return out
end

function ConfigManager.Save(name: string): string
	if not hasFS() then
		return "no FS (writefile missing)"
	end
	name = string.gsub(name or "", "[^%w%-%_]", "")
	if #name == 0 then
		return "invalid name"
	end
	ConfigManager.Ensure()
	local c = (getgenv() :: any).LIV4Config
	local ok, j = pcall(function()
		return HS:JSONEncode(serializable(c))
	end)
	if not ok then
		return "encode failed"
	end
	local ok2, err = pcall(function()
		(getgenv() :: any).writefile(FOLDER .. "/" .. name .. ".json", j)
	end)
	return ok2 and ("saved " .. name) or ("save failed: " .. tostring(err))
end

function ConfigManager.Load(name: string): string
	if not hasFS() then
		return "no FS (readfile missing)"
	end
	local ok, j = pcall(function()
		return (getgenv() :: any).readfile(FOLDER .. "/" .. name .. ".json")
	end)
	if not ok then
		return "read failed"
	end
	local ok2, t = pcall(function()
		return HS:JSONDecode(j)
	end)
	if not ok2 or type(t) ~= "table" then
		return "decode failed"
	end
	(getgenv() :: any).LIV4Config = restore(t);
	(getgenv() :: any).RivalsConfig = (getgenv() :: any).LIV4Config
	return "loaded " .. name .. " (re-execute to apply fully)"
end

function ConfigManager.Delete(name: string): string
	if not hasFS() then
		return "no FS"
	end
	pcall(function()
		(getgenv() :: any).delfile(FOLDER .. "/" .. name .. ".json")
	end)
	return "deleted " .. name
end

return ConfigManager
