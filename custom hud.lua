local settings = {
	health = true,
	ammo = true,
	crit = true,
	warp = true,
	killfeed = true,
	chat = true,
	crosshair = true,
	size = 6
}

local font = draw.CreateFont("TF2 BUILD", 24, 1000)
local warp_font = draw.CreateFont("TF2 BUILD", 18, 1000)
local chat_font = draw.CreateFont("TF2 BUILD", 12, 1000)

client.RemoveConVarProtection("cl_drawhud")
client.Command("cl_drawhud 0", true)
gui.SetValue("double tap indicator size", 0)
gui.SetValue("crit hack indicator size", 0)

local line = draw.Line
local should_draw_hud = true

local typing = false

local function draw_crosshair (x, y)
	line(x, y-settings.size/2 - 10, x, y+settings.size/2 - 10) -- top
	line(x-settings.size/2 - 10, y, x+settings.size/2 - 10, y) -- left
	line(x+settings.size/2 + 10, y, x-settings.size/2 + 10, y) -- right
	line(x, y+settings.size/2 + 10, x, y-settings.size/2 + 10) -- top
end

local TEAM_BLU, TEAM_RED = 3, 2

local color = {
	[TEAM_BLU] = {102, 255, 255, 255},
	[TEAM_RED] = {255, 100, 100, 255},
	[E_TeamNumber.TEAM_SPECTATOR] = {255,255,255,255},
	[E_TeamNumber.TEAM_UNASSIGNED] = {255,255,255,255}
}

local last_tick = 0
callbacks.Register("CreateMove", function ()
	local state, tick = input.IsButtonPressed(E_ButtonCode.KEY_I)
	if state and tick ~= last_tick and not typing then
		last_tick = tick
		should_draw_hud = not should_draw_hud
		if not should_draw_hud then
			client.Command("cl_drawhud 1", true)
		else
			client.Command("cl_drawhud 0", true)
		end
	end
end)

