local alib = require("alib")
alib.settings.font = draw.CreateFont("Arial", 16, 1000, E_FontFlag.FONTFLAG_ANTIALIAS | E_FontFlag.FONTFLAG_CUSTOM | E_FontFlag.FONTFLAG_GAUSSIANBLUR)
alib.settings.window.outline.color = {96, 0, 148, 255}
alib.settings.window.background[4] = 200
alib.settings.window.title.background = {96, 0, 148, 255}
alib.settings.window.shadow.offset = 0
alib.settings.window.title.fade.enabled = true

local spectators = {}
local spectated = false
local gap = 2
--local spectated_in_firstperson = false

local width, height = draw.GetScreenSize()

local window = {
   width = 150, height = 0,
   x = width/2 - 150/2, y = 50
}

draw.SetFont(alib.settings.font)
local spec_tx = draw.GetTextSize("spectators")

callbacks.Register("FrameStageNotify", function (stage)
   if stage == E_ClientFrameStage.FRAME_NET_UPDATE_POSTDATAUPDATE_END then
      local players = entities.FindByClass("CTFPlayer")
      local localplayer = entities.GetLocalPlayer()
      if not localplayer then return end

      local specs = {}
      local window_height = 0
      local window_width = 0
      local speced = false

      for _, player in pairs(players) do
         if not player:IsDormant() and not player:IsAlive() and player ~= localplayer and player:GetTeamNumber() == localplayer:GetTeamNumber() then
            local m_hObserverTarget = player:GetPropEntity("m_hObserverTarget")
            if m_hObserverTarget == localplayer then
               local isFirstPerson = player:GetPropInt("m_iObserverMode") == 4 --- thank you random unkcheats user
               specs[player:GetName()] = isFirstPerson
               local name = player:GetName()
               draw.SetFont(alib.settings.font)
               local tx, th = draw.GetTextSize(name)
               window_height = window_height + math.floor(th) + gap
               window_width = window_width < math.floor(tx)+ gap and math.floor(tx) + gap or window_width
               window_width = spec_tx + window_width
               speced = true
               --spectated_in_firstperson = isFirstPerson and not spectated_in_firstperson
            end
         end
      end
      spectators = specs
      spectated = speced
      window.height = math.floor(window_height)
      window.width = math.floor(window_width)
   end
end)

callbacks.Register("Draw", function (param)
   if not spectated then return end
   local current_text_y = window.y
   window.x = math.floor(width/2) - math.floor(window.width/2)
   alib.objects.window(window.width, window.height, window.x, window.y, "spectators")
   for name, isfirstperson in pairs(spectators) do
      draw.SetFont(alib.settings.font)
      local tw, th = draw.GetTextSize(name)
      draw.Color(255, 255, 255, 255)
      draw.SetFont(alib.settings.font)
      draw.Text(window.x + gap, current_text_y + gap, name) --- name

      local str = isfirstperson and "1st" or "3rd"
      draw.SetFont(alib.settings.font)
      local tw2 = draw.GetTextSize(str)
      draw.SetFont(alib.settings.font)
      if isfirstperson then
         draw.Color(255, 100, 100, 255)
      else
         draw.Color(255, 255, 255, 255)
      end
      draw.Text(window.x + gap + window.width - math.floor(tw2), current_text_y + gap, str)
      current_text_y = current_text_y + gap + math.floor(th)
   end
end)

callbacks.Register("Unload", function (param)
   alib.unload()
end)