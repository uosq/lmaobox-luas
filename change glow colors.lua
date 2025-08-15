--- made by navet

---@diagnostic disable: duplicate-set-field, undefined-field, redefined-local, cast-local-type

-- =============================================================================
-- CONSTANTS AND CONFIGURATION
-- =============================================================================

local OUTLINE_THICKNESS = 1
local TAB_BUTTON_WIDTH = 120
local TAB_BUTTON_HEIGHT = 25
local TAB_BUTTON_MARGIN = 2
local HEADER_SIZE = 25
local COMPONENT_TYPES = {
	BUTTON = 1,
	CHECKBOX = 2,
	SLIDER = 3,
	DROPDOWN = 4,
	LISTBOX = 5,
	COLORED_SLIDER = 6,
}

-- =============================================================================
-- MODULE STATE
-- =============================================================================

local draw_id = tostring(os.clock())
local font = draw.CreateFont("TF2 BUILD", 12, 1000)
local last_keypress_tick = 0

local deferred_dropdowns = {}

---@type table<integer, WINDOW>
local windows = {}

---@type WINDOW?
local current_window_context = nil

---@type BUTTON|CHECKBOX|SLIDER|DROPDOWN|LISTBOX
local current_component = nil

---@type SLIDER?
local dragging_slider = nil

---@type WINDOW?
local dragging_window = nil
local oldmx, oldmy = 0, 0
local dx, dy = 0, 0

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

local function clamp(value, min_val, max_val)
	return math.max(min_val, math.min(max_val, value))
end

local function is_mouse_inside(x1, y1, x2, y2)
	local mouse = input.GetMousePos()
	local mx, my = table.unpack(mouse)
	return mx >= x1 and mx <= x2 and my >= y1 and my <= y2
end

local function get_current_window_tab()
	local window = current_window_context
	if not window then
		error("Current window context is nil!")
		return nil
	end

	-- If no tabs exist, return 0 (will be handled by make_new_component)
	if #window.tabs == 0 then
		return 0
	end

	return #window.tabs
end

local function get_content_area_offset()
	local window = current_window_context
	if not window or #window.tabs <= 1 then
		return 0
	end
	return TAB_BUTTON_WIDTH + (TAB_BUTTON_MARGIN * 2) -- add margin on both sides
end

local function get_new_component_index()
	local window = current_window_context
	assert(window, "Window context is nil!")

	-- If no tabs exist, create a default one
	if #window.tabs == 0 then
		table.insert(window.tabs, {
			name = "",
			components = {},
		})
	end

	return #window.tabs[#window.tabs].components + 1
end

local function make_new_component(component)
	local window = current_window_context
	if not window then
		return nil
	end

	-- If no tabs exist, create a default one
	if #window.tabs == 0 then
		table.insert(window.tabs, {
			name = "",
			components = {},
		})
	end

	local current_tab = get_current_window_tab()
	local index = get_new_component_index()

	window.tabs[current_tab].components[index] = component
	return window.tabs[current_tab].components[index]
end

-- =============================================================================
-- INPUT HANDLING
-- =============================================================================

local function handle_tab_button_click(window, tab_index)
	local tab_x = window.x + TAB_BUTTON_MARGIN -- Add margin to x position
	local tab_y = window.y + (tab_index - 1) * (TAB_BUTTON_HEIGHT + TAB_BUTTON_MARGIN)
	local tab_x2 = tab_x + TAB_BUTTON_WIDTH
	local tab_y2 = tab_y + TAB_BUTTON_HEIGHT

	if is_mouse_inside(tab_x, tab_y, tab_x2, tab_y2) then
		local state, tick = input.IsButtonPressed(E_ButtonCode.MOUSE_LEFT)
		if state and tick > last_keypress_tick then
			-- Set active tab for THIS specific window (my stupid brain is stupid)
			window.active_tab_index = tab_index
			last_keypress_tick = tick
		end
		return true
	end
	return false
end

