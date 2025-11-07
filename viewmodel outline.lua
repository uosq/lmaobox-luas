--- made by navet

--- 100 is completely opaque (not transparent)
--- 0 is completely invisible

local flat = materials.Create("flatmat",
[[UnlitGeneric
{
  $basetexture "vgui/white_additive"
}
]])

local mat = materials.Create("nav1",
[[UnlitGeneric
{
   $basetexture "vgui/white_additive"
   $wireframe "1"
   $additive 1
   $envmap "skybox/sky_dustbowl_01"
}]])

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

---@param dme DrawModelContext
local function DrawModel(dme)
	local pViewModel = dme:GetEntity()

	if
		(pViewModel and pViewModel:GetClass() ~= "CTFViewModel")
		or not (
			string.find(dme:GetModelName(), "models/weapons")
			or string.find(dme:GetModelName(), "models/workshop/weapons")
			or string.find(dme:GetModelName(), "models/workshop_partner/weapons")
		)
	then
		return
	end

	render.SetStencilEnable(true)
	render.OverrideDepthEnable(true, true)
	render.ClearBuffers(false, false, true)

	PlayerStencil()
	dme:ForcedMaterialOverride(flat)
	dme:SetAlphaModulation(0.1)
	dme:SetColorModulation(0.61, 0, 1)
	dme:Execute()

	OutlineStencil()
	dme:ForcedMaterialOverride(mat)
	dme:SetAlphaModulation(1)
end

local function StaticProp()
	render.SetStencilEnable(false)
	render.OverrideDepthEnable(false, false)
end

callbacks.Register("DrawStaticProps", StaticProp)
callbacks.Register("DrawModel", DrawModel)
