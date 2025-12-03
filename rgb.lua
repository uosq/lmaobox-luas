--- made by navet
--- rainbow colors

--- The ... parameter: R, G, B, A; All of them are optional
---@param option string
local function SetGuiColor(option, ...)
	local args = { ... }
	local r, g, b, a

	r = args[1] or 255
	g = args[2] or 255
	b = args[3] or 255
	a = args[4] or 255

	local color = ((r & 0xFF) << 24) | ((g & 0xFF) << 16) | ((b & 0xFF) << 8) | (a & 0xFF)

	--- Convert to signed integer (so, would this be a number? hmmmm)
	if color >= 0x80000000 then
		color = color - 0x100000000
	end

	gui.SetValue(option, color)
end

---@param h number Hue [0, 360]
---@param s number Saturation [0, 1]
---@param v number Value/Brightness [0, 1]
---@param a number Alpha [0, 255]
---@return integer, integer, integer, integer
local function HSVToRGBA(h, s, v, a)
	local c = v * s
	local x = c * (1 - math.abs((h / 60) % 2 - 1))
	local m = v - c

	local r_, g_, b_ = 0, 0, 0

	if h < 60 then
		r_, g_, b_ = c, x, 0
	elseif h < 120 then
		r_, g_, b_ = x, c, 0
	elseif h < 180 then
		r_, g_, b_ = 0, c, x
	elseif h < 240 then
		r_, g_, b_ = 0, x, c
	elseif h < 300 then
		r_, g_, b_ = x, 0, c
	else
		r_, g_, b_ = c, 0, x
	end

	local r = ((r_ + m) * 255 + 0.5)//1
	local g = ((g_ + m) * 255 + 0.5)//1
	local b = ((b_ + m) * 255 + 0.5)//1

	return r, g, b, a//1
end

local function OnDraw()
	SetGuiColor("gui color", HSVToRGBA(globals.RealTime()*10 % 360, 1.0, 1.0, 255))
end

callbacks.Register("Draw", OnDraw)
