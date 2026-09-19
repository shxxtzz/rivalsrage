--!strict
-- SilentAim.luau | liv4cheets Internal | REAL silent aim (was a no-op before)
-- Hooks Fighter.UseItem:FireServer and swaps the shot table's .position with
-- the FOV target. Camera never moves, shots still land. Needs hookmetamethod,
-- getnamecallmethod, checkcaller, newcclosure (present on Potassium/Wave).

local SilentAim = {}

function SilentAim.Start(Utils, Config, getTarget: () -> Vector3?)
	local g = getgenv() :: any
	if type(g.hookmetamethod) ~= "function"
		or type(g.getnamecallmethod) ~= "function"
		or type(g.checkcaller) ~= "function"
		or type(g.newcclosure) ~= "function"
	then
		warn("[liv4] silent: executor lacks hook fns, silent aim unavailable")
		return SilentAim
	end
	if g.LIV4SilentHooked then
		return SilentAim
	end
	g.LIV4SilentHooked = true

	local old
	old = g.hookmetamethod(game, "__namecall", g.newcclosure(function(self, ...)
		local args = { ... }
		local okM, method = pcall(g.getnamecallmethod)
		if okM and method == "FireServer" then
			local okC, isCallerLocal = pcall(g.checkcaller)
			-- We want to intercept FireServer calls FROM the local player
			-- (isCallerLocal == true means our client initiated the call).
			if okC and isCallerLocal and typeof(self) == "Instance" then
				local nm = ""
				pcall(function()
					nm = (self :: Instance).Name
				end)
				if nm == "UseItem" then
					local c = g.LIV4Config or Config.Current
					local cb = c and c.Combat
					if cb and cb.SilentEnabled then
						local okT, pos = pcall(getTarget)
						if okT and typeof(pos) == "Vector3" then
							for i, a in ipairs(args) do
								if type(a) == "table" and typeof(a.position) == "Vector3" then
									local cp = {}
									for k, v in pairs(a) do
										cp[k] = v
									end
									cp.position = pos
									args[i] = cp
									break
								end
							end
						end
					end
				end
			end
		end
		return old(self, unpack(args))
	end))

	return SilentAim
end

return SilentAim
