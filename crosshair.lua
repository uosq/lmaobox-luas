local alib = require("alib")
alib.settings.font = draw.CreateFont("TF2 BUILD", 12, 1000)

local width, height = draw.GetScreenSize()

local window = {
    x = 10, y = math.floor(height/2),
    width = 250, height = 130,
}

local R_slider = {
    x = 5, y = 5,
    width = 240, height = 20,
    min = 1, max = 255,
    value = 255
}

local G_slider = {
    x = 5, y = 30,
    width = 240, height = 20,
    min = 1, max = 255,
    value = 255
}

local B_slider = {
    x = 5, y = 55,
    width = 240, height = 20,
    min = 1, max = 255,
    value = 255
}

local A_slider = {
    x = 5, y = 80,
    width = 240, height = 20,
    min = 1, max = 255,
    value = 255
}

local size_slider = {
    x = 5, y = 105,
    width = 240, height = 20,
    min = 2, max = 150,
    value = 6
}

local line = draw.Line
local register = callbacks.Register
local getconvar = client.GetConVar
local setconvar = client.SetConVar

if getconvar("crosshair") ~= 0 then
	setconvar("crosshair", 0)
end

local function draw_crosshair (x, y)
    local half_size = math.floor(size_slider.value / 2)
    local offset_from_center = 5

    -- Calculate the start and end points for each line 
    local top_start_y = y - half_size - offset_from_center
    local top_end_y = y - offset_from_center

    local bottom_start_y = y + offset_from_center
    local bottom_end_y = y + half_size + offset_from_center

    local left_start_x = x - half_size - offset_from_center
    local left_end_x = x - offset_from_center

    local right_start_x = x + offset_from_center
    local right_end_x = x + half_size + offset_from_center

    -- Draw the lines
    line(x, top_start_y, x, top_end_y)  -- Top
    line(left_start_x, y, left_end_x, y) -- Left
    line(right_start_x, y, right_end_x, y) -- Right
    line(x, bottom_start_y, x, bottom_end_y) -- Bottom
end

register("Draw", function()
    if engine.Con_IsVisible() or engine.IsGameUIVisible() or (gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot()) then
        return
    end

    local me = entities.GetLocalPlayer();
    if not me then return end
    if aimbot.GetAimbotTarget() <= 0 then
        local source = me:GetAbsOrigin() + me:GetPropVector( "localdata", "m_vecViewOffset[0]" );
        local destination = source + engine.GetViewAngles():Forward() * 1000
        local trace = engine.TraceLine( source, destination, MASK_SHOT_HULL );

        local screenPos = client.WorldToScreen(trace.endpos)
        if not screenPos then return end
        draw.Color(R_slider.value, G_slider.value, B_slider.value, A_slider.value)
        draw_crosshair(screenPos[1], screenPos[2])
    else
        local target = entities.GetByIndex(aimbot.GetAimbotTarget())
        if target then
            local screenPos = client.WorldToScreen(target:GetAbsOrigin() + Vector3(0, 0, 50))
            if screenPos then
                draw.Color(R_slider.value, G_slider.value, B_slider.value, A_slider.value)
                draw_crosshair(screenPos[1], screenPos[2])
            end
        end
    end
end)

register("CreateMove", function (param)
    if input.IsButtonDown(E_ButtonCode.MOUSE_LEFT) and alib.math.isMouseInside(window, R_slider) then
        local value = alib.math.GetNewSliderValue(window, R_slider, R_slider.min, R_slider.max)
        R_slider.value = math.floor(value)
     end

     if input.IsButtonDown(E_ButtonCode.MOUSE_LEFT) and alib.math.isMouseInside(window, G_slider) then
        local value = alib.math.GetNewSliderValue(window, G_slider, G_slider.min, G_slider.max)
        G_slider.value = math.floor(value)
     end

     if input.IsButtonDown(E_ButtonCode.MOUSE_LEFT) and alib.math.isMouseInside(window, B_slider) then
        local value = alib.math.GetNewSliderValue(window, B_slider, B_slider.min, B_slider.max)
        B_slider.value = math.floor(value)
     end

     if input.IsButtonDown(E_ButtonCode.MOUSE_LEFT) and alib.math.isMouseInside(window, A_slider) then
        local value = alib.math.GetNewSliderValue(window, A_slider, A_slider.min, A_slider.max)
        A_slider.value = math.floor(value)
     end

     if input.IsButtonDown(E_ButtonCode.MOUSE_LEFT) and alib.math.isMouseInside(window, size_slider) then
        local value = alib.math.GetNewSliderValue(window, size_slider, size_slider.min, size_slider.max)
        size_slider.value = math.floor(value)
     end
end)

