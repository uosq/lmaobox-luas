--- made by navet
--[[
  Player Prediction Library
  25/10/2025 (DD/MM/YYYY)

  This is mostly a conversion from TF2's spaghetti code to Lua
]]

---@alias water_level integer

local E_WaterLevel = {
	WL_NotInWater = 0,
	WL_Feet = 1,
	WL_Waist = 2,
	WL_Eyes = 3,
}

--- Why is this not in the lua docs?
local RuneTypes_t = {
	RUNE_NONE = -1,
	RUNE_STRENGTH = 0,
	RUNE_HASTE = 1,
	RUNE_REGEN = 2,
	RUNE_RESIST = 3,
	RUNE_VAMPIRE = 4,
	RUNE_REFLECT = 5,
	RUNE_PRECISION = 6,
	RUNE_AGILITY = 7,
	RUNE_KNOCKOUT = 8,
	RUNE_KING = 9,
	RUNE_PLAGUE = 10,
	RUNE_SUPERNOVA = 11,
}

local COORD_FRACTIONAL_BITS = 5
local COORD_DENOMINATOR = (1 << COORD_FRACTIONAL_BITS)
local COORD_RESOLUTION = (1.0 / COORD_DENOMINATOR)

local MAX_CLIP_PLANES = 5
local DIST_EPSILON = 0.03125

local clip_planes = {}
for i = 1, MAX_CLIP_PLANES do
	clip_planes[i] = Vector3()
end

--- Returns the current water level and the velocity if there is any water current
---@param origin Vector3
---@param mins Vector3
---@param maxs Vector3
---@param viewOffset Vector3
---@return integer, Vector3
local function GetWaterLevel(mins, maxs, origin, viewOffset)
	local point = Vector3()
	local cont = 0

	---@type water_level
	local waterlevel = 0

	local v = Vector3()

	point = origin + (mins + maxs) * 0.5
	point.z = origin.z + mins.z + 1

	cont = engine.GetPointContents(point, 0)

	if (cont & MASK_WATER) ~= 0 then
		waterlevel = E_WaterLevel.WL_Feet

		point.z = origin.z + (mins.z + maxs.z) * 0.5
		cont = engine.GetPointContents(point, 1)
		if (cont & MASK_WATER) ~= 0 then
			waterlevel = E_WaterLevel.WL_Waist
			point.z = origin.z + viewOffset.z
			if (cont & MASK_WATER) ~= 0 then
				waterlevel = E_WaterLevel.WL_Eyes
			end
		end

		if (cont & MASK_CURRENT) ~= 0 then
			if (cont & CONTENTS_CURRENT_0) ~= 0 then
				v.x = v.x + 1
			end
			if (cont & CONTENTS_CURRENT_90) ~= 0 then
				v.y = v.y + 1
			end
			if (cont & CONTENTS_CURRENT_180) ~= 0 then
				v.x = v.x - 1
			end
			if (cont & CONTENTS_CURRENT_270) ~= 0 then
				v.y = v.y - 1
			end
			if (cont & CONTENTS_CURRENT_UP) ~= 0 then
				v.z = v.z + 1
			end
			if (cont & CONTENTS_CURRENT_DOWN) ~= 0 then
				v.z = v.z - 1
			end
		end
	end

	return waterlevel, v
end

local function GetCurrentGravity()
	local _, sv_gravity = client.GetConVar("sv_gravity")
	return sv_gravity
end

---@param velocity Vector3
local function CheckVelocity(velocity)
	local _, sv_maxvelocity = client.GetConVar("sv_maxvelocity")
	if velocity.x > sv_maxvelocity then
		velocity.x = sv_maxvelocity
	end

	if velocity.y > sv_maxvelocity then
		velocity.y = sv_maxvelocity
	end

	if velocity.z > sv_maxvelocity then
		velocity.z = sv_maxvelocity
	end

	if velocity.x < -sv_maxvelocity then
		velocity.x = -sv_maxvelocity
	end

	if velocity.y < -sv_maxvelocity then
		velocity.y = -sv_maxvelocity
	end

	if velocity.z < -sv_maxvelocity then
		velocity.z = -sv_maxvelocity
	end
end

local function CheckIsOnGround(origin, mins, maxs, index)
	local down = Vector3(origin.x, origin.y, origin.z - 18)
	local trace = engine.TraceHull(origin, down, mins, maxs, MASK_PLAYERSOLID, function(ent, contentsMask)
		return ent:GetIndex() ~= index
	end)

	return trace and trace.fraction < 1.0 and not trace.startsolid and trace.plane and trace.plane.z >= 0.7
