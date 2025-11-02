local alib = load(http.Get("https://github.com/uosq/lbox-alib/releases/download/0.44.1/source.lua"))()
alib.settings.font = draw.CreateFont("TF2 BUILD", 12, 1000)

local selected_ratio = 0
local ratio_index = 0

--- https://www.google.com/search?client=firefox-b-d&q=common+aspect+ratios
local ratios = { (1 / 1), (3 / 2), (4 / 3), (16 / 9), (5 / 4), (3 / 1), 1.85, 2.40, 9/16, 0 }
local ratio_names = { "1:1", "3:2", "4:3", "16:9", "5:4", "3:1",
   "1.85:1", "2.4:1", "9:16", "default" }

local window = {}
window.x = 100
window.y = 200
window.width = 200
window.height = alib.math.GetListHeight(#ratios)

local list = {}
list.x = 0
list.y = 0
list.width = window.width
list.height = alib.math.GetListHeight(#ratios)

callbacks.Register("CreateMove", function(param)
   if gui.IsMenuOpen() and not engine.Con_IsVisible() and engine.IsGameUIVisible() and not ((gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot())) then
      for i, v in ipairs(ratios) do
         local is_mouse_inside = alib.math.isMouseInside(window, list, "ITEM", i)
         if is_mouse_inside and input.IsButtonDown(E_ButtonCode.MOUSE_LEFT) then
            ratio_index = i
            selected_ratio = v
         end
      end
   end
end)

callbacks.Register("Draw", function(param)
   if gui.IsMenuOpen() and not engine.Con_IsVisible() and engine.IsGameUIVisible() and not ((gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot())) then
      alib.objects.window(window.width, window.height, window.x, window.y, "aspect ratios")
      alib.objects.list(list.width, list.x + window.x, list.y + window.y, ratio_index, ratio_names)
   end
end)

---@param view ViewSetup
callbacks.Register("RenderView", function(view)
   if gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot() then
      view.aspectRatio = 0
      return
   end
   view.aspectRatio = selected_ratio
end)

callbacks.Register("Unload", alib.unload)
