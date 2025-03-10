---[[ Made by navet ]]
---@class PlayerTable
---@field visible boolean
---@field position {[1]: integer, [2]: integer}?
---@field target boolean
---@field priority boolean
---@field friend boolean

local VISIBLE_COLOR <const> = { 255, 255, 255, 255 }
local INVISIBLE_COLOR <const> = { 150, 150, 150, 255 }
local TARGET_COLOR <const> = { 100, 255, 100, 255 }
local PRIORITY_COLOR <const> = { 246, 255, 0, 255 }
local FRIEND_COLOR <const> = { 195, 0, 255, 255 }

local width <const>, height <const> = draw.GetScreenSize()
local centerx <const> = math.floor(width * 0.5)

---@type PlayerTable[]
local players = {}

---@param usercmd UserCmd
local function CreateMove(usercmd)
   ---@type PlayerTable[]
   local playertable = {}

   local localplayer = entities:GetLocalPlayer()
   if not localplayer then return end

   local team <const> = localplayer:GetTeamNumber()
   local localpos <const> = localplayer:GetAbsOrigin()

   local t = entities.FindByClass("CTFPlayer")
   for _, entity in pairs(t) do
      if entity and entity:IsValid() and entity:IsAlive() and not entity:IsDormant() and entity:GetTeamNumber() ~= team and entity ~= localplayer then
         local origin, mins, maxs = entity:GetAbsOrigin(), entity:GetMins(), entity:GetMaxs()
         if origin and mins and maxs then
            local center = origin + ((mins + maxs) * 0.5)
            local trace = engine.TraceLine(localpos, center, MASK_SHOT_HULL)
            if trace then
               local index = entity:GetIndex()
               local bVisible = trace and trace.fraction >= 0.4 and trace.entity:GetIndex() == index
               local screen = client.WorldToScreen(center)
               local bTarget = aimbot.GetAimbotTarget() == index
               local priority = playerlist.GetPriority(entity)
               local bPrioritized = priority > 0
               local bFriend = priority == -1
               if screen then
                  playertable[#playertable + 1] = {
                     visible = bVisible,
                     position = screen,
                     target = bTarget,
                     priority = bPrioritized,
                     friend = bFriend
                  }
               end
            end
         end
      end
   end

   players = playertable
end

---@param lineprops PlayerTable
local function get_color(lineprops)
   if lineprops.target then
      return TARGET_COLOR
   elseif lineprops.friend then
      return FRIEND_COLOR
   elseif lineprops.priority then
      return PRIORITY_COLOR
   end
   return lineprops.visible and VISIBLE_COLOR or INVISIBLE_COLOR
end

local function Draw()
   local player = entities:GetLocalPlayer()
   if not player then return end

   for i = 1, #players do
      local lineprops = players[i]
      if lineprops then
         local color = get_color(lineprops)
         draw.Color(table.unpack(color))
         if gui.GetValue("thirdperson") == 1 then
            local pos = client.WorldToScreen(player:GetAbsOrigin())
            if pos then
               draw.Line(pos[1], pos[2], lineprops.position[1], lineprops.position[2])
            end
         else
            draw.Line(centerx, height, lineprops.position[1], lineprops.position[2])
         end
      end
   end
end

callbacks.Register("CreateMove", "line tracer createmove", CreateMove)
callbacks.Register("Draw", "line tracer draw", Draw)
