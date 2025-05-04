local alib_source = http.Get("https://github.com/uosq/lbox-alib/releases/download/0.44.1/source.lua")
local alib = load(alib_source)()
alib.settings.window.title.fade.enabled = true
alib.settings.window.outline.thickness = 0
alib.settings.checkbox.shadow.offset = 0

local screenw, screenh = draw.GetScreenSize()
local centerx, centery = math.floor(screenw / 2), math.floor(screenh / 2)

local settings = {
	health = true,
	ammo = true,
	crit = true,
	warp = true,
	killfeed = true,
	chat = true,
	metal = true,
}

local window = {
	x = centerx - 350 / 2,
	y = centery - 370 / 2,
	width = 350,
	height = 370,
}

--- i dont know why, i dont want to know why, but my piece of garbage code doesnt detect mouse clicks correctly
--- if i dont manually make the checkbox
local health_checkbox = {
	x = 10,
	y = 10,
	width = 50,
	height = 50,
	checked = settings.health
}

local ammo_checkbox = {
	x = 10,
	y = 70,
	width = 50,
	height = 50,
	checked = settings.ammo
}

local crit_checkbox = {
	x = 10,
	y = 130,
	width = 50,
	height = 50,
	checked = settings.crit
}

local warp_checkbox = {
	x = 10,
	y = 190,
	width = 50,
	height = 50,
	checked = settings.warp
}

local killfeed_checkbox = {
	x = 10,
	y = 250,
	width = 50,
	height = 50,
	checked = settings.killfeed
}

local chat_checkbox = {
	x = 10,
	y = 310,
	width = 50,
	height = 50,
	checked = settings.chat
}

local classes = { "scout", "soldier", "pyro", "demoman", "heavyweapons", "engineer", "medic", "sniper", "spy", "random" }
local list = {
	x = 110,
	y = 10,
	width = 180,
	items = classes,
	selected_item_index = 1,
}

--- info panel

local info_window = {
	x = 5,
	y = centery - 50 / 2,
	width = 120,
	height = 50
}

--- info panel end

local font = draw.CreateFont("TF2 BUILD", 24, 1000)
local warp_font = draw.CreateFont("TF2 BUILD", 18, 1000)
local chat_font = draw.CreateFont("TF2 BUILD", 12, 1000)
alib.settings.font = warp_font

client.RemoveConVarProtection("cl_drawhud")
client.Command("cl_drawhud 0", true)
gui.SetValue("double tap indicator size", 0)
gui.SetValue("crit hack indicator size", 0)

local should_draw_hud = true

local TEAM_BLU, TEAM_RED = 3, 2

local color = {
	[TEAM_BLU] = { 102, 255, 255, 255 },
	[TEAM_RED] = { 255, 100, 100, 255 },
	[E_TeamNumber.TEAM_SPECTATOR] = { 255, 255, 255, 255 },
	[E_TeamNumber.TEAM_UNASSIGNED] = { 255, 255, 255, 255 }
}

callbacks.Register("CreateMove", function()
	should_draw_hud = not (engine.IsChatOpen() and engine.Con_IsVisible() and not engine.IsGameUIVisible() and client.GetConVar("_cl_classmenuopen") == 1)
	if not should_draw_hud then
		client.Command("cl_drawhud 1", true)
	else
		client.Command("cl_drawhud 0", true)
	end
end)

