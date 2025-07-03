--- original by nullptr (goennigoegoe)
--- modified by navet

callbacks.Register("CreateMove", function(cmd)
	local plocal = entities.GetLocalPlayer()
	if not plocal then
		return
	end

	local target = (((gui.GetValue("fake lag value (ms)") + 15) / 1000) * 66.67) // 1

	if (cmd.tick_count % target) == 0 then
		plocal:SetPropFloat(globals.CurTime() - (target * globals.TickInterval()), "m_flAnimTime")
	else
		plocal:SetPropFloat(globals.CurTime() + 1, "m_flAnimTime")
	end
end)
