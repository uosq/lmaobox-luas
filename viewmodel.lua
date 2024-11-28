local settings = {
	key = KEY_LSHIFT, -- activates the script
	look = MOUSE_RIGHT, -- makes your view go to where you are aiming (normal mode?),
	goback = KEY_R, -- recenters your aim to where you are looking
	crosshair = true,
	size = 6,
}

local color = draw.Color
local line = draw.Line

local register = callbacks.Register
local getconvar = client.GetConVar
local setconvar = client.SetConVar
local getlocalplayer = entities.GetLocalPlayer
local world_to_screen = client.WorldToScreen
local isbuttondown = input.IsButtonDown
local isbuttonreleased = input.IsButtonReleased
local isconsolevisible = engine.Con_IsVisible
local isgameuivisible = engine.IsGameUIVisible
local istakingscreenshot = engine.IsTakingScreenshot

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
local screenPos

---@param cmd UserCmd
callbacks.Register("CreateMove", function (cmd)
	local me = getlocalplayer()
	if not me then return end
	local source = me:GetAbsOrigin() + me:GetPropVector( "localdata", "m_vecViewOffset[0]" )
	local destination = source + engine.GetViewAngles():Forward() * 1000
	local trace = engine.TraceLine( source, destination, MASK_SHOT_HULL )
	local localscreenPos = world_to_screen(trace.endpos)
	screenPos = localscreenPos ~= nil and localscreenPos or screenPos
end)

---@param view ViewSetup
local function renderview(view)
	if isbuttondown(settings.key) then
		local viewangle = engine:GetViewAngles()

		if not debounce then
			debounce = true
			oldangle = viewangle
			selected_pitch = oldangle.pitch
			selected_yaw = oldangle.yaw
		end

		if isbuttondown(settings.look) then
			view.angles = viewangle
			oldangle = viewangle
			selected_pitch = oldangle.pitch
			selected_yaw = oldangle.yaw
		elseif input.IsButtonDown(settings.goback) then
			view.angles = oldangle
			engine.SetViewAngles(oldangle)
		else
			view.angles = EulerAngles(selected_pitch, selected_yaw, view.angles.z)
		end

	elseif isbuttonreleased(settings.key) then
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

if not settings.crosshair then return end

if getconvar("crosshair") ~= 0 then
	setconvar("crosshair", 0)
end

local function draw_crosshair (x, y)
	color(255,255,255,255)
	line(x, y-settings.size/2 - 10, x, y+settings.size/2 - 10) -- top
	line(x-settings.size/2 - 10, y, x+settings.size/2 - 10, y) -- left
	line(x+settings.size/2 + 10, y, x-settings.size/2 + 10, y) -- right
	line(x, y+settings.size/2 + 10, x, y-settings.size/2 + 10) -- bottom
end

register("Draw", function()
	if isconsolevisible() or isgameuivisible() or (gui.GetValue("clean screenshots") == 1 and istakingscreenshot()) then
		return
	end
	if screenPos then
		draw_crosshair(screenPos[1], screenPos[2])
	end
end)
