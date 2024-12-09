local alib = require("alib")

local ui_visible = true -- disable ui

local right = {
    x = 5, y = 5,
    width = 100,
    height = 20,
    value = 0,
    min = 0,
    max = 150
}

local up = {
    x = 5, y = 30,
    width = 100,
    height = 20,
    value = 0,
    min = 0,
    max = 150
}

local dist = {
    x = 5, y = 55,
    width = 100,
    height = 20,
    value = 0,
    min = 0,
    max = 150
}

local window = {
    x = 5, y = 5,
    width = 110,
    height = 80,
}

---@param usercmd UserCmd
callbacks.Register("CreateMove", function (usercmd)
    if input.IsButtonDown(MOUSE_LEFT) and alib.math.isMouseInside(window, right) then
       local value = alib.math.GetNewSliderValue(window, right, right.min, right.max)
       right.value = value
    end

    if input.IsButtonDown(MOUSE_LEFT) and alib.math.isMouseInside(window, up) then
        local value = alib.math.GetNewSliderValue(window, up, up.min, up.max)
        up.value = value
     end

     if input.IsButtonDown(MOUSE_LEFT) and alib.math.isMouseInside(window, dist) then
        local value = alib.math.GetNewSliderValue(window, dist, dist.min, dist.max)
        dist.value = value
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
    if not engine.IsGameUIVisible() or not ui_visible then return end
    alib.objects.window(window.width, window.height, window.x, window.y)
    alib.objects.sliderfade(right.width, right.height, right.x + window.y, right.y + window.y, right.min, right.max, right.value, 150, 255, true) -- right
    alib.objects.sliderfade(up.width, up.height, up.x + window.x, up.y + window.y, up.min, up.max, up.value, 150, 255, true) -- up
    alib.objects.sliderfade(dist.width, dist.height, dist.x + window.x, dist.y + window.y, dist.min, dist.max, dist.value, 150, 255, true) -- dist
end)

callbacks.Register("RenderView", render)
callbacks.Register("Unload", alib.unload)