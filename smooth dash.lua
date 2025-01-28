--[[
Made by navet
--]]

--- settings
local charge_key = gui.GetValue("force recharge key") --- change this to E_ButtonCode.KEY_something if you want to change the key
local send_key = gui.GetValue("double tap key") --- change this to E_ButtonCode.KEY_something if you want to change the key
local maxticks = 24 -- default is 24 for valve servers
local passive_recharge = true -- if you want to not recharge passively make this false
local speed = 2 -- will probably get fixed someday
--- end of settings

--- the charge bar is not mine, i pasted it from another script, idk who tho im sorry :(
local barWidth = 200
local barHeight = 15
local backgroundOffset = 5

local screenX, screenY = draw.GetScreenSize()
local barX = math.floor(screenX / 2 - barWidth / 2)
local barY = math.floor(screenY / 2) + 20

local charged_ticks = 0

local localplayer = nil

local next_recharge_tick = 0
local warping = false
local recharging = false

local boostBf = BitBuffer()
boostBf:WriteInt(9, 6) --- msg type clc_Move
boostBf:WriteInt(7, 4) -- m_nNewCommands
boostBf:WriteInt(15, 7) -- m_nBackupCommands
boostBf:SetCurBit(0) -- NETMSG_TYPE_BITS

--- disable tick shifting stuff from lbox
gui.SetValue("double tap", "none")
gui.SetValue("dash move key", 0)

local clc_Move_type = 9
local msg_type_size = 6

local BACKUP_COMMANDS_SIZE = 3
local NEW_COMMANDS_SIZE = 4

local function create_clc_buffer(new_commands, backup_commands)
	local bf = BitBuffer()
	bf:SetCurBit(0)
	bf:WriteInt(clc_Move_type, msg_type_size)
	bf:WriteInt(new_commands, NEW_COMMANDS_SIZE)
	bf:WriteInt(backup_commands, BACKUP_COMMANDS_SIZE)
	bf:SetCurBit(0)
	return bf
end

---@param usercmd UserCmd
callbacks.Register("CreateMove", function(usercmd)
	localplayer = entities:GetLocalPlayer()

	if input.IsButtonDown(send_key) and charged_ticks > 0 and not recharging and not warping then
		warping = true
	end

	if input.IsButtonReleased(send_key) and warping then
		warping = false
	end
end)

---@param msg NetMessage
local function SendNetMsg(msg)
	local netchannel = clientstate:GetNetChannel()
	if netchannel then
		return netchannel:SendNetMsg(msg)
	end
	return false
end

---@param msg NetMessage
local function SendCLMove(msg)
	local orig_bf = BitBuffer() -- save original clc_Move
	msg:WriteToBitBuffer(orig_bf)
	print(msg:ToString())
	orig_bf:SetCurBit(6) -- skip msg type

	boostBf:SetCurBit(6) -- skip msg type
	msg:ReadFromBitBuffer(boostBf)
	boostBf:SetCurBit(6) -- i dont remember if we need to skip it here, but just in case its here :)
	SendNetMsg(msg) --- send our clc_Move message
	charged_ticks = charged_ticks - 1

	msg:ReadFromBitBuffer(orig_bf)
	SendNetMsg(msg) --- send original msg
	orig_bf:Delete()
end

---@param msg NetMessage
local function DoWarp(msg)
	for i = 1, speed do
		if charged_ticks <= 0 then
			break
		end

		SendCLMove(msg)
	end
end

---@param msg NetMessage
local function Warp(msg)
	if msg:GetType() == 6 then
		if clientstate:GetClientSignonState() == E_SignonState.SIGNONSTATE_SPAWN then
			charged_ticks = 0
			next_recharge_tick = 0
			recharging = false
		end
	end
	if
		msg:GetType() == 9
		and localplayer
		and localplayer:IsAlive()
		and gui.GetValue("anti aim") == 0
		and gui.GetValue("fake lag") == 0
	then
		if warping and charged_ticks > 0 and not recharging then
			local buffer = create_clc_buffer(2, 1)
			buffer:SetCurBit(6)
			msg:ReadFromBitBuffer(buffer)
			charged_ticks = charged_ticks - 1
			buffer:Delete()
			return true
		end

		if input.IsButtonDown(charge_key) and charged_ticks < maxticks and not warping then
			recharging = true
			charged_ticks = charged_ticks + 1
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
			next_recharge_tick = globals.TickCount() + 66.67
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
	used_ticks = math.max(0, math.min(used_ticks, maxticks))

	-- Background
	draw.Color(70, 70, 70, 150)
	draw.FilledRect(
		barX - backgroundOffset,
		barY - backgroundOffset,
		barX + barWidth + backgroundOffset,
		barY + barHeight + backgroundOffset
	)

	local filledWidth = math.floor(barWidth * used_ticks / maxticks)
	if used_ticks == maxticks then
		draw.Color(1, 221, 103, 255) -- Green
	else
		draw.Color(97, 97, 76, 255) -- Red
	end
	draw.FilledRect(barX, barY, barX + filledWidth, barY + barHeight)
end

callbacks.Register("SendNetMsg", Warp)
callbacks.Register("Draw", Draw)

callbacks.Register("Unload", function()
	boostBf:Delete()
end)
