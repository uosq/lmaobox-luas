--[[ Made by navet ]]

--- SETTINGS

--- possible values: flat or textured
--- default is flat
local MATERIAL_MODE <const> = "flat"

local COLORS = {
	TEAM = {
		RED = { 255, 200, 200, 51 },
		BLU = { 94, 189, 224, 51 },
	},

	TARGET = { 128, 255, 0, 50 },
	FRIEND = { 66, 245, 170, 50 },
	BACKTRACK = { 50, 166, 168, 50 },
	ANTIAIM = { 168, 50, 50, 50 },
	PRIORITY = { 238, 255, 0, 50 },

	LOCALPLAYER = { 156, 66, 245, 50 },
	VIEWMODEL_ARM = { 24, 255, 0, 50 },

	WEAPON_PRIMARY = { 163, 64, 90, 100 },
	WEAPON_SECONDARY = { 74, 79, 125, 100 },
	WEAPON_MELEE = { 255, 255, 255, 100 },

	RED_HAT = { 21, 255, 0, 150 },
	BLU_HAT = { 255, 0, 13, 150 },

	SENTRY_RED = { 255, 0, 0, 150 },
	SENTRY_BLU = { 8, 0, 255, 150 },

	DISPENSER_RED = { 130, 0, 0, 150 },
	DISPENSER_BLU = { 3, 0, 105, 150 },

	TELEPORTER_RED = { 173, 31, 107, 150 },
	TELEPORTER_BLU = { 0, 217, 255, 150 },

	AMMOPACK = { 255, 255, 255, 150 },
	HEALTHKIT = { 255, 200, 200, 255 },

	MVM_MONEY = { 52, 235, 82, 150 },

	RAGDOLL_RED = { 255, 150, 150, 100 },
	RAGDOLL_BLU = { 150, 150, 255, 100 },
}

local TOGGLE_CHAMS_KEY <const> = E_ButtonCode.KEY_J

--- Should we draw chams on them?
local HEALTHPACK <const> = true
local AMMOPACK <const> = true
local VIEWMODEL_ARM <const> = true
local PLAYERS <const> = true
local SENTRIES <const> = true
local DISPENSERS <const> = true
local TELEPORTERS <const> = true
local MONEY <const> = true
local LOCALPLAYER <const> = true
local ANTIAIM <const> = true
local BACKTRACK <const> = true
local RAGDOLLS <const> = true

local DRAW_ON_ENEMY_ONLY <const> = false
local DRAW_ON_VISIBLE_ONLY <const> = false --- WARNING: they look less saturated when on visible only, idk why
local DRAW_ORIGINAL_MATERIAL_ON_PLAYER <const> = false
local DRAW_ORIGINAL_VIEWMODEL_ARM_MATERIAL <const> = false
local DRAW_ORIGINAL_MATERIAL_ON_EVERYTHING_ELSE <const> = false
--- End of the settings, please don't change anything below if you dont know what you're doing

---@class COLOR
---@field r integer
---@field g integer
---@field b integer
---@field a integer

local materials = materials
local render = render
local entities = entities
local aimbot = aimbot
local string = string
local playerlist = playerlist
local models = models

local flat_material_string <const> = [[
"UnlitGeneric"
{
  $basetexture "vgui/white_additive"
}
]]

local texture_material_string <const> = [[
"VertexLitGeneric"
{
  $basetexture "vgui/white_additive"
}
]]

--- used for string.find
local WEARABLES_CLASS <const> = "Wearable"
local TEAM_RED <const> --[[, TEAM_BLU <const>]] = 2 --, 3
local SENTRY_CLASS <const>, DISPENSER_CLASS <const>, TELEPORTER_CLASS <const> =
	 "CObjectSentrygun", "CObjectDispenser", "CObjectTeleporter"
local MVM_MONEY_CLASS <const> = "CCurrencyPack"
local VIEWMODEL_ARM_CLASS <const> = "CTFViewModel"

local last_button_press_tick = 0

local chams_materials <const> = {
	flat = materials.Create("TRANSPARENT CHAMS FLAT MAT", flat_material_string),
	textured = materials.Create("TRANSPARENT CHAMS TEXTURED MAT", texture_material_string),
}

---@param r integer
---@param g integer
---@param b integer
---@param a integer
local function get_color(r, g, b, a)
	return r / 255, g / 255, b / 255, a / 255