local function handle_slider_drag()
	local window = current_window_context
	if not window then
		error("Current window context is nil!")
		return
	end

	local component = current_component
	local content_offset = get_content_area_offset()

	local slider_x = component.x + window.x + content_offset
	local slider_y = component.y + window.y
	local slider_w = component.width
	local slider_h = component.height

	-- Check if mouse is over the slider area
	if is_mouse_inside(slider_x, slider_y, slider_x + slider_w, slider_y + slider_h) then
		-- Start dragging if mouse is pressed and no other slider is being dragged
		if input.IsButtonDown(E_ButtonCode.MOUSE_LEFT) and dragging_slider == nil then
			dragging_slider = component
		end
	end

	-- Handle dragging
	if dragging_slider == component and input.IsButtonDown(E_ButtonCode.MOUSE_LEFT) then
		local mouse = input.GetMousePos()
		local mx = mouse[1]

		-- Calculate new value based on mouse position
		local relative_x = mx - slider_x
		local progress = clamp(relative_x / slider_w, 0, 1)

		-- Update slider value
		component.value = component.min + progress * (component.max - component.min)

		-- Call callback if exists
		if component.func then
			---@diagnostic disable-next-line: missing-parameter
			component.func(component.value)
		end
	end

	-- Stop dragging when mouse is released
	if dragging_slider == component and not input.IsButtonDown(E_ButtonCode.MOUSE_LEFT) then
		dragging_slider = nil
	end
end

local function handle_window_drag()
	local window = current_window_context
	assert(window, "Window context is nil! WTF")

	if input.IsButtonReleased(E_ButtonCode.MOUSE_LEFT) and dragging_window == window then
		dragging_window = nil
	end

	local state, tick = input.IsButtonPressed(E_ButtonCode.MOUSE_LEFT)

	if
		not dragging_slider
		and state
		and tick > last_keypress_tick
		and is_mouse_inside(window.x, window.y - HEADER_SIZE, window.x + window.width, window.y)
	then
		last_keypress_tick = tick
		dragging_window = window
	end

	if dragging_window == window then
		window.x = window.x + dx
		window.y = window.y + dy
	end
end

-- =============================================================================
-- COMPONENT RENDERING
-- =============================================================================