end

---@param velocity Vector3
---@param frametime number
local function StartGravity(velocity, frametime)
	local gravity = GetCurrentGravity()
	velocity.z = velocity.z - gravity * 0.5 * frametime
	CheckVelocity(velocity)
end

---@param velocity Vector3
---@param frametime number
local function FinishGravity(velocity, frametime)
	local gravity = GetCurrentGravity()
	velocity.z = velocity.z - gravity * 0.5 * frametime
	CheckVelocity(velocity)
end

---@param velocity Vector3
---@param is_on_ground boolean
---@param frametime number
local function Friction(velocity, is_on_ground, frametime)
	local speed, newspeed, control, friction, drop
	speed = velocity:LengthSqr()
	if speed < 0.01 then
		return
	end

	local _, sv_stopspeed = client.GetConVar("sv_stopspeed")
	drop = 0

	if is_on_ground then
		local _, sv_friction = client.GetConVar("sv_friction")
		friction = sv_friction

		control = speed < sv_stopspeed and sv_stopspeed or speed
		drop = drop + control * friction * frametime
	end

	newspeed = speed - drop
	if newspeed ~= speed then
		newspeed = newspeed / speed
		--velocity = velocity * newspeed
		velocity.x = velocity.x * newspeed
		velocity.y = velocity.y * newspeed
		velocity.z = velocity.z * newspeed
	end
end

---@param index integer
local function StayOnGround(origin, mins, maxs, step_size, index)
	local vstart = Vector3(origin.x, origin.y, origin.z + 2)
	local vend = Vector3(origin.x, origin.y, origin.z - step_size)

	local trace = engine.TraceHull(vstart, vend, mins, maxs, MASK_PLAYERSOLID, function(ent, contentsMask)
		return ent:GetIndex() ~= index
	end)

	if trace and trace.fraction < 1.0 and not trace.startsolid and trace.plane and trace.plane.z >= 0.7 then
		local delta = math.abs(origin.z - trace.endpos.z)
		if delta > (0.5 * COORD_RESOLUTION) then
			origin.x = trace.endpos.x
			origin.y = trace.endpos.y
			origin.z = trace.endpos.z
			return true
		end
	end

	return false
end

---@param velocity Vector3
---@param wishdir Vector3
---@param wishspeed number
---@param accel number
---@param frametime number
local function Accelerate(velocity, wishdir, wishspeed, accel, frametime)
	local addspeed, accelspeed, currentspeed

	currentspeed = velocity:Dot(wishdir)
	addspeed = wishspeed - currentspeed

	if addspeed <= 0 then
		return
	end

	accelspeed = accel * frametime * wishspeed
	if accelspeed > addspeed then
		accelspeed = addspeed
	end

	--print(string.format("Velocity: %s, accelspeed: %s, wishdir: %s", velocity, accelspeed, wishdir))
	velocity.x = velocity.x + wishdir.x * accelspeed
	velocity.y = velocity.y + wishdir.y * accelspeed
	velocity.z = velocity.z + wishdir.z * accelspeed
end

local function ClipVelocity(velocity, normal, overbounce)
	local backoff = velocity.x * normal.x + velocity.y * normal.y + velocity.z * normal.z
	backoff = (backoff < 0) and (backoff * overbounce) or (backoff / overbounce)
	velocity.x = velocity.x - normal.x * backoff
	velocity.y = velocity.y - normal.y * backoff
	velocity.z = velocity.z - normal.z * backoff
end

