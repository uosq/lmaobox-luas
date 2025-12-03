--- I am not smart enough to make this by myself
--- Source: https://www.unknowncheats.me/forum/team-fortress-2-a/700159-simple-glow-outline.html

local stencil = 1
local glow = 2

local m_pMatGlowColor = materials.Find("dev/glow_color")
assert(m_pMatGlowColor, "Glow Color is nil!")

local m_pMatHaloAddToScreen = materials.Create("GlowMaterialHalo",
[[UnlitGeneric
{
	$basetexture "GlowBuffer1"
	$additive "1"
}]])
assert(m_pMatHaloAddToScreen, "Halo Add To Screen is nil!")

local m_pMatBlurX = materials.Create("GlowMatBlurX",
[[BlurFilterX
{
	$basetexture "GlowBuffer1"
}]]);
assert(m_pMatBlurX, "Blur Filter X is nil!")

local m_pMatBlurY = materials.Create("GlowMatBlurY",
[[BlurFilterY
{
	$basetexture "GlowBuffer2"
}]])
assert(m_pMatBlurY, "Blur Filter Y is nil!")

local pRtFullFrame = materials.FindTexture("_rt_FullFrameFB", "RenderTargets", true);
assert(pRtFullFrame, "Full Frame FB is nil!")

local m_pGlowBuffer1 = materials.CreateTextureRenderTarget(
	"GlowBuffer1",
	pRtFullFrame:GetActualWidth(),
	pRtFullFrame:GetActualHeight()
)
assert(m_pGlowBuffer1, "Glow Buffer 1 is nil!")

local m_pGlowBuffer2 = materials.CreateTextureRenderTarget(
	"GlowBuffer2",
	pRtFullFrame:GetActualWidth(),
	pRtFullFrame:GetActualHeight()
);
assert(m_pGlowBuffer2, "Glowo Buffer 2 is nil!")

local STUDIO_RENDER = 0x00000001
local STUDIO_NOSHADOWS = 0x00000080

local function GetGuiColor(option)
    local value = gui.GetValue(option)
    if value == 255 then
        return nil
    elseif value == -1 then
	return {1, 1, 1, 1}
    end

    -- convert signed 32-bit int to unsigned 32-bit
    if value < 0 then
        value = value + 0x100000000
    end

    local r = (value >> 24) & 0xFF
    local g = (value >> 16) & 0xFF
    local b = (value >> 8)  & 0xFF
    local a = value & 0xFF

    return { r * 0.003921, g * 0.003921, b * 0.003921, a * 0.003921 }
end

local function GetColor(entity)
	if playerlist.GetPriority(entity) > 0 then
		return {1, 1, 0.0, 1}
	elseif playerlist.GetPriority(entity) < 0 then
		return {0, 1, 0.501888, 1}
	end

	if entity:GetTeamNumber() == 3 then
		return GetGuiColor("blue team color") or {0.145077, 0.58815, 0.74499, 1}
	else
		return GetGuiColor("red team color") or {0.929277, 0.250944, 0.250944, 1}
	end

	return {0, 0, 0, 1}
end

local function DrawEntities(players)
	for index, color in pairs (players) do
		local player = entities.GetByIndex(index)
		if player then
			render.SetColorModulation(table.unpack(color))
			player:DrawModel(STUDIO_RENDER | STUDIO_NOSHADOWS)
		end
	end
end

local function GetPlayers(outTable)
	local count = 0
	for _, player in pairs (entities.FindByClass("CTFPlayer")) do
		if player:ShouldDraw() and player:IsDormant() == false then
			local color = GetColor(player)
			outTable[player:GetIndex()] = color
			local child = player:GetMoveChild()
			while child ~= nil do
				if gui.GetValue("glow weapon") == 1 and (child:IsShootingWeapon() or child:IsMeleeWeapon()) then
					outTable[child:GetIndex()] = {1, 1, 1, 1}
				else
					outTable[child:GetIndex()] = color
				end
				count = count + 1
				child = child:GetMovePeer()
			end

			count = count + 1
		end
	end
	return count
end

local function GetBuildings(className, outTable)
	local count = 0
	for _, building in pairs(entities.FindByClass(className)) do
		if building:ShouldDraw() and building:IsDormant() == false then
			outTable[building:GetIndex()] = GetColor(building)
			count = count + 1
		end
	end
	return count
end

