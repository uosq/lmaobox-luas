--- made by navet

--- config here
--- the SteamID3 of the target
local targetSteamID3 = "[U:1:123456678]"
local targetName = "fsdfsdfdsf"
local searchForTargetName = false

party.CancelQueue(party.GetAllMatchGroups().Casual)

if clientstate.GetClientSignonState() <= E_SignonState.SIGNONSTATE_SPAWN then
    local casual = party.GetAllMatchGroups()["Casual"]
    local canqueue = type(party.CanQueueForMatchGroup(casual)) == "boolean"
    if canqueue then
        party.QueueUp(casual)
    end
end

local playerInMatch = false

---@param lobby GameServerLobby
local function OnLobbyUpdated(lobby)
    playerInMatch = false

    if searchForTargetName then
        for _, player in pairs(lobby:GetMembers()) do
            if player:GetName() == targetName then
                playerInMatch = true
                break
            end
        end
    else
        for _, player in pairs(lobby:GetMembers()) do
            if player:GetSteamID() == targetSteamID3 then
                playerInMatch = true
                break
            end
        end
    end

    if playerInMatch == false then
        gamecoordinator.AbandonMatch()
        local casual = party.GetAllMatchGroups()["Casual"]
        local canqueue = type(party.CanQueueForMatchGroup(casual)) == "boolean"
        if canqueue then
            party.QueueUp(casual)
        end
    else
        gamecoordinator.AcceptMatchInvites()
        gamecoordinator.JoinMatchmakingMatch()
        party.CancelQueue(party.GetAllMatchGroups().Casual)
    end
end

callbacks.Register("OnLobbyUpdated", OnLobbyUpdated)