local function TryPlayerMove(origin, velocity, frametime, mins, maxs, shouldHitEntity, surface_friction)
	local time_left = frametime
	local numplanes = 0
	local temp_vec1 = Vector3() --- fuck this, im not gonna try to reverse engineer my stupid ass code
	local temp_vec2 = Vector3() --- ^^^^

	for bumpcount = 0, 3 do
		if velocity:LengthSqr() < 0.01 then
			break
		end

		temp_vec1.x = origin.x + velocity.x * time_left
		temp_vec1.y = origin.y + velocity.y * time_left
		temp_vec1.z = origin.z + velocity.z * time_left

		local trace = engine.TraceHull(origin, temp_vec1, mins, maxs, MASK_PLAYERSOLID, shouldHitEntity)

		if trace.allsolid then
			velocity.x, velocity.y, velocity.z = 0, 0, 0
			return
		end

		if trace.fraction > 0 then
			origin.x, origin.y, origin.z = trace.endpos.x, trace.endpos.y, trace.endpos.z
		end

		if trace.fraction >= 0.99 then
			break
		end

		time_left = time_left * (1 - trace.fraction)

		if numplanes >= MAX_CLIP_PLANES then
			velocity.x, velocity.y, velocity.z = 0, 0, 0
			return
		end

		-- Store plane normal
		local plane = clip_planes[numplanes + 1]
		plane.x, plane.y, plane.z = trace.plane.x, trace.plane.y, trace.plane.z
		numplanes = numplanes + 1

		-- Just clip against the new plane
		local overbounce = (trace.plane.z > 0.7) and 1.0 or 1.5 -- (1.0 + (1.0 - surface_friction) * 0.5)
		ClipVelocity(velocity, plane, overbounce)

		-- Check velocity against all planes
		local valid = true
		for i = 1, numplanes do
			local dot = velocity.x * clip_planes[i].x + velocity.y * clip_planes[i].y + velocity.z * clip_planes[i].z
			if dot < 0 then
				valid = false
				break
			end
		end

		if not valid and numplanes >= 2 then
			temp_vec2.x = clip_planes[1].y * clip_planes[2].z - clip_planes[1].z * clip_planes[2].y
			temp_vec2.y = clip_planes[1].z * clip_planes[2].x - clip_planes[1].x * clip_planes[2].z
			temp_vec2.z = clip_planes[1].x * clip_planes[2].y - clip_planes[1].y * clip_planes[2].x

			local len = temp_vec2:LengthSqr()
			if len > 0.01 then
				temp_vec2.x, temp_vec2.y, temp_vec2.z = temp_vec2.x / len, temp_vec2.y / len, temp_vec2.z / len
				local scalar = velocity.x * temp_vec2.x + velocity.y * temp_vec2.y + velocity.z * temp_vec2.z
				velocity.x, velocity.y, velocity.z = temp_vec2.x * scalar, temp_vec2.y * scalar, temp_vec2.z * scalar
			else
				velocity.x, velocity.y, velocity.z = 0, 0, 0
			end
		end
	end
end

local function StepMove(
	origin,
	velocity,
	frametime,
	mins,
	maxs,
	shouldHitEntity,
	surface_friction,
	step_size,
	is_on_ground
)
	local orig_x, orig_y, orig_z = origin.x, origin.y, origin.z
	local orig_vx, orig_vy, orig_vz = velocity.x, velocity.y, velocity.z

	local temp_vec1 = Vector3()

	-- Try regular move first
	TryPlayerMove(origin, velocity, frametime, mins, maxs, shouldHitEntity, surface_friction)

	local down_dist = (origin.x - orig_x) + (origin.y - orig_y)

	if not is_on_ground or down_dist > 5.0 or (orig_vx * orig_vx + orig_vy * orig_vy) < 1.0 then
		return
	end

	local down_x, down_y, down_z = origin.x, origin.y, origin.z
	local down_vx, down_vy, down_vz = velocity.x, velocity.y, velocity.z

	-- reset and try step up
	origin.x, origin.y, origin.z = orig_x, orig_y, orig_z
	velocity.x, velocity.y, velocity.z = orig_vx, orig_vy, orig_vz

	-- step up
	temp_vec1.x, temp_vec1.y, temp_vec1.z = origin.x, origin.y, origin.z + step_size + DIST_EPSILON
	local up_trace = engine.TraceHull(origin, temp_vec1, mins, maxs, MASK_PLAYERSOLID, shouldHitEntity)

	if not up_trace.startsolid and not up_trace.allsolid then
		origin.x, origin.y, origin.z = up_trace.endpos.x, up_trace.endpos.y, up_trace.endpos.z
	end

	-- move forward
	local up_orig_x, up_orig_y = origin.x, origin.y
	TryPlayerMove(origin, velocity, frametime, mins, maxs, shouldHitEntity, surface_friction)

	local up_dist = (origin.x - up_orig_x) + (origin.y - up_orig_y)

	-- if stepping up didn't help, revert to original result
	if up_dist <= down_dist then
		origin.x, origin.y, origin.z = down_x, down_y, down_z
		velocity.x, velocity.y, velocity.z = down_vx, down_vy, down_vz
		return
	end

	-- step down to ground
	temp_vec1.x, temp_vec1.y = origin.x, origin.y
	temp_vec1.z = origin.z - step_size - DIST_EPSILON
	local down_trace = engine.TraceHull(origin, temp_vec1, mins, maxs, MASK_PLAYERSOLID, shouldHitEntity)

	if down_trace.plane.z >= 0.7 and not down_trace.startsolid and not down_trace.allsolid then
		origin.x, origin.y, origin.z = down_trace.endpos.x, down_trace.endpos.y, down_trace.endpos.z
	end
