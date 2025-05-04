--- made by navet

--- settings
--- aim method of the slow weapons
--- like spy's revolvers, scout's scattergun, shotguns, etc
local slow <const> = "silent"

--- aim method of the fast weapons
--- like miniguns, pistols, etc
local fast <const> = "smooth"
--- settings

local function Run()
  local plocal = entities.GetLocalPlayer()
  if not plocal then return end
  if not plocal:IsAlive() then return end

  local pweapon = plocal:GetPropEntity("m_hActiveWeapon")
  if not pweapon then return end

  local data = pweapon:GetWeaponData()

  --- the weapon shoots fast
  --- the * 10 and the flooring is because
  --- we want to lose a bit of accuracy, or else
  --- the value would be something like
  --- 1.0000000099
  local delay = (data.timeFireDelay * 10) // 1
  if delay <= 1 then
    gui.SetValue("aim method", fast)
  else
    gui.SetValue("aim method", slow)
  end
end

callbacks.Register("CreateMove", Run)
