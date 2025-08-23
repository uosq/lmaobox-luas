--- made by navet

--- settings
local char = "*" --- the snowflakes, change them to whatever you want (letter or number)
local only_on_menu = false
local rainbow_balls = false      --- guaranteed rainbow snowflakes
local random_rainbow_balls = true
local chance_of_rainbow_ball = 8 --- 1/N, with N = number you replace "8" with
local num_balls = 500            --- its a good compromise, if you want more i recommend lowering the font size (22 is the default here)

local vertical_wind = 3
local width, height = draw.GetScreenSize()
local font = draw.CreateFont("Arial", 22, 1000)

local normal_snowflake_color = {255, 255, 255, 255} --- R G B A (Red Green Blue Alpha)
---

--- pre cache these functions, for some reason makes the stuttering stop (or reduce)
local Text = draw.Text --
local Color = draw.Color
local SetFont = draw.SetFont
local IsMenuOpen = gui.IsMenuOpen

local math_random = math.random
local math_floor = math.floor
local math_randomseed = math.randomseed
local ipairs = ipairs

local balls = {}
local flake = tostring(char)

local function create_ball()
   local x = math_random(0, width)
   local y = math_random(-height, 0)

   local color = { math_random(0, 255), math_random(0, 255), math_random(0, 255), 255 }

   return math_floor(x), math_floor(y),
       ((math_random(chance_of_rainbow_ball) == 1 and random_rainbow_balls) or rainbow_balls) and color or normal_snowflake_color
end

--- create the balls
for i = 1, num_balls do
   balls[i] = { create_ball() }
end

-- Update ball position
---@param param UserCmd
callbacks.Register("CreateMove", function(param)
   if only_on_menu and not IsMenuOpen() then return end
   math_randomseed(param.tick_count) --- tick_count is like os.clock
   for i = 1, num_balls do
      -- Reset if snowflake goes off screen
      if balls[i][1] > width or balls[i][1] < 0 or balls[i][2] > height then
         balls[i] = { create_ball() }
      end

      balls[i][2] = balls[i][2] + vertical_wind + math_random(0, 3)

      -- Random horizontal movement
      if math_random(1, 32) == 1 then
         balls[i][1] = balls[i][1] + math_random(-2, 2)
      end
   end
end)

-- Draw snowflakes
callbacks.Register("Draw", function()
   if only_on_menu and not IsMenuOpen() then return end

   SetFont(font)
   for k, ball in ipairs(balls) do
      local x, y, color = ball[1], ball[2], ball[3]
      if y > 0 and y < height and x > 0 and x < width then
         Color(color[1], color[2], color[3], color[4])
         Text(x, y, flake)
      end
   end
end)
