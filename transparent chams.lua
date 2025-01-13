--- thank you Glitch, helped me a lot with making this not choke your fps to death! <3
---@diagnostic disable: cast-local-type

--- SETTINGS
---
local toggle_key = E_ButtonCode.KEY_J

--- draw chams on them?
local HealthPack = true
local AmmoPack = true
local ViewmodelArm = true
local Players = true
local Sentries = true
local Dispensers = true
local Teleporters = true
local Money = true
local LocalPlayer = true
local AntiAim = true
local Backtrack = true

local EnemyOnly = true

---

local materials = materials
local render = render
local entities = entities
local aimbot = aimbot
local string = string
local gui = gui
local playerlist = playerlist
local models = models

local flat = materials.Create("flat_chams", [[
UnlitGeneric
{
	$basetexture "vgui/white_additive"
}
]])

local textured = materials.Create("textured_chams", [[
VertexLitGeneric
{
	$basetexture "vgui/white_additive"
}
]])

---@param r integer [0, 255]
---@param g integer [0, 255]
---@param b integer [0, 255]
---@param a integer [0, 255]
local function setcolor(r, g, b, a)
	return { r / 255, g / 255, b / 255, a / 255 }
end

--- E_TeamNumber is inverted
local TEAMS = {
	RED = 2,
	BLU = 3
}

local COLORS = {
	TEAM = {
		[TEAMS.RED] = setcolor(255, 200, 200, 51),
		[TEAMS.BLU] = setcolor(94, 189, 224, 51),
	},

	TARGET = setcolor(128, 255, 0, 50),
	FRIEND = setcolor(66, 245, 170, 50),
	BACKTRACK = setcolor(50, 166, 168, 50),
	ANTIAIM = setcolor(168, 50, 50, 50),
	PRIORITY = setcolor(238, 255, 0, 50),

	LOCALPLAYER = setcolor(156, 66, 245, 50),
	VIEWMODEL_ARM = setcolor(24, 255, 0, 50),

	WEAPON_PRIMARY = setcolor(163, 64, 90, 100),
	WEAPON_SECONDARY = setcolor(74, 79, 125, 100),
	WEAPON_MELEE = setcolor(255, 255, 255, 100),

	RED_HAT = setcolor(21, 255, 0, 150),
	BLU_HAT = setcolor(255, 0, 13, 150),

	SENTRY_RED = setcolor(255, 0, 0, 150),
	SENTRY_BLU = setcolor(8, 0, 255, 150),

	DISPENSER_RED = setcolor(130, 0, 0, 150),
	DISPENSER_BLU = setcolor(3, 0, 105, 150),

	TELEPORTER_RED = setcolor(173, 31, 107, 150),
	TELEPORTER_BLU = setcolor(0, 217, 255, 150),

	AMMOPACK = setcolor(255, 255, 255, 150),
	HEALTHKIT = setcolor(255, 200, 200, 255),

	MVM_MONEY = setcolor(52, 235, 82, 150),
}

local trackedEntities = {
	CTFPlayer = Players,           --- Players
	CObjectSentrygun = Sentries,   --- Sentries
	CObjectDispenser = Dispensers, --- Dispensers
	CObjectTeleporter = Teleporters, --- Teleporters
	CCurrencyPack = Money,         --- MVM Money
}

local depth_mode = {
	always = 0.2,
	["when visible"] = 1,
	["when invisible"] = 0.2,
}

--- END OF SETTINGS
local FindByClass = entities.FindByClass
local GetByIndex = entities.GetByIndex
local GetAimbotTarget = aimbot.GetAimbotTarget
local type = type
local toggle = true

--- the one we render is this
local entity_colors = {}

--- the new one that gets swapped with the above one
local entitycolors = {}

local currentTarget = nil
local currentMode = depth_mode.always
local selectedMaterial = flat

local number_players = 0

