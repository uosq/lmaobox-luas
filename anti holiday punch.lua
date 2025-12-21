--- made by navet
--- this does not work
--- i have to fix it
--- please dont complaint to me that it doesnt work
--- thank you

local HOLIDAY_PUNCH_INDEX = 656

local function GetWorldSpaceCenter(ent)
	return ent:GetAbsOrigin() + (ent:GetMins() + ent:GetMaxs()) * 0.5
end

local function Normalize(vec)
	local len = vec:Length()
	if len < 0.0001 then
		return 0
	end

	vec.x = vec.x/len
	vec.y = vec.y/len
	vec.z = vec.z/len

	return len
end

---@param direction Vector3
local function DirectionToAngles(direction)
    local pitch = math.asin(-direction.z) * (180 / math.pi)
    local yaw = math.atan(direction.y, direction.x) * (180 / math.pi)
    return Vector3(pitch, yaw, 0)
end

--- this is as guess
--- tf2's source code doesn't have this function anywhere
--- fuck you valve!!
local function GetWorldSpaceCenter(pEntity)
	local mins, maxs = pEntity:GetMins(), pEntity:GetMaxs()
	local origin = pEntity:GetPropVector("tflocaldata", "m_vecOrigin")
	return origin + (mins + maxs) * 0.5
end

local function GetEyeAngles(pEntity)
	return pEntity:GetPropVector("tflocaldata", "m_angEyeAngles[0]")
end

---@param targetForward Vector3
---@param dir Vector3
---@param plocal Entity
---@param pTarget Entity
---@return boolean
local function IsBehindAndFacingEntity(plocal, dir, targetForward)
	local localForward = EulerAngles(GetEyeAngles(plocal):Unpack()):Forward()
	localForward.z = 0
	Normalize(localForward)

	targetForward.z = 0
	Normalize(targetForward)

	local posVsTargetView = dir:Dot(targetForward)
	local posVsLocalView = dir:Dot(localForward)
	local viewAnglesDot = localForward:Dot(targetForward)

	local isBehind = posVsTargetView > 0 --- for some reason this is positive, but in the tf2's source code it is negative wtf
	local isLookingAtTarget = posVsLocalView > 0.5
	local isFacingBack = viewAnglesDot > -0.3

	--print(string.format("isBehind=%s (%.2f), isLookingAtTarget=%s (%.2f), isFacingBack=%s (%.2f)", isBehind, posVsTargetView, isLookingAtTarget, posVsLocalView, isFacingBack, viewAnglesDot))

	return (isBehind and isLookingAtTarget and isFacingBack)
end

---@param cmd UserCmd
local function OnCreateMove(cmd)
	local plocal = entities.GetLocalPlayer()
	if plocal == nil then
		return
	end

	local localteam = plocal:GetTeamNumber()
	local localcenter = GetWorldSpaceCenter(plocal)

	local players = entities.FindByClass("CTFPlayer")
	local closestdistance, selecteddir = math.huge, nil

	local forward = engine.GetViewAngles():Forward()

	for _, player in pairs (players) do
		if player:IsAlive() and player:IsDormant() == false and player:GetTeamNumber() ~= localteam then
			local weapon = player:GetPropEntity("m_hActiveWeapon")
			if weapon:GetPropInt("m_iItemDefinitionIndex") == HOLIDAY_PUNCH_INDEX then
				local dir = (GetWorldSpaceCenter(player) - localcenter)
				local distance = Normalize(dir)
				if distance < closestdistance and distance <= 48 and IsBehindAndFacingEntity(player, dir, forward) then
					closestdistance = distance
					selecteddir = dir
				end
			end
		end
	end

	if not selecteddir then
		return
	end

	cmd.viewangles = DirectionToAngles(selecteddir)
end

callbacks.Register("CreateMove", OnCreateMove)