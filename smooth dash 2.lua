--- made by navet
--- rewrite of the smooth dash.lua

--- settings

local WARP_KEY <const> = "MOUSE_5"
local RECHARGE_KEY <const> = "MOUSE_4"
local TOGGLE_PASSIVE_RECHARGE <const> = "R"

local INCREASE_MODE <const> = "LEFT"
local DECREASE_MODE <const> = "RIGHT"

local passive_time = 2 --- 1 second (x * 66.67 ticks)
local font = draw.CreateFont("TF2 BUILD", 16, 1000) --- change the "TF2 BUILD" if you want
local smallfont = draw.CreateFont("TF2 BUILD", 8, 1000)

---

local modes = {
	slow = 0, --- really fucking stupid
	normal = 1, --- normal warp
	fast = 2, --- fast short warp
	-- dt = 3, i wish we could do this
}

local current_mode = modes.normal
local current_mode_name = "normal"

local MAX_NEW_COMMANDS <const> = 15
local MAX_BACKUP_COMMANDS <const> = 7

local warping, recharging, passive = false, false, true
local forced_fast = false --- only true when choked commands > 0

local last_keypress_tick = 0

local storedticks = 0

local sw, sh = draw.GetScreenSize()
local x, y = sw // 2, (sh // 2) + 30 --- middle point
local w, h = 100, 20 --- x-50 and x+50 are the outermost edges, y-10 and y+10 are the outermost edges
local thickness = 2

