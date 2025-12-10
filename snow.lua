--- made by navet

---
local only_on_menu = true
---

local char = "*" --- the snowflakes, change them to whatever you want (letter or number)
local num_balls = 500 --- its a good compromise, if you want more i recommend lowering the font size (22 is the default here)
local vertical_wind = 300
local width, height = draw.GetScreenSize()
local aspect = width/height
local font = draw.CreateFont("Arial", (16 * aspect)//1, 1000)
local balls = {}
local flake = tostring(char)

local function create_ball()
	local x = math.random(0, width)
	local y = math.random(-height, 0)

	--- horizontal sin
	local h_phase = math.random() * 10
	local h_speed = 0.3 + math.random() * 0.6 --- 0.3-0.9
	local h_amp = 15 + math.random() * 25 --- sway

	--- vertical
	local v_phase = math.random() * 10
	local v_speed = 0.5 + math.random() * 0.8 --- 0.5–1.3
	local v_amp = 20 + math.random() * 30 --- wobble 20-50

	local fall_speed = vertical_wind * (0.7 + math.random() * 0.6) --- 70%–130%

	return x, y, h_phase, h_speed, h_amp, v_phase, v_speed, v_amp, fall_speed
end

--- create the balls
for i = 1, num_balls do
   balls[i] = { create_ball() }
end

-- Draw snowflakes
callbacks.Register("Draw", function()
	if only_on_menu and gui.IsMenuOpen() == false then return end

	local frametime = globals.FrameTime()
	local time = globals.RealTime()

	draw.SetFont(font)
	draw.Color(255, 255, 255, 255)

	for i = 1, num_balls do
		local ball = balls[i]

		local x, y = ball[1], ball[2]
		local h_phase, h_speed, h_amp = ball[3], ball[4], ball[5]
		local v_phase, v_speed, v_amp = ball[6], ball[7], ball[8]
		local fall_speed = ball[9]

		y = y + (fall_speed + math.sin(time * v_speed + v_phase) * v_amp) * frametime

		x = x + math.sin(time * h_speed + h_phase) * h_amp * frametime

		ball[1], ball[2] = x, y

		-- reset if out of the screen
		if x < -50 or x > width + 50 or y > height + 50 then
			balls[i] = { create_ball() }
		end

		if y > 0 and y < height and x > 0 and x < width then
			draw.TextShadow(x//1, y//1, flake)
		end
	end
end)