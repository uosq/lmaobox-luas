local event <const> = "player_calledformedic"
local priority <const> = 10
local seconds <const> = 5 --- if in 5 seconds the player calls 3 times, we add priority 10 to the fucker so we know we have to kill them later on another match
local forgive_seconds <const> = 10 --- after how much time should we forgive the player? put 0 if never (recommended to be 0, fuck them later)

local players = {
	--[[
  -- [userid] = {tick_call1, tick_call2, tick_call3}
  --]]
}

---@param game_event GameEvent
local function FireGameEvent(game_event)
	local localplayer = entities:GetLocalPlayer()

	if not localplayer then
		return
	end
	if localplayer:GetPropInt("m_PlayerClass", "m_iClass") ~= 5 then
		return
	end

	if game_event:GetName() == event then
		local userid = game_event:GetInt("userid")
		local player = entities.GetByUserID(userid)
		if player and player:GetTeamNumber() == localplayer:GetTeamNumber() then
			--playerlist.SetPriority(userid, priority)
			if not players[userid] then
				players[userid] = { tick_call1 = globals.TickCount() }
				return
			end

			if not players[userid]["tick_call2"] then
				players[userid]["tick_call2"] = globals.TickCount()
				return
			end

			if not players[userid]["tick_call3"] then
				players[userid]["tick_call3"] = globals.TickCount()
			end

			local target = players[userid]
			if target then
				local time = target.tick_call3 - target.tick_call1
				if time <= (seconds * 67) then
					playerlist.SetPriority(userid, priority)
				end
			end
		end
	end
end

local function CreateMove(usercmd)
	if forgive_seconds == 0 then
		callbacks.Unregister("CreateMove", "CM medic priority")
		return
	end

	for userid, value in pairs(players) do
		if value.tick_call3 and (globals.TickCount() - value.tick_call3) >= (forgive_seconds * 67) then
			playerlist.SetPriority(userid, 0)
			players[userid] = nil
			return
		end
		if
			not value.tick_call3
			and value.tick_call1
			and (globals.TickCount() - value.tick_call1) >= (forgive_seconds * 67)
		then
			players[userid] = nil
			print("1")
			return
		end

		if
			not value.tick_call3
			and value.tick_call2
			and (globals.TickCount() - value.tick_call2) >= (forgive_seconds * 67)
		then
			players[userid] = nil
			print("2")
			return
		end
	end
end

callbacks.Register("CreateMove", "CM medic priority", CreateMove)
callbacks.Register("FireGameEvent", "FGM medic priority", FireGameEvent)
