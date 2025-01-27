--[[
Made by navet
--]]

--- settings
local charge_key = gui.GetValue("force recharge key") --- change this to E_ButtonCode.KEY_something if you want to change the key
local send_key = gui.GetValue("double tap key")       --- change this to E_ButtonCode.KEY_something if you want to change the key
local maxticks = 24                                   -- default is 24 for valve servers
local passive_recharge = true                         -- if you want to not recharge passively make this false
--- end of settings

--- the charge bar is not mine, i pasted it from another script, idk who tho im sorry :(
local barWidth = 200
local barHeight = 15
local backgroundOffset = 5

local screenX, screenY = draw.GetScreenSize()
local barX = math.floor(screenX / 2 - barWidth / 2)
local barY = math.floor(screenY / 2) + 20

local charged_ticks = 0

local localplayer = nil

local next_recharge_tick = 0
local warping = false
local recharging = false

local boostBf = BitBuffer()
boostBf:WriteInt(15, 4)  -- m_nNewCommands
boostBf:WriteInt(15, 15) -- m_nBackupCommands
boostBf:SetCurBit(6)     -- NETMSG_TYPE_BITS

--- disable tick shifting stuff from lbox
gui.SetValue("double tap", "none")
gui.SetValue("dash move key", 0)

---@param usercmd UserCmd
callbacks.Register("CreateMove", function(usercmd)
   localplayer = entities:GetLocalPlayer()

   if input.IsButtonDown(send_key) and charged_ticks > 0 and not recharging and not warping then
      warping = true
   end

   if input.IsButtonReleased(send_key) and warping then
      warping = false
   end
end)

---@param msg NetMessage
local function Warp(msg)
   if msg:GetType() == 9 and localplayer and localplayer:IsAlive() and gui.GetValue("anti aim") == 0 and gui.GetValue("fake lag") == 0 then
      if warping and charged_ticks > 0 and not recharging then
         msg:ReadFromBitBuffer(boostBf)
         charged_ticks = charged_ticks - 1
         boostBf:SetCurBit(6)
         return true
      end

      if input.IsButtonDown(charge_key) and charged_ticks < maxticks and not warping then
         recharging = true
         charged_ticks = charged_ticks + 1
         recharging = false
         return false
      end

      if passive_recharge and not recharging and charged_ticks < maxticks and globals.TickCount() >= next_recharge_tick and not warping then
         recharging = true
         charged_ticks = charged_ticks + 1
         next_recharge_tick = globals.TickCount() + 66.67
         recharging = false
         return false
      end
   end
   return true
end

local function Draw()
   if engine.Con_IsVisible() or engine.IsGameUIVisible() then
      return
   end

   local used_ticks = charged_ticks
   used_ticks = math.max(0, math.min(used_ticks, maxticks))

   -- Background
   draw.Color(70, 70, 70, 150)
   draw.FilledRect(barX - backgroundOffset, barY - backgroundOffset, barX + barWidth + backgroundOffset,
      barY + barHeight + backgroundOffset)

   local filledWidth = math.floor(barWidth * (used_ticks) / (maxticks))
   if used_ticks == maxticks then
      draw.Color(1, 221, 103, 255) -- Green
   else
      draw.Color(97, 97, 76, 255)  -- Red
   end
   draw.FilledRect(barX, barY, barX + filledWidth, barY + barHeight)
end

callbacks.Register("SendNetMsg", Warp)
callbacks.Register("Draw", Draw)

callbacks.Register("Unload", function()
   boostBf:Delete()
end)
