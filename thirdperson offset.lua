local alib = require("alib")

local ui_visible = true -- disable ui

local right = {
    x = 5, y = 5,
    width = 100,
    height = 20,
    value = 0,
    min = -150,
    max = 150
}

local up = {
    x = 5, y = 30,
    width = 100,
    height = 20,
    value = 0,
    min = -150,
    max = 150
}

local dist = {
    x = 5, y = 55,
    width = 100,
    height = 20,
    value = 0,
    min = -150,
    max = 150
}

local window = {
    x = 5, y = 5,
    width = 110,
    height = 80,
}

local font = draw.CreateFont("TF2 BUILD", 12, 1000)

---@param usercmd UserCmd
callbacks.Register("CreateMove", function (usercmd)
    if input.IsButtonDown(MOUSE_LEFT) and alib.math.isMouseInside(window, right) then
       local value = alib.math.GetNewSliderValue(window, right, right.min, right.max)
       right.value = value
    elseif input.IsButtonDown(MOUSE_RIGHT) and alib.math.isMouseInside(window, right) then
        right.value = 0
    end

    if input.IsButtonDown(MOUSE_LEFT) and alib.math.isMouseInside(window, up) then
        local value = alib.math.GetNewSliderValue(window, up, up.min, up.max)
        up.value = value
    elseif input.IsButtonDown(MOUSE_RIGHT) and alib.math.isMouseInside(window, up) then
        up.value = 0
     end

     if input.IsButtonDown(MOUSE_LEFT) and alib.math.isMouseInside(window, dist) then
        local value = alib.math.GetNewSliderValue(window, dist, dist.min, dist.max)
        dist.value = value
     elseif input.IsButtonDown(MOUSE_RIGHT) and alib.math.isMouseInside(window, dist) then
        dist.value = 0
     end
 end)

---@param view ViewSetup
local function render(view)
    if gui.GetValue("thirdperson") == 1 then
        local vforward, vright, vup = engine:GetViewAngles():Forward(), engine:GetViewAngles():Right(), engine:GetViewAngles():Up()
        view.origin = view.origin + vright * right.value
        view.origin = view.origin + vup * up.value
        view.origin = view.origin + vforward * dist.value
    end
end

callbacks.Register("Draw", function (param)
    if not gui.IsMenuOpen() or not ui_visible then return end
    alib.objects.window(window.width, window.height, window.x, window.y)

    alib.objects.sliderfade(right.width, right.height, right.x + window.y, right.y + window.y, right.min, right.max, right.value, 150, 255, true) -- right
    do
        local percent = (right.value - right.min) / (right.max - right.min)
        draw.SetFont(font)
        local tw = draw.GetTextSize("right")
        draw.Color(0, 0, 0, 200)
        draw.Text(right.x + window.x + math.floor(right.width * percent) - tw, right.y + math.floor(right.height/2), "right")
    end

    alib.objects.sliderfade(up.width, up.height, up.x + window.x, up.y + window.y, up.min, up.max, up.value, 150, 255, true) -- up
    do
        local percent = (up.value - up.min) / (up.max - up.min)
        
        draw.SetFont(font)
        local tw = draw.GetTextSize("up")
        draw.Color(0, 0, 0, 200)
        draw.Text(up.x + window.x + math.floor(up.width * percent) - tw, up.y + math.floor(up.height/2), "up")
    end

    alib.objects.sliderfade(dist.width, dist.height, dist.x + window.x, dist.y + window.y, dist.min, dist.max, dist.value, 150, 255, true) -- dist
    do
        local percent = (dist.value - dist.min) / (dist.max - dist.min)
        draw.SetFont(font)
        local tw = draw.GetTextSize("dist")
        draw.Color(0, 0, 0, 200)
        draw.Text(dist.x + window.x + math.floor(dist.width * percent) - tw, dist.y + math.floor(dist.height/2), "dist")
    end
end)

callbacks.Register("RenderView", render)
callbacks.Register("Unload", alib.unload)