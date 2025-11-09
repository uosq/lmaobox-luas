--- made by navet
--- Warns when a player with > 1 priority joins the server

--- cheaters in the previous lobby update
local cheaters = {}

local function PartySay(text)
    client.Command(string.format("say_party %s", text), true)
end

---@param event GameEvent
local function PlayerSpawnEvent(event)
    local team = event:GetInt("team")
    if team ~= 0 then
        return
    end

    local userid = event:GetInt("userid")
    if playerlist.GetPriority(userid) <= 0 then
        return
    end

    local text = string.format("Cheater %s (UserID: %s) joined the match!", client.GetPlayerNameByUserID(userid), userid)
    client.ChatPrintf(text)
    PartySay(text)
end

---@param event GameEvent
local function PlayerDisconnectEvent(event)
    local steamID = event:GetString("networkid")
    if cheaters[steamID] then
        cheaters[steamID] = nil
        local name = steam.GetPlayerName(steamID)
        local text = string.format("Cheater %s (SteamID3: %s) quit!", name, steamID)
        client.ChatPrintf(text)
        PartySay(text)
    end
end

---@param event GameEvent
local function OnGameEvent(event)
    if event:GetName() == "player_spawn" then
        PlayerSpawnEvent(event)
    elseif event:GetName() == "player_disconnect" then
        PlayerDisconnectEvent(event)
    end
end

---@param lobby GameServerLobby
local function OnLobbyUpdate(lobby)
    for _, player in pairs(lobby:GetMembers()) do
        if playerlist.GetPriority(player:GetSteamID()) > 0 then
            local steamID = player:GetSteamID()
            if cheaters[steamID] == nil and steam.GetPlayerName(steamID) ~= "[unknown]" then
                cheaters[steamID] = true
                local text = string.format("Cheater %s (SteamID3: %s) joined the match!", steam.GetPlayerName(steamID), steamID)
                client.ChatPrintf(text)
                PartySay(text)
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