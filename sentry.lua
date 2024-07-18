local settings = {
    speed = 1, -- is as low as you can get
    inverted = false,
    real = true, -- if real yaw changes
    fake = true, -- if fake yaw changes
}

local direction = 1 -- dont change plez

gui.SetValue("anti aim", 1)

gui.SetValue("anti aim - yaw (real)", (settings.real == true and "custom" or "none"))
gui.SetValue("anti aim - yaw (fake)", (settings.fake == true and "custom" or "none"))

local custom_yaw_real = "anti aim - custom yaw (real)"
local custom_yaw_fake = "anti aim - custom yaw (fake)"

gui.SetValue(custom_yaw_real, (settings.real == true and 0 or gui.GetValue(custom_yaw_real)))
gui.SetValue(custom_yaw_fake, (settings.fake == true and 0 or gui.GetValue(custom_yaw_fake)))

local yaw = 0

local function change_angle()
    if (yaw >= 45 or yaw <= -45)  then
        direction = -direction
    end

    local new_yaw = yaw + (settings.speed * direction * (settings.inverted == true and -1 or 1))

    if settings.real then
        gui.SetValue(custom_yaw_real, new_yaw)
    end

    if settings.fake then
        gui.SetValue(custom_yaw_fake, new_yaw)
    end

    yaw = new_yaw
end

callbacks.Register( "CreateMove", change_angle )