local function hud()
	if not should_draw_hud then return end
	if (gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot()) or engine.IsGameUIVisible() or engine.Con_IsVisible() then
		return
	end

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

		draw.Color(team_color[1], team_color[2], team_color[3], team_color[4])
		draw.FilledRect(centerx - width, 0, centerx + width, height)

		draw.Color(255, 255, 255, 255)
		draw.SetFont(font)
		draw.TextShadow(centerx - math.floor(textwidth / 2), height, str)
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
		draw.TextShadow(centerx - math.floor(healthSizeX / 2), lastHeight, health_str)
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
				ammo_str = isPrimaryWeapon and string.format("%s/%s", clip1, primary_clip2) or
					 string.format("%s/%s", clip1, secondary_clip2)
			else
				ammo_str = string.format("%s", primary_clip2)
			end

			local ammoW, ammoH = draw.GetTextSize(ammo_str)
			draw.SetFont(font)
			draw.Color(255, 255, 255, 255)

			lastHeight = lastHeight + ammoH
			draw.TextShadow(centerx - math.floor(ammoW / 2), lastHeight, ammo_str)
		else
			local melee_str = "MELEE"
			local meleeW, meleeH = draw.GetTextSize(melee_str)
			draw.SetFont(font)
			draw.Color(255, 100, 100, 255)

			lastHeight = lastHeight + meleeH
			draw.TextShadow(centerx - math.floor(meleeW / 2), lastHeight, melee_str)
		end
	end

	if settings.metal then
		local isEngineer = localplayer:GetPropInt("m_iClass") == E_Character.TF2_Engineer
		if isEngineer then
			local ammoDataTable = localplayer:GetPropDataTableInt("m_iAmmo")
			local metal_quantity = ammoDataTable[4]
			local metal_str = string.format("%i/200", metal_quantity)
			local metalW, metalH = draw.GetTextSize(metal_str)
			draw.SetFont(font)
			draw.Color(255, 255, 255, 255)
			lastHeight = lastHeight + metalH
			draw.TextShadow(centerx - math.floor(metalW / 2), lastHeight, metal_str)
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
		local percentage = warp.GetChargedTicks() / 23
		if percentage == 1 then
			draw.Color(150, 255, 150, 255)
		else
			draw.Color(255, 150, 150, 255)
		end
		draw.FilledRectFade(centerx - width + 2, lastHeight + 2, math.floor(centerx - width + (width * percentage * 2) - 2),
			lastHeight + height - 2, 150, 10, false)

		-- warp text
		local maxticks = client.GetConVar("sv_maxusrcmdprocessticks") - 1
		draw.SetFont(warp_font)
		draw.Color(255, 255, 255, 150)
		local str = string.format("TICKS: %s/%s", warp.GetChargedTicks(), maxticks)
		local textwidth, textheight = draw.GetTextSize(str)
		draw.Text(centerx - math.floor(textwidth / 2), lastHeight + 2, str)
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

		local percentage = critbucket / 1000 -- 1000 is max
		draw.Color(150, 150, 255, 255)
		draw.FilledRectFade(centerx - width + 2, lastHeight + 2, math.floor(centerx - width + (width * percentage * 2) - 2),
			lastHeight + height - 2, 150, 10, false)
		local str = string.format("CRIT BUCKET: %.1f", weapon:GetCritTokenBucket())
		local textwidth, textheight = draw.GetTextSize(str)
		draw.SetFont(warp_font)
		draw.Color(255, 255, 255, 150)
		draw.Text(centerx - math.floor(textwidth / 2), lastHeight + 2, str)
	end

	--- engineer specific (sentry, dispenser, etc)
	local isEngineer = localplayer:GetPropInt("m_iClass") == E_Character.TF2_Engineer
	if isEngineer then
		local hasSentry, hasDispenser, hasTeleEntrance, hasTeleExit = false, false, false, false
		local sentries = entities.FindByClass("CObjectSentrygun")
		local dispensers = entities.FindByClass("CObjectDispenser")
		for k, sentry in pairs(sentries) do
			if sentry:GetTeamNumber() == localplayer:GetTeamNumber() and sentry:GetPropEntity("m_hBuilder") == localplayer then
				hasSentry = true
				return
			end
		end
		for k, dispenser in pairs(dispensers) do
			if dispenser:GetTeamNumber() == localplayer:GetTeamNumber() and dispenser:GetPropEntity("m_hBuilder") == localplayer then
				hasDispenser = true
				return
			end
		end
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
			death_string = string.format("%s + %s x %s", death.attacker:GetName(), death.assister:GetName(),
				death.victim:GetName())
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
	if not settings.chat then return end
	if not should_draw_hud then return end
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

		killfeed_deaths[#killfeed_deaths + 1] = {
			victim = victim,
			attacker = attacker,
			assister = assister,
			tick_to_disappear =
				 current_tick + (hud_deathnotice_time * 66 * 2)
		}
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

		--- background
		draw.Color(255, 255, 255, 255)
		draw.FilledRect(x - 10, lastHeight + textheight, x + textwidth + 10, lastHeight + textheight + textheight)

		--- fuck this in particular im not gonna draw each word separately that i want to color
		local msg_color = color[chat_message.player:GetTeamNumber()]
		draw.Color(msg_color[1], msg_color[2], msg_color[3], msg_color[4])
		draw.Text(x, y, str)
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
		chatType = string.sub(chatType, 2) -- skip a useless character
		local playerName = bf:ReadString(256)
		local message = bf:ReadString(256)

		local current_tick = globals.TickCount()
		local hud_saytext_time = client.GetConVar("hud_saytext_time")

		local players = entities.FindByClass("CTFPlayer")
		for _, player in pairs(players) do
			if player:GetName() == playerName then
				chat_messages[#chat_messages + 1] = {
					player = player,
					message = message,
					tick_to_disappear = current_tick +
						 (hud_saytext_time * 66),
					type = chatType
				}
			end
		end
	end
