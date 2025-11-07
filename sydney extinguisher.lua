---@param uCmd UserCmd
local function CreateMove(uCmd)
	if gui.GetValue("trigger key") ~= 0 and not input.IsButtonDown(gui.GetValue("trigger key")) then
		return
	end

	local pLocal = entities.GetLocalPlayer()
	if not pLocal then
		return
	end

	--- get our current weapon
	local pWeapon = pLocal:GetPropEntity("m_hActiveWeapon")
	if not pWeapon then
		return
	end

	local m_iItemDefinitionIndex = pWeapon:GetPropInt("m_iItemDefinitionIndex")
	assert(m_iItemDefinitionIndex, "Item definition index is nil! Is this a valid weapon?")

	--- sydney sleeper has item definition index 230
	if m_iItemDefinitionIndex == 230 then
		local shootpos = pLocal:GetAbsOrigin() + pLocal:GetPropVector("m_vecViewOffset[0]")
		assert(shootpos, "Shoot position is nil!")

		---@param ent Entity
		local function shouldHitEntity(ent, contentsMask)
			if ent:GetIndex() == pLocal:GetIndex() then
				return false
			end

			return true
		end

		local trace = engine.TraceLine(
			shootpos,
			shootpos + engine.GetViewAngles():Forward() * 8192,
			MASK_SHOT_HULL,
			shouldHitEntity
		)

		if trace and trace.entity:IsValid() and trace.entity:IsPlayer() and not trace.entity:IsDormant() then
			local ent = trace.entity

			if ent:GetTeamNumber() == pLocal:GetTeamNumber() and ent:InCond(E_TFCOND.TFCond_OnFire) then
				uCmd.buttons = uCmd.buttons | IN_ATTACK
			end
		end
	end
end

callbacks.Register("CreateMove", CreateMove)
