--- a very special thanks to Glitch, wouldn't have figured out how to make this without him
--- made by navet

-- settings

--- apply outline to engineer buildings?
local buildings = true
local enemy_only = false
local visible_only = false
local backtrack_visible_only = true
local viewmodel = true
local hide_viewmodel = true
local fill = true --- fills the inside of the outline to give it a bit more contrast (visible_only doesnt work with it yet)
local fill_originalmat = false

local colors <const> = {
	RED = { 255, 0, 0 }, --- RED players
	BLU = { 0, 255, 255 }, --- BLU players
	LOCALPLAYER = { 156, 66, 245 }, --- you
	TARGET = { 128, 255, 0 }, --- aimbot target
	PRIORITY = { 255, 255, 0 }, --- players with priority higher than 0
	FRIEND = { 0, 255, 221 }, --- players with priority lower than 0
	BACKTRACK = { 0, 255, 0 },
	ANTIAIM = { 255, 255, 255 },

	RED_SENTRY = { 255, 0, 0 },
	BLU_SENTRY = { 0, 255, 255 },

	RED_DISPENSER = { 255, 0, 0 },
	BLU_DISPENSER = { 0, 255, 255 },

	RED_TELEPORTER = { 255, 0, 0 },
	BLU_TELEPORTER = { 0, 255, 255 },

	RED_HAT = { 255, 0, 0 },
	BLU_HAT = { 0, 150, 255 },

	PRIMARY_WEAPON = { 163, 64, 90 },
	SECONDARY_WEAPON = { 74, 79, 125 },
	MELEE_WEAPON = { 255, 255, 255 },

	VIEWMODEL = { 255, 255, 255 },
}

--- end of settings :p

--[[local function GetAttachments(entity)
   local indexs = {}
   local size = 0

   local moveChild = entity:GetMoveChild()
   while moveChild do
      size = size + 1
      indexs[moveChild:GetIndex()] = 0
      moveChild:GetMovePeer()
   end

   return size, indexs
end]]

---@param entity Entity
local function getentitycolor(entity)
	do
		local localindex = client:GetLocalPlayerIndex()
		if not localindex then
			return nil
		end

		--- localplayer check
		if localindex == entity:GetIndex() then
			return colors.LOCALPLAYER
		end
	end

	do --- aimbot target
		if aimbot.GetAimbotTarget() == entity:GetIndex() then
			return colors.TARGET
		end
	end

	do --- player weapons
		if entity:IsWeapon() then
			if entity:IsMeleeWeapon() then
				return colors.MELEE_WEAPON
			else
				return entity:GetLoadoutSlot() == E_LoadoutSlot.LOADOUT_POSITION_PRIMARY and colors.PRIMARY_WEAPON
					or colors.SECONDARY_WEAPON
			end
		end
	end

	do --- priority
		local priority = playerlist.GetPriority(entity)
		if priority > 0 then
			return colors.PRIORITY
		elseif priority < 0 then
			return colors.FRIEND
		end
	end

	do --- putting them in a do end because of class and team variables
		local class = entity:GetClass()
		if not class then
			return nil
		end

		local team = entity:GetTeamNumber()
		if not team then
			return nil
		end

		do --- buildings
			local is_sentry, is_teleporter, is_dispenser
			is_sentry = class == "CObjectSentrygun"
			is_teleporter = class == "CObjectTeleporter"
			is_dispenser = class == "CObjectDispenser"

			if is_sentry then
				return colors[team == 2 and "RED_SENTRY" or "BLU_SENTRY"]
			elseif is_teleporter then
				return colors[team == 2 and "RED_TELEPORTER" or "BLU_TELEPORTER"]
			elseif is_dispenser then
				return colors[team == 2 and "RED_DISPENSER" or "BLU_DISPENSER"]
			end
		end

		do --- hats
			if string.find(class, "Wearable") then
				return colors[team == 2 and "RED_HAT" or "BLU_HAT"]
			end
		end

		do
			if string.find(class, "Ragdoll") then
				return entity:GetPropInt("m_iTeam") == 2 and colors.RED or colors.BLU
			end
		end
	end

	return colors[entity:GetTeamNumber() == 2 and "RED" or "BLU"]
end

local mat = materials.Create(
	"outlinetest",
	[["UnlitGeneric"
{
   $basetexture "vgui/white_additive"
   $wireframe "1"
   $additive 1
   $envmap "skybox/sky_dustbowl_01"
}
]]
)

local flat = materials.Create(
	"flatmat",
	[[UnlitGeneric
{
   $basetexture "vgui/white_additive"
}]]
)

local function OutlineStencil()
	render.SetStencilCompareFunction(E_StencilComparisonFunction.STENCILCOMPARISONFUNCTION_EQUAL)
	render.SetStencilPassOperation(E_StencilOperation.STENCILOPERATION_KEEP)
	render.SetStencilFailOperation(E_StencilOperation.STENCILOPERATION_KEEP)
	render.SetStencilZFailOperation(E_StencilOperation.STENCILOPERATION_KEEP)
	render.SetStencilTestMask(0xFF)
	render.SetStencilWriteMask(0x0)
	render.SetStencilReferenceValue(0)
end

local function PlayerStencil()
	render.SetStencilCompareFunction(E_StencilComparisonFunction.STENCILCOMPARISONFUNCTION_ALWAYS)
	render.SetStencilPassOperation(E_StencilOperation.STENCILOPERATION_REPLACE)
	render.SetStencilFailOperation(E_StencilOperation.STENCILOPERATION_KEEP)
	render.SetStencilZFailOperation(E_StencilOperation.STENCILOPERATION_REPLACE)
	render.SetStencilTestMask(0x0)
	render.SetStencilWriteMask(0xFF)
	render.SetStencilReferenceValue(1)
