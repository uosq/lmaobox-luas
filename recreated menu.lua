local LBOX_Styles = {
  multi = 1 << 0,
  checkbox = 1 << 1,
  -- wont make lua tab yet
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
    ["aim bot"] = {
      style = LBOX_Styles.checkbox,
    },
  },
}

local tabs = { aimbot = "aimbot", trigger = "trigger", esp = "esp", radar = "radar", visual = "visual", misc = "misc" }
local current_tab = tabs.aimbot

local window = {
	x = 0,
	y = 0,
	colors = {
		background = { 30, 30, 30, 252 }, --- default dark color
	},
}

local function is_mouse_inside(object)
  local mousePos = input.GetMousePos()
  local mx, my = mousePos[1], mousePos[2]
  return mx >= object.x + (window.x and mx <= object.x + object.width + window.x and
    my >= object.y + window.y and my <= object.y + object.height + window.y
end

local option_width, option_height = 280, 20
local option_startY = 25

local function change_color(color)
	draw.Color(color[1], color[2], color[3], color[4])
end

local function RenderWindow()
  local size = {x = 0, y = 0}
  local index = 0
  for key, value in pairs (options[current_tab]) do
    local y = window.y + startY
  end
end

callbacks.Register("Draw", "RecreatedLboxMenu", RenderWindow)
