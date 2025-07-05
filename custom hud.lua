--- made by navet

local font = draw.CreateFont("TF2 BUILD", 16, 600)

local health_unformatted = "%s / %s"
local ammo_unformatted = "%s / %s"

---@alias RGB {[1]: integer, [2]: integer, [3]: integer}

---@param color RGB?
---@param x integer
---@param y integer
---@param text string
local function DrawText(color, x, y, text)
	draw.Color(41, 46, 57, 255)
	draw.Text(x + 1, y + 1, text)

	if color then
		draw.Color(color[1], color[2], color[3], 255)
	else
		draw.Color(236, 239, 244, 255)
	end
	draw.Text(x, y, text)
end

local function DrawCrosshair(center_x, center_y)
	local size = 8
	draw.Color(136, 192, 208, 255)
	draw.Line(center_x, center_y, center_x + size, center_y) -- x--
	draw.Line(center_x - size, center_y, center_x, center_y) -- --x
	draw.Line(center_x, center_y - size, center_x, center_y + size) -- center to top
	draw.Line(center_x, center_y, center_x, center_y + size) -- center to bottom
end

local function Draw()
	if client.GetConVar("_cl_classmenuopen") == 1 then
		if client.GetConVar("cl_drawhud") == 0 then
			client.SetConVar("cl_drawhud", 1)
		end
		return
	end

	local plocal = entities.GetLocalPlayer()
	if not plocal then
		return
	end

	local current_weapon = plocal:GetPropEntity("m_hActiveWeapon")
	if not current_weapon then
		return
	end

	if engine.IsTakingScreenshot() and client.GetConVar("cl_drawhud") == 0 then
		client.SetConVar("cl_drawhud", 1)
		return
	elseif engine.IsTakingScreenshot() then
		return
	end

	if engine.IsChatOpen() and client.GetConVar("cl_drawhud") == 0 then
		client.SetConVar("cl_drawhud", 1)
		return
	elseif engine.IsChatOpen() then
		return
	end

	if engine.IsGameUIVisible() and client.GetConVar("cl_drawhud") == 0 then
		client.SetConVar("cl_drawhud", 1)
		return
	elseif engine.IsGameUIVisible() then
		return
	end

	if client.GetConVar("cl_drawhud") == 1 then
		client.SetConVar("cl_drawhud", 0)
	end

	local screen_w, screen_h = draw.GetScreenSize()
	local center_x, center_y = screen_w // 2, screen_h // 2
	local start_y = center_y + 20

	draw.SetFont(font)

	local health = plocal:GetHealth()
	local max_health = plocal:GetMaxHealth()
	local health_ratio = health / max_health

	local health_text = string.format(health_unformatted, health, max_health)
	local health_w, health_h = draw.GetTextSize(health_text)

	if health_ratio >= 0.5 then
		DrawText({ 163, 190, 140 }, center_x - (health_w // 2), start_y, health_text)
	else
		DrawText({ 191, 97, 106 }, center_x - (health_w // 2), start_y, health_text)
	end

	start_y = start_y + health_h + 5

	if not current_weapon:IsMeleeWeapon() then
		local is_primary = current_weapon:GetLoadoutSlot() == E_LoadoutSlot.LOADOUT_POSITION_PRIMARY
		local ammo_datatable = plocal:GetPropDataTableInt("m_iAmmo")
		local clip1 = current_weapon:GetPropInt("m_iClip1")
		local primary_clip2, secondary_clip2 = ammo_datatable[2], ammo_datatable[3]

		local ammo_text = ""

		if clip1 ~= -1 and clip1 then
			ammo_text = is_primary and string.format(ammo_unformatted, clip1, primary_clip2)
				or string.format(ammo_unformatted, clip1, secondary_clip2)
		else
			ammo_text = string.format("%s", primary_clip2)
		end

		local ammo_w, ammo_h = draw.GetTextSize(ammo_text)
		DrawText({ 180, 142, 173 }, center_x - (ammo_w // 2), start_y, ammo_text)

		start_y = start_y + ammo_h + 5
	end

	if plocal:GetPropInt("m_iClass") == E_Character.TF2_Engineer then
		local ammo_datatable = plocal:GetPropDataTableInt("m_iAmmo")
		local quantity = ammo_datatable[4]
		local text = string.format("%i/200", quantity)
		local metal_w, metal_h = draw.GetTextSize(text)

		DrawText({ 235, 203, 139 }, center_x - (metal_w // 2), start_y, text)

		start_y = start_y + metal_h + 10

		if current_weapon:GetLoadoutSlot() == 3 or current_weapon:GetLoadoutSlot() == 4 then
			local buildings = { "sentry", "dispenser", "teleporter", "teleporter (e)" }

			local total_size = 0

			for i = 1, 4 do
				local w = draw.GetTextSize(buildings[i])
				total_size = (total_size + w) // 1
			end

			local text_x = center_x - (total_size // 2)
			local text_y = start_y

			for i = 1, 4 do
				local text_w, text_h = draw.GetTextSize(buildings[i])

				DrawText(nil, text_x, text_y, buildings[i])

				local number = tostring(i)
				local number_w, _ = draw.GetTextSize(number) --- fucking stupid
				local number_x, number_y
				number_x = text_x + (text_w // 2) - (number_w // 2)
				number_y = text_y + (text_h // 1) + 5

				DrawText(nil, number_x, number_y, number)

				text_x = text_x + (text_w // 1) + 5
			end
		end
	elseif plocal:GetPropInt("m_iClass") == E_Character.TF2_Spy then
		local cloak = plocal:GetPropFloat("m_flCloakMeter")
		local cloak_ratio = cloak / 100 --- 100 is max cloak
		local width, height = 100, 10
		local x, y = center_x - (width * 0.5), start_y

		draw.Color(67, 76, 94, 255)
		draw.FilledRect(x, y, x + width, y + height)

		draw.Color(236, 239, 244, 255)
		draw.FilledRect(x, y, x + (width * cloak_ratio) // 1, y + height)

		start_y = start_y + y + height + 5
	elseif plocal:GetPropInt("m_iClass") == E_Character.TF2_Sniper then
		local width, height = 100, 10
		local x, y = center_x - (width * 0.5), start_y
		if plocal:InCond(E_TFCOND.TFCond_Zoomed) then
			local MACHINA_INDEX = 526
			local multiplier = current_weapon:GetPropInt("m_Item", "m_iItemDefinitionIndex") == MACHINA_INDEX and 1.15
				or 1
			local current_charge = current_weapon:GetPropFloat("SniperRifleLocalData", "m_flChargedDamage")
			local max_charge = 150 * multiplier
			local charge_ratio = current_charge / max_charge

			--- sniper charge
			draw.Color(67, 76, 94, 255)
			draw.FilledRect(x, y, x + width, y + height)

			draw.Color(236, 239, 244, 255)
			draw.FilledRect(x, y, x + (width * charge_ratio) // 1, y + height)

			start_y = start_y + height + 5
		end

		--- jarate
		local last_firetime =
			plocal:GetEntityForLoadoutSlot(E_LoadoutSlot.LOADOUT_POSITION_SECONDARY):GetPropFloat("m_flLastFireTime")

		local jarate_ratio = math.min((globals.CurTime() - last_firetime) / 20, 1) --- clamp to max 1

		if plocal:GetPropDataTableInt("m_iAmmo")[5] == 1 then
			jarate_ratio = 1
		end

		y = start_y

		draw.Color(67, 76, 94, 255)
		draw.FilledRect(x, y, x + width, y + height)

		draw.Color(235, 203, 139, 255)
		draw.FilledRect(x, y, x + (width * jarate_ratio) // 1, y + height)

		start_y = start_y + height + 5
	elseif plocal:GetPropInt("m_iClass") == E_Character.TF2_Demoman then
		if current_weapon:GetClass() == "CTFPipebombLauncher" then
			local width, height, x, y
			width, height = 100, 10
			x, y = center_x - (width // 2), start_y

			local MAX_CHARGE_STOCK = 4 --- seconds
			local MAX_CHARGE_QUICKIE = 1.2 --- seconds

			--- not sure if this works
			local chosen_max = current_weapon:AttributeHookFloat("sticky_arm_time") == 1 and MAX_CHARGE_STOCK
				or MAX_CHARGE_QUICKIE

			local charge_ratio = (
				globals.CurTime() - current_weapon:GetPropFloat("PipebombLauncherLocalData", "m_flChargeBeginTime")
			) / chosen_max

			if charge_ratio > chosen_max then
				charge_ratio = 0
			end

			draw.Color(67, 76, 94, 255)
			draw.FilledRect(x, y, x + width, y + height)

			draw.Color(236, 239, 244, 255)
			draw.FilledRect(x, y, x + (width * charge_ratio) // 1, y + height)

			start_y = start_y + height + 5
		end

		local sticky_count = plocal
			:GetEntityForLoadoutSlot(E_LoadoutSlot.LOADOUT_POSITION_SECONDARY)
			:GetPropInt("PipebombLauncherLocalData", "m_iPipebombCount")

		local sticky_text = tostring(sticky_count)
		local sticky_w, sticky_h = draw.GetTextSize(sticky_text)

		DrawText(nil, center_x - (sticky_w // 2), start_y, sticky_text)

		start_y = start_y + sticky_h + 5
	end

	DrawCrosshair(center_x, center_y)
end

callbacks.Register("Draw", Draw)
