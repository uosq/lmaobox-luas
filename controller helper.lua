local E_ControllerCodes = {
   DPAD_LEFT = 149,
   DPAD_UP = 145,
   DPAD_RIGHT = 147,
   DPAD_DOWN = 148,
   SELECT = 120,
   --START couldn't get,
   A = 114,
   B = 115,
   X = 116,
   Y = 117,
   LEFT_SHOULDER = 118,
   RIGHT_SHOULDER = 119,
   LEFT_TRIGGER = 154,
   RIGHT_TRIGGER = 155,
   LEFT_STICK_CLICK = 122,
   RIGHT_STICK_CLICK = 123,
}

local RIGHT_SHOULDER = 0x2000
local LEFT_SHOULDER = 0x1000

local left_last_tick = 0
local right_last_tick = 0

callbacks.Register("CreateMove", function (param)
   local state, tick = input.IsButtonPressed(E_ControllerCodes.RIGHT_SHOULDER)
   if state and tick ~= right_last_tick then
      right_last_tick = tick
      local viewangle = engine:GetViewAngles()
      local new_angle = viewangle - Vector3(0,90,0)
      new_angle = EulerAngles(new_angle.x, new_angle.y, new_angle.z)
      engine.SetViewAngles(new_angle)
   end

   local state, tick = input.IsButtonPressed(E_ControllerCodes.LEFT_SHOULDER)
   if state and tick ~= left_last_tick then
      left_last_tick = tick
      local viewangle = engine:GetViewAngles()
      local new_angle = viewangle + Vector3(0,90,0)
      new_angle = EulerAngles(new_angle.x, new_angle.y, new_angle.z)
      engine.SetViewAngles(new_angle)
   end
end)