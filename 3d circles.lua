local lerp_factor = 0.05 --- how smooth it is (less is smoother)
local num_segments = 48 --- resolution of the circle
local angle_step <const> = 2 * math.pi / num_segments --- dont change plz

local dLine = draw.Line
local dColor = draw.Color
local dOutlinedCircle = draw.OutlinedCircle

local circles, lines = true, true
local prev_circles = {} -- store previous circle points for interpolation

---@param start_pos Vector3
---@param end_pos Vector3
---@return Trace
local function trace_line(start_pos, end_pos)
	local TraceLine = engine.TraceLine
	local res = TraceLine and TraceLine(start_pos, end_pos, MASK_SOLID_BRUSHONLY)
	return res and res.fraction and res or { fraction = 1.0, endpos = end_pos }
end

---@param x number
---@param y number
---@param z number
local function get_ground_z(x, y, z)
	local vec3 = Vector3
	local trace = trace_line(vec3(x, y, z + 100), vec3(x, y, z - 200))
	return (trace.fraction < 0.9 and trace.endpos and trace.endpos.z) or z
end

---@param center Vector3
---@param ideal Vector3
---@param radius number
local function project(center, ideal, radius)
	local sqrt = math.sqrt
	local vec3 = Vector3
	local dx, dy = ideal.x - center.x, ideal.y - center.y
	local len_2d = sqrt(dx * dx + dy * dy)

	--- be sure to maintain 2d projection
	if len_2d == 0 then
		return vec3(center.x, center.y, get_ground_z(center.x, center.y, center.z))
	end

	-- scale to radius
	local scale = radius / len_2d
	local end_pos = vec3(center.x + dx * scale, center.y + dy * scale, center.z)

	-- trace to ground and check for obstacles
	local tr = trace_line(center, end_pos)
	if tr.fraction < 0.9 and tr.endpos then
		-- if we hit something, project that hit point to the ground
		return vec3(tr.endpos.x, tr.endpos.y, get_ground_z(tr.endpos.x, tr.endpos.y, center.z))
	end

	-- or use the calculated position with ground height
	return vec3(end_pos.x, end_pos.y, get_ground_z(end_pos.x, end_pos.y, center.z))
end

---@param a Vector3
---@param b Vector3
---@param t number
---@return Vector3
local function lerp_vec3(a, b, t)
	local vec3 = Vector3
	return vec3(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t)
end

---@param center Vector3
---@param radius number
---@param circle_name string
local function draw_3d_circle(center, radius, circle_name)
	local cos, sin = math.cos, math.sin
	local vec3 = Vector3

	-- calculate the current circle points
	local current_points = {}

	for i = 0, num_segments do
		local a = (i % num_segments) * angle_step

		-- calculate point on circle in 2d, then project to 3d
		local circle_x = radius * cos(a)
		local circle_y = radius * sin(a)
		local ideal = vec3(center.x + circle_x, center.y + circle_y, center.z)
		local world = project(center, ideal, radius)
		current_points[i] = world
	end

	-- start or get previous points
	if not prev_circles[circle_name] then
		prev_circles[circle_name] = {}
		for i = 0, num_segments do
			prev_circles[circle_name][i] = current_points[i]
		end
	end

	-- smoothly inerpolate between previous and current points
	local smoothed_points = {}
	for i = 0, num_segments do
		if prev_circles[circle_name][i] and current_points[i] then
			smoothed_points[i] = lerp_vec3(prev_circles[circle_name][i], current_points[i], lerp_factor)
			prev_circles[circle_name][i] = smoothed_points[i] -- update for next frame
		else
			smoothed_points[i] = current_points[i]
			prev_circles[circle_name][i] = current_points[i]
		end
	end

	-- draw the circle
	local prev_screen = nil
	for i = 0, num_segments do
		if smoothed_points[i] then
			local screen = client.WorldToScreen(smoothed_points[i])
			if screen then
				if prev_screen then
					if lines then
						dLine(prev_screen[1], prev_screen[2], screen[1], screen[2])
					end

					if circles then
						--- num_segments // 2 is stupid as hell, but less segments = more fps :3
						dOutlinedCircle(screen[1], screen[2], 3, num_segments // 2)
					end
				end
				prev_screen = screen
			end
		end
	end
end
