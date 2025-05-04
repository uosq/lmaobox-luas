---@param cmd UserCmd
local function Run(cmd)
	local plocal = entities.GetLocalPlayer()
	if not plocal then return end

	local weapon = plocal:GetPropEntity("m_hActiveWeapon")
	if not weapon then return end

	local team = plocal:GetTeamNumber()

	local trace = weapon:DoSwingTrace()

	if trace and trace.entity and trace.entity:GetTeamNumber() ~= team and trace.entity:IsPlayer() then
		local target = trace.entity
		local direction = (plocal:GetAbsOrigin() - target:GetAbsOrigin())
		direction = direction / direction:Length()
		local target_forward = target:GetAbsAngles():Forward()
		target_forward = target_forward / target_forward:Length()
		local product = direction:Dot(target_forward)
		print(product)

		if product <= 0 then
			cmd.buttons = cmd.buttons | IN_ATTACK
		end
	end
end

callbacks.Register("CreateMove", "auto backstabk lolo", Run)