end

local GetByIndex = entities.GetByIndex
local enabled = true

---@type integer?
local localplayer_index = nil

---@type table<integer, COLOR>, table<integer, COLOR>
local entity_list_color_front, entity_list_color_back = {}, {}

---@param entity Entity?
local function get_entity_color(entity)
	if (not entity) then
		return nil
	end

	if (entity:GetIndex() == localplayer_index) then
		return COLORS.LOCALPLAYER
	end

	if (aimbot.GetAimbotTarget() == entity:GetIndex()) then
		return COLORS.TARGET
	end

	if (entity:IsWeapon() and entity:IsMeleeWeapon()) then
		return COLORS.WEAPON_MELEE
	elseif (entity:IsWeapon() and not entity:IsMeleeWeapon()) then
		return entity:GetLoadoutSlot() == E_LoadoutSlot.LOADOUT_POSITION_PRIMARY and COLORS.WEAPON_PRIMARY
			 or COLORS.WEAPON_SECONDARY
	end

	local team = entity:GetTeamNumber()
	do
		local class = entity:GetClass() -- not entity:GetPropInt("m_PlayerClass", "m_iClass")!!

		if (class == SENTRY_CLASS) then
			return team == TEAM_RED and COLORS.SENTRY_RED or COLORS.SENTRY_BLU
		elseif (class == DISPENSER_CLASS) then
			return team == TEAM_RED and COLORS.DISPENSER_RED or COLORS.DISPENSER_BLU
		elseif (class == TELEPORTER_CLASS) then
			return team == TEAM_RED and COLORS.TELEPORTER_RED or COLORS.TELEPORTER_BLU
		elseif (class == MVM_MONEY_CLASS) then
			return COLORS.MVM_MONEY
		elseif (class == VIEWMODEL_ARM_CLASS) then
			return COLORS.VIEWMODEL_ARM
		end

		if (class and string.find(class, WEARABLES_CLASS)) then
			return team == TEAM_RED and COLORS.RED_HAT or COLORS.BLU_HAT
		end
	end

	do
		local priority = playerlist.GetPriority(entity)
		if (priority and priority <= -1) then
			return COLORS.FRIEND
		elseif (priority and priority >= 1) then
			return COLORS.PRIORITY
		end
	end

	return COLORS.TEAM[team == TEAM_RED and "RED" or "BLU"]
end

local function update_entities()
	collectgarbage("stop")

	local me = entities:GetLocalPlayer()
	if (not me) then return end

	local localteam = me:GetTeamNumber()
	if (not localteam) then return end

	local localindex = me:GetIndex()

	local max_entities = entities:GetHighestEntityIndex()
	for i = 1, max_entities do
		local entity = GetByIndex(i)
		if (not entity) then goto continue end
		if (entity:IsDormant()) then goto continue end
		if (not LOCALPLAYER and i == localindex) then goto continue end
		local class = entity:GetClass()
		local team = entity:GetTeamNumber()

		if (DRAW_ON_ENEMY_ONLY and team == localteam) then
			goto continue
		end

		if (PLAYERS and entity:IsPlayer() and entity:IsAlive()) then
			entity_list_color_back[i] = get_entity_color(entity)

			local moveChild = entity:GetMoveChild()
			while (moveChild) do
				entity_list_color_back[moveChild:GetIndex()] = get_entity_color(moveChild)
				moveChild = moveChild:GetMovePeer()
			end
		else
			--- excluding ragdolls, they aren't alive >:)
			if (entity:GetHealth() >= 1) then
				if ((SENTRIES and class == SENTRY_CLASS) or (DISPENSERS and class == DISPENSER_CLASS)
						 or (TELEPORTERS and class == TELEPORTER_CLASS)) then
					entity_list_color_back[i] = get_entity_color(entity)
					goto continue
				end

				if (MONEY and class == MVM_MONEY_CLASS) then
					entity_list_color_back[i] = get_entity_color(entity)
					goto continue
				end

				--- medkit, ammopack
				if ((AMMOPACK or HEALTHPACK) and class == "CBaseAnimating") then
					local model = entity:GetModel()
					if (not model) then goto continue end

					local model_name = string.lower(models.GetModelName(model))
					if (not model_name) then goto continue end

					if (AMMOPACK and string.find(model_name, "ammo")) then
						entity_list_color_back[i] = COLORS.AMMOPACK
					elseif (HEALTHPACK and (string.find(model_name, "health") or string.find(model_name, "medkit"))) then
						entity_list_color_back[i] = COLORS.HEALTHKIT
					end

					goto continue
				end
			end

			if (RAGDOLLS and (class == "CTFRagdoll" or class == "CRagdollProp" or class == "CRagdollPropAttached")) then
				entity_list_color_back[i] = entity:GetPropInt("m_iTeam") == TEAM_RED and COLORS.RAGDOLL_RED or
					 COLORS.RAGDOLL_BLU
				goto continue
			end
		end
		::continue::
	end

	--- lol viewmodel is not in entity list
	if (VIEWMODEL_ARM) then
		local viewmodel = me:GetPropEntity("m_hViewModel[0]")
		if (viewmodel) then
			entity_list_color_back[viewmodel:GetIndex()] = get_entity_color(viewmodel)
		end
	end

	entity_list_color_front, entity_list_color_back = entity_list_color_back, entity_list_color_front
	collectgarbage("restart")
