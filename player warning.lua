--- made by navet
--- Warns when a player with > 1 priority joins the server

--- cheaters in the previous lobby update
local cheaters = {}

---@param event GameEvent
local function OnGameEvent(event)
    if event:GetName() ~= "player_spawn" then
        return
    end

    local team = event:GetInt("team")
    if team ~= 0 then
        return
    end

    local userid = event:GetInt("userid")
    if playerlist.GetPriority(userid) <= 0 then
        return
    end

    client.ChatPrintf(string.format("[LMAOBOX] Player %s joined the game!", client.GetPlayerNameByUserID(userid)))
end

---@param lobby GameServerLobby
local function OnLobbyUpdate(lobby)
    for _, player in pairs(lobby:GetMembers()) do
        if playerlist.GetPriority(player:GetSteamID()) > 0 then
            local steamID = player:GetSteamID()
            if cheaters[steamID] == nil then
                client.ChatPrintf(string.format("[LMAOBOX] Player %s joined the game!", steam.GetPlayerName(steamID)))
                cheaters[steamID] = true
            end
        end
    end
end

local function OnDraw()
    if clientstate.GetClientSignonState() < 5 then
        if #cheaters == 0 then
            return
        end

        cheaters = {}
    end
end

callbacks.Register("FireGameEvent", OnGameEvent)
callbacks.Register("OnLobbyUpdated", OnLobbyUpdate)
callbacks.Register("Draw", OnDraw)