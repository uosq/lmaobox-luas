--- made by navet

---@diagnostic disable: cast-local-type
local font = draw.CreateFont("TF2 BUILD", 16, 1000)
local netvar = "m_flChargedDamage"

local machina_index = 526

local function clamp(num, min, max)
   return math.max(min, math.min(num, max))
end

local function Draw()
   local player <const> = entities:GetLocalPlayer()
   if not player then return end
   if not player:IsAlive() then return end
   if engine:IsGameUIVisible() or engine:Con_IsVisible() or engine:IsTakingScreenshot() then return end

   local weapon <const> = player:GetPropEntity("m_hActiveWeapon")
   if not weapon then return end

   if not player:InCond(E_TFCOND.TFCond_Zoomed)
   and weapon:GetWeaponID() ~= E_WeaponBaseID.TF_WEAPON_SNIPERRIFLE_CLASSIC then return end

   local screenW <const>, screenH <const> = draw.GetScreenSize()

   local m_flChargedDamage <const> = weapon:GetPropFloat("SniperRifleLocalData", netvar)
   local defindex <const> = weapon:GetPropInt("m_Item", "m_iItemDefinitionIndex")
   local multiplier <const> = defindex == machina_index and 1.15 or 1

   draw.SetFont(font)
   local unformattedtext <const> = "%1.f"
   local bodyshot <const> = string.format(unformattedtext, m_flChargedDamage * multiplier)
   local textW, textH = draw.GetTextSize(bodyshot)

   local r , g
   local percent <const> = bodyshot/(150*multiplier)
   r = math.floor((1 - percent) * 255)
   g = math.floor(percent * 255)

   r = clamp(r, 0, 255)
   g = clamp(g, 0, 255)

   local critshot <const> = string.format(unformattedtext, m_flChargedDamage * 3 * multiplier)
   local critW <const>, critH <const> = draw.GetTextSize(critshot)

   draw.Color(r, g, 0, 255)
   draw.TextShadow( math.floor((screenW*0.5) - textW*0.5), math.floor( (screenH * 0.5) + textH + 15 ), bodyshot )

   draw.Color(r, g, 0, 255)
   draw.TextShadow( math.floor((screenW*0.5) - critW*0.5), math.floor( (screenH * 0.5) + critH + textH + 15 ), critshot )
end

local function Unload()
   font = nil
   machina_index = nil
   netvar = nil
   callbacks.Unregister("Draw", "scoped charge")
end

callbacks.Register("Draw", "scoped charge", Draw)
callbacks.Register("Unload", "unload scoped charge", Unload)