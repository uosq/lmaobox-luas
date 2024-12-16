local tolerance = 6 --- how close the sniper can aim before anti aim is enabled

local yaw_angles = {
   forward = 0,
   left = 90,
   right = -90,
   back = 180,
   custom = 0,
   ["spin left"] = 0,
   ["spin right"] = 0,
   none = 0,
}

---@param source Vector3
---@param dest Vector3
---@return EulerAngles
local function CalculateAngle(source, dest)
	local angles = EulerAngles()
	local delta = source - dest

	angles.pitch = math.atan(delta.z/ delta:Length2D()) * (180 / math.pi )
	angles.yaw = math.atan(delta.y, delta.x) * (180 / math.pi)

	if delta.x > 0 then
		angles.yaw = angles.yaw + 180

	elseif delta.x < 0 then
		angles.yaw = angles.yaw - 180
	end

	return angles
end

---@param source EulerAngles
---@param dest EulerAngles
local function CalculateFOV(source, dest)
	local v_source = source:Forward()
	local v_dest = dest:Forward()
	local result = math.deg ( math.acos(v_dest:Dot(v_source) / v_dest:LengthSqr()) )
	if result == "inf" or result ~= result then
		result = 0
	end
	return result
end

---@param player Entity
local function GetHitboxPos(player, hitbox)
	local model = player:GetModel()
	local studioHdr = models.GetStudioModel(model)

	local pHitBoxSet = player:GetPropInt("m_nHitboxSet")
	local hitboxSet = studioHdr:GetHitboxSet(pHitBoxSet)
	local hitboxes = hitboxSet:GetHitboxes()

	local hitbox = hitboxes[hitbox]
	local bone = hitbox:GetBone()

	local boneMatrices = player:SetupBones()
	local boneMatrix = boneMatrices[bone]
	if boneMatrix then
		local bonePos = Vector3( boneMatrix[1][4], boneMatrix[2][4], boneMatrix[3][4] )
		return bonePos
	end
	return nil
end

---@param player Entity
local function GetShootPos(player)
	return (player:GetAbsOrigin() + player:GetPropVector("m_vecViewOffset[0]"))
end

local antiaim_entity = nil

callbacks.Register("CreateMove", function (param)
   local localplayer = entities.GetLocalPlayer()
   if not localplayer then return end

   local closestfov = math.huge
   local players = entities.FindByClass("CTFPlayer")
   for _, player in pairs (players) do
      if player:IsValid() and player:IsAlive() and player:GetPropInt("m_iClass") == E_Character.TF2_Sniper and player:GetPropEntity("m_hActiveWeapon"):GetLoadoutSlot() == E_LoadoutSlot.LOADOUT_POSITION_PRIMARY and player ~= localplayer and player:GetTeamNumber() ~= localplayer:GetTeamNumber() and player:InCond(E_TFCOND.TFCond_Zoomed) then
         local pos
         if gui.GetValue("anti aim") == 1 then
            
            print("a",pos)
         else
            pos = GetHitboxPos(localplayer, 1) --- get local head position
            print("h",pos)
         end
         if pos then
            local eyeangle = player:GetPropVector("tflocaldata", "m_angEyeAngles[0]")
            local viewangle = EulerAngles(eyeangle.x, eyeangle.y, eyeangle.z)
            local angle = CalculateAngle(GetShootPos(player), pos)
            local fov = CalculateFOV(viewangle, angle)
            closestfov = fov < closestfov and fov or closestfov
         end
      end
   end

   if math.floor(closestfov) < tolerance then
      gui.SetValue("anti aim", 1)
   else
      gui.SetValue("anti aim", 0)
   end
end)

callbacks.Register("DrawModel", function (ctx)
   local entity = ctx:GetEntity()
   if entity and ctx:IsDrawingAntiAim() and entity ~= antiaim_entity then
      antiaim_entity = entity
      print("found anti aim")
   end
end)