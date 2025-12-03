--- Unfinished script, dont knwo if it works

---@param msg UserMessage
local function OnUserMessage(msg)
    if msg:GetID() ~= E_UserMessage.VoteStart then
        return
    end

    local plocal = entities.GetLocalPlayer()
    if not plocal then
        return
    end

    local bf = msg:GetBitBuffer()
    bf:SetCurBit(8) --- skip msg type

    local voteTeamIndex = bf:ReadByte()
    if voteTeamIndex ~= plocal:GetTeamNumber() then
        return
    end

    local voteID = bf:ReadByte()
    --[[local issue =]] bf:ReadString(256)
    --[[local detail =]] bf:ReadString(256)
    local isYesNoVote = bf:ReadByte()
    local targetIndex = bf:ReadByte()

    if not isYesNoVote then
        return
    end

    local target = entities.GetByIndex(targetIndex)
    if target == nil then
        return
    end

    local priority = playerlist.GetPriority(target)
    if priority == -1 then
        client.Command(string.format("vote %s option1", voteID), true)
    else
        client.Command(string.format("vote %s option2", voteID), true)
    end

    print(voteID)
end

callbacks.Register("DispatchUserMessage", OnUserMessage)