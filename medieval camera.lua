local oldOrigin = Vector3()
local targetOrigin = Vector3()

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function VecLerp(a, b, t)
	local c = Vector3()
	c.x = Lerp(a.x, b.x, t)
	c.y = Lerp(a.y, b.y, t)
	c.z = Lerp(a.z, b.z, t)
	return c
end

---@param view ViewSetup
local function RenderView(view)
    local plocal = entities.GetLocalPlayer()
    if not plocal or not plocal:GetPropBool("m_nForceTauntCam") then
        return
    end

    local angles = engine.GetViewAngles()
    local forward, right, up = angles:Forward(), angles:Right(), angles:Up()
    local origin = view.origin + forward * 12.5 + right * 25.0 + up * -10.0

	local trace = engine.TraceHull(view.origin, origin, Vector3(-10,-10,-10), Vector3(10,10,10), MASK_SHOT_HULL, function() return true end)

    targetOrigin = trace.endpos

	if trace.fraction >= 1.0 then
		view.origin = targetOrigin
	else
		view.origin = Lerp(oldOrigin, targetOrigin, 0.05)
	end

    oldOrigin = Vector3(view.origin.x, view.origin.y, view.origin.z)
end

callbacks.Register("RenderView", RenderView)