-- liv4cheets boot test: run this FIRST, check executor output + F9, send results back
print("[liv4-boot] start")
local okEx, exName = pcall(function()
	return (identifyexecutor or function()
		return "unknown"
	end)()
end)
print("[liv4-boot] executor:", okEx, tostring(exName))

local path = "C:/Users/supa/Documents/robloxrivalsluau/liv4cheets-Internal.lua"
local okRead, src = pcall(readfile, path)
print("[liv4-boot] readfile ok:", okRead, "len:", okRead and #src or tostring(src))
if not okRead then
	warn("[liv4-boot] readfile failed, try moving bundle into executor workspace and use readfile('liv4cheets-Internal.lua')")
	return
end

local fn, err = loadstring(src, "@liv4cheets")
print("[liv4-boot] compile ok:", fn ~= nil, "err:", tostring(err):sub(1, 500))
if not fn then
	return
end

local okRun, r = pcall(fn)
print("[liv4-boot] run ok:", okRun, "ret:", tostring(r):sub(1, 500))
