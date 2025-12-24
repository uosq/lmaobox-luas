--- made by navet
--- Warns when a player with > 1 priority joins the server

--- config
local notification = true
--- 

--- cheaters in the previous lobby update
local cheaters = {}

local function PartySay(text)
	client.Command(string.format("say_party %s", text), true)
end

local function Notify(text)
	client.ChatPrintf(text)

	if notification then
		engine.Notification(text)
    	else
		PartySay(text)
    	end
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

    local priority = playerlist.GetPriority(userid)
    local text = string.format("Player %s joined the match! Priority: %i", client.GetPlayerNameByUserID(userid), priority)
    Notify(text)
end

---@param event GameEvent
local function PlayerDisconnectEvent(event)
    local steamID = event:GetString("networkid")
    if cheaters[steamID] then
        cheaters[steamID] = nil
        local name = steam.GetPlayerName(steamID)
        local priority = playerlist.GetPriority(steamID)
        local text = string.format("Player %s quit! Priority: %i", name, priority)
        Notify(text)
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
                local text = string.format("Lobby Update - Player %s in the match (priority: %i)!", steam.GetPlayerName(steamID), playerlist.GetPriority(steamID))
                client.ChatPrintf(text)
                Notify(text)
            end
        end
    end
end

local font = draw.CreateFont("Arial", 32, 0)

local function OnDraw()
    if clientstate.GetClientSignonState() < 5 and notification then
        if #cheaters > 0 then
            cheaters = {}
        end

        if engine.IsTakingScreenshot() or engine.Con_IsVisible() or not engine.IsGameUIVisible() then
            return
        end

        draw.SetFont(font)
        draw.Color(255, 100, 100, 255)
        local w, h = draw.GetScreenSize()
        local text = "PLAYER WARNING IS LOADED!"
        local tw, th = draw.GetTextSize(text)
        draw.TextShadow(w//2 - tw//2, math.floor(h*0.2) - th//2, text)

        text = "WARNINGS GO TO THE PARTY CHAT!"
        tw = draw.GetTextSize(text)
        draw.TextShadow(w//2 - tw//2, math.floor(h*0.25) - th//2, text)
    end
end

callbacks.Register("FireGameEvent", OnGameEvent)
callbacks.Register("OnLobbyUpdated", OnLobbyUpdate)
callbacks.Register("Draw", OnDraw)