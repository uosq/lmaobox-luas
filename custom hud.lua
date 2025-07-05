--- made by navet

local font_size = 16
local font = draw.CreateFont("TF2 BUILD", font_size, 600)

local health_unformatted = "%s / %s"
local ammo_unformatted = "%s / %s"

---@type table<number, {player: Entity, message: string, tick_to_disappear: number, type: "TF_Chat_All"|"TF_Chat_Team"}>
local chat_messages = {}

---@alias RGB {[1]: integer, [2]: integer, [3]: integer}

---@param color RGB?
---@param x integer
---@param y integer
---@param text string
local function DrawText(color, x, y, text)
	draw.Color(41, 46, 57, 255)
	draw.Text(x + 2, y + 2, text)

	if color then
		draw.Color(color[1], color[2], color[3], 255)
	else
		draw.Color(236, 239, 244, 255)
	end
	draw.Text(x, y, text)
end

local function DrawCrosshair(current_weapon, center_x, center_y)
	local size = 8
	local spread = current_weapon:GetWeaponSpread()
	if spread then
		size = size * (1 + (spread * 10)) // 1
	end

	draw.Color(136, 192, 208, 255)
	draw.Line(center_x, center_y, center_x + size, center_y) -- x--
	draw.Line(center_x - size, center_y, center_x, center_y) -- --x
	draw.Line(center_x, center_y - size, center_x, center_y + size) -- center to top
	draw.Line(center_x, center_y, center_x, center_y + size) -- center to bottom
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
					tick_to_disappear = current_tick + (hud_saytext_time * 66),
					type = chatType,
				}
			end
		end
	end
end

