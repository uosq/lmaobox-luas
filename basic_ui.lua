local alib = require('alib')

local window_theme = alib.theme:new(
    'Verdana',
    alib.rgba(50,50,50),
    nil,
    nil,
    alib.rgba(120,30,125)
)

local button_theme = alib.theme:new(
    nil,
    alib.rgba(150,150,150),
    alib.rgba(123,123,255),
    alib.rgba(255,255,255),
    alib.rgba(100,255,100)

)

local window = alib.window:create(
    'window',
    100,100,500,300,
    window_theme,
    1
)

local button = alib.button:create(
    'button',
    'bottom text',
    10,50,100,40,
    true,
    button_theme,
    1,
    window,
    function()
        print('oi')
    end
)

local topbar_theme = alib.theme:new(
    nil,
    alib.rgba(0,0,0),
    alib.rgba(0,0,0),
    alib.rgba(255,255,255),
    alib.rgba(0,0,0)
)

topbar = button:create(
        'topbar', 'topbar',
        0,0,
        window.width,
        30,
        true,
        topbar_theme,
        0,
        window,
        function()
            local mx = input.GetMousePos()[1]
            local my = input.GetMousePos()[2]
            local drag_delta = { x=0, y=0 }
            local last_mouse_pos = { x=mx,y=my }
            drag_delta.x = mx - last_mouse_pos.x
            drag_delta.y = my - last_mouse_pos.y

            local window_children = {button, topbar}
            local randomtext = alib.rstring(128)
            callbacks.Register("Draw", "mousedrag" .. randomtext, function()

                -- got some ideas on how to make this from LnxLib or ImMenu im not sure which one but i mostly made this myself lol

                local mx = input.GetMousePos()[1]
                local my = input.GetMousePos()[2]
                if not input.IsButtonDown( MOUSE_LEFT ) then
                    callbacks.Unregister( "Draw", "mousedrag" .. randomtext )
                    return
                end
                drag_delta.x = mx - last_mouse_pos.x
                drag_delta.y = my - last_mouse_pos.y
                last_mouse_pos = {x=mx,y=my}

                for k,v in pairs (window_children) do
                    v.x = v.x + drag_delta.x
                    v.y = v.y + drag_delta.y
                end
                window.x = window.x + drag_delta.x
                window.y = window.y + drag_delta.y
            end)
        end
    )

callbacks.Register( "Draw", alib.rstring(128) ,function()
    window:render()
    button:render()
    topbar:render()
end)

callbacks.Register("Unload", function()
    alib.unload()
    window = nil
    button = nil
    topbar = nil
end)
