local function QueueUp()
	local casual = party.GetAllMatchGroups()["Casual"]
	local reasons = party.CanQueueForMatchGroup(casual)
	if reasons then
		party.QueueUp(casual)
		return true
	end
	return false
end

if #party.GetQueuedMatchGroups() <= 0 and party.CanQueueForMatchGroup(party.GetAllMatchGroups()["Casual"]) then
	party.QueueUp(party.GetAllMatchGroups()["Casual"])
end

local function CreateMove_Queue()
	local in_queue = #party.GetQueuedMatchGroups() > 0
	if not in_queue and not clientstate:GetNetChannel() then
		print("queued!")
		client.ChatPrintf("queued!")
		QueueUp()
	end
end

callbacks.Register("Draw", CreateMove_Queue)
