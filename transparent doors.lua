---@param dme DrawModelContext
local function DrawModel(dme)
    if string.find(dme:GetModelName(), "door") then
        dme:SetAlphaModulation(0.5)
    end
end

callbacks.Register("DrawModel", DrawModel)