local settings = {
    speed = 1,
    inverted = false,
    real = true, -- if real yaw changes
    fake = true, -- if fake yaw changes
}

local direction = 1 -- dont change plez

gui.SetValue("anti aim", 1)

gui.SetValue("anti aim - yaw (real)", (settings.real == true and "custom" or "none"))
gui.SetValue("anti aim - yaw (fake)", (settings.fake == true and "custom" or "none"))

gui.SetValue("anti aim - custom yaw (real)", (settings.real == true and 0 or gui.GetValue("anti aim - custom yaw (real)")))
gui.SetValue("anti aim - custom yaw (fake)", (settings.real == true and 0 or gui.GetValue("anti aim - custom yaw (fake)")))

local function change_angle()
    local yaw = gui.GetValue( "anti aim - custom yaw (fake)" )
    if (yaw >= 45 or yaw <= -45) then
        direction = -direction
    end

    local new_yaw = yaw + (settings.speed * direction * (settings.inverted == true and -1 or 1))

    gui.SetValue( "anti aim - custom yaw (real)", (settings.real == true and new_yaw or 0) )
    gui.SetValue( "anti aim - custom yaw (fake)", (settings.fake == true and new_yaw or 0) )
end

callbacks.Register( "CreateMove", change_angle )
