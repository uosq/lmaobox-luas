local settings = {
	key = KEY_LSHIFT, -- activates the script
	look = MOUSE_RIGHT, -- makes your view go to where you are aiming (normal mode?),
	goback = KEY_R, -- recenters your aim to where you are looking
}

local crosshair_enable = true
local crosshair_size = 6

local color = draw.Color
local line = draw.Line

local register = callbacks.Register
local getconvar = client.GetConVar
local setconvar = client.SetConVar

local oldangle = EulerAngles()
local debounce = false

local old_method = gui.GetValue("aim method")
gui.SetValue("aim method", "plain")
print("There are settings you can change on " .. GetScriptName())
printc(255, 150, 150, 255, "Your aim method has been changed to plain")
if engine:GetServerIP() then
	client.ChatPrintf("\x05[LMAOBOX] \x01There are settings you can change on " .. GetScriptName())
	client.ChatPrintf("\x05Your aim method has been changed to plain")
end

local selected_pitch, selected_yaw = engine:GetViewAngles():Unpack()

---@param view ViewSetup
local function renderview(view)
	if input.IsButtonDown(settings.key) then
		if not debounce then
			debounce = true
			oldangle = engine.GetViewAngles()
			selected_pitch = oldangle.pitch
			selected_yaw = oldangle.yaw
		end

		if input.IsButtonDown(settings.look) then
			view.angles = engine:GetViewAngles()
			oldangle = engine.GetViewAngles()
			selected_pitch = oldangle.pitch
			selected_yaw = oldangle.yaw
		elseif input.IsButtonDown(settings.goback) then
			view.angles = oldangle
			engine.SetViewAngles(oldangle)
		else
			view.angles = EulerAngles(selected_pitch, selected_yaw, view.angles.z)
		end

	elseif input.IsButtonReleased(settings.key) then
		view.angles = oldangle
		engine.SetViewAngles(oldangle)
		debounce = false
	end
end

register("RenderView", renderview)

register("Unload", function()
	if getconvar("crosshair") == 0 then
		setconvar("crosshair", 1)
	end

	gui.SetValue("aim method", tostring(old_method))
	client.ChatPrintf("\x05Your aim method has been changed to " .. tostring(old_method))
	printc(150, 255, 150, 255, "Your aim method has been changed to " .. tostring(old_method))
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