local function OnDoPostScreenSpaceEffects()
	if engine.IsTakingScreenshot() then
		return
	end

	local glowEnts = {}
	local entCount = 0
	entCount = entCount + GetPlayers(glowEnts)
	entCount = entCount + GetBuildings("CObjectSentrygun", glowEnts)
	entCount = entCount + GetBuildings("CObjectDispenser", glowEnts)
	entCount = entCount + GetBuildings("CObjectTeleporter", glowEnts)
	
	if entCount == 0 then
		return
	end

	local origGlowVal = gui.GetValue("glow")
	gui.SetValue("glow", 0)

	local w, h = draw.GetScreenSize()

	--- Stencil Pass
	do
		render.SetStencilEnable(true)

		render.ForcedMaterialOverride(m_pMatGlowColor)
		local savedBlend = render.GetBlend()
		render.SetBlend(0)

		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(E_StencilComparisonFunction.STENCILCOMPARISONFUNCTION_ALWAYS)
		render.SetStencilPassOperation(E_StencilOperation.STENCILOPERATION_REPLACE)
		render.SetStencilFailOperation(E_StencilOperation.STENCILOPERATION_KEEP)
		render.SetStencilZFailOperation(E_StencilOperation.STENCILOPERATION_REPLACE)
		
		DrawEntities(glowEnts)

		render.SetBlend(savedBlend)
		render.ForcedMaterialOverride(nil)
		render.SetStencilEnable(false)
	end

	--- Color pass
	do
		render.PushRenderTargetAndViewport()

		local r, g, b = render.GetColorModulation()

		local savedBlend = render.GetBlend()
		render.SetBlend(1.0)

		render.SetRenderTarget(m_pGlowBuffer1)
		render.Viewport(0, 0, w, h)

		render.ClearColor3ub(0, 0, 0)
		render.ClearBuffers(true, false, false)

		render.ForcedMaterialOverride(m_pMatGlowColor)

		DrawEntities(glowEnts)

		render.ForcedMaterialOverride(nil)
		render.SetColorModulation(r, g, b)
		render.SetBlend(savedBlend)

		render.PopRenderTargetAndViewport()
	end

	--- Blur pass
	if glow > 0 then
		render.PushRenderTargetAndViewport()
		render.Viewport(0, 0, w, h)
		
		-- More blur iterations = blurrier (does this word exist?) glow
		for i = 1, glow do
			render.SetRenderTarget(m_pGlowBuffer2)
			render.DrawScreenSpaceRectangle(m_pMatBlurX, 0, 0, w, h, 0, 0, w - 1, h - 1, w, h)
			render.SetRenderTarget(m_pGlowBuffer1)
			render.DrawScreenSpaceRectangle(m_pMatBlurY, 0, 0, w, h, 0, 0, w - 1, h - 1, w, h)
		end
		
		render.PopRenderTargetAndViewport()
	end

	--- Final pass
	do
		render.SetStencilEnable(true)
		render.SetStencilWriteMask(0)
		render.SetStencilTestMask(0xFF)

		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(E_StencilComparisonFunction.STENCILCOMPARISONFUNCTION_NOTEQUAL)

		render.SetStencilPassOperation(E_StencilOperation.STENCILOPERATION_KEEP)
		render.SetStencilFailOperation(E_StencilOperation.STENCILOPERATION_KEEP)
		render.SetStencilZFailOperation(E_StencilOperation.STENCILOPERATION_KEEP)

		--- my code to make the glow work
		--- not used anymore :(
		--[[render.DrawScreenSpaceRectangle(
			m_pMatHaloAddToScreen,
			0, 0,
			w, h,
			0, 0,
			w - 1, h - 1,
			w, h
		)]]

		--- pasted from amalgam
		--- https://github.com/rei-2/Amalgam/blob/fce4740bf3af0799064bf6c8fbeaa985151b708c/Amalgam/src/Features/Visuals/Glow/Glow.cpp#L65
		if stencil > 0 then
			local iSide = (stencil + 1) // 2
			render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, -iSide, 0, w, h, 0, 0, w - 1, h - 1, w, h);
			render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, 0, -iSide, w, h, 0, 0, w - 1, h - 1, w, h);
			render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, iSide, 0, w, h, 0, 0, w - 1, h - 1, w, h);
			render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, 0, iSide, w, h, 0, 0, w - 1, h - 1, w, h);
			local iCorner = stencil // 2
			if (iCorner > 0) then
				render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, -iCorner, -iCorner, w, h, 0, 0, w - 1, h - 1, w, h);
				render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, iCorner, iCorner, w, h, 0, 0, w - 1, h - 1, w, h);
				render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, iCorner, -iCorner, w, h, 0, 0, w - 1, h - 1, w, h);
				render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, -iCorner, iCorner, w, h, 0, 0, w - 1, h - 1, w, h);
			end
		end

		if glow > 0 then
			render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, 0, 0, w, h, 0, 0, w - 1, h - 1, w, h);
		end

		render.SetStencilEnable(false)
	end

	gui.SetValue("glow", origGlowVal)
end

callbacks.Register("DoPostScreenSpaceEffects", OnDoPostScreenSpaceEffects)