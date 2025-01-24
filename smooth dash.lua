--[[
Made by navet
--]]

--- the charge bar is not mine, i pasted it from another script, idk who tho im sorry :(
local barWidth = 200
local barHeight = 15
local backgroundOffset = 5

local screenX, screenY = draw.GetScreenSize()
local barX = math.floor(screenX / 2 - barWidth / 2)
local barY = math.floor(screenY / 2) + 20

local maxticks = 24
local charged_ticks = 0

local charge_key = gui.GetValue("force recharge key")
local send_key = gui.GetValue("double tap key")
local passive_recharge = true

local localplayer = nil

local next_recharge_tick = 0
local warping = false
local recharging = false

local boostBf = BitBuffer()
boostBf:WriteInt(7, 4)   -- m_nNewCommands
boostBf:WriteInt(15, 15) -- m_nBackupCommands
boostBf:SetCurBit(6)     -- NETMSG_TYPE_BITS

local chargeBf = BitBuffer()
chargeBf:WriteInt(0, 4) -- m_nNewCommands
chargeBf:WriteInt(0, 7) -- m_nBackupCommands
chargeBf:SetCurBit(6)   -- NETMSG_TYPE_BITS

---@param usercmd UserCmd
callbacks.Register("CreateMove", function(usercmd)
   localplayer = entities:GetLocalPlayer()

   if input.IsButtonDown(send_key) and charged_ticks > 0 and not recharging then
      warping = true
   end

   if input.IsButtonReleased(send_key) then
      warping = false
   end

   if localplayer and localplayer:IsAlive() and charged_ticks < maxticks and recharging then
      usercmd.buttons = 0
      usercmd.sendpacket = false
   end
end)

---@param msg NetMessage
local function DoBoost(msg)
   if recharging then return true end
   msg:ReadFromBitBuffer(boostBf)
   boostBf:SetCurBit(6)
   charged_ticks = charged_ticks - 1
   return true
end

local function ChargeSingleTick(msg, tick_amount)
   charged_ticks = charged_ticks + 1
   next_recharge_tick = globals.TickCount() + tick_amount
   msg:ReadFromBitBuffer(chargeBf)
   boostBf:SetCurBit(6)
   return false
end

---@param msg NetMessage
local function Warp(msg)
   if msg:GetType() == 9 and localplayer and localplayer:IsAlive() and gui.GetValue("anti aim") == 0 and gui.GetValue("fake lag") == 0 then
      if input.IsButtonDown(send_key) and charged_ticks > 0 and not recharging then
         return DoBoost(msg)
      end

      if input.IsButtonDown(charge_key) and charged_ticks < maxticks and not warping then
         return ChargeSingleTick(msg, 0)
      end

      if passive_recharge and not recharging and charged_ticks < maxticks and globals.TickCount() >= next_recharge_tick and not warping then
         recharging = true
         local charged = ChargeSingleTick(msg, 67)
         recharging = false
         return charged
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
   chargeBf:Delete()
end)
