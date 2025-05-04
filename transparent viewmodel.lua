--- made by navet

--- settings
--- goes from 0 to 100
--- 0 is completely invisible
--- 100 is completely visible
local transparency = 100
--- end of the settings

local alpha <const> = transparency / 100
local normalweapons_model <const> = "models/weapons/c_models"
local workshopweapons_model <const> = "models/workshop/weapons/c_models"

---@param dme DrawModelContext
local function DrawModel(dme)
   local entity = dme:GetEntity()
   if entity then return end

   local modelname = dme:GetModelName()
   if not string.find(modelname, normalweapons_model) or not string.find(modelname, workshopweapons_model) then
      return
   end

   dme:SetAlphaModulation(alpha)
end

callbacks.Register("DrawModel", "alpha vm", DrawModel)