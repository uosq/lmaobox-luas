local heatmaker_definition_index = 752
local IN_RELOAD = 8192

local function CreateMove(uCmd)
    local plocal = entities.GetLocalPlayer()
    if plocal == nil then
        return
    end

    local weapon = plocal:GetPropEntity("m_hActiveWeapon")
    if weapon:GetPropInt("m_iItemDefinitionIndex") ~= heatmaker_definition_index then
        return
    end

    local rage = plocal:GetPropFloat("m_Shared", "tfsharedlocaldata", "m_flRageMeter")

    if rage > 0 then
        uCmd.buttons = uCmd.buttons | IN_RELOAD --- default IN_RELOAD does not work
    end
end

callbacks.Register("CreateMove", CreateMove)