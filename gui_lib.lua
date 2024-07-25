local font = draw.CreateFont("Verdana", 12, 500)
draw.SetFont(font)
local objects = {}

---@param r number
---@param g number
---@param b number
---@param a number|nil
---@return table
local function rgba(r,g,b,a)
    return {r=r,g=g,b=b,a=a or 255}
end

---@param name string
---@param position table x,y
---@param size table width,height
---@param can_click boolean
---@param click_func function|nil
---@param bg_color table rgba
---@param select_color table|nil rgba
---@param outline table { thickness, color }
---@return table
local function Object_new(name, position, size, can_click, bg_color, select_color, outline, click_func)
    local new_index = #objects+1
    objects[new_index] = {
        name = name,
        position = position,
        size = size,
        can_click = can_click or false,
        click_func = click_func or nil,
        mouse_inside = false,
        outline = outline,
        bg_color = bg_color,
        select_color = select_color or rgba(100,255,100),
        render_func = function()
            draw.Color(bg_color.r,bg_color.g,bg_color.b,bg_color.a)
            draw.FilledRect(position.x, position.y, position.x + size.width, position.y + size.height)
            
            draw.Color (outline.color.r,outline.color.g,outline.color.b,outline.color.a)
            for i = 1, outline.thickness do
				draw.OutlinedRect(position.x - 1 * i, position.y - 1 * i, position.x + size.width + 1 * i, position.y + size.height + 1 * i)
			end
        end,
    }
    return objects[new_index]
end

---comment
---@param name string
---@param position table x,y
---@param size table width,height
---@param bg_color table r,g,b,a
---@return table
local function Window_new(name, position, size, bg_color, outline)
    return Object_new( name, position, size, false, bg_color, nil, outline, nil )
end

---comment
---@param name string
---@param position table x,y
---@param size table width,height
---@param bg_color table rgba
---@param text_color table rgba
---@param text string default text: button
---@param can_click boolean
---@param click_func function
---@return table
local function Button_new(name, position, size, bg_color, text_color, text, can_click, select_color, outline, click_func)
    local new_button = Object_new(name, position, size, can_click, bg_color, select_color, outline, click_func)
    new_button.text_color = text_color
    new_button.text = text
    new_button.render_func = function()
        local text_size_x, text_size_y = draw.GetTextSize( text )
        
        if new_button.mouse_inside then
            draw.Color (new_button.select_color.r,new_button.select_color.g,new_button.select_color.b,new_button.select_color.a)
        else
            draw.Color (bg_color.r,bg_color.g,bg_color.b, bg_color.a)
        end
        draw.FilledRect(position.x, position.y, position.x + size.width, position.y + size.height)
        
        draw.Color (new_button.text_color.g,new_button.text_color.g,new_button.text_color.b,new_button.text_color.a)
        draw.Text( position.x + size.width/2 - math.floor(text_size_x/2), position.y + size.height/2 - math.floor(text_size_y/2), text )

        draw.Color (outline.color.r,outline.color.g,outline.color.b,outline.color.a)
        for i = 1, outline.thickness do
            draw.OutlinedRect(position.x - 1 * i, position.y - 1 * i, position.x + size.width + 1 * i, position.y + size.height + 1 * i)
        end
    end
    return new_button
end

---@param object table
---@return boolean
local function is_mouse_inside(object)
    local mousePos = input.GetMousePos()
    local mx, my = mousePos[1], mousePos[2]
    if (mx < object.position.x) then return false end
    if (mx > object.position.x + object.size.width) then return false end
    if (my < object.position.y) then return false end
    if (my > object.position.y + object.size.height) then return false end
    return true
end

callbacks.Register( "Draw", "focusiguess", function()
    for k,v in pairs (objects) do
        if v.can_click and is_mouse_inside(v) then
            v.mouse_inside = true
        else
            v.mouse_inside = false
        end
    end
end)

local last_clicked_tick = 0
callbacks.Register( "Draw", "mouseclicks", function()
    local state, tick = input.IsButtonPressed( MOUSE_LEFT )
    if not state or last_clicked_tick == tick then
        goto continue
    end
    for k,v in pairs (objects) do
        if not v.can_click then
            goto continue2
        end
        if is_mouse_inside(v) then
            v.click_func()
        end
        ::continue2::
    end
    last_clicked_tick = tick
    ::continue::
end)
callbacks.Register( "Draw", "render", function()
    for k,v in pairs (objects) do
        v.render_func()
    end
end)

local window = Window_new("Window", {x=1920/2,y=1080/2}, {width=800,height=600}, rgba(100,100,100), {thickness=2,color=rgba(255,255,255)})

local window_total_size_x = window.position.x + window.size.width
local window_total_size_y = window.position.y + window.size.height

local button = Button_new ("Button", {x=(window_total_size_x - 100),y=(window_total_size_y - 200)}, {width=100,height=50}, rgba(20,20,20), rgba(255,255,255), "test", true, nil, {thickness=2, color=rgba(255,0,0)}, function()
    print'oi'
end)

local button2 = Button_new ("button2", {x=(window_total_size_x - 250), y=(window_total_size_y - 200)}, {width=100,height=50}, rgba(20,20,20), rgba(255,255,255), "lul", true, nil, {thickness=1, color=rgba(100,100,255)}, function()
    gui.SetValue( "aim bot", (gui.GetValue( "aim bot") == 1 and 0 or 1) )
end)

local topbar = Button_new ("topbar", {x=window.position.x,y=window.position.y}, {width=window.size.width,height=30}, rgba(0,0,0), rgba(0,0,0), "", true, rgba(0,0,0), {thickness = 0, color = rgba(0,0,0,0)}, function ()
    local mx = input.GetMousePos()[1]
    local my = input.GetMousePos()[2]
    local drag_delta = { x=0, y=0 }
    local last_mouse_pos = { x=mx,y=my }
    drag_delta.x = mx - last_mouse_pos.x
    drag_delta.y = my - last_mouse_pos.y

    callbacks.Register("Draw", "mousedrag", function()

        -- got some ideas on how to make this from LnxLib or ImMenu im not sure which one but i mostly made this myself lol

        local mx = input.GetMousePos()[1]
        local my = input.GetMousePos()[2]
        if not input.IsButtonDown( MOUSE_LEFT ) then
            callbacks.Unregister( "Draw", "mousedrag" )
            return
        end
        drag_delta.x = mx - last_mouse_pos.x
        drag_delta.y = my - last_mouse_pos.y
        last_mouse_pos = {x=mx,y=my}

        for k,v in pairs (objects) do
            v.position.x = v.position.x + drag_delta.x
            v.position.y = v.position.y + drag_delta.y
        end
    end)
end)
