local function QueueUp()
	local casual = party.GetAllMatchGroups()["Casual"]
	local reasons = party.CanQueueForMatchGroup(casual)
	local in_queue = #party.GetQueuedMatchGroups() > 0
	if not in_queue and reasons then
		party.QueueUp(casual)
		return true
	end
	return false
end

local function Draw_Queue()
	if clientstate:GetNetChannel() then
		return
	end -- we dont need it to run in the background on a match
	local in_queue = #party.GetQueuedMatchGroups() > 0
	if not in_queue and clientstate:GetClientSignonState() < E_SignonState.SIGNONSTATE_CONNECTED then
		print("queued!")
		client.ChatPrintf("queued!")
		QueueUp()
	end
end

--- guesses
local states <const> = {
	NotKicked = 0,
	NotKickable = 12, --- ?
}

local function Check_Vote()
	local localplayer = entities:GetLocalPlayer()
	if not localplayer then
		return
	end

	if not clientstate:GetNetChannel() then
		return
	end

	local state = gamerules.GetPlayerVoteState(localplayer:GetIndex())
	if state ~= states.NotKicked then --- im guessing 12 is the "not kicked" state? idk
		QueueUp()
	end
end

callbacks.Register("Draw", Draw_Queue)
callbacks.Register("CreateMove", Check_Vote)
