--- original by nullptr (goennigoegoe)
--- modified by navet

callbacks.Register("CreateMove", function(cmd)
	local plocal = entities.GetLocalPlayer()
	if not plocal then
		return
	end

	if (cmd.tick_count % 21) == 0 then
		plocal:SetPropFloat(globals.CurTime() - (21 * globals.TickInterval()), "m_flAnimTime")
	else
		plocal:SetPropFloat(globals.CurTime() + 1, "m_flAnimTime")
	end
end)
