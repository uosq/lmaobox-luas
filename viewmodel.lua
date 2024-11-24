local crosshair_enable = true
local crosshair_size = 6

local color = draw.Color
local line = draw.Line

local register = callbacks.Register
local getconvar = client.GetConVar
local setconvar = client.SetConVar
local getvalue = gui.GetValue

local oldangle = EulerAngles()
local debounce = false

local selected_pitch, selected_yaw

printc(255, 100, 100, 255, "When pressing your AIM KEY the script will turn on!!!")
if engine.GetServerIP() then
    client.ChatPrintf("\x05When pressing your AIM KEY the script will turn on!!!")
end

callbacks.Register("CreateMove", function ()
    local silent = gui.GetValue("aim method") == "silent"
    if not silent then return end
    if aimbot.GetAimbotTarget() > 0 and input.IsButtonDown(gui.GetValue("aim key")) then
        local me = entities.GetLocalPlayer()
        if not me then return end

        local pitch, yaw = me:GetPropVector("tfnonlocaldata","m_angEyeAngles[0]"):Unpack()
        engine.SetViewAngles(EulerAngles(pitch, yaw, 0))

    elseif aimbot.GetAimbotTarget() <= 0 and debounce then
        engine.SetViewAngles(oldangle)
    end
end)

---@param view ViewSetup
local function renderview(view)

    if input.IsButtonDown(getvalue("aim key")) then
        if not debounce then
            debounce = true
            oldangle = engine.GetViewAngles()
            selected_pitch = oldangle.pitch
            selected_yaw = oldangle.yaw
        end

        view.angles = EulerAngles(selected_pitch, selected_yaw, view.angles.z)

    elseif input.IsButtonReleased(gui.GetValue("aim key")) then
        view.angles = oldangle
        engine.SetViewAngles(oldangle)
        debounce = false
    end
end

callbacks.Register("RenderView", renderview)

register("Unload", function()
    if getconvar("crosshair") == 0 then
        setconvar("crosshair", 1)
    end
end)


if not crosshair_enable then
    return
end

if getconvar("crosshair") ~= 0 then
	setconvar("crosshair", 0)
end

local function draw_crosshair (x, y)
    color(255,255,255,255)
    line(x, y-crosshair_size/2 - 10, x, y+crosshair_size/2 - 10) -- top
    line(x-crosshair_size/2 - 10, y, x+crosshair_size/2 - 10, y) -- left
    line(x+crosshair_size/2 + 10, y, x-crosshair_size/2 + 10, y) -- right
    line(x, y+crosshair_size/2 + 10, x, y-crosshair_size/2 + 10) -- top
end

register("Draw", function()
    if engine.Con_IsVisible() or engine.IsGameUIVisible() or (gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot()) then
        return
    end

    local me = entities.GetLocalPlayer();
    if not me then return end
    local source = me:GetAbsOrigin() + me:GetPropVector( "localdata", "m_vecViewOffset[0]" );
    local destination = source + engine.GetViewAngles():Forward() * 1000;
    local trace = engine.TraceLine( source, destination, MASK_SHOT_HULL );

    local screenPos = client.WorldToScreen(trace.endpos)
    if not screenPos then return end
    draw_crosshair(screenPos[1], screenPos[2])
end)
