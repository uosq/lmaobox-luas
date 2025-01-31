--[[
Made by navet
--]]

--- settings
local charge_key = gui.GetValue("force recharge key") --- change this to E_ButtonCode.KEY_something if you want to change the key
local send_key = gui.GetValue("double tap key") --- change this to E_ButtonCode.KEY_something if you want to change the key
local toggle_passive_recharge_key = E_ButtonCode.KEY_R --- Toggles passive recharge |change this to E_ButtonCode.KEY_thekeyyouwant EXAMPLE: E_ButtonCode.KEY_R

local passive_recharge = true -- if you want to not recharge passively make this false
local passive_recharge_ticks = 2 --- how much ticks should it recharge every time |  WARNING: DOESNT WORK YET! Waiting for netchannel:SendNetMsg() fix!
local passive_recharge_time_seconds = 1 --- how often should be recharge passively in seconds?

local shoot_in_recharge = true -- if you try to shoot while recharging it'll stop until you stop shooting (pressing M1 or primary fire key)
local shoot_while_warp = true -- disable this if you want to stop warping while shooting or aimbot is shooting

local warp_standing_still = false -- enable if you want to warp while not moving (why?)

--- this option affects shoot_while_warp and shoot_in_recharge
local check_aimbot_target = true -- WARNING: this will effectively disable recharging with aimbot always turned on!

local recharge_standing_still = false --- i dont like this but well if you really want it, its an option ig
local recharge_in_air = true --- disable to stop being able to recharge while in the air
--- end of settings