end

local function draw_escape_menu()
	draw.Color(0, 0, 0, 150)
	draw.FilledRect(0, 0, screenw, screenh)

	--- background
	alib.objects.window(window.width, window.height, window.x, window.y, "settings")

	--- i wish i could automate this, but for some reason it doesnt work like it should, but hey at least more control :)
	--- health
	alib.objects.checkbox(health_checkbox.width, health_checkbox.height, health_checkbox.x + window.x,
		health_checkbox.y + window.y, health_checkbox.checked)
	do
		draw.SetFont(warp_font)
		local tw, th = draw.GetTextSize("health")
		draw.Color(255, 255, 255, 255)
		draw.TextShadow(health_checkbox.x + window.x + health_checkbox.width / 2 - math.floor(tw / 2),
			health_checkbox.y + window.y + health_checkbox.height / 2 - math.floor(th / 2), "health")
	end

	--- ammo
	alib.objects.checkbox(ammo_checkbox.width, ammo_checkbox.height, ammo_checkbox.x + window.x,
		ammo_checkbox.y + window.y, ammo_checkbox.checked)
	do
		draw.SetFont(warp_font)
		local tw, th = draw.GetTextSize("ammo")
		draw.Color(255, 255, 255, 255)
		draw.TextShadow(ammo_checkbox.x + window.x + ammo_checkbox.width / 2 - math.floor(tw / 2),
			ammo_checkbox.y + window.y + ammo_checkbox.height / 2 - math.floor(th / 2), "ammo")
	end

	--- crit
	alib.objects.checkbox(crit_checkbox.width, crit_checkbox.height, crit_checkbox.x + window.x,
		crit_checkbox.y + window.y, crit_checkbox.checked)
	do
		draw.SetFont(warp_font)
		local tw, th = draw.GetTextSize("crit")
		draw.Color(255, 255, 255, 255)
		draw.TextShadow(crit_checkbox.x + window.x + crit_checkbox.width / 2 - math.floor(tw / 2),
			crit_checkbox.y + window.y + crit_checkbox.height / 2 - math.floor(th / 2), "crit")
	end

	--- warp
	alib.objects.checkbox(warp_checkbox.width, warp_checkbox.height, warp_checkbox.x + window.x,
		warp_checkbox.y + window.y, warp_checkbox.checked)
	do
		draw.SetFont(warp_font)
		local tw, th = draw.GetTextSize("warp")
		draw.Color(255, 255, 255, 255)
		draw.TextShadow(warp_checkbox.x + window.x + warp_checkbox.width / 2 - math.floor(tw / 2),
			warp_checkbox.y + window.y + warp_checkbox.height / 2 - math.floor(th / 2), "warp")
	end

	--- killfeed
	alib.objects.checkbox(killfeed_checkbox.width, killfeed_checkbox.height, killfeed_checkbox.x + window.x,
		killfeed_checkbox.y + window.y, killfeed_checkbox.checked)
	do
		draw.SetFont(warp_font)
		local tw, th = draw.GetTextSize("killfeed")
		draw.Color(255, 255, 255, 255)
		draw.TextShadow(killfeed_checkbox.x + window.x + killfeed_checkbox.width / 2 - math.floor(tw / 2),
			killfeed_checkbox.y + window.y + killfeed_checkbox.height / 2 - math.floor(th / 2), "killfeed")
	end

	--- chat
	alib.objects.checkbox(chat_checkbox.width, chat_checkbox.height, chat_checkbox.x + window.x,
		chat_checkbox.y + window.y, chat_checkbox.checked)
	do
		draw.SetFont(warp_font)
		local tw, th = draw.GetTextSize("chat")
		draw.Color(255, 255, 255, 255)
		draw.TextShadow(chat_checkbox.x + window.x + chat_checkbox.width / 2 - math.floor(tw / 2),
			chat_checkbox.y + window.y + chat_checkbox.height / 2 - math.floor(th / 2), "chat")
	end

	--- class switcher
	alib.objects.list(list.width, list.x + window.x, list.y + window.y, list.selected_item_index, list.items)