local function draw_tab_buttons(window)
	if #window.tabs <= 1 then
		return
	end

	for i, tab in ipairs(window.tabs) do
		local tab_x = window.x + TAB_BUTTON_MARGIN -- Add margin to x position
		local tab_y = window.y + (i - 1) * (TAB_BUTTON_HEIGHT + TAB_BUTTON_MARGIN)
		-- Use window-specific active tab index (or 1 if it's a single tab window (no tabs basically))
		local is_active = (i == (window.active_tab_index or 1))
		local is_hovered = handle_tab_button_click(window, i)

		-- Draw tab button outline
		--[[draw.Color(143, 188, 187, 255)
		draw.FilledRect(
			tab_x - OUTLINE_THICKNESS,
			tab_y - OUTLINE_THICKNESS,
			tab_x + TAB_BUTTON_WIDTH + OUTLINE_THICKNESS,
			tab_y + TAB_BUTTON_HEIGHT + OUTLINE_THICKNESS
		)]]

		-- Draw tab button background
		if is_active then
			draw.Color(76, 86, 106, 255) -- Active tab color
		elseif is_hovered then
			draw.Color(67, 76, 94, 255) -- Hovered tab color
		else
			draw.Color(59, 66, 82, 255) -- Normal tab color
		end

		draw.FilledRect(tab_x, tab_y, tab_x + TAB_BUTTON_WIDTH, tab_y + TAB_BUTTON_HEIGHT)

		-- Draw tab button text
		if tab.name and tab.name ~= "" then
			draw.SetFont(font)
			local tw, th = draw.GetTextSize(tab.name)
			draw.Color(236, 239, 244, 255)
			draw.Text(
				tab_x + (TAB_BUTTON_WIDTH // 2) - (tw // 2),
				tab_y + (TAB_BUTTON_HEIGHT // 2) - (th // 2),
				tab.name
			)
		end
	end
end

--- source: https://gist.github.com/GigsD4X/8513963
local function HSVToRGB( hue, saturation, value )
	-- Returns the RGB equivalent of the given HSV-defined color
	-- (adapted from some code found around the web)

	-- If it's achromatic, just return the value
	if saturation == 0 then
		return value, value, value;
	end;

	-- Get the hue sector
	local hue_sector = math.floor( hue / 60 );
	local hue_sector_offset = ( hue / 60 ) - hue_sector;

	local p = value * ( 1 - saturation );
	local q = value * ( 1 - saturation * hue_sector_offset );
	local t = value * ( 1 - saturation * ( 1 - hue_sector_offset ) );

	if hue_sector == 0 then
		return value, t, p;
	elseif hue_sector == 1 then
		return q, value, p;
	elseif hue_sector == 2 then
		return p, value, t;
	elseif hue_sector == 3 then
		return p, q, value;
	elseif hue_sector == 4 then
		return t, p, value;
	elseif hue_sector == 5 then
		return value, p, q;
	end;
end;

local function draw_colored_slider()
	local window = current_window_context
	if not window then
		error("Current window context is nil!")
		return
	end

	local component = current_component
	local content_offset = get_content_area_offset()

	local slider_x = component.x + window.x + content_offset
	local slider_y = component.y + window.y
	local slider_w = component.width
	local slider_h = component.height

	-- Handle slider interaction
	handle_slider_drag()

	-- Calculate dimensions
	local knob_width = 10
	local track_height = 4
	local track_y = slider_y + (slider_h // 2) - (track_height // 2)

	-- Calculate knob position based on value
	local progress = (component.value - component.min) / (component.max - component.min)
	local knob_x = (slider_x + (progress * (slider_w - knob_width))) // 1

	-- Draw track background
	draw.Color(67, 76, 94, 255)
	draw.FilledRect(slider_x, track_y, slider_x + slider_w, track_y + track_height)

	-- Draw track fill (progress)
	if progress < 1 then
		local r, g, b = HSVToRGB(progress*360, 0.5, 1)
		draw.Color((r*255)//1, (g*255)//1, (b*255)//1, 255)
	else
		draw.Color(255, 255, 255, 255)
	end
	draw.FilledRect(slider_x, track_y, knob_x + (knob_width / 2), track_y + track_height)

	-- Draw knob outline
	--draw.Color(143, 188, 187, 255)
	draw.FilledRect(knob_x - 1, slider_y - 1, knob_x + knob_width + 1, slider_y + slider_h + 1)

	-- Draw knob
	if dragging_slider == component then
		draw.Color(76, 86, 106, 255) -- Dragging color
	elseif is_mouse_inside(knob_x, slider_y, knob_x + knob_width, slider_y + slider_h) then
		draw.Color(67, 76, 94, 255) -- Hover color
	else
		draw.Color(59, 66, 82, 255) -- Normal color
	end

	draw.FilledRect(knob_x, slider_y, knob_x + knob_width, slider_y + slider_h)

	-- Draw label if exists
	if component.label and component.label ~= "" then
		draw.SetFont(component.font or font)
		local tw, th = draw.GetTextSize(component.label)

		draw.Color(236, 239, 244, 255)
		draw.Text(slider_x, slider_y - th - 2, component.label)
	end

	-- Draw value text
	local value_text = string.format("%.1f", component.value)
	draw.SetFont(component.font or font)
	local value_tw, value_th = draw.GetTextSize(value_text)

	draw.Color(236, 239, 244, 255)
	draw.Text(slider_x + slider_w - value_tw, slider_y - value_th - 2, value_text)
end

local function draw_window()
	local window = current_window_context
	if not window then
		error("The window context is nil!")
		return
	end

	handle_window_drag()

	local content_offset = get_content_area_offset()

	-- Draw window outline
	draw.Color(143, 188, 187, 255)
	draw.FilledRect(
		window.x - OUTLINE_THICKNESS,
		window.y - OUTLINE_THICKNESS - ((window.header and window.header ~= "") and HEADER_SIZE or 0),
		window.x + window.width + OUTLINE_THICKNESS,
		window.y + window.height + OUTLINE_THICKNESS
	)

	if window.header and window.header ~= "" then
		draw.SetFont(font)
		draw.Color(0, 0, 0, 255)

		local text_width, text_height = draw.GetTextSize(window.header)
		draw.Text(
			window.x + (window.width // 2) - (text_width // 2),
			window.y - (HEADER_SIZE // 2) - (text_height // 2),
			window.header
		)
	end

	-- Draw window background
	draw.Color(46, 52, 64, 255)
	draw.FilledRect(window.x, window.y, window.x + window.width, window.y + window.height)

	-- Draw tab buttons if multiple tabs exist
	draw_tab_buttons(window)

	-- Draw content area background (if tabs exist)
	if #window.tabs > 1 then
		draw.Color(41, 46, 57, 255)
		draw.FilledRect(window.x + content_offset, window.y, window.x + window.width, window.y + window.height)
	end

	-- Draw components from active tab (use window-specific active tab)
	local active_tab_index = window.active_tab_index or 1
	-- Reset active tab if it's out of bounds for this window
	if active_tab_index > #window.tabs then
		active_tab_index = 1
		window.active_tab_index = 1
	end

	local current_tab = window.tabs[active_tab_index] or window.tabs[1]
	if current_tab then
		for _, component in pairs(current_tab.components) do
			current_component = component
			draw_colored_slider()
		end
	end

	for _, dd in ipairs(deferred_dropdowns) do
		local component = dd.component
		local window = dd.window
		local content_offset = get_content_area_offset()
		local x = window.x + component.x + content_offset
		local y = window.y + component.y
		local _, text_h = draw.GetTextSize(component.label or "")

		for i, item in ipairs(component.items) do
			local iy = y + component.height + (i - 1) * component.height
			local is_hovered = is_mouse_inside(x, iy, x + component.width, iy + component.height)

			draw.Color(143, 188, 187, 255)
			draw.FilledRect(
				x - OUTLINE_THICKNESS,
				iy - OUTLINE_THICKNESS,
				x + component.width + OUTLINE_THICKNESS,
				iy + component.height + OUTLINE_THICKNESS
			)

			if is_hovered then
				draw.Color(76, 86, 106, 255)
			else
				draw.Color(67, 76, 94, 255)
			end
			draw.FilledRect(x, iy, x + component.width, iy + component.height)

			draw.Color(236, 239, 244, 255)
			draw.Text(x + 4, iy + (component.height // 2) - (text_h // 2), item)
		end
	end

	if current_tab.draw_func and type(current_tab.draw_func) == "function" then
		-- Pass useful context to the draw function
		current_tab.draw_func(window, current_tab, content_offset)
	end
end

local function draw_all_windows()
	if not gui.IsMenuOpen() then
		return
	end

	local mouse = input.GetMousePos()
	local mx, my = table.unpack(mouse)
	dx, dy = mx - oldmx, my - oldmy

	for _, window in ipairs(windows) do
		current_window_context = window
		draw_window()
	end

	oldmx, oldmy = mx, my
	deferred_dropdowns = {}
end

-- =============================================================================
-- COMPONENT FACTORY FUNCTIONS
-- =============================================================================

local function create_slider_component()
	---@type SLIDER
	local slider = {
		type = COMPONENT_TYPES.SLIDER,
		font = font,
		height = 20,
		width = 150,
		label = "",
		x = 0,
		y = 0,
		min = 0,
		max = 100,
		value = 50,
		func = nil, -- Callback function called when value changes
	}
	return slider
end

-- =============================================================================
-- PUBLIC API
-- =============================================================================

---@class MENU
local menu = {}

---@return WINDOW
function menu:make_window()
	---@type WINDOW
	local window = {
		x = 0,
		y = 0,
		width = 0,
		height = 0,
		tabs = {},
		active_tab_index = 1, -- Each window now has its own active tab index
	}

	table.insert(windows, window)
	current_window_context = windows[#windows]
	return windows[#windows]
end

function menu:make_colored_slider()
	local window = current_window_context
	if not window then
		error("Current window context is nil!")
		return nil
	end

	local slider = create_slider_component()
	slider.type = COMPONENT_TYPES.COLORED_SLIDER
	return make_new_component(slider)
end

function menu.unload()
	menu = nil
	font = nil
	package.loaded["nmenu"] = nil
	input.SetMouseInputEnabled(false)
	callbacks.Unregister("Draw", draw_id)
end

local colors = {
   RED = 0, --- RED players
   BLU = 180, --- BLU players
   LOCALPLAYER = 172, --- you
   TARGET = 90, --- aimbot target
   PRIORITY = 60, --- players with priority higher than 0
   FRIEND = 172, --- players with priority lower than 0

   RED_SENTRY = 0,
   BLU_SENTRY = 180,

   RED_DISPENSER = 0,
   BLU_DISPENSER = 180,

   RED_TELEPORTER = 0,
   BLU_TELEPORTER = 180,

   RED_HAT = 0,
   BLU_HAT = 180,

   PRIMARY_WEAPON = 360,
   SECONDARY_WEAPON = 360,
   MELEE_WEAPON = 360,
}

local sliderGap = 35

local window = menu:make_window()
window.x = 40
window.y = 40
window.header = "glow color"
window.width = 410
window.height = 690

local starty = 25

for name, color in pairs (colors) do
   local slider = menu:make_colored_slider()
   slider.max = 360
   slider.min = 0
   slider.value = color
   slider.x = 10
   slider.y = starty
   slider.width = 390
   slider.height = 20
   slider.label = string.gsub(name, "_", " ")
   slider.func = function()
      colors[name] = slider.value
   end
   starty = starty + sliderGap + 5
end

callbacks.Register("Draw", draw_id, draw_all_windows)

---@param entity Entity
local function getentitycolor(entity)
   local localindex = client:GetLocalPlayerIndex()
   if not localindex then return 0 end

   --- localplayer check
   if localindex == entity:GetIndex() then
      return colors.LOCALPLAYER
   end

   --- aimbot target
   if aimbot.GetAimbotTarget() == entity:GetIndex() then
      return colors.TARGET
   end

   --- player weapons
   if entity:IsWeapon() then
      if entity:IsMeleeWeapon() then
         return colors.MELEE_WEAPON
      else
         return entity:GetLoadoutSlot() == E_LoadoutSlot.LOADOUT_POSITION_PRIMARY and colors.PRIMARY_WEAPON or colors.SECONDARY_WEAPON
      end
   end

   --- priority
   local priority = playerlist.GetPriority(entity)
   if priority > 0 then
      return colors.PRIORITY
   elseif priority < 0 then
      return colors.FRIEND
   end

   --- putting them in a do end because of class and team variables
   local class = entity:GetClass()
   local team = entity:GetTeamNumber()
   local isred = team == 2

   --- buildings
   if class == "CObjectSentrygun" then
      return isred and colors.RED_SENTRY or colors.BLU_SENTRY
   elseif class == "CObjectTeleporter" then
      return isred and colors.RED_TELEPORTER or colors.BLU_TELEPORTER
   elseif class == "CObjectDispenser" then
      return isred and colors.RED_DISPENSER or colors.BLU_DISPENSER
   end

   --- hats
   --if string.find(class, "Wearable") then
   if class == "CTFWearableRazorback"
      or class == "CTFWearableDemoShield"
      or class == "CTFWearableLevelableItem"
      or class == "CTFWearableCampaignItem"
      or class == "CTFWearableRobotArm"
      or class == "CTFWearableVM"
      or class == "CTFWearable"
      or class == "CTFWearableItem" then
      return isred and colors.RED_HAT or colors.BLU_HAT
   end

   return isred and colors.RED or colors.BLU
end

--- source: https://gist.github.com/GigsD4X/8513963
local function HSVToRGB( hue, saturation, value )
	-- Returns the RGB equivalent of the given HSV-defined color
	-- (adapted from some code found around the web)

	-- If it's achromatic, just return the value
	if saturation == 0 then
		return value, value, value;
	end;

	-- Get the hue sector
	local hue_sector = math.floor( hue / 60 );
	local hue_sector_offset = ( hue / 60 ) - hue_sector;

	local p = value * ( 1 - saturation );
	local q = value * ( 1 - saturation * hue_sector_offset );
	local t = value * ( 1 - saturation * ( 1 - hue_sector_offset ) );

	if hue_sector == 0 then
		return value, t, p;
	elseif hue_sector == 1 then
		return q, value, p;
	elseif hue_sector == 2 then
		return p, value, t;
	elseif hue_sector == 3 then
		return p, q, value;
	elseif hue_sector == 4 then
		return t, p, value;
	elseif hue_sector == 5 then
		return value, p, q;
	end;
end;

---@return number, number, number
local function GetHSVColor(hue)
   if hue == 360 then
      return 1, 1, 1
   end

   return HSVToRGB(hue, 0.5, 1)
end

---@param dm DrawModelContext
local function DrawModel(dm)
   if dm:IsDrawingGlow() then
      local glow_entity = dm:GetEntity()
      if not glow_entity then return end

      local color = getentitycolor(glow_entity)

      dm:SetColorModulation(GetHSVColor(color))
   end
end

callbacks.Register("DrawModel", "glow colors", DrawModel)
callbacks.Register("Unload", menu.unload)