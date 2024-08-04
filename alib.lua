---@alias colored {r: number, g: number, b: number, a: number}
---@alias custom_theme {font:integer ,bg_color: colored, sel_color: colored, text_color: colored, outline_color: colored}

local function unload()
    package.loaded.alib = nil
end

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

---@param color colored
---@param font Font
---@param x number
---@param y number
---@param text string
local function ctext(color,font,x,y,text)
    draw.Color(color.r,color.g,color.b,color.a)
    draw.SetFont(font)
    draw.Text( x, y, text )
end

---@param font string
local function createfont(font)
    local font = draw.CreateFont( font, 12, 1000 )
    return font
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
    --local font = draw.CreateFont( font or 'Verdana', 12, 1000 )
    local font = createfont(font or 'Verdana')
    ntheme.font = font
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
    if self.visible == false then
        return
    end

    if gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot() then
        return
    end

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

function window:destroy()
    self = nil
end

function window:getchildren()
    local children = {}
    for k,v in pairs (self) do
        if type(v) == "table" and v.name and v.parent then
            children[#children+1] = v
        end
    end
    return children
end

local button = {}
button.__index = button

---@param name string default text: button
---@param text string default text: text
---@param x number
---@param y number
---@param width number
---@param height number
---@param out_thickness number
---@param on_click function
---@param theme custom_theme
function button:create(name,text,x,y,width,height,theme,out_thickness,parent,on_click)
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
    new_button._can_click = true
    new_button.text = text
    new_button.font = theme.font
    new_button.parent = parent
    new_button.text_color = theme.text_color
    new_button._on_click = on_click
    new_button._last_clicked_tick = nil
    new_button.visible = true

    parent[name] = new_button

    callbacks.Register( "Draw", tostring(new_button) .. 'mouseclicks' , function ()
        local state, tick = input.IsButtonPressed( MOUSE_LEFT )
        if new_button._can_click and new_button.visible and new_button:is_mouse_inside() and state and tick ~= new_button._last_clicked_tick then
            new_button:click()
    end
        new_button._last_clicked_tick = tick
    end)

    callbacks.Register( "Unload", function()
        callbacks.Unregister( "Draw", tostring(new_button) .. 'mouseclicks' )
        new_button.visible = false
    end)

    callbacks.Register("Unload", function()
        callbacks.Unregister("Draw", tostring(new_button) .. 'focus')
    end)

    return new_button
end

function button:render()
    if self.visible == false then
        return
    end

    if gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot() then
        return
    end

    draw.SetFont(self.font)
    local text_size_x, text_size_y = draw.GetTextSize( self.text )
    if self:is_mouse_inside() then
        draw.Color (self.sel_color.r,self.sel_color.g,self.sel_color.b,self.sel_color.a)
    else
        draw.Color (self.bg_color.r,self.bg_color.g,self.bg_color.b, self.bg_color.a)
    end
    draw.FilledRect(self.x, self.y, self.x + self.width, self.y + self.height)
    
    draw.Color (self.text_color.r,self.text_color.g,self.text_color.b,self.text_color.a)
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
    if self.visible == false then
        return
    end
    self._on_click(self,self)
end

function button:destroy()
    self = nil
end

local slider = {}
slider.__index = slider

---@param name string
---@param x number
---@param y number
---@param width number
---@param height number
---@param out_thickness number
---@param theme custom_theme
---@param value number
function slider:create(name,text,parent,min,value,max,x,y,width,height,theme,out_thickness)
    local nslider = setmetatable({}, slider)
    nslider.name = name
    nslider.x = (parent.x or 0) + x
    nslider.y = (parent.y or 0) + y
    nslider.width = width
    nslider.height = height
    nslider.text = text
    nslider.font = theme.font
    nslider.bg_color = theme.bg_color
    nslider.sel_color = theme.sel_color
    nslider.text_color = theme.text_color
    nslider.outline_thickness = out_thickness
    nslider.outline_color = theme.outline_color
    nslider._can_click = true
    nslider.parent = parent
    nslider.min = min
    nslider.max = max
    nslider.value = clamp(value, min,max)
    nslider.visible = true

    parent[name] = nslider

    callbacks.Register( "Draw", tostring(nslider) .. 'sliderclicks' , function ()
        if nslider._can_click and nslider.visible and nslider:is_mouse_inside() and input.IsButtonDown( MOUSE_LEFT ) then
            local mx = input.GetMousePos()[1]

            if not input.IsButtonDown( MOUSE_LEFT ) then
                callbacks.Unregister( "Draw", "sliderclicks" )
                return
            end

            local initial_mouse_pos = mx - nslider.x
            local new_value = nslider.min + (initial_mouse_pos/nslider.width) * (nslider.max - nslider.min)
            nslider.value = clamp(new_value, nslider.min, nslider.max)
        end
    end)

    callbacks.Register( "Unload", function()
        callbacks.Unregister( "Draw", tostring(nslider) .. 'sliderclicks' )
        callbacks.Unregister("Draw", tostring(nslider) .. 'focus')
        nslider.visible = false
    end)

    return nslider
end

function slider:render()
    if self.visible == false then
        return
    end

    if gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot() then
        return
    end

    draw.SetFont(self.font)
    draw.Color(self.bg_color.r, self.bg_color.g, self.bg_color.b, self.bg_color.a)
    draw.FilledRect(self.x - 1, self.y - 1, self.x + self.width + 1, self.y + self.height + 1)
    
    local value_range = self.max - self.min
    local value_percentage = (self.value - self.min) / value_range
    draw.Color(self.sel_color.r, self.sel_color.g, self.sel_color.b, self.sel_color.a)
    draw.FilledRect(self.x, self.y, self.x + self.width * value_percentage, self.y + self.height)

    draw.Color (self.text_color.g,self.text_color.g,self.text_color.b,self.text_color.a)
    draw.Text( self.x + self.width + 10, self.y + self.height - 10, self.text )
    draw.Text( self.x + self.width + 10, self.y + self.height - 20, tostring(self.value) )
end

function slider:is_mouse_inside()
    local mousePos = input.GetMousePos()
    local mx, my = mousePos[1], mousePos[2]
    if (mx < self.x) then return false end
    if (mx > self.x + self.width) then return false end
    if (my < self.y) then return false end
    if (my > self.y + self.height) then return false end
    return true
end

function slider:destroy()
    self = nil
end

local checkbox = {}
checkbox.__index = checkbox

---@param name string
---@param text string
---@param x number
---@param y number
---@param size number
---@param outline_thickness number
---@param parent table
---@param checked boolean
---@param theme custom_theme
---@param selected_color colored
---@param unselected_color colored
---@param on_click function
function checkbox:create(name,text,x,y,size,outline_thickness,parent,checked,theme,selected_color,unselected_color,on_click)
    local ncheckbox = setmetatable({},checkbox)
    ncheckbox.name = name
    ncheckbox.x = (parent.x or 0) + x
    ncheckbox.y = (parent.y or 0) + y
    ncheckbox.width = 1 * size
    ncheckbox.height = 1 * size
    ncheckbox.checked = checked
    ncheckbox.bg_color = theme.bg_color
    ncheckbox.sel_color = theme.sel_color
    ncheckbox.text_color = theme.text_color
    ncheckbox.outline_thickness = outline_thickness
    ncheckbox.selected_color = selected_color
    ncheckbox.unselected_color = unselected_color
    ncheckbox._can_click = true
    ncheckbox.visible = true
    ncheckbox.parent = parent
    ncheckbox.font = theme.font
    ncheckbox.text = text
    parent[name] = ncheckbox
    ncheckbox.on_click = on_click

    callbacks.Register( "Draw", tostring(ncheckbox) .. 'mouseclicks' , function ()
        local state, tick = input.IsButtonPressed( MOUSE_LEFT )
        if ncheckbox._can_click and ncheckbox.visible and ncheckbox:is_mouse_inside() and state and tick ~= ncheckbox._last_clicked_tick then
            ncheckbox:click()
        end
        ncheckbox._last_clicked_tick = tick
    end)

    callbacks.Register( "Unload", function()
        callbacks.Unregister( "Draw", tostring(ncheckbox) .. 'mouseclicks' )
        ncheckbox.visible = false
    end)

    callbacks.Register("Unload", function()
        callbacks.Unregister("Draw", tostring(ncheckbox) .. 'focus')
    end)

    return ncheckbox
end

function checkbox:is_mouse_inside()
    local mousePos = input.GetMousePos()
    local mx, my = mousePos[1], mousePos[2]
    if (mx < self.x) then return false end
    if (mx > self.x + self.width) then return false end
    if (my < self.y) then return false end
    if (my > self.y + self.height) then return false end
    return true
end

function checkbox:click()
    if self.visible == false then
        return
    end

    self.checked = not self.checked
    self.on_click(self,self)
end

function checkbox:render()
    if self.visible == false then
        return
    end

    if gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot() then
        return
    end

    draw.SetFont(self.font)
    draw.Color(self.bg_color.r, self.bg_color.g, self.bg_color.b, self.bg_color.a)
    for i = 1, self.outline_thickness do
        draw.OutlinedRect(self.x - 1 * i, self.y - 1 * i, self.x + self.width + 1 * i, self.y + self.height + 1 * i)
    end

    if self.checked then
        draw.Color(self.selected_color.r, self.selected_color.g, self.selected_color.b, self.selected_color.a)
    else
        draw.Color(self.unselected_color.r, self.unselected_color.g, self.unselected_color.b, self.unselected_color.a)
    end
    draw.FilledRect(self.x, self.y, self.x + self.width, self.y + self.height)

    draw.Color (self.text_color.g,self.text_color.g,self.text_color.b,self.text_color.a)
    draw.Text( self.x + self.width + 10, self.y + self.height/5, self.text )
end

local combobox_button = {}
combobox_button.__index = combobox_button

function combobox_button:new(parent,index,height,item)
    local bcombobox = setmetatable({},combobox_button)
    bcombobox.parent = parent
    bcombobox.height = height
    bcombobox.bg_color = parent.item_theme.bg_color
    bcombobox.sel_color = parent.item_theme.sel_color
    bcombobox.text_color = parent.item_theme.text_color
    bcombobox.outline_thickness = parent.item_theme.outline_thickness
    bcombobox.item = item
    bcombobox.index = index
    bcombobox.x = parent.x
    bcombobox.y = parent.y + (index * height) + (parent.item_theme.outline_thickness or 0)

    callbacks.Register( "Draw", "bdropdownclick"..tostring(index), function()
        if input.IsButtonDown( MOUSE_LEFT ) and bcombobox:is_mouse_inside() and bcombobox.parent.showing_values then
            bcombobox:click()
        end
    end)

    return bcombobox
end

function combobox_button:click()
    if self.parent.showing_values == false then return end
    self.parent.selected_item = self.index
    for i,v in ipairs (self.parent._items_table) do
        callbacks.Unregister("Draw", "bdropdownclick"..tostring(i))
    end
    self.parent:click()
end

function combobox_button:render()
    if gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot() then
        return
    end
    local text_size_x, text_size_y = draw.GetTextSize( tostring(self.parent.items[self.index]) )
    if self:is_mouse_inside() then
        draw.Color(self.sel_color.r,self.sel_color.g,self.sel_color.b,self.sel_color.a)
    else
        draw.Color (self.bg_color.r,self.bg_color.g,self.bg_color.b,self.bg_color.a)
    end
    draw.FilledRect( self.x, self.y, self.x + self.parent.width, self.y + self.parent.height )
    draw.Color(self.text_color.r,self.text_color.g,self.text_color.b,self.text_color.a)
    draw.SetFont(self.parent.font)
    draw.Text( self.x + self.parent.width/2 - math.floor(text_size_x/2), self.y + self.height/2 - math.floor(text_size_y/2), self.parent.items[self.index] )
end

function combobox_button:is_mouse_inside()
    local mousePos = input.GetMousePos()
    local mx, my = mousePos[1], mousePos[2]
    if (mx < self.x) then return false end
    if (mx > self.x + self.parent.width) then return false end
    if (my < self.y) then return false end
    if (my > self.y + self.height) then return false end
    return true
end

local combobox = {}
combobox.__index = combobox

---@param name string
---@param x number
---@param y number
---@param height number
---@param combobox_theme custom_theme
---@param item_theme custom_theme
---@param items table example {"plain","silent","silent+"}
function combobox:create(name,parent,x,y,width,height,outline_thickness,combobox_theme,item_theme,items)
    local ncombobox = setmetatable({},combobox)
    ncombobox.name = name
    ncombobox.x = (parent.x or 0) + x
    ncombobox.y = (parent.y or 0) + y
    ncombobox.height = height
    ncombobox.width = width
    ncombobox.font = combobox_theme.font
    ncombobox.bg_color = combobox_theme.bg_color
    ncombobox.sel_color = combobox_theme.sel_color
    ncombobox.text_color = combobox_theme.text_color
    ncombobox.outline_color = combobox_theme.outline_color
    ncombobox.outline_thickness = outline_thickness
    ncombobox._can_click = true
    ncombobox.items = items
    ncombobox.parent = parent
    ncombobox.item_theme = item_theme
    ncombobox._items_table = {}
    ncombobox.showing_values = false
    ncombobox._last_clicked_tick = nil
    ncombobox.selected_item = 1
    ncombobox.visible = true
    parent[name] = ncombobox

    callbacks.Register( "Draw", tostring(ncombobox) .. 'mouseclicks' , function ()
        local state, tick = input.IsButtonPressed( MOUSE_LEFT )
        if ncombobox._can_click and ncombobox.visible and ncombobox:is_mouse_inside() and state and tick ~= ncombobox._last_clicked_tick then
            ncombobox:click()
        end
        ncombobox._last_clicked_tick = tick
    end)

    callbacks.Register( "Unload", function()
        callbacks.Unregister( "Draw", tostring(ncombobox) .. 'mouseclicks' )
        ncombobox.visible = false
    end)

    callbacks.Register("Unload", function()
        callbacks.Unregister("Draw", tostring(ncombobox) .. 'focus')
    end)

    return ncombobox
end

function combobox:is_mouse_inside()
    local mousePos = input.GetMousePos()
    local mx, my = mousePos[1], mousePos[2]
    if (mx < self.x) then return false end
    if (mx > self.x + self.width) then return false end
    if (my < self.y) then return false end
    if (my > self.y + self.height) then return false end
    return true
end

function combobox:click()
    self.showing_values = not self.showing_values
    for k,v in pairs(self.parent:getchildren()) do
        if v ~= self then
            v._can_click = not self.showing_values
        end
    end
    if self.showing_values then
        for i,v in ipairs(self.items) do
            local new_button = combobox_button:new(self, i, 20, v )
            self._items_table[#self._items_table+1] = new_button
        end
    else

        callbacks.Register("Unload", function()
            for i,v in ipairs (self._items_table) do
                callbacks.Unregister("Draw", "bcomboboxclick"..tostring(i))
            end
        end)

        self._items_table = {}
    end
end

function combobox:render()
    if not self.visible then return end

    if gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot() then
        return
    end

    -- render the combobox first
    local text_size_x, text_size_y = draw.GetTextSize( self.items[self.selected_item] )
    if self:is_mouse_inside() then
        draw.Color (self.sel_color.r,self.sel_color.g,self.sel_color.b,self.sel_color.a)
    else
        draw.Color (self.bg_color.r,self.bg_color.g,self.bg_color.b, self.bg_color.a)
    end
    draw.FilledRect(self.x, self.y, self.x + self.width, self.y + self.height)
    
    draw.SetFont(self.font)
    draw.Color (self.text_color.r,self.text_color.g,self.text_color.b,self.text_color.a)
    draw.Text( self.x + self.width/2 - math.floor(text_size_x/2), self.y + self.height/2 - math.floor(text_size_y/2), tostring(self.items[self.selected_item]) )

    draw.Color (self.outline_color.r,self.outline_color.g,self.outline_color.b,self.outline_color.a)
    for i = 1, self.outline_thickness do
        draw.OutlinedRect(self.x - 1 * i, self.y - 1 * i, self.x + self.width + 1 * i, self.y + self.height + 1 * i)
    end

    if #self.items == 0 then return end
    if not self.showing_values then return end

    -- render the values
    for i,v in ipairs (self._items_table) do
        if v then
            v:render()
        end
    end
end

local text = {}
text.__index = text

--[[local text_alignment = {
    left = 1,
    center = 2,
    bottom = 3,
    right = 4,
}]]

---@param name string
---@param x number
---@param y number
---@param parent table
---@param theme custom_theme
---@param ntext string
function text:new(name,x,y,--[[alignment,]]parent,theme,ntext)
    local new_text = setmetatable({},text)
    new_text.text = ntext
    new_text.x = parent.x + x
    new_text.y = parent.y + y
    new_text.parent = parent
    new_text.name = name
    new_text.text_color = theme.text_color
    new_text.font = theme.font
    --new_text.alignment = alignment
    parent[name] = new_text
    return new_text
end

function text:render()
    -- theres probably more i could do but im too lazy to find out lol
    local text_size_x,text_size_y = draw.GetTextSize (self.text)
    ctext(self.text_color, self.font, self.x + self.parent.width/2 - math.floor(text_size_x/2), self.y + self.parent.height/2 - math.floor(text_size_y/2), self.text)
    --[[if self.alignment == text_alignment.center then
        ctext(self.text_color, self.font, self.x + self.parent.width/2 - math.floor(text_size_x/2), self.y + self.parent.height/2 - math.floor(text_size_y/2), self.text)
    elseif self.alignment == text_alignment.left then
        ctext(self.text_color, self.font, self.x - math.floor(text_size_x/2), self.y + self.parent.height/2 - math.floor(text_size_y/2), self.text)
    end]]
end

---@param duration number seconds
---@param func function
local function wait(duration, func)
    local duration = globals.TickCount() + (66 * duration)
    local rs = random_string(12)
    local success,result
    callbacks.Register("Draw", 'wait'..rs, function ()
        if globals.TickCount() < duration then
            success,result = pcall(func)
        else
            callbacks.Unregister( 'Draw', 'wait'..rs )
        end
    end)
    return success,result
end

local lib = {
    version = 0.32,
    window = window,
    button = button,
    rgba = rgba,
    clamp = clamp,
    theme = theme,
    rstring = random_string,
    unload = unload,
    slider = slider,
    checkbox = checkbox,
    combobox = combobox,
    text = text,
    --text_alignment = text_alignment,
}

local known_bugs = {
    "when clicking on a combobox button a number of times, it prints 'attempt to call a number value'",
    "clicking combobox very fast makes it click on the first item", -- seriously wtf how is this even possible?
    "not unregistering combobox buttons click callback"
}

printc( 100, 255, 100, 255, string.format("alib %.2f loaded", lib.version) )

printc( 255,100,100,255, "known bugs:" )
for k,v in pairs (known_bugs) do
    printc(255,100,100,255, tostring(v))
end

local duration = globals.TickCount() + (66 * 3)
local font = createfont('TF2 BUILD')
local w,h = draw.GetScreenSize()
callbacks.Register("Draw", 'loaded', function ()
    if globals.TickCount() < duration then
        ctext(rgba(100,255,100), font, math.ceil(w*0.7), math.ceil(h*0.1), string.format("alib %.2f loaded", lib.version ))
    else
        callbacks.Unregister( 'Draw', 'loaded' )
    end
end)


return lib