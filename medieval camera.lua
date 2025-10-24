--- made by navet
--- thirdperson medieval camera

local function RenderView(view)
	local plocal = entities.GetLocalPlayer()
	if plocal == nil then
		return
	end

	--- thirdperson?
	if plocal:GetPropBool("m_nForceTauntCam") == false then
		return
	end

	local forward, right, up, angles
	angles = engine.GetViewAngles()
	forward = angles:Forward()
	right = angles:Right()
	up = angles:Up()

	local origin = view.origin
	origin = origin + forward * 12.5
	origin = origin + right * 25.0
	origin = origin + up * -10.0

	view.origin = origin
end

callbacks.Register("RenderView", RenderView)
