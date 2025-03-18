---@diagnostic disable: need-check-nil, assign-type-mismatch
--- made by navet

--- first time loading this can make your game
--- freeze for a second or two

local alib_source = http.Get("https://github.com/uosq/lbox-alib/releases/download/0.44.1/source.lua")
---@module "source"
local alib = load(alib_source)()
alib.settings.font = draw.CreateFont("TF2 BUILD", 16, 1000)

--- you can change the transparency by changing the 4th value
--- but honestly its better to just stick with 255
--local color <const> = {40, 40, 40, 255}
local apply_to_sky <const> = false --- applies the color to the sky too
--- i completely forgot about this option
--- lol
--- well too late now :p

--- this is pretty cool
local function apply_color(r, g, b, a, sky)
   a = a or 1
   materials.Enumerate(function (material)
      local group = material:GetTextureGroupName()
      local name = material:GetName()
      if (sky and group == "SkyBox textures") or group == "World textures"
      or string.find(name, "concrete", 1, true) or string.find(name, "wood", 1, true) or string.find(name, "nature", 1, true)
      or string.find(name, "wall", 1, true) then
         material:ColorModulate(r, g, b)
         material:AlphaModulate(a)
         material:SetShaderParam("$color2", Vector3(r, g, b))
      end
   end)
end

--- we reset because we can change or not the sky
--- so we reset it just in case
local function reset_color()
   apply_color(1, 1, 1, 1, false)
   apply_color(1, 1, 1, 1, true)
end

local last_click_tick = 0

local baseslider = {
   width = 200,
   height = 30,
   x = 0,
   y = 0,
   mouse_inside = false,
   min = 0,
   max = 0,
   value = 0,
}

local button = {
   width = 70,
   height = 15,
   x = 0,
   y = 0,
   text = "button",
   mouse_inside = false,
}

local window = {
   x = 150,
   y = 150,
   width = 400,
   height = 110,
   drag_x = 0,
   drag_y = 0,
   title_height = alib.settings.window.title.height
}

local h, s, v, applybutton
applybutton = setmetatable({}, {__index = button})
h = setmetatable({}, {__index = baseslider})
s = setmetatable({}, {__index = baseslider})
v = setmetatable({}, {__index = baseslider})

h.max, s.max, v.max = 100, 100, 100
h.value = 5
s.value = 10
v.value = 35

h.x, s.x, v.x = 5, 5, 5
h.y, s.y, v.y = 5, 40, 75

applybutton.width = 100
applybutton.height = 20
applybutton.x = h.x + h.width + 70
applybutton.y = h.y
applybutton.text = "apply"

--- fuck this im not making window dragging manually
--- made by claude.ai
local function handle_window_drag()
   local mouse_x, mouse_y
   mouse_x, mouse_y = input.GetMousePos()[1], input.GetMousePos()[2]
   local in_title_bar = mouse_x >= window.x and
                        mouse_x <= window.x + window.width and
                        mouse_y <= window.y and
                        mouse_y >= window.y - window.title_height

   -- Check if left mouse button is pressed
   local left_mouse_pressed, tick = input.IsButtonPressed(E_ButtonCode.MOUSE_LEFT)
   local left_mouse_down = input.IsButtonDown(E_ButtonCode.MOUSE_LEFT)

   -- Start dragging
   if left_mouse_pressed and tick > last_click_tick and in_title_bar then
      window.dragging = true
      window.drag_x = mouse_x - window.x
      window.drag_y = mouse_y - window.y
      last_click_tick = tick
   end

   -- Continue dragging
   if left_mouse_down and window.dragging then
      window.x = mouse_x - window.drag_x
      window.y = mouse_y - window.drag_y
   else
      -- Stop dragging if mouse is released
      window.dragging = false
   end
end

function baseslider:refresh()
   local state = input.IsButtonDown(E_ButtonCode.MOUSE_LEFT)
   if state and alib.math.isMouseInside(window, self) then
      local new_value = alib.math.GetNewSliderValue(window, self, self.min, self.max)
      self.value = new_value
   end
end

