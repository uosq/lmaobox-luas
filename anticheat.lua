--- made by navet

--- SETTINGS

local CHECK_TEAMMATES <const> = true
local CHECK_ENEMIES <const> = true

local tolerances =
{
   viewangles = 10, --- 24 degrees between last tick and now
}

--- END OF SETTINGS

---@class cheater_t
---@field is_cheating boolean
---@field last_tick_eyeangles Vector3?

local cheaters = {}

local function CreateMove()
   local players = entities.FindByClass("CTFPlayer")

   for _, player in pairs(players) do
      if player:GetIndex() == client:GetLocalPlayerIndex() then goto continue end
      if not player or player:IsDormant() or not player:IsAlive() then goto continue end
      if cheaters[player:GetIndex()] and cheaters[player:GetIndex()].is_cheating == true then goto continue end

      local index = player:GetIndex()

      if not cheaters[index] then
         cheaters[index] = {is_cheating = false, last_tick_eyeangles = nil}
      end

      ---@type cheater_t
      local player_t = cheaters[index]

      local m_angEyeAngles = player:GetPropVector("tfnonlocaldata", "m_angEyeAngles[0]")
      if not m_angEyeAngles then goto continue end

      local diff = (m_angEyeAngles - (player_t.last_tick_eyeangles or m_angEyeAngles)):Length2D()
      local suspicious_eyeangles = m_angEyeAngles.x > 89 or m_angEyeAngles.x < -89 or diff > tolerances.viewangles
      print(diff)

      if suspicious_eyeangles then
         player_t.is_cheating = true
         --print(tostring(player:GetName()) .. " got marked as cheater!")
         client.ChatPrintf(tostring(player:GetName()) .. " got marked as cheater!")
      end

      player_t.last_tick_eyeangles = m_angEyeAngles
      ::continue::
   end
end

callbacks.Register("CreateMove", "cheat detector", CreateMove)