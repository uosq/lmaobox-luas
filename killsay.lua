-- Made by navet

local modes = {
   priority = 1,
   everyone = 2,
}

local mode = modes.priority
local teamchat = false

local messages = {
   "{name} even with {class} you're useless",
   "prepare thyself {name}",
   "ez",
   "1",
}

local patterns = {
   name = {
      pattern = "{name}",
      func = "victim:GetName()"
   },

   class = {
      pattern = "{class}",
      func = "classes[victim:GetPropInt('m_PlayerClass', 'm_iClass')]"
   }
}

local classes <const> = {
   [1] = "scout",
   [2] = "sniper",
   [3] = "soldier",
   [4] = "demo",
   [5] = "medic",
   [6] = "heavy",
   [7] = "pyro",
   [8] = "spy",
   [9] = "engineer",
}

---@param event GameEvent
local function FireGameEvent(event)
   if event:GetName() == "player_death" then
      local localplayerIndex = client:GetLocalPlayerIndex()

      local victimindex = event:GetInt("victim_entindex")
      if victimindex == localplayerIndex then return end

      local victim = entities.GetByIndex(victimindex)
      if not victim then return end
      if mode == modes.priority and playerlist.GetPriority(victim) < 1 then return end

      local attackerID = event:GetInt("attacker")
      local attacker = entities.GetByUserID(attackerID)
      if not attacker or not attacker:IsPlayer() or attacker:GetIndex() ~= localplayerIndex then return end

      local selected_msg <const> = messages[math.random(1, #messages)]
      if not selected_msg then return end

      local ENV <const> = { victim = victim, classes = classes, tostring = tostring }

      local str = selected_msg
      for _, pattern_name in pairs(patterns) do
         ---@type string
         local newtext = load(string.format("return tostring(%s)", pattern_name.func), nil, "t", ENV)()
         str = string.gsub(str, pattern_name.pattern, newtext)
      end

      if not str then return end

      if teamchat then client.ChatTeamSay(str) else client.ChatSay(str) end
   end
end

callbacks.Register("FireGameEvent", "kill say", FireGameEvent)
