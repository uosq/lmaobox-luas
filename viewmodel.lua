local crosshair_size = 6

local color = draw.Color
local line = draw.Line
local register = callbacks.Register
local get_target = aimbot.GetAimbotTarget
local getbyindex = entities.GetByIndex
local get_studio_model = models.GetStudioModel
local worldtoscreen = client.WorldToScreen
local width, height = draw.GetScreenSize()
local vector3 = Vector3
local getconvar = client.GetConVar
local setconvar = client.SetConVar
local getvalue = gui.GetValue

local oldangle = EulerAngles()
local debounce = false

local selected_pitch, selected_yaw

if engine.GetServerIP() then
    client.ChatPrintf("\x05Your aim method has been changed to PLAIN")
    client.ChatPrintf("\x05When pressing your AIM KEY the script will turn on!!!")
end

printc(255, 100, 100, 255, "Your aim method has been changed to PLAIN")
gui.SetValue("aim method", "plain")
printc(255, 100, 100, 255, "When pressing your AIM KEY the script will turn on!!!")

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
        engine.SetViewAngles(oldangle)
        view.angles = engine.GetViewAngles()
        debounce = false
    end
end

callbacks.Register("RenderView", renderview)

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
    local current_target = get_target()
    if current_target ~= nil and current_target > 0 then
        local player = getbyindex(current_target)
        if not player or not player:IsValid() then return end

        local model = player:GetModel()
        local studioHdr = get_studio_model(model)

        local myHitBoxSet = player:GetPropInt("m_nHitboxSet")
        local hitboxSet = studioHdr:GetHitboxSet(myHitBoxSet)
        local hitboxes = hitboxSet:GetHitboxes()
        local boneMatrices = player:SetupBones()
        local hitbox = hitboxes[5] -- "chest" hitbox
        local bone = hitbox:GetBone()

        local boneMatrix = boneMatrices[bone]

        if boneMatrix ~= nil then
            local bonePos = vector3( boneMatrix[1][4], boneMatrix[2][4], boneMatrix[3][4] )
            local screenPos = worldtoscreen(bonePos)
            if not screenPos then return end
            draw_crosshair(screenPos[1], screenPos[2])
        end
        else
        draw_crosshair(width/2, height/2)
    end
end)

register("Unload", function()
    setconvar("crosshair", 1)
    gui.SetValue("aim method", "silent") -- "silent+" doesnt work for some reason
    printc(100,255,100,255, "Your aim method has been changed to SILENT")
    client.ChatPrintf("\x04Your aim method has been changed to SILENT")
end)
