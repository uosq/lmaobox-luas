--- made by navet

---@enum pitch_modes
local pitch_modes = {
    none = 0,
    up = 1,
    fakeup = 2,
    down = 3,
    fakedown = 4,
}

---@enum yaw_modes
local yaw_modes = {
    forward = 0,
    left = 1,
    right = 2,
    spin = 3,
    jitter = 4,
    back = 5,
}

local spin_speed = 10

local real_pitch = pitch_modes.none

local real_yaw = yaw_modes.jitter
local fake_yaw = yaw_modes.forward

---@param mode pitch_modes
local function get_pitch(mode)
    if mode == pitch_modes.none then
        return nil
    elseif mode == pitch_modes.up then
        return 89
    elseif mode == pitch_modes.fakeup then
        return -270
    elseif mode == pitch_modes.down then
        return -89
    elseif mode == pitch_modes.fakedown then
        return 270
    end
end

---@param mode yaw_modes
local function get_yaw_offset(mode)
    if mode == yaw_modes.forward then
        return 0
    elseif mode == yaw_modes.left then
        return 90
    elseif mode == yaw_modes.right then
        return -90
    elseif mode == yaw_modes.spin then
        return (((globals.TickCount()) % 180) - 180) * spin_speed
    elseif mode == yaw_modes.jitter then
        return ((globals.TickCount() % 2) == 0) and 90 or -90
    elseif mode == yaw_modes.back then
        return 180
    end
end

---@param cmd UserCmd
local function CreateMove(cmd)
    if cmd.buttons & IN_ATTACK ~= 0 or (input.IsButtonDown(gui.GetValue("aim key")) and aimbot.GetAimbotTarget() > 0) then return end
    if clientstate:GetChokedCommands() >= 21 then
        cmd.sendpacket = true
        return
    end
    local bsendpacket = (cmd.tick_count % 2) == 0
    cmd.sendpacket = bsendpacket

    local pitch, yaw_offset
    pitch = get_pitch(real_pitch)
    yaw_offset = get_yaw_offset(bsendpacket and fake_yaw or real_yaw)

    local x, y
    x = pitch or cmd.viewangles.x
    y = cmd.viewangles.y + yaw_offset
    cmd:SetViewAngles(x, y, 0)
end

callbacks.Register("CreateMove", "custom antiaim", CreateMove)
