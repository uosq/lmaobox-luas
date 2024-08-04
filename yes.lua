local alib = require("alib")

local window_theme = alib.theme:new(
    "TF2 BUILD",
    alib.rgba(80,80,80),
    nil, nil, alib.rgba(100,255,100)
)

local window = alib.window:create(
    'main window',
    400, 600, 800, 600,
    window_theme,
    2
)