local function hud()
	if not should_draw_hud then return end
	if (gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot()) or engine.IsGameUIVisible() or engine.Con_IsVisible() then
		return
	end

	local screenw, screenh = draw.GetScreenSize()
	local centerx, centery = screenw/2, screenh/2

	local localplayer = entities:GetLocalPlayer()
	if not localplayer then return end

	local weapon = localplayer:GetPropEntity("m_hActiveWeapon")
	if not weapon then return end

	local lastHeight = centery

	-- match details
	local state = gamerules.GetRoundState()
	if state == E_RoundState.ROUND_RUNNING then
		local width, height = 50, 5
		local str = tostring(gamerules.GetTimeLeftInMatch())
		draw.SetFont(font)
		local textwidth, textheight = draw.GetTextSize(str)

		local team_color = color[localplayer:GetTeamNumber()]

		draw.Color(team_color[1],team_color[2], team_color[3], team_color[4])
		draw.FilledRect(centerx - width, 0, centerx + width, height)

		draw.Color(255, 255, 255, 255)
		draw.SetFont(font)
		draw.TextShadow(centerx - math.floor(textwidth/2), height, str)
	end

	-- health
	if settings.health then
		local health = localplayer:GetHealth()
		local maxhealth = localplayer:GetMaxHealth()
		local health_str = string.format("HEALTH: %s", localplayer:GetHealth())
		local healthSizeX, healthSizeY = draw.GetTextSize(health_str)
		local healthColor = {}
		healthColor.r = math.floor(255 * (1 - (health / maxhealth)))
		healthColor.g = math.floor(255 * (health / maxhealth))
		healthColor.b = 0
		
		lastHeight = lastHeight + healthSizeY + 20
		draw.Color(healthColor.r, healthColor.g, healthColor.b, 255)
		draw.SetFont(font)
		draw.TextShadow(centerx - math.floor(healthSizeX/2), lastHeight, health_str)
	
		-- crosshair (USES HEALTH COLOR)
		if settings.crosshair then
			draw.Color(healthColor.r, healthColor.g, healthColor.b, 255)
			draw_crosshair(screenw/2, screenh/2)
		end
	end

	-- ammo
	if settings.ammo then
		local isPrimaryWeapon = weapon:GetLoadoutSlot() == E_LoadoutSlot.LOADOUT_POSITION_PRIMARY
		local isMelee = weapon:IsMeleeWeapon()
		if not isMelee then
			local ammoDataTable = localplayer:GetPropDataTableInt("m_iAmmo")
			local primary_clip2, secondary_clip2 = ammoDataTable[2], ammoDataTable[3]
			local clip1 = weapon:GetPropInt("m_iClip1")
			local ammo_str = ""
			if clip1 ~= -1 and clip1 ~= nil then
				ammo_str = isPrimaryWeapon and string.format("%s/%s", clip1, primary_clip2) or string.format("%s/%s", clip1, secondary_clip2)
			else
				ammo_str = string.format("%s", primary_clip2)
			end
	
			local ammoW, ammoH = draw.GetTextSize(ammo_str)
			draw.SetFont(font)
			draw.Color(255,255,255,255)
	
			lastHeight = lastHeight + ammoH
			draw.TextShadow(centerx - math.floor(ammoW/2), lastHeight, ammo_str)
			else
				local melee_str = "MELEE"
				local meleeW, meleeH = draw.GetTextSize(melee_str)
				draw.SetFont(font)
				draw.Color(255, 100, 100, 255)
	
				lastHeight = lastHeight + meleeH
				draw.TextShadow(centerx - math.floor(meleeW/2), lastHeight, melee_str)
		end
	end

	-- warp / dt bar
	if settings.warp then
		local width, height = 100, 20
		lastHeight = lastHeight + height + 5

		-- background
		draw.Color(50, 50, 50, 255)
		draw.FilledRect(centerx - width, lastHeight, centerx + width, lastHeight + height)

		-- bar
		local percentage = warp.GetChargedTicks()/23
		if percentage == 1 then
			draw.Color(150,255,150,255)
		else
			draw.Color(255,150,150,255)
		end
		draw.FilledRectFade(centerx - width + 2, lastHeight + 2, math.floor(centerx - width + (width * percentage * 2) - 2), lastHeight + height - 2, 150, 10, false)

		-- warp text
		local maxticks = client.GetConVar("sv_maxusrcmdprocessticks") - 1
		draw.SetFont(warp_font)
		draw.Color(255, 255, 255, 150)
		local str = string.format("TICKS: %s/%s", warp.GetChargedTicks(), maxticks)
		local textwidth, textheight = draw.GetTextSize(str)
		draw.Text(centerx - math.floor(textwidth/2), lastHeight + 2, str)
	end

	-- crit bar
	if settings.crit then
		local width, height = 100, 20
		lastHeight = lastHeight + height + 5
		
		--- background
		draw.Color(50, 50, 50, 255)
		draw.FilledRect(centerx - width, lastHeight, centerx + width, lastHeight + height)

		--- actual bar
		local critbucket = weapon:GetCritTokenBucket()
		if not critbucket then return end

		local percentage = critbucket/1000 -- 1000 is max
		draw.Color(150, 150, 255, 255)
		draw.FilledRectFade(centerx - width + 2, lastHeight + 2, math.floor(centerx - width + (width * percentage * 2) - 2), lastHeight + height - 2, 150, 10, false)
		local str = string.format("CRIT BUCKET: %.1f", weapon:GetCritTokenBucket())
		local textwidth, textheight = draw.GetTextSize(str)
		draw.SetFont(warp_font)
		draw.Color(255, 255, 255, 150)
		draw.Text(centerx - math.floor(textwidth/2), lastHeight + 2, str)
	end
end

---@type table<number, {victim: Entity, attacker: Entity, assister: Entity?, tick_to_disappear: number}>
local killfeed_deaths = {
	--[[
	{
	victim: Entity,
	attacker: Entity,
	assister: Entity?,
	tick_to_disappear = globals.TickCount() + (client.GetConVar("hud_deathnotice_time") * 66)
	}
	]]
}

local function draw_killfeed()
	if not settings.killfeed then return end
	if not should_draw_hud then return end

	if (gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot()) or engine.IsGameUIVisible() or engine.Con_IsVisible() then
		return
	end

	local screenw, screenh = draw.GetScreenSize()
	local lastHeight = 5
	for pos, death in ipairs(killfeed_deaths) do
		local death_string = ""
		local died_alone = death.attacker == death.victim
		
		if death.assister then
			death_string = string.format("%s + %s x %s", death.attacker:GetName(), death.assister:GetName(), death.victim:GetName())
		else
			death_string = string.format("%s x %s", death.attacker:GetName(), death.victim:GetName())
		end
		
		if died_alone then
			death_string = string.format("%s died a horrible death :(", death.victim:GetName())
		end

		
		draw.SetFont(font)
		local textwidth, textheight = draw.GetTextSize(death_string)

		local x1 = screenw - textwidth - 30

		--- background
		--draw.Color(255, 255, 255, 255)
		--draw.FilledRectFade(x1 - 15, lastHeight + textheight, x1 + textwidth + 15, lastHeight + textheight + textheight, 150, 50, false)

		--- text
		local color = color[death.attacker:GetTeamNumber()]
		draw.Color(color[1], color[2], color[3], color[4])
		draw.TextShadow(x1, lastHeight + textheight, death_string)
		lastHeight = lastHeight + textheight + 10

		if death.tick_to_disappear <= globals.TickCount() then
			table.remove(killfeed_deaths, pos)
		end
	end
