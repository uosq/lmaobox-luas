-- [[ Made by Navet ]]

local ACCEPTABLE_FOV <const> = 89
local M_RADPI <const> = 57.295779513082
local RAGE <const> = false

---@type Entity?
local localplayer = nil

---@param source Vector3
---@param dest Vector3
---@return EulerAngles
local function CalcAngle(source, dest)
	local angles = Vector3()
	local delta = (source - dest)
	local fHyp = math.sqrt((delta.x * delta.x) + (delta.y * delta.y))

	angles.x = (math.atan(delta.z / fHyp) * M_RADPI)
	angles.y = (math.atan(delta.y / delta.x) * M_RADPI)
	angles.z = 0.0

	if delta.x >= 0.0 then
		angles.y = angles.y + 180.0
	end

	return EulerAngles(angles:Unpack())
end

---@param src EulerAngles
---@param dst EulerAngles
---@return number
local function CalcFov(src, dst)
	local v_source = src:Forward()
	local v_dest = dst:Forward()
	local result = math.deg(math.acos(v_dest:Dot(v_source) / v_dest:LengthSqr()))

	if result ~= result or result == math.huge then
		result = 0.0
	end

	return result
end

---@return Vector3
local function GetShootPos()
	assert(localplayer, "GetShootPos: localplayer is nil!")
	return localplayer:GetAbsOrigin() + localplayer:GetPropVector("localdata", "m_vecViewOffset[0]")
end

local function GetGUIValue(name)
	return gui.GetValue(name) == 1
end

local function NormalizeVector(vec)
	return vec / vec:Length()
end

local function DotVector(a, b)
	return (a.x * b.x + a.y * b.y + a.z * b.z)
end

---@param target Entity
local function LookingAtBack(target)
	local vecToTarget = target:GetAbsOrigin() - localplayer:GetAbsOrigin()
	vecToTarget.z = 0
	vecToTarget = NormalizeVector(vecToTarget)

	local forward = engine:GetViewAngles():Forward()
	forward.z = 0
	forward = NormalizeVector(forward)

	local targetForward = target:GetAbsAngles():Forward()
	targetForward.z = 0
	targetForward = NormalizeVector(targetForward)

	local pos_vs_target = vecToTarget:Dot(targetForward) --- behind
	local pos_vs_owner = vecToTarget:Dot(forward) --- facing
	local viewangles = targetForward:Dot(forward) --- facestab

	local behind = pos_vs_target < 0
	local facing = pos_vs_owner > 0.5
	local view = viewangles < -0.3

	local str = "behind: %s : %s, facing: %s : %s, viewangles: %s : %s"
	print(string.format(str, tostring(pos_vs_target), behind, tostring(pos_vs_owner), facing, viewangles, view))
	return behind and facing
end

local function GetTarget()
	assert(localplayer, "GetBestTarget: localplayer is nil!")
	local weapon = localplayer:GetPropEntity("m_hActiveWeapon")
	if not weapon or weapon:GetWeaponID() ~= E_WeaponBaseID.TF_WEAPON_KNIFE then
		return false
	end
	local trace = weapon:DoSwingTrace()
	if trace.entity and trace.entity:GetTeamNumber() ~= localplayer:GetTeamNumber() and trace.entity:IsPlayer() then
		local player = trace.entity
		if player:InCond(E_TFCOND.TFCond_Disguised) and GetGUIValue("ignore disguised") then
			goto continue
		end
		if player:InCond(E_TFCOND.TFCond_Cloaked) and GetGUIValue("ignore cloaked") then
			goto continue
		end
		if player:InCond(E_TFCOND.TFCond_Ubercharged) then
			goto continue
		end
		if player:InCond(E_TFCOND.TFCond_Taunting) and GetGUIValue("ignore taunting") then
			goto continue
		end
		if player:InCond(E_TFCOND.TFCond_Bonked) and GetGUIValue("ignore bonked") then
			goto continue
		end
		if playerlist.GetPriority(player) == -1 and GetGUIValue("ignore steam friends") then
			goto continue
		end

		if LookingAtBack(player) then
			client.ChatPrintf("looking at the back of someone")
			return true
		end
	end
	::continue::
	return false
end

---@param usercmd UserCmd
local function RunAutoBackstab(usercmd)
	localplayer = entities:GetLocalPlayer()
	assert(localplayer, "CreateMove: localplayer is nil!")

	local target = GetTarget()
	if target then
		usercmd.buttons = usercmd.buttons | IN_ATTACK
	end
end

callbacks.Register("CreateMove", "NavetAutobackstab", RunAutoBackstab)