end

local last_tick = 0
--- this is bs it doesnt work without doing it manually
local function mouse_input()
	if not engine.IsGameUIVisible() and not gui.IsMenuOpen() then return end
	local state, tick = input.IsButtonPressed(E_ButtonCode.MOUSE_LEFT)
	if state and tick ~= last_tick then
		if alib.math.isMouseInside(window, health_checkbox) then
			health_checkbox.checked = not health_checkbox.checked
			settings.health = health_checkbox.checked
		end

		if alib.math.isMouseInside(window, ammo_checkbox) then
			ammo_checkbox.checked = not ammo_checkbox.checked
			settings.ammo = ammo_checkbox.checked
		end

		if alib.math.isMouseInside(window, crit_checkbox) then
			crit_checkbox.checked = not crit_checkbox.checked
			settings.crit = crit_checkbox.checked
		end

		if alib.math.isMouseInside(window, warp_checkbox) then
			warp_checkbox.checked = not warp_checkbox.checked
			settings.warp = warp_checkbox.checked
		end

		if alib.math.isMouseInside(window, killfeed_checkbox) then
			killfeed_checkbox.checked = not killfeed_checkbox.checked
			settings.killfeed = killfeed_checkbox.checked
		end

		if alib.math.isMouseInside(window, chat_checkbox) then
			chat_checkbox.checked = not chat_checkbox.checked
			settings.chat = chat_checkbox.checked
		end

		for i, v in ipairs(list.items) do
			local is_mouse_inside = alib.math.isMouseInsideItem(window, list, i)
			if is_mouse_inside and input.IsButtonDown(E_ButtonCode.MOUSE_LEFT) then
				list.selected_item_index = i
				client.Command(string.format("join_class %s", v), true)
			end
		end

		last_tick = tick
	end
end

--- load crosshair
local content = http.Get("https://raw.githubusercontent.com/uosq/lmaobox-luas/refs/heads/main/crosshair.lua")
filesystem.CreateDirectory("navet custom hud")
io.output("navet custom hud/crosshair.lua")
io.write(content)
io.flush()
io.close(io.stdout)
LoadScript("navet custom hud/crosshair.lua")
callbacks.Register("Unload", function()
	UnloadScript("navet custom hud/crosshair.lua")
end)

local function hud_manager()
	if (gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot()) then -- or engine.IsGameUIVisible() or engine.Con_IsVisible() then
		return
	elseif engine.IsGameUIVisible() and gui.IsMenuOpen() then
		input.SetMouseInputEnabled(true)
		draw_escape_menu()
	elseif not engine.IsGameUIVisible() then
		input.SetMouseInputEnabled(false)
		hud()
	end
end

callbacks.Register("DispatchUserMessage", chat_msgs)
callbacks.Register("Draw", draw_chat)

callbacks.Register("Draw", hud_manager)
callbacks.Register("CreateMove", mouse_input)

callbacks.Register("FireGameEvent", killfeed)
callbacks.Register("Draw", draw_killfeed)

callbacks.Register("Unload", function()
	client.Command("cl_drawhud 1", true)
	input.SetMouseInputEnabled(false)
	gui.SetValue("double tap indicator size", 3)
	gui.SetValue("crit hack indicator size", 3)
end)