end

---@param velocity Vector3
---@param origin Vector3
---@param mins Vector3
---@param maxs Vector3
---@param step_size number
---@param frametime number
---@param index integer
local function WalkMove(velocity, origin, mins, maxs, step_size, frametime, index, maxspeed)
	local wishdir = Vector3()
	local wishspeed

	-- Infer desired movement direction from current velocity
	local speed2d = velocity:Length2D()
	if speed2d < 0.001 then
		return
	end
	wishdir.x = velocity.x / speed2d
	wishdir.y = velocity.y / speed2d
	wishdir.z = 0
	wishspeed = maxspeed

	-- Clamp to server-defined max speed
	local _, sv_maxspeed = client.GetConVar("sv_maxspeed")
	if wishspeed > sv_maxspeed then
		wishspeed = sv_maxspeed
	end

	-- Zero out vertical velocity before acceleration
	velocity.z = 0

	local _, accel = client.GetConVar("sv_accelerate")
	Accelerate(velocity, wishdir, wishspeed, accel, frametime)
	velocity.z = 0

	local spd = velocity:Length()
	if spd < 1.0 then
		return
	end

	-- Attempt to move to destination
	local dest = Vector3(origin.x + velocity.x * frametime, origin.y + velocity.y * frametime, origin.z)

	local trace = engine.TraceHull(origin, dest, mins, maxs, MASK_PLAYERSOLID, function(ent, contentsMask)
		return ent:GetIndex() ~= index
	end)

	if trace.fraction == 1.0 then
		-- Full unobstructed move
		origin.x, origin.y, origin.z = trace.endpos.x, trace.endpos.y, trace.endpos.z
		StayOnGround(origin, mins, maxs, step_size, index)
	end

	-- Stop if airborne
	local is_on_ground = CheckIsOnGround(origin, mins, maxs)
	if not is_on_ground then
		return
	end

	-- Try step move if blocked
	if trace.fraction < 1.0 then
		StepMove(origin, velocity, frametime, mins, maxs, function(ent, contentsMask)
			return ent:GetIndex() ~= index
		end, 1.0, step_size, is_on_ground)
	end

	StayOnGround(origin, mins, maxs, step_size, index)
end

---@param target Entity
---@return number
local function GetAirSpeedCap(target)
	local m_hGrapplingHookTarget = target:GetPropEntity("m_hGrapplingHookTarget")
	if m_hGrapplingHookTarget then
		if target:GetCarryingRuneType() == RuneTypes_t.RUNE_AGILITY then
			local m_iClass = target:GetPropInt("m_iClass")
			return (m_iClass == E_Character.TF2_Soldier or E_Character.TF2_Heavy) and 850 or 950
		end
		local _, tf_grapplinghook_move_speed = client.GetConVar("tf_grapplinghook_move_speed")
		return tf_grapplinghook_move_speed
	elseif target:InCond(E_TFCOND.TFCond_Charging) then
		local _, tf_max_charge_speed = client.GetConVar("tf_max_charge_speed")
		return tf_max_charge_speed
	else
		local flCap = 30.0
		if target:InCond(E_TFCOND.TFCond_ParachuteDeployed) then
			local _, tf_parachute_aircontrol = client.GetConVar("tf_parachute_aircontrol")
			flCap = flCap * tf_parachute_aircontrol
		end
		if target:InCond(E_TFCOND.TFCond_HalloweenKart) then
			if target:InCond(E_TFCOND.TFCond_HalloweenKartDash) then
				local _, tf_halloween_kart_dash_speed = client.GetConVar("tf_halloween_kart_dash_speed")
				return tf_halloween_kart_dash_speed
			end
			local _, tf_hallowen_kart_aircontrol = client.GetConVar("tf_hallowen_kart_aircontrol")
			flCap = flCap * tf_hallowen_kart_aircontrol
		end
		return flCap * target:AttributeHookFloat("mod_air_control")
	end
end

