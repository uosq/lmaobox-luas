printc(150, 255, 150, 255, "You can use 'change_zoom' command to change the max zoom")
printc(150, 255, 150, 255, "Example: change_zoom 100")

local machina_index = 526

local zoom = 10

local function Rifle(view, player, weapon)
     if not player:InCond(E_TFCOND.TFCond_Zoomed)
    and weapon:GetWeaponID() ~= E_WeaponBaseID.TF_WEAPON_SNIPERRIFLE_CLASSIC then return end

    local m_flChargedDamage = weapon:GetPropFloat("SniperRifleLocalData", "m_flChargedDamage")
    local defindex = weapon:GetPropInt("m_Item", "m_iItemDefinitionIndex")
    local multiplier = defindex == machina_index and 1.15 or 1
    local percent = (m_flChargedDamage * multiplier) / (150 * multiplier)

    view.fov = math.min(view.fov - (percent * zoom), 0.1)
end

---@param view ViewSetup
---@param weapon Entity
local function Huntsman(view, weapon)
    local beginchargetime = weapon:GetChargeBeginTime()
    if beginchargetime > 0.0 then
        local percent = (globals.CurTime() - beginchargetime) / weapon:GetChargeMaxTime()
        if percent > 1.0 then
            percent = 1.0
        end

        view.fov = math.min(view.fov - (percent * zoom), 0.1)
    end
end

---@param view  ViewSetup
local function RenderView(view)
    local player = entities:GetLocalPlayer()
    if not player then return end
    if not player:IsAlive() then return end
    if engine:IsGameUIVisible() or engine:Con_IsVisible() or engine:IsTakingScreenshot() then return end

    local weapon = player:GetPropEntity("m_hActiveWeapon")
    if not weapon then return end

    local id = weapon:GetWeaponID()

    if id == E_WeaponBaseID.TF_WEAPON_SNIPERRIFLE or id == E_WeaponBaseID.TF_WEAPON_SNIPERRIFLE_CLASSIC then
        Rifle(view, player, weapon)
    elseif id == E_WeaponBaseID.TF_WEAPON_COMPOUND_BOW then
        Huntsman(view, weapon)
    end
end

---@param cmd StringCmd
callbacks.Register("SendStringCmd", function (cmd)
    local str = cmd:Get()

    local words = {}
    for word in string.gmatch(str, "%S+") do
        words[#words+1] = word
    end

    if #words < 2 then
        return
    end

    if words[1] == "change_zoom" and words[2] then
        local newzoom = tonumber(words[2])
        if newzoom then
            zoom = newzoom
        end

        cmd:Set("")
    end
end)

callbacks.Register("RenderView", RenderView)