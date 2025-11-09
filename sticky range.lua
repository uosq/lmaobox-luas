--- made by navet

local max_num_segments = 64 --- higher number = higher resolution = less fps (your choice)

local FULL_RES = 500
local HALF_RES = 900
local EVEN_LOWER_RES = 1600
local MINIMUM_SEGMENTS = 4

local dLine = draw.Line
local dColor = draw.Color
local WorldToScreen = client.WorldToScreen
local cos, sin = math.cos, math.sin
local sqrt = math.sqrt

local double_pi = 2 * math.pi

local function generate_trig_cache(num_segments)
	local cos_cache = {}
	local sin_cache = {}

	for i = 0, num_segments do
		local a = (i / num_segments) * double_pi
		cos_cache[i] = cos(a)
		sin_cache[i] = sin(a)
	end

	return cos_cache, sin_cache
end

---@param pos1 Vector3
---@param pos2 Vector3
---@return number
---this is bad, why use sqrt when we can square every distance instead? too bad, im too lazy to fix this now
local function distance_2d(pos1, pos2)
	local dx = pos1.x - pos2.x
	local dy = pos1.y - pos2.y
	return sqrt(dx * dx + dy * dy)
end

---@param world_point Vector3
---@param circles table
---@param exclude_circle table
---@return boolean
---i know, im the master of shitty names
local function is_point_inside_other_circles(world_point, circles, exclude_circle)
	for _, circle in ipairs(circles) do
		if circle ~= exclude_circle then
			local dist = distance_2d(world_point, circle.pos)
			if dist < circle.radius * 0.95 then
				return true
			end
		end
	end
	return false
end

---@param circles table
---@param num_segments integer
---@param cos_cache table
---@param sin_cache table
local function draw_merged_circles(circles, num_segments, cos_cache, sin_cache)
	if #circles == 0 then
		return
	end

	local function draw_circle(circle)
		local prev_screen = nil
		for i = 0, num_segments do
			local world_x = circle.pos.x + cos_cache[i] * circle.radius
			local world_y = circle.pos.y + sin_cache[i] * circle.radius
			local world_z = circle.pos.z
			local screen = WorldToScreen(Vector3(world_x, world_y, world_z))
			if screen and prev_screen then
				dLine(prev_screen[1], prev_screen[2], screen[1], screen[2])
			end
			prev_screen = screen
		end
	end

	if #circles == 1 then
		draw_circle(circles[1])
		return
	end

	for _, circle in ipairs(circles) do
		local prev_screen = nil
		local prev_visible = false

		for i = 0, num_segments do
			local world_x = circle.pos.x + cos_cache[i] * circle.radius
			local world_y = circle.pos.y + sin_cache[i] * circle.radius
			local world_z = circle.pos.z
			local world_point = Vector3(world_x, world_y, world_z)

			local is_visible = not is_point_inside_other_circles(world_point, circles, circle)
			local screen = WorldToScreen(world_point)

			if screen and is_visible then
				if prev_screen and prev_visible then
					dLine(prev_screen[1], prev_screen[2], screen[1], screen[2])
				end
				prev_screen = screen
				prev_visible = true
			else
				prev_visible = false
			end
		end
	end
end

---@param sticky_data table
---@return table
local function create_merged_groups(sticky_data)
	local merged = {}
	local used = {}

	for i, sticky1 in ipairs(sticky_data) do
		if not used[i] then
			local group = { sticky1 }
			used[i] = true

			-- find all stickies that overlap with this one
			for j = i + 1, #sticky_data do
				if not used[j] then
					local sticky2 = sticky_data[j]
					local dist = distance_2d(sticky1.pos, sticky2.pos)
					local combined_radius = sticky1.radius + sticky2.radius

					-- check if circles overlap
					if dist <= combined_radius then
						table.insert(group, sticky2)
						used[j] = true
					end
				end
			end

			table.insert(merged, group)
		end
	end

	return merged
end

---@param pos Vector3
---@param player_pos Vector3
---@return integer
local function compute_circle_lod_segments(pos, player_pos)
	local distance = distance_2d(pos, player_pos)
	local num_segments = math.floor(max_num_segments / (1 + distance * 0.01))
	return math.max(MINIMUM_SEGMENTS, math.min(max_num_segments, num_segments))
end

---@param group table
---@param player_pos Vector3
---@return integer
local function compute_group_lod_segments(group, player_pos)
	local closest_distance = math.huge

	-- find the closest sticky in this group
	for _, circle in ipairs(group) do
		local distance = distance_2d(circle.pos, player_pos)
		closest_distance = math.min(closest_distance, distance)
	end

	if closest_distance <= FULL_RES then
		return max_num_segments
	elseif closest_distance <= HALF_RES then
		return (max_num_segments * 0.5) // 1
	elseif closest_distance <= EVEN_LOWER_RES then
		return (max_num_segments * 0.25) // 1
	else
		return MINIMUM_SEGMENTS
	end
end

---@param groups table
---@param player_pos Vector3
local function draw_groups_with_lod(groups, player_pos)
	for _, group in ipairs(groups) do
		if #group == 1 then
			-- single sticky: use individual LOD
			local segments = compute_circle_lod_segments(group[1].pos, player_pos)
			local cos_cache, sin_cache = generate_trig_cache(segments)
			draw_merged_circles(group, segments, cos_cache, sin_cache)
		else
			-- multiple stickies: use group-based LOD
			local segments = compute_group_lod_segments(group, player_pos)
			local cos_cache, sin_cache = generate_trig_cache(segments)
			draw_merged_circles(group, segments, cos_cache, sin_cache)
		end
	end
end

callbacks.Register("Draw", function()
	local local_player = entities.GetLocalPlayer()
	if not local_player then
		return
	end

	local lp_pos = local_player:GetAbsOrigin()
	local stickies = entities.FindByClass("CTFGrenadePipebombProjectile")

	local red_stickies = {}
	local blu_stickies = {}

	for _, sticky in pairs(stickies) do
		local data = {
			pos = sticky:GetAbsOrigin(),
			radius = sticky:GetPropFloat("m_DmgRadius"),
			team = sticky:GetTeamNumber(),
		}
		if data.team == 2 then
			red_stickies[#red_stickies + 1] = data
		elseif data.team == 3 then
			blu_stickies[#blu_stickies + 1] = data
		end
	end

	if #red_stickies > 0 then
		dColor(255, 0, 0, 255)
		local red_groups = create_merged_groups(red_stickies)
		draw_groups_with_lod(red_groups, lp_pos)
	end

	if #blu_stickies > 0 then
		dColor(3, 219, 252, 255)
		local blu_groups = create_merged_groups(blu_stickies)
		draw_groups_with_lod(blu_groups, lp_pos)
	end
end)