---@param v Vector3 Velocity
---@param wishdir Vector3
---@param wishspeed number
---@param accel number
---@param dt number globals.TickInterval()
---@param surf number Is currently surfing?
---@param target Entity
local function AirAccelerate(v, wishdir, wishspeed, accel, dt, surf, target)
	wishspeed = math.min(wishspeed, GetAirSpeedCap(target))
	local currentspeed = v:Dot(wishdir)
	local addspeed = wishspeed - currentspeed
	if addspeed <= 0 then
		return
	end

	local accelspeed = math.min(accel * wishspeed * dt * surf, addspeed)
	v.x = v.x + accelspeed * wishdir.x
	v.y = v.y + accelspeed * wishdir.y
	v.z = v.z + accelspeed * wishdir.z
end

---@param pos Vector3
---@param vel Vector3
---@param mins Vector3
---@param maxs Vector3
---@param shouldHitEntity fun(ent: Entity, contentsMask: integer): boolean
local function CategorizePosition(pos, vel, mins, maxs, shouldHitEntity)
	local down = Vector3(pos.x, pos.y, pos.z - 66)
	local is_on_ground = false
	local ground_normal = nil
	local surface_friction = 1.0

	if vel.z <= 180.0 then
		local trace = engine.TraceHull(pos, down, mins, maxs, MASK_PLAYERSOLID, shouldHitEntity)
		if trace and trace.fraction < 1.0 and trace.plane and trace.plane.z >= 0.7 then
			is_on_ground = true
			ground_normal = Vector3(trace.plane.x, trace.plane.y, trace.plane.z)
		end
	end

	return is_on_ground, ground_normal, surface_friction
end

---@param velocity Vector3
---@param origin Vector3
---@param mins Vector3
---@param maxs Vector3
---@param frametime number
---@param player Entity
---@param index integer
local function AirMove(velocity, origin, mins, maxs, frametime, player, index)
	local wishdir = Vector3()
	local wishspeed

	local speed2d = velocity:Length2D()
	if speed2d < 0.001 then
		return
	end

	wishdir.x = velocity.x / speed2d
	wishdir.y = velocity.y / speed2d
	wishdir.z = 0
	wishspeed = speed2d

	local _, maxspeed = client.GetConVar("sv_maxspeed")
	if wishspeed > maxspeed then
		wishspeed = maxspeed
	end

	local _, airaccel = client.GetConVar("sv_airaccelerate")
	AirAccelerate(velocity, wishdir, wishspeed, airaccel, frametime, 1.0, player)

	-- move player
	TryPlayerMove(origin, velocity, frametime, mins, maxs, function(ent, contentsMask)
		return ent:GetIndex() ~= index
	end, 1.0)
end

--- Returns the player's predicted path and the last position
---@param player Entity
---@param time_ticks integer
---@return Vector3[], Vector3
local function SimulatePlayer(player, time_ticks)
	local velocity = player:EstimateAbsVelocity()
	local frametime = globals.TickInterval()
	local mins, maxs, origin, viewOffset
	local step_size
	mins = player:GetMins()
	maxs = player:GetMaxs()
	origin = player:GetAbsOrigin()
	viewOffset = player:GetPropVector("localdata", "m_vecViewOffset[0]")
	step_size = player:GetPropFloat("localdata", "m_Local", "m_flStepSize")
	local index = player:GetIndex()
	local maxspeed = player:GetPropFloat("m_flMaxspeed")

	local path = {}

	if velocity:Length() == 0.0 then
		return { origin }, origin
	end

	for _ = 1, time_ticks do
		if GetWaterLevel(mins, maxs, origin, viewOffset) == 0 then
			StartGravity(velocity, frametime)
		end

		local is_on_ground = CheckIsOnGround(origin, mins, maxs)
		if is_on_ground then
			Friction(velocity, is_on_ground, frametime)
		end

		CheckVelocity(velocity)

		if is_on_ground then
			WalkMove(velocity, origin, mins, maxs, step_size, frametime, index, maxspeed)
		else
			AirMove(velocity, origin, mins, maxs, frametime, player, index)
		end

		CategorizePosition(origin, velocity, mins, maxs, function(ent, contents)
			return ent:GetIndex() ~= index
		end)
		CheckVelocity(velocity)

		if GetWaterLevel(mins, maxs, origin, viewOffset) == 0 then
			FinishGravity(velocity, frametime)
		end

		if is_on_ground then
			velocity.z = 0
		end

		path[#path + 1] = Vector3(origin.x, origin.y, origin.z)
	end

	return path, path[#path]
end

return SimulatePlayer
