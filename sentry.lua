local settings = {
    speed = 0.7,
    inverted = false,
}

print("I recommend using smooth aimbot")

local direction = 1 -- dont change plez

local pitch,yaw,roll = engine.GetViewAngles():Unpack()

local yaw_max_left = yaw + 45
local yaw_max_right = yaw - 45

local function change_angle()
    local has_target = aimbot.GetAimbotTarget()
    if has_target > 0 then
        pitch,yaw,roll = engine.GetViewAngles():Unpack()
        yaw_max_left = yaw + 45
        yaw_max_right = yaw - 45
        goto lul
    end
    
    if (yaw >= yaw_max_left or yaw <= yaw_max_right) then
        direction = -direction
    end

    local new_yaw = yaw + (settings.speed * direction * (settings.inverted == true and -1 or 1))
    engine.SetViewAngles( EulerAngles( pitch, new_yaw, roll ) )
    yaw = new_yaw

    ::lul::
end

callbacks.Register( "CreateMove", change_angle )
