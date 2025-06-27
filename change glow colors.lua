--- made by navet

--- you can add a 4th value if you want to change the transparency
RED = {255, 150, 150} --- RED players
BLU = {150, 255, 255} --- BLU players
LOCALPLAYER = {0, 255, 221} --- you
TARGET = {128, 255, 0} --- aimbot target
PRIORITY = {255, 255, 0} --- players with priority higher than 0
FRIEND = {0, 255, 221} --- players with priority lower than 0

RED_SENTRY = {255, 0, 0}
BLU_SENTRY = {0, 255, 255}

RED_DISPENSER = {255, 0, 0}
BLU_DISPENSER = {0, 255, 255}

RED_TELEPORTER = {255, 0, 0}
BLU_TELEPORTER = {0, 255, 255}

RED_HAT = {255, 0, 0}
BLU_HAT = {0, 150, 255}

PRIMARY_WEAPON = {163, 64, 90}
SECONDARY_WEAPON = {74, 79, 125}
MELEE_WEAPON = {255, 255, 255}

---@param entity Entity
local function getentitycolor(entity)
   local localindex = client:GetLocalPlayerIndex()
   if not localindex then return {255, 255, 255, 255} end

   --- localplayer check
   if localindex == entity:GetIndex() then
      return LOCALPLAYER
   end

   --- aimbot target
   if aimbot.GetAimbotTarget() == entity:GetIndex() then
      return TARGET
   end

   --- player weapons
   if entity:IsWeapon() then
      if entity:IsMeleeWeapon() then
         return MELEE_WEAPON
      else
         return entity:GetLoadoutSlot() == E_LoadoutSlot.LOADOUT_POSITION_PRIMARY and PRIMARY_WEAPON or SECONDARY_WEAPON
      end
   end

   --- priority
   local priority = playerlist.GetPriority(entity)
   if priority > 0 then
      return PRIORITY
   elseif priority < 0 then
      return FRIEND
   end

   --- putting them in a do end because of class and team variables
   local class = entity:GetClass()
   local team = entity:GetTeamNumber()
   local isred = team == 2

   --- buildings
   if class == "CObjectSentrygun" then
      return isred and RED_SENTRY or BLU_SENTRY
   elseif class == "CObjectTeleporter" then
      return isred and RED_TELEPORTER or BLU_TELEPORTER
   elseif class == "CObjectDispenser" then
      return isred and RED_DISPENSER or BLU_DISPENSER
   end

   --- hats
   --if string.find(class, "Wearable") then
   if class == "CTFWearableRazorback"
      or class == "CTFWearableDemoShield"
      or class == "CTFWearableLevelableItem"
      or class == "CTFWearableCampaignItem"
      or class == "CTFWearableRobotArm"
      or class == "CTFWearableVM"
      or class == "CTFWearable"
      or class == "CTFWearableItem" then
      return isred and RED_HAT or BLU_HAT
   end

   return isred and RED or BLU
end

---@param dm DrawModelContext
local function DrawModel(dm)
   if dm:IsDrawingGlow() then
      local glow_entity = dm:GetEntity()
      if not glow_entity then return end

      local color = getentitycolor(glow_entity)

      local a = color[4]
      dm:SetColorModulation(color[1] * 0.004, color[2] * 0.004, color[3] * 0.004)
      if a then
         dm:SetAlphaModulation(a * 0.004)
      end
   end
end

callbacks.Register("DrawModel", "glow colors", DrawModel)