local leftx, uppery, rightx, lowery
leftx, rightx = x - (w // 2), x + (w // 2)
uppery, lowery = y - (h // 2), y + (h // 2)

local bf = BitBuffer()

local GetConVar = client.GetConVar
local IsButtonDown = input.IsButtonDown
local IsButtonPressed = input.IsButtonPressed

local function GetMaxTicks()
	local maxticks = GetConVar("sv_maxusrcmdprocessticks")
	return maxticks
end

---@param prefix boolean
---@param key string
local function GetKey(prefix, key)
	if prefix then
		return E_ButtonCode["KEY_" .. string.upper(key)]
	else
		return E_ButtonCode[string.upper(key)]
	end
end

local function UpdateModeName()
	for name, mode in pairs(modes) do
		if mode == current_mode then
			current_mode_name = name
			break
		end
	end
end

---@param cmd UserCmd
local function CreateMove(cmd)
	local maxticks = GetMaxTicks()
	forced_fast = clientstate:GetChokedCommands() > 0

	warping = storedticks > 0 and IsButtonDown(GetKey(false, WARP_KEY))
	recharging = clientstate:GetChokedCommands() < (MAX_NEW_COMMANDS + MAX_BACKUP_COMMANDS)
		and storedticks < maxticks
		and IsButtonDown(GetKey(false, RECHARGE_KEY))
		and (cmd.sendpacket or clientstate:GetChokedCommands() == 0)

	if warping and (cmd.tick_count % 2) == 0 and current_mode == modes.slow then
		warping = false
	end

	local state, tick = IsButtonPressed(GetKey(true, TOGGLE_PASSIVE_RECHARGE))

	if state and tick > last_keypress_tick then
		last_keypress_tick = tick
		passive = not passive
	end

	state, tick = IsButtonPressed(GetKey(true, INCREASE_MODE))

	if state and tick > last_keypress_tick then
		last_keypress_tick = tick
		current_mode = current_mode + 1
		if current_mode > modes.fast then
			current_mode = modes.slow
		end

		UpdateModeName()
	end

	state, tick = IsButtonPressed(GetKey(true, DECREASE_MODE))

	if state and tick > last_keypress_tick then
		last_keypress_tick = tick
		current_mode = current_mode - 1
		if current_mode < modes.slow then
			current_mode = modes.fast
		end

		UpdateModeName()
	end

	--- not perfectly accurate, but it works
	if storedticks < maxticks and not warping and passive and (cmd.tick_count % ((passive_time * 66) // 1)) == 0 then
		recharging = true
	end

	if recharging then
		cmd.buttons = 0
		cmd.tick_count = 2147483647 --- this apparently fixes the interpolation issue (bs, doesnt do shit)
		local plocal = entities.GetLocalPlayer()
		if not plocal then
			return
		end

		plocal:SetPropFloat(globals.CurTime() + 0.1, "m_flAnimTime")
	end
end

local function clamp(value, min, max)
	return math.min(math.max(value, min), max)
end

---@return integer, integer
local function GetRealCommands()
	local chokedcommands = clientstate:GetChokedCommands()
	local newcmds, backupcmds
	newcmds = 1 + chokedcommands
	newcmds = clamp(newcmds, 0, MAX_NEW_COMMANDS)

	local extracmds = chokedcommands + 1 - newcmds
	backupcmds = math.max(2, extracmds)
	backupcmds = clamp(backupcmds, 0, MAX_BACKUP_COMMANDS)

	return newcmds, backupcmds
end

---@param msg NetMessage
local function SendNetMsg(msg)
	if msg:GetType() == 9 and clientstate:GetChokedCommands() == 0 then
		if warping then
			if storedticks > 0 then
				local newcmds, backupcmds = GetRealCommands()

				bf:SetCurBit(0)

				if forced_fast or current_mode == modes.fast then
					bf:WriteInt(newcmds + backupcmds, 4) --- m_nNewCommands
					bf:WriteInt(0, 3) --- m_nBackupCommands
					storedticks = clamp(storedticks - backupcmds, 0, GetMaxTicks())
				else
					--- this is kinda janky, but it works so who cares
					local totalcmds = newcmds + backupcmds
					totalcmds = clamp(totalcmds - 1, 0, MAX_NEW_COMMANDS + MAX_BACKUP_COMMANDS)
					bf:WriteInt(totalcmds, 4) --- m_nNewCommands
					bf:WriteInt(1, 3) --- m_nBackupCommands
					storedticks = clamp(storedticks - 1, 0, GetMaxTicks())
				end

				bf:SetCurBit(0)
				msg:ReadFromBitBuffer(bf)
			end
		elseif recharging then
			storedticks = clamp(storedticks + 1, 0, GetMaxTicks())
			return false
		end
	elseif msg:GetType() == 6 and clientstate:GetClientSignonState() == E_SignonState.SIGNONSTATE_SPAWN then
		storedticks = 0
	end
end

---@param bVar boolean
local function ChangeColor(bVar)
	if bVar then
		draw.Color(100, 255, 100, 200)
	else
		draw.Color(255, 0, 0, 200)
	end
end

---@param bvar boolean
---@param text string
---@param index integer
local function DrawText(bvar, text, index)
	local gap = 2
	local tx, ty, tw, th
	draw.SetFont(smallfont)

	tw, th = draw.GetTextSize(tostring(text))
	tx, ty = x - (tw // 2), lowery + thickness + gap + (th * index)

	draw.SetFont(smallfont)
	ChangeColor(bvar)
	draw.Text(tx, ty, tostring(text))
end

local function Draw()
	local netchannel = clientstate:GetNetChannel()
	if not netchannel then
		return
	end

	if engine.Con_IsVisible() or engine.IsTakingScreenshot() then
		return
	end

	local maxticks = GetMaxTicks()
	local percent = storedticks / maxticks

	draw.Color(40, 40, 40, 255)
	draw.FilledRect(leftx - thickness, uppery - thickness, rightx + thickness, lowery + thickness)

	draw.Color(255, 255, 255, 255)
	draw.FilledRectFade(leftx, uppery, rightx, lowery, 255, 0, true)

	draw.Color(192, 192, 192, 255)
	draw.FilledRectFade(leftx, uppery, rightx, lowery, 0, 255, true)

	draw.Color(40, 40, 40, 255)
	draw.FilledRect((leftx + ((rightx - leftx) * percent)) // 1, uppery, rightx, lowery)

	local tx, ty, tw, th
	draw.SetFont(font)
	tw, th = draw.GetTextSize(current_mode_name)
	tx, ty = x - (tw // 2), y - (th // 2)
	draw.SetFont(font)
	draw.Color(0, 0, 0, 255)
	draw.Text(tx, ty, current_mode_name)

	draw.SetFont(smallfont)
	DrawText(warping, string.format("WARP KEY: %s", WARP_KEY), 0)
	DrawText(recharging, string.format("RECHARGE KEY: %s", RECHARGE_KEY), 1)
	DrawText(passive, string.format("PASSIVE KEY: %s", TOGGLE_PASSIVE_RECHARGE), 2)
end

local function Unload()
	bf:Delete()
end

callbacks.Register("SendNetMsg", SendNetMsg)
callbacks.Register("CreateMove", CreateMove)
callbacks.Register("Draw", Draw)
callbacks.Register("Unload", Unload)