register("Draw", function()
    if not gui.IsMenuOpen() then return end
    alib.objects.window(window.width, window.height, window.x, window.y, "crosshair settings")

    do
    alib.objects.sliderfade(R_slider.width, R_slider.height, R_slider.x + window.x, R_slider.y + window.y, R_slider.min, R_slider.max, R_slider.value, 255, 50, true)
        local percent = (R_slider.value - R_slider.min) / (R_slider.max - R_slider.min)
        draw.SetFont(alib.settings.font)
        local tw, th = draw.GetTextSize(tostring(R_slider.value))
        draw.Color(255, 50, 50, 255)
        draw.Text(R_slider.x + window.x + math.floor(R_slider.width * percent) - tw, R_slider.y + math.floor(th/2) + window.y, tostring(R_slider.value))
    end

    do
    alib.objects.sliderfade(G_slider.width, G_slider.height, G_slider.x + window.x, G_slider.y + window.y, G_slider.min, G_slider.max, G_slider.value, 255, 50, true)
        local percent = (G_slider.value - G_slider.min) / (G_slider.max - G_slider.min)
        draw.SetFont(alib.settings.font)
        local tw, th = draw.GetTextSize(tostring(G_slider.value))
        draw.Color(50, 255, 50, 255)
        draw.Text(G_slider.x + window.x + math.floor(G_slider.width * percent) - tw, G_slider.y + math.floor(th/2) + window.y, tostring(G_slider.value))
    end

    do
    alib.objects.sliderfade(B_slider.width, B_slider.height, B_slider.x + window.x, B_slider.y + window.y, B_slider.min, B_slider.max, B_slider.value, 255, 50, true)
        local percent = (B_slider.value - B_slider.min) / (B_slider.max - B_slider.min)
        draw.SetFont(alib.settings.font)
        local tw, th = draw.GetTextSize(tostring(B_slider.value))
        draw.Color(50, 50, 255, 255)
        draw.Text(B_slider.x + window.x + math.floor(B_slider.width * percent) - tw, B_slider.y + math.floor(th/2) + window.y, tostring(B_slider.value))
    end

    do
    alib.objects.sliderfade(A_slider.width, A_slider.height, A_slider.x + window.x, A_slider.y + window.y, A_slider.min, A_slider.max, A_slider.value, 255, 50, true)
        local percent = (A_slider.value - A_slider.min) / (A_slider.max - A_slider.min)
        draw.SetFont(alib.settings.font)
        local tw, th = draw.GetTextSize(tostring(A_slider.value))
        draw.Color(255, 255, 255, 255)
        draw.Text(A_slider.x + window.x + math.floor(A_slider.width * percent) - tw, A_slider.y + math.floor(th/2) + window.y, tostring(A_slider.value))
    end

    do
    alib.objects.sliderfade(size_slider.width, size_slider.height, size_slider.x + window.x, size_slider.y + window.y, size_slider.min, size_slider.max, size_slider.value, 255, 50, true)
        local percent = (size_slider.value - size_slider.min) / (size_slider.max - size_slider.min)
        draw.SetFont(alib.settings.font)
        local tw, th = draw.GetTextSize(tostring(size_slider.value))
        draw.Color(255, 255, 255, 255)
        draw.Text(size_slider.x + window.x + math.floor(size_slider.width * percent) - tw, size_slider.y + math.floor(th/2) + window.y, tostring(size_slider.value))
    end
end)

register("Unload", function()
    setconvar("crosshair", 1)
    alib.unload()
end)