--- table for easier looping ig
local BUILDING_COLORS = {
	CObjectSentrygun = {
		[TEAMS.RED] = COLORS.SENTRY_RED,
		[TEAMS.BLU] = COLORS.SENTRY_BLU
	},
	CObjectDispenser = {
		[TEAMS.RED] = COLORS.DISPENSER_RED,
		[TEAMS.BLU] = COLORS.DISPENSER_BLU
	},
	CObjectTeleporter = {
		[TEAMS.RED] = COLORS.TELEPORTER_RED,
		[TEAMS.BLU] = COLORS.TELEPORTER_BLU
	},
	CCurrencyPack = COLORS.MVM_MONEY,
	CTFViewModel = COLORS.VIEWMODEL_ARM
}

---@param entity Entity
local function getEntityColor(entity)
	local localplayer = entities:GetLocalPlayer()
	if localplayer and localplayer == entity then return COLORS.LOCALPLAYER end
	if entity == currentTarget then return COLORS.TARGET end

	local team_number = entity:GetTeamNumber()
	local class = entity:GetClass()

	local building_color = BUILDING_COLORS[class]
	if building_color then
		return type(building_color) == "table" and building_color[team_number] or building_color
	end

	-- check for hats
	if string.find(class, "Wearable") then
		return team_number == TEAMS.RED and COLORS.RED_HAT or COLORS.BLU_HAT
	end

	local priority = playerlist.GetPriority(entity)
	if priority == -1 then return COLORS.FRIEND end
	if priority > 0 then return COLORS.PRIORITY end

	if entity:IsWeapon() then
		if entity:IsMeleeWeapon() then
			return COLORS.WEAPON_MELEE
		end
		return entity:GetLoadoutSlot() == E_LoadoutSlot.LOADOUT_POSITION_PRIMARY
			 and COLORS.WEAPON_PRIMARY
			 or COLORS.WEAPON_SECONDARY
	end

	-- Default team color
	return COLORS.TEAM[team_number]
end

local function update_entities()
	collectgarbage("stop")
	currentTarget = GetByIndex(GetAimbotTarget())
	local local_player = entities.GetLocalPlayer()
	entitycolors = {}

	local num = 0
	-- Process players and their children
	for _, player in pairs(FindByClass("CTFPlayer")) do
		---@diagnostic disable-next-line: need-check-nil
		if player and player ~= local_player and player:IsAlive() and not player:IsDormant() and player:ShouldDraw() and not player:InCond(E_TFCOND.TFCond_Cloaked) and (not EnemyOnly or player:GetTeamNumber() ~= local_player:GetTeamNumber()) then
			num = num + 1
			local index = player:GetIndex()
			entitycolors[index] = getEntityColor(player)

			-- Handle player attachments (HATS / WEAPONS)
			local moveChild = player:GetMoveChild()
			while moveChild do
				entitycolors[moveChild:GetIndex()] = getEntityColor(moveChild)
				moveChild = moveChild:GetMovePeer()
			end
		end
	end
	number_players = num
	num = nil

	--- for health pack and ammo pack
	for _, pack in pairs(FindByClass("CBaseAnimating")) do
		if pack and not pack:IsDormant() and pack:ShouldDraw() then
			local model = pack:GetModel()
			if not model then return end
			local modelName = string.lower(models.GetModelName(model))
			if not modelName then return end
			if AmmoPack and string.find(modelName, "ammo") then
				entitycolors[pack:GetIndex()] = COLORS.AMMOPACK
			elseif HealthPack and string.find(modelName, "health") or string.find(modelName, "medkit") then
				entitycolors[pack:GetIndex()] = COLORS.HEALTHKIT
			end
		end
	end

	--- localplayer
	if LocalPlayer and local_player then
		entitycolors[local_player:GetIndex()] = COLORS.LOCALPLAYER
		local moveChild = local_player:GetMoveChild()
		while moveChild do
			entitycolors[moveChild:GetIndex()] = getEntityColor(moveChild)
			moveChild = moveChild:GetMovePeer()
		end
	end

	--- viewmodel arm
	if ViewmodelArm and local_player then
		local viewmodel = local_player:GetPropEntity("m_hViewModel[0]")
		if viewmodel then
			entitycolors[viewmodel:GetIndex()] = COLORS.VIEWMODEL_ARM
		end
	end

	--- buildings
	for className in pairs(trackedEntities) do
		if className ~= "CTFPlayer" then
			for _, building in pairs(FindByClass(className)) do
				if building and not building:IsDormant() and building:ShouldDraw() and building:GetHealth() > 0 and (not EnemyOnly or building:GetTeamNumber() ~= local_player:GetTeamNumber()) then
					entitycolors[building:GetIndex()] = getEntityColor(building)
				end
			end
		end
	end

	--- party members if enabled (updated every 10 seconds)
	--- this is bullshit, why cant we just get the player userid directly??
	--[[
	if Party and cmd.tick_count > last_party_check_tick then
		local members = party.GetMembers()
		for _, member in pairs(members) do
			local name = steam.GetPlayerName(member)

			local players = FindByClass()
		end
	end]]

	-- swap references instead of copying
	entity_colors, entitycolors = entitycolors, entity_colors
	collectgarbage("restart")
