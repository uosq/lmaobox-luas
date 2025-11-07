local font_height = 12
local font = draw.CreateFont("Arial", font_height, 0)
local title = "spectators"

draw.SetFont(font)
local spec_tx = draw.GetTextSize(title)
local gap = 2

local x, y = 200, 200

local function OnDraw()
    local localplayer = entities.GetLocalPlayer()
    if localplayer == nil then
        return
    end

    local list = {}
    --- window's width and height
    local width, height = 0, 0

    draw.SetFont(font)

    local spectated = false

    for _, player in pairs(entities.FindByClass("CTFPlayer")) do
        if not player:IsDormant() and not player:IsAlive() and player ~= localplayer --[[and player:GetTeamNumber() == localplayer:GetTeamNumber()]] then
            local m_hObserverTarget = player:GetPropEntity("m_hObserverTarget")
            if m_hObserverTarget == localplayer then
               local isFirstPerson = player:GetPropInt("m_iObserverMode") == 4 --- thank you random unkcheats user
               list[player:GetName()] = isFirstPerson
               local name = player:GetName()
               local tx, th = draw.GetTextSize(name)
               height = height + math.floor(th) + gap
               width = width < math.floor(tx)+ gap and math.floor(tx) + gap or width
               width = spec_tx + width
               spectated = true
               --spectated_in_firstperson = isFirstPerson and not spectated_in_firstperson
            end
        end
    end

    if spectated then
        draw.Color(40, 40, 40, 250)
        draw.FilledRect(x, y, x + width, y + height)

        draw.Color(255, 255, 255, 255)
        draw.OutlinedRect(x - 1, y - 1, x + width + 1, y + height + 1)

        draw.Color(255, 255, 255, 255)
        for name, isFirstPerson in pairs(list) do
            draw.Text(x + gap, y, string.format("%s - %s", name, isFirstPerson and "FP" or "TP"))
            y = y + font_height + gap
        end
    end
end

callbacks.Register("Draw", OnDraw)