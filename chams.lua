--- options: flat or textured
local material = "textured"
local enemy_only = false

local colors = {
   red = {
      occluded = {200, 0, 0, 100},
      unoccluded = {255, 0, 0, 255},
   },

   blu = {
      occluded = {0, 200, 200, 100},
      unoccluded = {0, 255, 255, 255},
   },
}

local flatmat, texturedmat

local flatvmt =
[[
UnlitGeneric
{
   $basetexture "vgui/white_additive"
   $additive 1
}
]]

local texturedvmt =
[[
VertexLitGeneric
{
   $basetexture "vgui/white_additive"
   $additive 1
}
]]

flatmat = materials.Create("flatchams", flatvmt)
texturedmat = materials.Create("texturedchams", texturedvmt)

---@param entity Entity
---@return boolean
local function ShouldDraw(entity)
   if entity:IsDormant() then return false end

   if entity:IsPlayer() then
      do
         local plocal = entities.GetLocalPlayer()
         if not plocal then return false end

         if plocal:GetTeamNumber() == entity:GetTeamNumber() and enemy_only then
            return false
         end
      end

      return true
      --- not a player
   else
      if entity:IsShootingWeapon() or entity:IsMeleeWeapon() then
         return true
      end
   end

   return false
end

---@param entity Entity
local function GetEntityColor(entity)
   local team = entity:GetTeamNumber()

   return colors[team == 2 and "red" or "blu"].occluded, colors[team == 2 and "red" or "blu"].unoccluded
end

---@param dme DrawModelContext
local function DrawModel(dme)
   local entity = dme:GetEntity()
   if not entity then return end
   if not ShouldDraw(entity) then return end

   local occludedcolor, unoccludedcolor = GetEntityColor(entity)
   local selectedmat = string.lower(material) == "flat" and flatmat or texturedmat

   render.ClearBuffers(false, false, true)
   render.SetStencilEnable(true)
   render.OverrideDepthEnable(true, true)

   --- unoccluded / visible
   render.SetStencilCompareFunction(E_StencilComparisonFunction.STENCILCOMPARISONFUNCTION_ALWAYS);
   render.SetStencilPassOperation(E_StencilOperation.STENCILOPERATION_REPLACE);
   render.SetStencilFailOperation(E_StencilOperation.STENCILOPERATION_KEEP);
   render.SetStencilZFailOperation(E_StencilOperation.STENCILOPERATION_KEEP);
   render.SetStencilReferenceValue(1);
   render.SetStencilWriteMask(0xFF);
   render.SetStencilTestMask(0x0);

   dme:SetColorModulation(unoccludedcolor[1]/255, unoccludedcolor[2]/255, unoccludedcolor[3]/255)
   dme:SetAlphaModulation(unoccludedcolor[4]/255)
   dme:ForcedMaterialOverride(selectedmat)
   dme:Execute()

   --- occluded / not visible
   render.SetStencilCompareFunction(E_StencilComparisonFunction.STENCILCOMPARISONFUNCTION_EQUAL)
   render.SetStencilPassOperation(E_StencilOperation.STENCILOPERATION_KEEP)
   render.SetStencilFailOperation(E_StencilOperation.STENCILOPERATION_KEEP)
   render.SetStencilZFailOperation(E_StencilOperation.STENCILOPERATION_KEEP)
   render.SetStencilReferenceValue(0)
   render.SetStencilWriteMask(0x0)
   render.SetStencilTestMask(0xFF)

   dme:SetColorModulation(occludedcolor[1]/255, occludedcolor[2]/255, occludedcolor[3]/255);
   dme:SetAlphaModulation(occludedcolor[4]/255)
   dme:DepthRange(0, 0.2)
   dme:ForcedMaterialOverride(selectedmat)
   dme:Execute()

   --- reset stuff
   --- we dont want any leaks, do we?
   dme:DepthRange(0, 1)
   dme:SetAlphaModulation(0)

   render.SetStencilEnable(false)
   render.OverrideDepthEnable(false, false)
end

callbacks.Register("DrawModel", "chams my beloved", DrawModel)
