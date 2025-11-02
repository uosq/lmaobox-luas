--- made by navet

local TF_TEAM_PVE_INVADERS = 3

---@param vec Vector3
local function NormalizeInPlace(vec)
	local len = vec:Length()
	if len == 0 then
		return
	end

	vec.x = vec.x / len
	vec.y = vec.y / len
	vec.z = vec.z / len
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

---@param targetForward Vector3?
---@param dir Vector3?
---@param plocal Entity
---@param pTarget Entity
---@return boolean
local function IsBehindAndFacingEntity(plocal, pTarget, dir, targetForward)
	dir = dir or GetWorldSpaceCenter(pTarget) - GetWorldSpaceCenter(plocal) -- local -> target
	dir.z = 0
	NormalizeInPlace(dir)

	local localForward = EulerAngles(GetEyeAngles(plocal):Unpack()):Forward()
	localForward.z = 0
	NormalizeInPlace(localForward)

	targetForward = targetForward or EulerAngles(GetEyeAngles(pTarget):Unpack()):Forward()
	targetForward.z = 0
	NormalizeInPlace(targetForward)

	local posVsTargetView = dir:Dot(targetForward)
	local posVsLocalView = dir:Dot(localForward)
	local viewAnglesDot = localForward:Dot(targetForward)

	local isBehind = posVsTargetView > 0 --- for some reason this is positive, but in the tf2's source code it is negative wtf
	local isLookingAtTarget = posVsLocalView > 0.5
	local isFacingBack = viewAnglesDot > -0.3

	--print(string.format("isBehind=%s (%.2f), isLookingAtTarget=%s (%.2f), isFacingBack=%s (%.2f)", isBehind, posVsTargetView, isLookingAtTarget, posVsLocalView, isFacingBack, viewAnglesDot))

	return (isBehind and isLookingAtTarget and isFacingBack)
end

---@param pTarget Entity
---@return boolean
local function CanBackstabEntity(plocal, pTarget)
	if pTarget == nil then
		return false
	end

	local iNoBackstab = pTarget:AttributeHookInt("cannot_be_backstabbed")
	if iNoBackstab == 0 then
		return false
	end

	if IsBehindAndFacingEntity(plocal, pTarget) then
		return true
	end

	if gamerules.IsMvM() and pTarget:GetTeamNumber() == TF_TEAM_PVE_INVADERS then
		if pTarget:InCond(E_TFCOND.TFCond_MVMBotRadiowave) then
			return true
		end

		if pTarget:InCond(E_TFCOND.TFCond_Sapped) and not pTarget:GetPropBool("m_bIsMiniBoss") then
			return true
		end
	end

	return false
end

---@param uCmd UserCmd
local function CreateMove(uCmd)
	local netchannel = clientstate.GetNetChannel()
	if netchannel == nil then
		return
	end

	local plocal = entities.GetLocalPlayer()
	if not plocal or not plocal:IsAlive() then
		return
	end

	if plocal:GetPropInt("m_iClass") ~= E_Character.TF2_Spy then
		return
	end

	local pweapon = plocal:GetPropEntity("m_hActiveWeapon")
	if not pweapon then
		return
	end

	if not pweapon:IsMeleeWeapon() then
		return
	end

	if pweapon:GetLoadoutSlot() ~= E_LoadoutSlot.LOADOUT_POSITION_MELEE then
		return
	end

	local swing = pweapon:DoSwingTrace()
	if
		swing
		and swing.entity ~= nil
		and swing.entity:IsValid()
		and swing.entity:IsPlayer()
		and swing.entity:GetTeamNumber() ~= plocal:GetTeamNumber()
	then
		if CanBackstabEntity(plocal, swing.entity) then
			uCmd.buttons = uCmd.buttons | IN_ATTACK
			return
		end
	end
end

callbacks.Register("CreateMove", CreateMove)