--- the charge bar is not mine, i pasted it from another script, idk who tho im sorry :(
local font = draw.CreateFont("TF2 BUILD", 12, 1000)
local barWidth = 200
local barHeight = 15
local backgroundOffset = 5

local screenX, screenY = draw.GetScreenSize()
local barX = math.floor(screenX / 2 - barWidth / 2)
local barY = math.floor(screenY / 2) + 20

local charged_ticks = 0

local localplayer = nil

local passive_recharge_time = passive_recharge_time_seconds * 66.67 --- 66.67 is 1 second in source engine spaghetti
local next_recharge_tick = 0
local last_pressed_tick = 0

local warping = false
local recharging = false
local shooting = false
local on_ground = true

local BACKUP_COMMANDS_SIZE = 3
local NEW_COMMANDS_SIZE = 4

--- disable tick shifting stuff from lbox
gui.SetValue("double tap", "none")
gui.SetValue("dash move key", 0)

local function ChatPrintf(...)
	local args = { ... }
	for i = 1, #args do
		client.ChatPrintf(args[i])
	end
end

if not clientstate:GetNetChannel() then
	printc(255, 150, 150, 255, "Disabled double tap and dash", "You can recharge with anti aim, it will mostly work")
else
	ChatPrintf("Disabled double tap and dash", "You can recharge with anti aim, it will mostly work")
end

-- tbh i dont think we should even get sv_maxusrcmdprocessticks, its not like valve's or community servers will change sv_maxusrcmdprocessticks to something bigger
-- sticking with the default 24 seems pretty reasonable to me
local function GetMaxPossibleTicks()
	local sv_maxusrcmdprocessticks = client.GetConVar("sv_maxusrcmdprocessticks") - 0 -- truly the most math of math i have ever mathed, fuck lsp warning about casting any to integer >:(
	return sv_maxusrcmdprocessticks == 0 and 999999999 or sv_maxusrcmdprocessticks -- default is 24 for valve servers
end

local function clamp(value, min, max)
	return math.min(math.max(value, min), max)
end

local maxticks = GetMaxPossibleTicks()

---@param new_commands integer
---@param backup_commands integer
local function create_clc_move_buffer(new_commands, backup_commands)
	local bf = BitBuffer()
	bf:SetCurBit(0)
	bf:WriteInt(new_commands, NEW_COMMANDS_SIZE) -- m_nNewCommands
	bf:WriteInt(backup_commands, BACKUP_COMMANDS_SIZE) -- m_nBackupCommands
	bf:Reset()
	bf:SetCurBit(0)
	return bf
end

---@param bf BitBuffer
local function clc_move_read(bf)
	bf:SetCurBit(0)
	local m_nNewCommands = bf:ReadInt(NEW_COMMANDS_SIZE)
	local m_nBackupCommands = bf:ReadInt(BACKUP_COMMANDS_SIZE)
	bf:SetCurBit(0)
	return { m_nNewCommands = m_nNewCommands, m_nBackupCommands = m_nBackupCommands, m_nLength = m_nLength }
end

---@param bf BitBuffer
local function clc_move_tostring(bf)
	local clc_move = clc_move_read(bf)
	local str = "clc_Move, new commands: %i, backup commands: %i, bytes: %i"
	bf:SetCurBit(0)
	local m_nNewCommands = clc_move.m_nNewCommands
	local m_nBackupCommands = clc_move.m_nBackupCommands
	local m_nLength = clc_move.m_nLength
	bf:SetCurBit(0)
	return string.format(str, tostring(m_nNewCommands), tostring(m_nBackupCommands), m_nLength)
end

local function CanChokeTick()
	return clientstate:GetChokedCommands() < maxticks
end

local function CanShiftTick()
	return clientstate:GetChokedCommands() == 0
end

---@param usercmd UserCmd
local function handle_input(usercmd)
	localplayer = entities:GetLocalPlayer()
	if not localplayer then
		return
	end

	warping = input.IsButtonDown(send_key)

	local state, tick = input.IsButtonPressed(toggle_passive_recharge_key)
	if state and tick ~= last_pressed_tick and not engine.IsChatOpen() then
		passive_recharge = not passive_recharge
		ChatPrintf("\x01Passive recharge is now: " .. tostring(passive_recharge and "on" or "off"))
		last_pressed_tick = tick
	end

	--shooting = usercmd.buttons & IN_ATTACK ~= 0 -- only works with normal player input, aimbot doesnt change this!
	if check_aimbot_target then
		shooting = usercmd.buttons & IN_ATTACK ~= 0
			or (aimbot.GetAimbotTarget() >= 1 and input.IsButtonDown(gui.GetValue("aim key"))) -- aimbot will mess with this
	else
		shooting = usercmd.buttons & IN_ATTACK ~= 0
	end
	maxticks = GetMaxPossibleTicks()
	charged_ticks = clamp(charged_ticks, 0, maxticks)
	on_ground = localplayer:GetPropInt("m_fFlags") & FL_ONGROUND ~= 0
end

---@param msg NetMessage
local function Warp(msg)
	if msg:GetType() == 6 then -- SignonState
		-- E_SignonState.SIGNONSTATE_SPAWN is before we fully join the server, i think its when we are sending or receiving info
		if clientstate:GetClientSignonState() == E_SignonState.SIGNONSTATE_SPAWN then
			charged_ticks = 0
			next_recharge_tick = 0
			recharging = false
			warping = false
			maxticks = GetMaxPossibleTicks()
		end
	end
	if
		msg:GetType() == 9
		and localplayer
		and localplayer:IsAlive()
		and not engine.IsChatOpen()
		and not engine.Con_IsVisible()
		and not engine.IsGameUIVisible()
	then
		if warping and charged_ticks > 0 and not recharging and CanShiftTick() then
			if
				(shooting and not shoot_while_warp)
				or (not warp_standing_still and localplayer:EstimateAbsVelocity():Length() <= 0)
			then
				return true
			end

			local buffer = create_clc_move_buffer(2, 1)
			msg:ReadFromBitBuffer(buffer)

			charged_ticks = charged_ticks - 1
			buffer:Delete()
			return true
		end

		--- early return so we dont recharge
		if (shooting and shoot_in_recharge) or (not on_ground and not recharge_in_air) or not CanChokeTick() then
			return true
		end

		if
			(
				input.IsButtonDown(charge_key)
				or (recharge_standing_still and localplayer:EstimateAbsVelocity():Length() == 0)
			)
			and charged_ticks < maxticks
			and not warping
		then
			recharging = true
			charged_ticks = charged_ticks + 1
			local netchan = clientstate:GetNetChannel()
			if netchan then
				local m_nOutSequenceNr, m_nInsequenceNr, m_nOutSequenceNrAck = netchan:GetSequenceData()
				m_nOutSequenceNr = m_nOutSequenceNr + 1
				--- appparently its to say its choked?
				--- im not sure but nothing else happens when i use this so idc i'll keep it until i have problems
				netchan:SetSequenceData(m_nOutSequenceNr, m_nInsequenceNr, m_nOutSequenceNrAck)
			end
			recharging = false
			return false
		end

		if
			passive_recharge
			and not recharging
			and charged_ticks < maxticks
			and globals.TickCount() >= next_recharge_tick
			and not warping
		then
			recharging = true
			charged_ticks = charged_ticks + 1
			next_recharge_tick = globals.TickCount() + passive_recharge_time
			recharging = false
			return false
		end
	end
	return true
end

local function Draw()
	if engine.Con_IsVisible() or engine.IsGameUIVisible() then
		return
	end

	local used_ticks = charged_ticks
	used_ticks = math.floor(math.max(0, math.min(used_ticks, maxticks)))

	-- Background
	draw.Color(70, 70, 70, 150)
	draw.FilledRect(
		barX - backgroundOffset,
		barY - backgroundOffset,
		barX + barWidth + backgroundOffset,
		barY + barHeight + backgroundOffset
	)

	local cant_warp = gui.GetValue("anti aim") == 1 or gui.GetValue("fake lag") == 1

	local filledWidth = math.floor((barWidth * used_ticks) / maxticks)
	if cant_warp then
		draw.Color(255, 50, 50, 255)
	elseif used_ticks == maxticks then
		draw.Color(1, 221, 103, 255) -- green
	else
		draw.Color(97, 97, 76, 255) -- darker green
	end
	draw.FilledRect(math.floor(barX), math.floor(barY), math.floor(barX + filledWidth), math.floor(barY + barHeight))

	local text = string.format("%i / %i", used_ticks, maxticks)

	draw.SetFont(font)
	local textW, textH = draw.GetTextSize(text)
	local textX, textY =
		barX + math.floor(barWidth / 2) - math.floor(textW / 2),
		barY + math.floor(barHeight / 2) - math.floor(textH / 2)
	draw.SetFont(font)
	draw.Color(255, 255, 255, 255)
	draw.Text(textX, textY, text)
end

callbacks.Register("SendNetMsg", Warp)
callbacks.Register("Draw", Draw)
callbacks.Register("CreateMove", handle_input)
