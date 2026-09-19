--!strict
-- Effects.luau | liv4cheets Internal | hitmarker visual (wired to Visual tab)

local Effects = {}

function Effects.Start(Utils, Config)
	local S = Utils.Services
	function Effects.Hitmarker(ch: Model, dmg: number?)
		local c = (getgenv() :: any).LIV4Config or Config.Current
		local v = c.Visual
		if v and v.ESPEnabled == false then
		end
		local head = ch and (ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart"))
		if not head then
			return
		end
		local g = Instance.new("BillboardGui")
		g.Size = UDim2.fromScale(1, 1)
		g.AlwaysOnTop = true
		g.Adornee = head
		g.Parent = ch
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundTransparency = 1
		l.Text = tostring(math.round(dmg or 10))
		l.Font = Enum.Font.GothamBlack
		l.TextSize = 42
		l.TextStrokeTransparency = 0
		l.Parent = g
		task.delay(0.8, function()
			pcall(function()
				g:Destroy()
			end)
		end)
	end
	return Effects
end

return Effects
