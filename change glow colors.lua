--- made by navet

--- you can add a 4th value if you want to change the transparency
local colors <const> = {
   RED = {255, 150, 150}, --- RED players
   BLU = {150, 255, 255}, --- BLU players
   LOCALPLAYER = {0, 255, 221}, --- you
   TARGET = {128, 255, 0}, --- aimbot target
   PRIORITY = {255, 255, 0}, --- players with priority higher than 0
   FRIEND = {0, 255, 221}, --- players with priority lower than 0

   RED_SENTRY = {255, 0, 0},
   BLU_SENTRY = {0, 255, 255},

   RED_DISPENSER = {255, 0, 0},
   BLU_DISPENSER = {0, 255, 255},

   RED_TELEPORTER = {255, 0, 0},
   BLU_TELEPORTER = {0, 255, 255},

   RED_HAT = {255, 0, 0},
   BLU_HAT = {0, 150, 255},

   PRIMARY_WEAPON = {163, 64, 90},
   SECONDARY_WEAPON = {74, 79, 125},
   MELEE_WEAPON = {255, 255, 255},
}

---@param entity Entity
local function getentitycolor(entity)
   do
      local localindex = client:GetLocalPlayerIndex()
      if not localindex then return nil end

      --- localplayer check
      if localindex == entity:GetIndex() then
         return colors.LOCALPLAYER
      end
   end

   do --- aimbot target
      if aimbot.GetAimbotTarget() == entity:GetIndex() then
         return colors.TARGET
      end
   end

   do --- player weapons
      if entity:IsWeapon() then
         if entity:IsMeleeWeapon() then
            return colors.MELEE_WEAPON
         else
            return entity:GetLoadoutSlot() == E_LoadoutSlot.LOADOUT_POSITION_PRIMARY and colors.PRIMARY_WEAPON or colors.SECONDARY_WEAPON
         end
      end
   end

   do --- priority
      local priority = playerlist.GetPriority(entity)
      if priority > 0 then
         return colors.PRIORITY
      elseif priority < 0 then
         return colors.FRIEND
      end
   end

   do --- putting them in a do end because of class and team variables
      local class = entity:GetClass()
      if not class then return nil end

      local team = entity:GetTeamNumber()
      if not team then return nil end

      do --- buildings
         local is_sentry, is_teleporter, is_dispenser
         is_sentry = class == "CObjectSentrygun"
         is_teleporter = class == "CObjectTeleporter"
         is_dispenser = class == "CObjectDispenser"

         if is_sentry then
            return colors[team == 2 and "RED_SENTRY" or "BLU_SENTRY"]
         elseif is_teleporter then
            return colors[team == 2 and "RED_TELEPORTER" or "BLU_TELEPORTER"]
         elseif is_dispenser then
            return colors[team == 2 and "RED_DISPENSER" or "BLU_DISPENSER"]
         end
      end

      do --- hats
         if string.find(class, "Wearable") then
            return colors[team == 2 and "RED_HAT" or "BLU_HAT"]
         end
      end
   end

   return colors[entity:GetTeamNumber() == 2 and "RED" or "BLU"]
end

---@param dm DrawModelContext
local function DrawModel(dm)
   if dm:IsDrawingGlow() then
      local glow_entity = dm:GetEntity()
      if not glow_entity then return end

      local color <const> = getentitycolor(glow_entity)
      if not color then return end

      local r <const>, g <const>, b <const>, a <const> = table.unpack(color)
      dm:SetColorModulation(r / 255, g / 255, b / 255)
      if a then
         dm:SetAlphaModulation(a / 255)
      end
   end
end

callbacks.Register("DrawModel", "glow colors", DrawModel)