end

-- damage logger / killfeed
---@param event GameEvent
local function killfeed(event)
	if event:GetName() == "player_death" then
		local victim = entities.GetByUserID(event:GetInt("userid"))
		if not victim then return end

		local attacker = entities.GetByUserID(event:GetInt("attacker"))
		if not attacker then return end

		local assisterID, assister = event:GetInt("assister")
		if assisterID then
			assister = entities.GetByUserID(assisterID)
		end

		local current_tick = globals.TickCount()
		local hud_deathnotice_time = client.GetConVar("hud_deathnotice_time")

		killfeed_deaths[#killfeed_deaths+1] = {victim = victim, attacker = attacker, assister = assister, tick_to_disappear = current_tick + (hud_deathnotice_time * 66)}
	end
end

---@type table<number, {player: Entity, message: string, tick_to_disappear: number, type: "TF_Chat_All"|"TF_Chat_Team"}>
local chat_messages = {}

local function draw_chat()
	if not settings.chat then return end
	if not should_draw_hud then return end

	if (gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot()) or engine.IsGameUIVisible() or engine.Con_IsVisible() then
		return
	end

	local lastHeight = 150

	for pos, chat_message in ipairs(chat_messages) do
		draw.SetFont(chat_font)
		local str = ""
		if chat_message.type == "TF_Chat_All" then -- seriously wtf why dont we just have a ChatType.All or something???
			str = string.format("[%s]: %s", chat_message.player:GetName(), chat_message.message)
		else
			str = string.format("(Team) [%s]: %s", chat_message.player:GetName(), chat_message.message)
		end
		local textwidth, textheight = draw.GetTextSize(str)

		local x = 30
		local y = lastHeight + textheight

		--- fuck this in particular im not gonna draw each word separately that i want to color
		local msg_color = color[chat_message.player:GetTeamNumber()]
		draw.Color(msg_color[1], msg_color[2], msg_color[3], msg_color[4])
		draw.TextShadow(x, y, str)
		lastHeight = lastHeight + textheight + 5

		if chat_message.tick_to_disappear <= globals.TickCount() then
			table.remove(chat_messages, pos)
		end
	end
end

---@param msg UserMessage
local function chat_msgs(msg)
	if msg:GetID() == E_UserMessage.SayText2 then
		local bf = msg:GetBitBuffer()
		bf:SetCurBit(8)

		local chatType = bf:ReadString(256)
		chatType = string.sub(chatType, 2) -- skipping that fucking character
		local playerName = bf:ReadString(256)
		local message = bf:ReadString(256)

		local current_tick = globals.TickCount()
		local hud_saytext_time = client.GetConVar("hud_saytext_time")

		local players = entities.FindByClass("CTFPlayer")
		for _, player in pairs(players) do
			if player:GetName() == playerName then
				chat_messages[#chat_messages+1] = {player = player, message = message, tick_to_disappear = current_tick + (hud_saytext_time * 66), type = chatType}
			end
		end
	end
end
callbacks.Register("DispatchUserMessage", chat_msgs)
callbacks.Register("Draw", draw_chat)

callbacks.Register("CreateMove", function ()
	if not typing and (input.IsButtonDown(KEY_Y) or input.IsButtonDown(KEY_U) or input.IsButtonDown(KEY_P)) and should_draw_hud then
		typing = true
		should_draw_hud = false
		client.Command("cl_drawhud 1", true)
		return
	end

	if typing and input.IsButtonDown(E_ButtonCode.KEY_ENTER) and not should_draw_hud then
		typing = false
		should_draw_hud = true
		client.Command("cl_drawhud 0", true)
	end
end)

callbacks.Register("Draw", hud)

callbacks.Register("FireGameEvent", killfeed)
callbacks.Register("Draw", draw_killfeed)

callbacks.Register("Unload", function ()
	client.Command("cl_drawhud 1", true)
	gui.SetValue("double tap indicator size", 3)
	gui.SetValue("crit hack indicator size", 3)
end)