--- i will not lie, i asked AI to do this
--- but only this function was made by AI
--- the other ones were made by me
---@param x integer
---@param y integer
---@param text string
---@param lineHeight integer|nil Optional line height (defaults to font height + 2)
local function DrawColoredText(x, y, text, lineHeight)
	lineHeight = lineHeight or 18 -- Default line height, adjust as needed

	-- Split text by newlines first
	local lines = {}
	for line in text:gmatch("([^\n]*)\n?") do
		if line ~= "" or text:match("\n") then
			table.insert(lines, line)
		end
	end

	-- Handle case where there are no newlines
	if #lines == 0 then
		lines = { text }
	end

	-- Draw each line
	for lineIndex, line in ipairs(lines) do
		local currentX = x
		local currentY = y + (lineIndex - 1) * lineHeight
		local defaultColor = { 255, 255, 255, 255 }
		local lastIndex = 1

		-- Pattern to match color tags like {#fcba03} or {#fcba03ff}
		for startPos, colorTag, hex, endPos in line:gmatch("()({#([%x]+)})()") do
			-- Draw preceding plain text (if any)
			if startPos > lastIndex then
				local plainText = line:sub(lastIndex, startPos - 1)
				draw.Color(table.unpack(defaultColor))
				draw.Text(currentX, currentY, plainText)
				currentX = currentX + draw.GetTextSize(plainText)
			end

			-- hex -> RGBA
			local r, g, b, a = 255, 255, 255, 255
			if #hex == 6 then
				r = tonumber(hex:sub(1, 2), 16) or 255
				g = tonumber(hex:sub(3, 4), 16) or 255
				b = tonumber(hex:sub(5, 6), 16) or 255
			elseif #hex == 8 then
				r = tonumber(hex:sub(1, 2), 16) or 255
				g = tonumber(hex:sub(3, 4), 16) or 255
				b = tonumber(hex:sub(5, 6), 16) or 255
				a = tonumber(hex:sub(7, 8), 16) or 255
			end

			-- update lastIndex to skip the color tag
			lastIndex = endPos

			-- find the next color tag or end of string to determine colored text length
			local nextTagStart = line:find("{#", lastIndex)
			local coloredText
			if nextTagStart then
				coloredText = line:sub(lastIndex, nextTagStart - 1)
			else
				coloredText = line:sub(lastIndex)
			end

			-- draw the colored text
			if coloredText and coloredText ~= "" then
				draw.Color(r, g, b, a)
				draw.Text(currentX, currentY, coloredText)
				currentX = currentX + draw.GetTextSize(coloredText)
				lastIndex = lastIndex + #coloredText
			end
		end

		-- draw any remaining plain text on this line
		if lastIndex <= #line then
			local remaining = line:sub(lastIndex)
			if remaining ~= "" then
				draw.Color(table.unpack(defaultColor))
				draw.Text(currentX, currentY, remaining)
			end
		end
	end
end

local function DrawChat()
	if #chat_messages == 0 then
		return
	end

	local screen_w, screen_h = draw.GetScreenSize()
	local x, y, width, height
	local margin = 15
	width, height = 400, 250
	x = screen_w - width - margin
	y = (screen_h * 0.75) // 1

	draw.Color(76, 86, 106, 200)
	draw.FilledRect(x, y - 25, x + width, y)

	local text_w, text_h = draw.GetTextSize("chat")
	DrawText(nil, x + (width // 2) - (text_w // 2), y - (25 // 2) - (text_h // 2), "chat")

	draw.Color(67, 76, 94, 200)
	draw.FilledRect(x, y, x + width, y + height)

	x = x + 3
	y = y + 3
	width = width - 6
	height = height - 6
	draw.Color(46, 52, 64, 200)
	draw.FilledRect(x, y, x + width, y + height)

	local start_y = y + 3

	for i, msg in pairs(chat_messages) do
		if msg.tick_to_disappear <= globals.TickCount() then
			chat_messages[i] = nil
		end
	end

	for i, msg in pairs(chat_messages) do
		local color = nil

		if msg.player:GetTeamNumber() == 2 then
			color = "#88c0d0"
		else
			color = "#bf616a"
		end

		DrawColoredText(x + 3, start_y, string.format("{%s}%s{#e5e9f0}: %s", color, msg.player:GetName(), msg.message))
		start_y = start_y + font_size + 5
	end
end

local function Draw()
	if client.GetConVar("_cl_classmenuopen") == 1 then
		if client.GetConVar("cl_drawhud") == 0 then
			client.SetConVar("cl_drawhud", 1)
		end
		return
	end

	local plocal = entities.GetLocalPlayer()
	if not plocal then
		return
	end

	local current_weapon = plocal:GetPropEntity("m_hActiveWeapon")
	if not current_weapon then
		return
	end

	if engine.IsTakingScreenshot() and client.GetConVar("cl_drawhud") == 0 then
		client.SetConVar("cl_drawhud", 1)
		return
	elseif engine.IsTakingScreenshot() then
		return
	end

	if engine.IsChatOpen() and client.GetConVar("cl_drawhud") == 0 then
		client.SetConVar("cl_drawhud", 1)
		return
	elseif engine.IsChatOpen() then
		return
	end

	if engine.IsGameUIVisible() and client.GetConVar("cl_drawhud") == 0 then
		client.SetConVar("cl_drawhud", 1)
		return
	elseif engine.IsGameUIVisible() then
		return
	end

	if gamerules.GetRoundState() == E_RoundState.ROUND_GAMEOVER and client.GetConVar("cl_drawhud") == 0 then
		client.SetConVar("cl_drawhud", 1)
		return
	elseif gamerules.GetRoundState() == E_RoundState.ROUND_GAMEOVER then
		return
	end

	if client.GetConVar("cl_drawhud") == 1 then
		client.SetConVar("cl_drawhud", 0)
	end

	local screen_w, screen_h = draw.GetScreenSize()
	local center_x, center_y = screen_w // 2, screen_h // 2

	draw.SetFont(font)

	if not plocal:IsAlive() then
		local start_y = screen_h // 6
		local m_hObserverTarget = plocal:GetPropEntity("m_hObserverTarget")

		if m_hObserverTarget then
			local text_w, text_h = draw.GetTextSize("spectating")
			DrawText(nil, center_x - (text_w // 2), start_y, "spectating")

			start_y = start_y + text_h + 5

			local name = m_hObserverTarget:GetName()
			name = name == "" and string.format("entity index: %i", m_hObserverTarget:GetIndex()) or name

			text_w, text_h = draw.GetTextSize(name)
			DrawText(nil, center_x - (text_w // 2), start_y, name)

			start_y = start_y + text_h + 5
		end

		local resources = entities.GetPlayerResources()
		if resources then
			local lp_res = resources:GetPropDataTableFloat("m_flNextRespawnTime")[
				plocal:GetIndex() + 1 --[[ wtf? ]]
			]
			local text = string.format("respawn in %i seconds", (lp_res - globals.CurTime()) // 1)
			local text_w = draw.GetTextSize(text)
			DrawText(nil, center_x - (text_w // 2), start_y, text)
			start_y = start_y + font_size + 5
		end

		return
	end

	DrawChat()

	local start_y = center_y + 20
	local health = plocal:GetHealth()
	local max_health = plocal:GetMaxHealth()
	local health_ratio = health / max_health

	local health_text = string.format(health_unformatted, health, max_health)
	local health_w, health_h = draw.GetTextSize(health_text)

	if health_ratio >= 0.5 then
		DrawText({ 163, 190, 140 }, center_x - (health_w // 2), start_y, health_text)
	else
		DrawText({ 191, 97, 106 }, center_x - (health_w // 2), start_y, health_text)
	end

	start_y = start_y + health_h + 5

	if not current_weapon:IsMeleeWeapon() then
		local is_primary = current_weapon:GetLoadoutSlot() == E_LoadoutSlot.LOADOUT_POSITION_PRIMARY
		local ammo_datatable = plocal:GetPropDataTableInt("m_iAmmo")
		local clip1 = current_weapon:GetPropInt("m_iClip1")
		local primary_clip2, secondary_clip2 = ammo_datatable[2], ammo_datatable[3]

		local ammo_text = ""

		if clip1 ~= -1 and clip1 then
			ammo_text = is_primary and string.format(ammo_unformatted, clip1, primary_clip2)
				or string.format(ammo_unformatted, clip1, secondary_clip2)
		else
			ammo_text = string.format("%s", primary_clip2)
		end

		local ammo_w, ammo_h = draw.GetTextSize(ammo_text)
		DrawText({ 180, 142, 173 }, center_x - (ammo_w // 2), start_y, ammo_text)

		start_y = start_y + ammo_h + 5
	end

	--- cri hack bar
	if current_weapon:CanRandomCrit() then
		---  stuff "borrowed" from the docs
		local critChance = current_weapon:GetCritChance()
		local dmgStats = current_weapon:GetWeaponDamageStats()
		local totalDmg = dmgStats["total"]
		local criticalDmg = dmgStats["critical"]

		-- (the + 0.1 is always added to the comparsion)
		local cmpCritChance = critChance + 0.1
		---

		local crit_ratio = 0

		-- If we are allowed to crit
		if cmpCritChance > current_weapon:CalcObservedCritChance() then
			crit_ratio = current_weapon:GetCritTokenBucket() / 1000
			local x, y, width, height
			width, height = 100, 10
			x, y = center_x - (width // 2), start_y

			draw.Color(67, 76, 94, 255)
			draw.FilledRect(x, y, x + width, y + height)

			draw.Color(236, 239, 244, 255)
			draw.FilledRect(x, y, x + (width * crit_ratio) // 1, y + height)
			start_y = start_y + height + 5
		else --Figure out how much damage we need
			local requiredTotalDamage = (criticalDmg * (2.0 * cmpCritChance + 1.0)) / cmpCritChance / 3.0
			local requiredDamage = requiredTotalDamage - totalDmg
			local text = string.format("Required damage: %.0f", requiredDamage)
			local tw = draw.GetTextSize(text)

			DrawText(nil, center_x - (tw // 2), start_y, text)
			start_y = start_y + font_size + 5
		end

		---
	end

	if plocal:GetPropInt("m_iClass") == E_Character.TF2_Engineer then
		local ammo_datatable = plocal:GetPropDataTableInt("m_iAmmo")
		local quantity = ammo_datatable[4]
		local text = string.format("%i / 200", quantity)
		local metal_w, metal_h = draw.GetTextSize(text)

		DrawText({ 235, 203, 139 }, center_x - (metal_w // 2), start_y, text)

		start_y = start_y + metal_h + 10

		if current_weapon:GetLoadoutSlot() == 3 or current_weapon:GetLoadoutSlot() == 4 then
			--- really stupid
			--- and not memory efficient
			--- but we have modern hardware with 4+ gb of ram so fuck it
			local buildings = { "sentry", "dispenser", "teleporter", "teleporter exit" }
			local has_buildings = { false, false, false, false }

			local total_size = 0

			for i = 1, 4 do
				local w = draw.GetTextSize(buildings[i])
				total_size = (total_size + w) // 1
			end

			local text_x = center_x - (total_size // 2)
			local text_y = start_y

			local plocal_index = plocal:GetIndex()

			for _, sentry in pairs(entities.FindByClass("CObjectSentrygun")) do
				local builder = sentry:GetPropEntity("m_hBuilder")
				if builder and builder:GetIndex() == plocal_index then
					has_buildings[1] = true
					break
				end
			end

			for _, dispenser in pairs(entities.FindByClass("CObjectDispenser")) do
				local builder = dispenser:GetPropEntity("m_hBuilder")
				if builder and builder:GetIndex() == plocal_index then
					has_buildings[2] = true
					break
				end
			end

			for _, tele in pairs(entities.FindByClass("CObjectTeleporter")) do
				local builder = tele:GetPropEntity("m_hBuilder")
				if builder and builder:GetIndex() == plocal_index then
					local exit = tele:GetPropInt("m_iObjectMode") == 1
					if exit then
						has_buildings[4] = true
					else
						has_buildings[3] = true
					end
				end
			end

			for i = 1, 4 do
				local text_w, text_h = draw.GetTextSize(buildings[i])

				DrawText(nil, text_x, text_y, buildings[i])

				local number = tostring(i)
				local number_w, number_h = draw.GetTextSize(number) --- fucking stupid
				local number_x, number_y
				number_x = text_x + (text_w // 2) - (number_w // 2)
				number_y = text_y + (text_h // 1) + 5

				DrawText(nil, number_x, number_y, number)

				if has_buildings[i] then
					local w, h = draw.GetTextSize("(built)")
					local x, y
					x = text_x + (text_w // 2) - (w // 2)
					y = number_y + number_h + 5
					DrawText(nil, x, y, "(built)")
				end

				text_x = text_x + (text_w // 1) + 5
			end

			start_y = start_y + font_size + 5
		end
	elseif plocal:GetPropInt("m_iClass") == E_Character.TF2_Spy then
		local cloak = plocal:GetPropFloat("m_flCloakMeter")
		local cloak_ratio = cloak / 100 --- 100 is max cloak
		local width, height = 100, 10
		local x, y = center_x - (width * 0.5), start_y

		draw.Color(67, 76, 94, 255)
		draw.FilledRect(x, y, x + width, y + height)

		draw.Color(236, 239, 244, 255)
		draw.FilledRect(x, y, x + (width * cloak_ratio) // 1, y + height)

		start_y = start_y + y + height + 5
	elseif plocal:GetPropInt("m_iClass") == E_Character.TF2_Sniper then
		local width, height = 100, 10
		local x, y = center_x - (width * 0.5), start_y
		if plocal:InCond(E_TFCOND.TFCond_Zoomed) then
			local MACHINA_INDEX = 526
			local multiplier = current_weapon:GetPropInt("m_Item", "m_iItemDefinitionIndex") == MACHINA_INDEX and 1.15
				or 1
			local current_charge = current_weapon:GetPropFloat("SniperRifleLocalData", "m_flChargedDamage")
			local max_charge = 150 * multiplier
			local charge_ratio = current_charge / max_charge

			--- sniper charge
			draw.Color(67, 76, 94, 255)
			draw.FilledRect(x, y, x + width, y + height)

			draw.Color(236, 239, 244, 255)
			draw.FilledRect(x, y, x + (width * charge_ratio) // 1, y + height)

			start_y = start_y + height + 5
		end

		--- jarate
		local last_firetime =
			plocal:GetEntityForLoadoutSlot(E_LoadoutSlot.LOADOUT_POSITION_SECONDARY):GetPropFloat("m_flLastFireTime")

		local jarate_ratio = 0

		if plocal:GetPropDataTableInt("m_iAmmo")[5] == 1 then
			jarate_ratio = 1
		else
			jarate_ratio = math.min((globals.CurTime() - last_firetime) / 20, 1) --- clamp to max 1
		end

		y = start_y

		draw.Color(67, 76, 94, 255)
		draw.FilledRect(x, y, x + width, y + height)

		draw.Color(235, 203, 139, 255)
		draw.FilledRect(x, y, x + (width * jarate_ratio) // 1, y + height)

		start_y = start_y + height + 5
	elseif plocal:GetPropInt("m_iClass") == E_Character.TF2_Demoman then
		if current_weapon:GetClass() == "CTFPipebombLauncher" then
			local width, height, x, y
			width, height = 100, 10
			x, y = center_x - (width // 2), start_y

			local MAX_CHARGE_STOCK = 4 --- seconds
			local MAX_CHARGE_QUICKIE = 1.2 --- seconds

			--- not sure if this works
			local chosen_max = current_weapon:AttributeHookFloat("sticky_arm_time") == 1 and MAX_CHARGE_STOCK
				or MAX_CHARGE_QUICKIE

			local charge_ratio = (
				globals.CurTime() - current_weapon:GetPropFloat("PipebombLauncherLocalData", "m_flChargeBeginTime")
			) / chosen_max

			if charge_ratio > chosen_max then
				charge_ratio = 0
			end

			draw.Color(67, 76, 94, 255)
			draw.FilledRect(x, y, x + width, y + height)

			draw.Color(236, 239, 244, 255)
			draw.FilledRect(x, y, x + (width * charge_ratio) // 1, y + height)

			start_y = start_y + height + 5
		end

		local sticky_count = plocal
			:GetEntityForLoadoutSlot(E_LoadoutSlot.LOADOUT_POSITION_SECONDARY)
			:GetPropInt("PipebombLauncherLocalData", "m_iPipebombCount")

		local sticky_text = tostring(sticky_count)
		local sticky_w, sticky_h = draw.GetTextSize(sticky_text)

		DrawText(nil, center_x - (sticky_w // 2), start_y, sticky_text)

		start_y = start_y + sticky_h + 5
	elseif plocal:GetPropInt("m_iClass") == E_Character.TF2_Medic then
		local medigun = plocal:GetEntityForLoadoutSlot(E_LoadoutSlot.LOADOUT_POSITION_SECONDARY)
		local charge_level = medigun:GetPropFloat("LocalTFWeaponMedigunData", "m_flChargeLevel") --- 0 to max_charge
		local max_charge = medigun:AttributeHookFloat("mult_medigun_uberchargerate")
		local charge_ratio = charge_level / max_charge
		local width, height, x, y
		width, height = 100, 10
		x, y = center_x - (width * 0.5), start_y

		draw.Color(67, 76, 94, 255)
		draw.FilledRect(x, y, x + width, y + height)

		if charge_ratio >= 1 then
			draw.Color(143, 188, 187, 255)
		else
			draw.Color(236, 239, 244, 255)
		end

		draw.FilledRect(x, y, x + (width * charge_ratio) // 1, y + height)

		start_y = start_y + height + 5

		if
			current_weapon:GetLoadoutSlot() == E_LoadoutSlot.LOADOUT_POSITION_SECONDARY
			and current_weapon:GetPropBool("m_bHealing")
		then
			local heal_target = current_weapon:GetPropEntity("m_hHealingTarget")
			if heal_target then
				y = start_y
				local heal_ratio = 0
				local over_ratio = 0

				if (heal_target:GetHealth() / heal_target:GetMaxHealth()) > 1 then
					over_ratio = (heal_target:GetHealth() - heal_target:GetMaxHealth())
						/ (heal_target:GetMaxBuffedHealth() - heal_target:GetMaxHealth())

					heal_ratio = math.min(heal_target:GetHealth() / heal_target:GetMaxHealth(), 1)
				else
					heal_ratio = heal_target:GetHealth() / heal_target:GetMaxHealth()
				end

				draw.Color(67, 76, 94, 255)
				draw.FilledRect(x, y, x + width, y + height)

				draw.Color(236, 239, 244, 255)
				draw.FilledRect(x, y, x + (width * heal_ratio) // 1, y + height)

				draw.Color(136, 192, 208, 255)
				draw.FilledRect(x, y, x + (width * over_ratio) // 1, y + height)

				start_y = start_y + height + 5
			end
		end
	elseif plocal:GetPropInt("m_iClass") == E_Character.TF2_Heavy then
		local sandvich = plocal:GetEntityForLoadoutSlot(E_LoadoutSlot.LOADOUT_POSITION_SECONDARY)
		if sandvich and sandvich:GetClass() == "CTFLunchBox" then
			local width, height, x, y
			local ready = plocal:GetPropDataTableInt("m_iAmmo")[5] == 1
			local text = ready and "sandvich ready" or "sandvich not ready"

			width, height = draw.GetTextSize(text)
			x, y = center_x - (width // 2), start_y

			if ready then
				DrawText({ 143, 188, 187 }, x, y, text)
			else
				DrawText({ 191, 97, 106 }, x, y, text)
			end

			start_y = start_y + height + 5
		end
	end

	--- info "panel"

	local options = {
		"aim bot",
		"backtrack",
		"anti aim",
		"nospread",
		"norecoil",
		"anti backstab",
		"thirdperson",
	}

	--- extra options not in the gui
	local extras = 2

	if gui.GetValue("fake latency") == 1 and gui.GetValue("backtrack") == 1 then
		extras = extras + 1
	end

	if gui.GetValue("fake lag") == 1 then
		extras = extras + 1
	end

	--- calculate the desired y first
	local needed_size = 0
	local counter = 0

	for i = 1, #options + extras do
		if options[i] then
			local value = gui.GetValue(options[i])
			if value == 1 then
				local _, h = draw.GetTextSize(options[i])
				needed_size = needed_size + h
				counter = counter + 1
			end
		else
			needed_size = needed_size + font_size
			counter = counter + 1
		end
	end

	local x = 10
	start_y = screen_h - needed_size - 10
	for i = 1, #options do
		if gui.GetValue(options[i]) == 1 then
			DrawText(nil, x, start_y, options[i])
			start_y = start_y + ((needed_size / counter) // 1)
		end
	end

	--[[- choked commands
	local choked_text = string.format("choked commands: %i", clientstate:GetChokedCommands())
	local tw = draw.GetTextSize(choked_text)
	DrawText(nil, x, start_y, choked_text)
	start_y = start_y + font_size
	---]]

	--- fake latency
	local fake_latency = false
	if gui.GetValue("fake latency") == 1 and gui.GetValue("backtrack") == 1 then
		local latency_text = string.format("fake latency: %i", gui.GetValue("fake latency value (ms)"))
		DrawText(nil, x, start_y, latency_text)

		start_y = start_y + font_size
		fake_latency = true
	end
	---

	if gui.GetValue("fake lag") == 1 then
		local lag_text = string.format(
			"fake lag: %i (Choked: %i)",
			gui.GetValue("fake lag value (ms)") + 15,
			clientstate:GetChokedCommands()
		)
		DrawText(nil, x, start_y, lag_text)
		start_y = start_y + font_size
	end

	--- latency
	local netchan = clientstate:GetNetChannel()
	if netchan then
		local real_ping = (
			(netchan:GetLatency(E_Flows.FLOW_OUTGOING) + netchan:GetLatency(E_Flows.FLOW_INCOMING)) * 1000
		) - (fake_latency and math.min(gui.GetValue("fake latency value (ms)"), 800) or 0)

		DrawText(nil, x, start_y, string.format("real ping: %.0f", real_ping))
		start_y = start_y + font_size

		local score_ping = netchan:GetLatency(E_Flows.FLOW_OUTGOING) + netchan:GetLatency(E_Flows.FLOW_INCOMING)
		DrawText(nil, x, start_y, string.format("scoreboard ping: %.0f", score_ping * 1000))
		start_y = start_y + font_size
	end
	---

	DrawCrosshair(current_weapon, center_x, center_y)
end

callbacks.Register("Draw", Draw)
callbacks.Register("DispatchUserMessage", chat_msgs)
