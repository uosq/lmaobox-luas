---@alias colored {r: number, g: number, b: number, a: number}
---@alias custom_theme {bg_color: colored, sel_color: colored, text_color: colored, outline_color: colored}

---@param number number
---@param min number
---@param max number
local function clamp(number, min, max)
    number = (number < min and min or number)
    number = (number > max and max or number)
    return number
end

---@param length number
---@return string
local function random_string(length)
    local text = ""
    for i = 1, length do
        local e = string.char(math.random(65,90))
        local dice = math.random(1,2)
        text = text .. (dice == 1 and e or e:lower())
    end
    return text
end

---@param r number
---@param g number
---@param b number
---@param a number?
---@return colored
local function rgba(r, g, b, a)
    r = clamp(r, 0, 255)
    g = clamp(g, 0, 255)
    b = clamp(b, 0, 255)
    a = clamp(a or 255, 0, 255)
	return { r = r, g = g, b = b, a = a }
end

local theme = {}
theme.__index = theme

---@param bg_color colored?
---@param sel_color colored?
---@param text_color colored?
---@return custom_theme
function theme:new(font,bg_color,sel_color,text_color, outline_color)
    local ntheme = setmetatable({}, theme)
    ntheme.bg_color = bg_color or rgba(80,80,80)
    ntheme.sel_color = sel_color or rgba(100,255,100)
    ntheme.text_color = text_color or rgba(255,255,255)
    ntheme.outline_color = outline_color or rgba(100,100,255)
    local font = draw.CreateFont( font or 'Verdana', 12, 600 )
    draw.SetFont(font)
    return ntheme
end

local window = {}
window.__index = window

---@param name string
---@param x number
---@param y number
---@param width number
---@param height number
---@param out_thickness number
---@param theme2 custom_theme
function window:create(name,x,y,width,height,theme2,out_thickness)
    local new_window = setmetatable({},window)
    new_window.name = name
    new_window.x = x
    new_window.y = y
    new_window.width = width
    new_window.height = height
    new_window.bg_color = theme2.bg_color
    new_window.sel_color = theme2.sel_color
    new_window.outline_thickness = out_thickness
    new_window.outline_color = theme2.outline_color
    return new_window
end

function window:render()
    draw.Color(self.bg_color.r, self.bg_color.g, self.bg_color.b, self.bg_color.a)
	draw.FilledRect(self.x, self.y, self.x + self.width, self.y + self.height)
	draw.Color(self.outline_color.r, self.outline_color.g, self.outline_color.b, self.outline_color.a)
	for i = 1, self.outline_thickness do
		draw.OutlinedRect(
			self.x - 1 * i,
			self.y - 1 * i,
			self.x + self.width + 1 * i,
			self.y + self.height + 1 * i
		)
	end
end

local button = {}
button.__index = button

---@param name string default text: button
---@param text string default text: text
---@param x number
---@param y number
---@param width number
---@param height number
---@param can_click boolean
---@param out_thickness number
---@param on_click function
---@param theme custom_theme
function button:create(name,text,x,y,width,height,can_click,theme,out_thickness,parent,on_click)
    local new_button = setmetatable({}, button)
    new_button.name = name
    new_button.x = (parent.x or 0) + x
    new_button.y = (parent.y or 0) + y
    new_button.width = width
    new_button.height = height
    new_button.bg_color = theme.bg_color
    new_button.sel_color = theme.sel_color
    new_button.outline_thickness = out_thickness
    new_button.outline_color = theme.outline_color
    new_button.can_click = can_click
    new_button.text = text
    new_button.parent = parent
    new_button.text_color = theme.text_color
    new_button.mouse_inside = false
    new_button.on_click = on_click
    new_button.last_clicked_tick = nil

    local random_text = random_string(128)
    callbacks.Register( "Draw", new_button.name .. 'mouseclicks' .. random_text , function ()
        local state, tick = input.IsButtonPressed( MOUSE_LEFT )
        if new_button.can_click and new_button:is_mouse_inside() and state and tick ~= new_button.last_clicked_tick then
            new_button:click()
        end
        new_button.last_clicked_tick = tick
    end)

    callbacks.Register( "Unload", function()
        callbacks.Unregister( "Draw", new_button.name .. 'mouseclicks' .. random_text )
    end)

    callbacks.Register("Draw", new_button.name .. 'focus' .. random_text, function ()
        if new_button.can_click and new_button:is_mouse_inside() then
            new_button.mouse_inside = true
        else
            new_button.mouse_inside = false
        end
    end)

    callbacks.Register("Unload", function()
        callbacks.Unregister("Draw", new_button.name .. 'focus' .. random_text)
    end)

    return new_button
end

function button:render()
    local text_size_x, text_size_y = draw.GetTextSize( self.text )
    if self.mouse_inside then
        draw.Color (self.sel_color.r,self.sel_color.g,self.sel_color.b,self.sel_color.a)
    else
        draw.Color (self.bg_color.r,self.bg_color.g,self.bg_color.b, self.bg_color.a)
    end
    draw.FilledRect(self.x, self.y, self.x + self.width, self.y + self.height)
    
    draw.Color (self.text_color.g,self.text_color.g,self.text_color.b,self.text_color.a)
    draw.Text( self.x + self.width/2 - math.floor(text_size_x/2), self.y + self.height/2 - math.floor(text_size_y/2), self.text )

    draw.Color (self.outline_color.r,self.outline_color.g,self.outline_color.b,self.outline_color.a)
    for i = 1, self.outline_thickness do
        draw.OutlinedRect(self.x - 1 * i, self.y - 1 * i, self.x + self.width + 1 * i, self.y + self.height + 1 * i)
    end
end

function button:is_mouse_inside()
    local mousePos = input.GetMousePos()
    local mx, my = mousePos[1], mousePos[2]
    if (mx < self.x) then return false end
    if (mx > self.x + self.width) then return false end
    if (my < self.y) then return false end
    if (my > self.y + self.height) then return false end
    return true
end

function button:click()
    self.on_click(self)
end

local function unload()
    local this = GetScriptName():match("[^\\]*.lua$")
    package.loaded.rstyle = nil
    package.loaded[this] = nil
end

local lib = {
    window = window,
    button = button,
    rgba = rgba,
    clamp = clamp,
    theme = theme,
    rstring = random_string,
    unload = unload,
}

return lib