end

local fast_interval = 5   --- every 5 ticks
local slow_interval = 133 --- every ~2 seconds

local update_interval = 0
local last_tick = 0

local last_button_press_tick = 0

---@param cmd UserCmd
callbacks.Register("CreateMove", function(cmd)
	local state, tick = input.IsButtonPressed(toggle_key)
	if state and tick ~= last_button_press_tick then
		last_button_press_tick = tick
		toggle = not toggle
	end
	if not toggle then return end
	if cmd.tick_count - last_tick >= update_interval then
		selectedMaterial = string.lower(gui.GetValue("draw style")) == "flat"
			 and flat
			 or textured
		currentMode = depth_mode[gui.GetValue("draw mode")]
		--- if we are playing on a high player count server, increase the update interval to not cause too much lag
		--- the player would definitely notice, but its better than having 10 fps
		update_interval = number_players > 50 and slow_interval or fast_interval

		last_tick = cmd.tick_count
		update_entities()
		--client.ChatPrintf((collectgarbage("count") / 1024) .. " MB")
	end
end)

---@param ctx DrawModelContext
---@param depth number [0, 1]
local function change_depth(ctx, depth)
	render.OverrideDepthEnable(true, true)
	ctx:DepthRange(0, depth and depth or 1)
	ctx:Execute()
	ctx:DepthRange(0, 1)
	render.OverrideDepthEnable(false, false)
end

--- sets the material, alpha and color
local function setctx(ctx, color)
	ctx:SetAlphaModulation(color[4])
	ctx:ForcedMaterialOverride(selectedMaterial)
	ctx:SetColorModulation(color[1], color[2], color[3])
end

---@param param DrawModelContext
local function handleDrawModel(param)
	if not toggle then return end
	local ctx = param

	local bDrawingBacktrack = ctx:IsDrawingBackTrack()
	local bDrawingAntiAim = ctx:IsDrawingAntiAim()
	if (bDrawingBacktrack and Backtrack) then
		local color = COLORS.BACKTRACK
		setctx(ctx, color)
		change_depth(ctx, currentMode)
		return
	elseif (bDrawingBacktrack and not Backtrack) then
		return
	elseif (bDrawingAntiAim and not AntiAim) then
		return
	elseif (bDrawingAntiAim and AntiAim) then
		local color = COLORS.ANTIAIM
		setctx(ctx, color)
		change_depth(ctx, currentMode)
		return
	end

	local entity = ctx:GetEntity()
	if not entity or entity:IsDormant() then return end
	local index = entity:GetIndex()

	if not entity_colors[index] then return end

	local color = entity_colors[index]
	if not color then return end
	setctx(ctx, color)

	--- ViewModel is strange, overriding DepthRange makes it get behind other models, so i gotta do this
	if entity:GetClass() ~= "CTFViewModel" then
		change_depth(ctx, currentMode)
	end
end

callbacks.Register("DrawModel", handleDrawModel)

callbacks.Register("Unload", function()
	MATERIALS = nil
	COLORS = nil
	BUILDING_COLORS = nil
	currentTarget = nil
	trackedEntities = nil
	entity_colors = nil
	selectedMaterial = nil
	flat = nil
	textured = nil
	fast_interval = nil
	slow_interval = nil
	update_interval = nil
	last_tick = nil
	collectgarbage("collect")
end)
