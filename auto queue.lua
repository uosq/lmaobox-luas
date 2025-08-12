--- made by navet

party.CancelQueue(party.GetAllMatchGroups().Casual)

local function Draw()
    local casual = party.GetAllMatchGroups()["Casual"]
    local canqueue = type(party.CanQueueForMatchGroup(casual)) == "boolean"
    if canqueue then
        party.QueueUp(casual)
    end
end

callbacks.Register("Draw", Draw)