---source: https://github.com/EmmanuelOga/columns/blob/master/utils/color.lua#L124
local function hsvToRgb(h, s, v, a)
   local r, g, b

   local i = math.floor(h * 6);
   local f = h * 6 - i;
   local p = v * (1 - s);
   local q = v * (1 - f * s);
   local t = v * (1 - (1 - f) * s);

   i = i % 6

   if i == 0 then r, g, b = v, t, p
   elseif i == 1 then r, g, b = q, v, p
   elseif i == 2 then r, g, b = p, v, t
   elseif i == 3 then r, g, b = p, q, v
   elseif i == 4 then r, g, b = t, p, v
   elseif i == 5 then r, g, b = v, p, q
   end

   return r, g, b, a
end

function button:refresh()
   local state, tick = input.IsButtonPressed(E_ButtonCode.MOUSE_LEFT)
   local mouse_inside = alib.math.isMouseInside(window, self)
   self.mouse_inside = mouse_inside

   if mouse_inside and state and tick > last_click_tick then
      local r, g, b, a = hsvToRgb(h.value/100, s.value/100, v.value/100, 1)
      reset_color()
      apply_color(r, g, b, a)
      last_click_tick = tick
   end
end

local function Draw()
   if not gui.IsMenuOpen() then return end

   handle_window_drag()

   h:refresh()
   s:refresh()
   v:refresh()
   applybutton:refresh()

   alib.objects.window(window.width, window.height, window.x, window.y, "world modulation")

   alib.objects.slider(h.width, h.height, h.x + window.x, h.y + window.y, h.min, h.max, h.value)
   alib.objects.slider(s.width, s.height, s.x + window.x, s.y + window.y, s.min, s.max, s.value)
   alib.objects.slider(v.width, v.height, v.x + window.x, v.y + window.y, v.min, v.max, v.value)
   alib.objects.button(applybutton.mouse_inside, applybutton.width, applybutton.height, applybutton.x + window.x, applybutton.y + window.y, applybutton.text)

   local gap = 5

   --- hsv text
   do
      local text = "hue"
      draw.SetFont(alib.settings.font)
      local tw, th = draw.GetTextSize(text)
      local x, y
      x = h.x + window.x + h.width + gap
      y = math.floor(h.y + window.y + (h.height * 0.5) - (th*0.5))
      draw.TextShadow(x, y, text)
   end

   do
      local text = "sat"
      draw.SetFont(alib.settings.font)
      local tw, th = draw.GetTextSize(text)
      local x, y
      x = s.x + window.x + s.width + gap
      y = math.floor(s.y + window.y + (s.height * 0.5) - (th*0.5))
      draw.TextShadow(x, y, text)
   end

   do
      local text = "bright"
      draw.SetFont(alib.settings.font)
      local tw, th = draw.GetTextSize(text)
      local x, y
      x = v.x + window.x + v.width + gap
      y = math.floor(v.y + window.y + (v.height * 0.5) - (th*0.5))
      draw.TextShadow(x, y, text)
   end

   do --- preview box
      local x, y, width, height
      width = 60
      height = 60
      x = math.floor(applybutton.x + window.x + (applybutton.width*0.5) - (width*0.5))
      y = applybutton.y + applybutton.height + window.y + 10
      local r, g, b, a = hsvToRgb(h.value/100, s.value/100, v.value/100, 1)
      r, g, b, a  = math.floor(r * 255), math.floor(g * 255), math.floor(b * 255), math.floor(a * 255)

      draw.Color(255, 255, 255, 255)
      draw.FilledRect(x - 1, y - 1, x + width + 1, y + height + 1)

      draw.Color(math.floor(r), math.floor(g), math.floor(b), math.floor(a))
      draw.FilledRect(x, y, x + width, y + height)
   end
end

callbacks.Register("Draw", "world modulation stuff", Draw)
callbacks.Register("Unload", function ()
   callbacks.Unregister("Draw", "world modulation stuff")

   reset_color()
   alib.unload()

   -- man im glad i dont have a gun with me
   -- every single time i see this warning i have a strong desire to just kill myself
   ---@diagnostic disable-next-line: cast-local-type
   last_click_tick = nil
   baseslider = nil
   button = nil
   window = nil
   h, s, v, applybutton = nil, nil, nil, nil
end)