end

---@param entity Entity
local function ShouldDraw(entity)
	local plocal = entities.GetLocalPlayer()
	if not plocal then
		return false
	end

	local pteam = plocal:GetTeamNumber()
	local class = entity:GetClass()

	--- probably better to just check if the class has "Wearable"
	--[[local size, attachments = GetAttachments(entity)
   if size == 0 then
      return false
   end

   if attachments[entity:GetIndex()] == 0 then
      return true
   end]]

	if class == "CTFRagdoll" or class == "CRagdollProp" or class == "CRagdollPropAttached" then
		return true
	end

	if entity:IsPlayer() then
		local team = entity:GetTeamNumber()
		if team == pteam and enemy_only then
			return false
		end

		return true
	else
		if entity:IsShootingWeapon() or entity:IsMeleeWeapon() then
			return true
		end

		if string.find(class, "Wearable") then
			return true
		end

		if
			buildings
			and (class == "CObjectSentrygun" or class == "CObjectTeleporter" or class == "CObjectDispenser")
			and entity:GetHealth() > 0
		then
			return true
		end
	end

	return false
end

---@param dme DrawModelContext
---@param selectedcolor integer[]
local function OutlineViewModel(dme, selectedcolor)
	render.SetStencilEnable(true)
	render.OverrideDepthEnable(true, true)

	--- player model
	PlayerStencil()
	if hide_viewmodel then
		dme:ForcedMaterialOverride(flat)
	end
	dme:SetAlphaModulation(hide_viewmodel and 0.1 or 1)
	dme:Execute()

	--- outline
	OutlineStencil()
	dme:ForcedMaterialOverride(mat)
	dme:SetColorModulation(selectedcolor[1] / 255, selectedcolor[2] / 255, selectedcolor[3] / 255)
	dme:SetAlphaModulation(1)
	dme:DepthRange(0, 0.1)
	dme:Execute()

	render.SetStencilEnable(false)
	render.OverrideDepthEnable(false, false)

	dme:ForcedMaterialOverride(nil)
	dme:DepthRange(0, 0.1)
	dme:SetColorModulation(1, 1, 1)
	dme:SetAlphaModulation(0)
end

---@param dme DrawModelContext
callbacks.Register("DrawModel", function(dme)
	if dme:IsDrawingGlow() then
		return
	end
	local entity = dme:GetEntity()
	local modelname = dme:GetModelName()

	--- viewmodel weapon
	if
		entity == nil
		and (string.find(modelname, "models/weapons/c_models") or string.find(
			modelname,
			"models/workshop/weapons/c_models"
		))
		and viewmodel
	then
		local selectedcolor = colors.VIEWMODEL
		OutlineViewModel(dme, selectedcolor)
		return
	elseif entity and entity:GetClass() == "CTFViewModel" then
		local selectedcolor = colors.VIEWMODEL
		OutlineViewModel(dme, selectedcolor)
		return
	end

	if not entity then
		return
	end
	if not ShouldDraw(entity) then
		return
	end

	local selectedcolor = dme:IsDrawingBackTrack() and colors.BACKTRACK
		or dme:IsDrawingAntiAim() and colors.ANTIAIM
		or getentitycolor(entity)
	if not selectedcolor then
		return
	end

	--render.SetStencilEnable(true)
	--render.OverrideDepthEnable(true, true)

	render.ClearBuffers(false, false, true)
	render.SetStencilEnable(true)
	render.OverrideDepthEnable(true, true)

	--- player model
	PlayerStencil()
	if fill then
		dme:ForcedMaterialOverride(flat)
		dme:SetColorModulation(selectedcolor[1] / 255, selectedcolor[2] / 255, selectedcolor[3] / 255)
		dme:SetAlphaModulation(0.1)
		dme:DepthRange(0, 0.2)
	else
		dme:ForcedMaterialOverride(nil)
		dme:SetAlphaModulation(0)
	end
	dme:Execute()

	--- outline
	OutlineStencil()
	dme:ForcedMaterialOverride(mat)
	dme:SetColorModulation(selectedcolor[1] / 255, selectedcolor[2] / 255, selectedcolor[3] / 255)
	dme:SetAlphaModulation(1)
	dme:DepthRange(
		0,
		((visible_only and not fill) or (backtrack_visible_only and dme:IsDrawingBackTrack())) and 1 or 0.2
	)

	--dmeDepthRange(0, 1)
	--[[dme:Execute()]]

	--[[render.SetStencilEnable(false)
    render.OverrideDepthEnable(false, false)]]

	--[[dme:ForcedMaterialOverride(nil)
    dme:DepthRange(0, 1)
    dme:SetColorModulation(1, 1, 1)
    dme:SetAlphaModulation((dme:IsDrawingBackTrack() or dme:IsDrawingAntiAim()) and 0 or 1)]]
	--render.DepthRange(0, 1)
end)

local function Props()
	render.OverrideDepthEnable(false, false)
	render.SetStencilEnable(false)
	render.DepthRange(0, 1)
end

local function FrameStageNotify(stage)
	if stage == E_ClientFrameStage.FRAME_RENDER_END then
		render.OverrideDepthEnable(false, false)
		render.SetStencilEnable(false)
	end
end

callbacks.Register("FrameStageNotify", FrameStageNotify)
callbacks.Register("DrawStaticProps", Props)

if client.GetConVar("mat_antialias") < 4 then
	if engine:GetServerIP() ~= "" then
		client.ChatPrintf("\x04Recommended to use at least mat_antialias 4")
	end

	print("Recommended to use at least mat_antialias 4")
end