end

---@param usercmd UserCmd
local function CreateMove(usercmd)
	local state, tick = input.IsButtonPressed(TOGGLE_CHAMS_KEY)
	if (state and tick > last_button_press_tick) then
		enabled = not enabled
		last_button_press_tick = tick
	end

	if (enabled and (usercmd.tick_count % 5) == 0) then
		update_entities()
	end
end

local function ENABLE_DEPTHOVERRIDE()
	render.OverrideDepthEnable(true, true)
	return true
end

local function DISABLE_DEPTHOVERRIDE()
	render.OverrideDepthEnable(false, false)
	return true
end

--- For AntiAim and Backtrack indicators
---@param context DrawModelContext
---@param material Material
---@param color COLOR
local function ChangeMaterialForIndicators(context, material, color)
	local r, g, b, a = get_color(table.unpack(color))
	context:SetAlphaModulation(a)
	context:ForcedMaterialOverride(material)
	context:SetColorModulation(r, g, b)

	ENABLE_DEPTHOVERRIDE()
	context:DepthRange(0, 0.2)
	context:Execute()
	context:DepthRange(0, 1)
	DISABLE_DEPTHOVERRIDE()
end

---@param context DrawModelContext
local function DrawModel(context)
	if (not enabled) then return end

	local material = chams_materials[MATERIAL_MODE]
	if (not material) then return end

	local drawing_backtrack, drawing_antiaim = context:IsDrawingBackTrack(), context:IsDrawingAntiAim()
	if (drawing_antiaim or drawing_backtrack) then
		if ((drawing_antiaim and ANTIAIM) or (drawing_backtrack and BACKTRACK)) then
			local color = (drawing_antiaim and COLORS.ANTIAIM or COLORS.BACKTRACK)
			ChangeMaterialForIndicators(context, material, color)
		end
		return
	end

	local entity = context:GetEntity()
	if (not entity) then return end
	local index = entity:GetIndex()
	local class = entity:GetClass()
	if (not index or not class) then return end
	if (not entity_list_color_front[index]) then return end

	local color = entity_list_color_front[index]
	if (not color) then return end

	if ((DRAW_ORIGINAL_MATERIAL_ON_PLAYER and class == "CTFPlayer")
			 or (class == VIEWMODEL_ARM_CLASS and DRAW_ORIGINAL_VIEWMODEL_ARM_MATERIAL)
			 or (DRAW_ORIGINAL_MATERIAL_ON_EVERYTHING_ELSE)) then
		--- draw the original material
		context:Execute()
	end

	ENABLE_DEPTHOVERRIDE()
	local r, g, b, a = get_color(table.unpack(color))
	context:SetAlphaModulation(a)
	context:ForcedMaterialOverride(material)
	context:SetColorModulation(r, g, b)

	if (not DRAW_ON_VISIBLE_ONLY) then
		context:DepthRange(0, (class == VIEWMODEL_ARM_CLASS and 0.1 or 0.2))
	end

	context:Execute()

	--- resetting stuff
	context:DepthRange(0, 1)
	context:SetColorModulation(get_color(255, 255, 255, 255))
	DISABLE_DEPTHOVERRIDE()
end

callbacks.Register("CreateMove", "CM TRANSPARENT CHAMS", CreateMove)
callbacks.Register("DrawModel", "DME TRANSPARENT CHAMS", DrawModel)
