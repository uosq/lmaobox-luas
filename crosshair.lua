local crosshair_size = 6 -- i recommend between 6-12 as size, im not really good making crosshairs

local color = draw.Color
local line = draw.Line
local register = callbacks.Register
local getconvar = client.GetConVar
local setconvar = client.SetConVar

if getconvar("crosshair") ~= 0 then
	setconvar("crosshair", 0)
end

if getconvar("crosshair") ~= 0 then
	setconvar("crosshair", 0)
end

local function draw_crosshair (x, y)
    line(x, y-crosshair_size/2 - 10, x, y+crosshair_size/2 - 10) -- top
    line(x-crosshair_size/2 - 10, y, x+crosshair_size/2 - 10, y) -- left
    line(x+crosshair_size/2 + 10, y, x-crosshair_size/2 + 10, y) -- right
    line(x, y+crosshair_size/2 + 10, x, y-crosshair_size/2 + 10) -- top
end

local color = {
	[E_TeamNumber.TEAM_BLU] = {255, 150, 150, 255},
	[E_TeamNumber.TEAM_RED] = {150, 150, 255, 255},
	[E_TeamNumber.TEAM_SPECTATOR] = {255,255,255,255},
	[E_TeamNumber.TEAM_UNASSIGNED] = {255,255,255,255}
}

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
    local cross_color = color[me:GetTeamNumber()]
    draw.Color(cross_color[1], cross_color[2], cross_color[3], cross_color[4])
    draw_crosshair(screenPos[1], screenPos[2])
end)

register("Unload", function()
    setconvar("crosshair", 1)
end)
