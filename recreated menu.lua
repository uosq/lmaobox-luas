local LBOX_Styles = {
	multi = 1 << 0,
	checkbox = 1 << 1,
	key = 1 << 2,
	number = 1 << 3,
	-- wont make lua tab yet
}

local LBOX_Sides = {
	left = 1 << 0,
	right = 1 << 1,
}

local options = {
	--[[
  tab = {
    option1 = {
      style = LBOX_Styles.multi,
      range = 3 (the indexes are 1 to 3), --- only works with multi
      text = "",
    },
    option2 = {
      style = LBOX_Styles.checkbox,
      text = "",
    },
  }
  --]]
	aimbot = {
		size = 475,
		{
			label = "aimbot",
			name = "aim bot",
			style = LBOX_Styles.checkbox,
			side = LBOX_Sides.left,
		},
		{
			label = "aimkey",
			name = "aim key",
			style = LBOX_Styles.checkbox,
			side = LBOX_Sides.left,
		},
	},
}

local tabs = { aimbot = "aimbot", trigger = "trigger", esp = "esp", radar = "radar", visual = "visual", misc = "misc" }
local current_tab = tabs.aimbot
local font <const> = draw.CreateFont("TF2 BUILD", 12, 1000, FONTFLAG_CUSTOM | FONTFLAG_OUTLINE)
local last_keypress_tick = 0

local window = {
	x = 0,
	y = 0,
	width = 770,
	colors = {
		background = { 30, 30, 30, 252 }, --- default dark color
		--background = { 200, 200, 200, 250 },
	},
}

local function is_mouse_inside(object)
	local mousePos = input.GetMousePos()
	local mx, my = mousePos[1], mousePos[2]
	return mx >= object.x + window.x
		and mx <= object.x + object.width + window.x
		and my >= object.y + window.y
		and my <= object.y + object.height + window.y
end

local option_width, option_height = 280, 20
local option_startY = 20 --- 25?

local function change_color(color)
	draw.Color(color[1], color[2], color[3], color[4])
end

---@param index integer
---@param name string
---@param side integer LBOX_Sides
---@param color integer[]
---@param label string
local function DrawCheckbox(index, label, name, side, color)
	local x, y, width, height
	x = window.x + (side == LBOX_Sides.left and 162 or 275)
	y = window.y + (option_startY * index)
	width = x + option_width
	height = y + option_height

	change_color(color)
	draw.FilledRect(x, y, width, height)

	draw.SetFont(font)
	draw.Color(255, 255, 255, 255)
	draw.Text(x + 10, y + 5, label)

	local state, tick = input.IsButtonPressed(E_ButtonCode.MOUSE_LEFT)

	if state and tick > last_keypress_tick and is_mouse_inside({ x = x, y = y, width = width, height = height }) then
		last_keypress_tick = tick
		local val = gui.GetValue(name)
		gui.SetValue(name, val == 1 and 0 or 1)
	end
end

local function RenderWindow()
	change_color(window.colors.background)
	draw.FilledRect(window.x, window.y, window.x + window.width, window.y + options[current_tab].size)

	local localplayer_isRed = entities:GetLocalPlayer():GetTeamNumber() == 2
	local color = localplayer_isRed and { 236, 57, 57, 255 } or { 12, 116, 191, 255 }
	change_color(color)
	draw.FilledRect(window.x, window.y, window.x + window.width, window.y + 7)

	for key, option in pairs(options) do
		local index = 1
		for value in pairs(option) do
			if type(value) == "table" then
				index = index + 1
				if value.style == LBOX_Styles.checkbox then
					DrawCheckbox(index, value.label, value.option, value.side, color)
				end
			end
		end
	end
end

callbacks.Unregister("Draw", "RecreatedLboxMenu")
callbacks.Register("Draw", "RecreatedLboxMenu", RenderWindow)
