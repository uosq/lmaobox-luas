--- made by navet

--- start settings
local self_explode = false --- if you can explode yourself when its possible to damage someone
local delay_ms = 100 --- delay before triggering them (in miliseconds) | 1 second is roughly 66 ticks
local vischeck = true --- check if the victim is visible or not (will still check distance if false) | its probably the same logic as CTFGrenadePipebombProjectile::DetonateStickies(), although im not sure
--- --- end settings

local explosion_tick = nil
local debug = false
local M_RADPI = 180 / math.pi

local function SetDetonateTick(cmd)
	explosion_tick = cmd.tick_count + (((delay_ms / 1000) + engine.RandomFloat(0, 0.5)) * 66.67) --- not entirely accurate, as its more of 66.66666... but its close enough :p
end

--- copied straight from lnxlib
---@param source Vector3
---@param dest Vector3
---@return Vector3 angles
local function PositionAngles(source, dest)
	local delta = source - dest

	local pitch = math.atan(delta.z / delta:Length2D()) * M_RADPI
	local yaw = math.atan(delta.y / delta.x) * M_RADPI

	if delta.x >= 0 then
		yaw = yaw + 180
	end

	if pitch ~= pitch then
		pitch = 0
	end
	if yaw ~= yaw then
		yaw = 0
	end

	return Vector3(pitch, yaw, 0)
end

---@param can_explode boolean
---@param cmd UserCmd
---@param plocal Entity
---@param sticky Entity
local function Detonate(can_explode, cmd, plocal, sticky)
	if can_explode and explosion_tick and explosion_tick <= cmd.tick_count then
		cmd.buttons = cmd.buttons | IN_ATTACK2
		explosion_tick = nil

		local angles = PositionAngles(
			plocal:GetAbsOrigin() + plocal:GetPropVector("localdata", "m_vecViewOffset[0]"),
			sticky:GetAbsOrigin()
		)

		cmd.viewangles = angles

		--engine.SetViewAngles(EulerAngles(angles:Unpack()))
	end
end

local function VisCheckEntity(sticky, entity, Is_plocal)
	if Is_plocal and not vischeck then
		return true
	end

	if not sticky or not sticky:IsValid() then
		return false
	end

	if not entity or not entity:IsValid() then
		return false
	end

	local trace = engine.TraceLine(sticky:GetAbsOrigin(), entity:GetAbsOrigin(), MASK_SHOT_BRUSHONLY)

	if trace and trace.entity:GetIndex() == entity:GetIndex() and trace.fraction >= 0.1 then
		return true
	end

	return false
end

---@param cmd UserCmd
local function Run(cmd)
	local plocal = entities.GetLocalPlayer()
	if not plocal or not plocal:IsAlive() then
		return
	end

	if plocal:GetPropInt("m_iClass") ~= 4 then
		return
	end

	local stickylauncher = plocal:GetEntityForLoadoutSlot(E_LoadoutSlot.LOADOUT_POSITION_SECONDARY)
	local detonate_mode = nil

	if stickylauncher then
		detonate_mode = stickylauncher:AttributeHookFloat("set_detonate_mode")
	end

	local stickies = entities.FindByClass("CTFGrenadePipebombProjectile")
	local players = entities.FindByClass("CTFPlayer")

	local plocalteam = plocal:GetTeamNumber()
	local plocalindex = plocal:GetIndex()
	local plocalpos = nil

	if not self_explode then
		plocalpos = plocal:GetAbsOrigin()
	end

	local can_explode = true

	for _, player in pairs(players) do
		if
			can_explode
			and not player:IsDormant()
			and player:IsAlive()
			and player:GetTeamNumber() ~= plocalteam
			and not player:InCond(E_TFCOND.TFCond_Cloaked)
		then
			for _, sticky in pairs(stickies) do
				if
					sticky:IsValid() and sticky:AttributeHookFloat("sticky_arm_time") == 1.0 --[[sticky can explode]]
				then
					local velocity = sticky:EstimateAbsVelocity():Length()

					if velocity == 0 then
						local owner = sticky:GetPropEntity("m_hThrower")
						if owner and owner:GetIndex() == plocalindex then
							local pos = sticky:GetAbsOrigin()
							local radius = sticky:GetPropFloat("m_DmgRadius")

							local playerpos = player:GetAbsOrigin()
							local distance = math.abs((pos - playerpos):Length())

							if can_explode and distance <= radius and explosion_tick == nil then
								local settick = false
								if vischeck then
									if VisCheckEntity(sticky, player) then
										SetDetonateTick(cmd)
										settick = true
									end
								else
									SetDetonateTick(cmd)
									settick = true
								end

								if settick and detonate_mode == 2.0 then
									explosion_tick = cmd.tick_count
								end

								if debug then
									client.ChatPrintf("New explosion tick: " .. tostring(explosion_tick))
								end
							end

							if not self_explode and plocalpos then
								local distance = math.abs((pos - plocalpos):Length())
								if distance <= radius and (VisCheckEntity(sticky, plocalpos, true)) then
									can_explode = false
									explosion_tick = nil
								end
							end

							if detonate_mode == 2.0 then
								Detonate(can_explode, cmd, plocal, sticky)
							else
								if can_explode and explosion_tick and explosion_tick <= cmd.tick_count then
									cmd.buttons = cmd.buttons | IN_ATTACK2
									explosion_tick = nil
								end
							end
						end
					end
				end
			end
		end
	end

	if debug and explosion_tick then
		local remaining_ticks = explosion_tick - cmd.tick_count
		local remaining_seconds = remaining_ticks / 66.67
		client.ChatPrintf("Tick: " .. tostring(cmd.tick_count))
		client.ChatPrintf("Explosion tick: " .. tostring(explosion_tick))
		client.ChatPrintf(string.format("Remaining seconds: %.2f", remaining_seconds)) -- idk why my logic isn't working right, this always starts at 1
	end
end

callbacks.Register("CreateMove", Run)
