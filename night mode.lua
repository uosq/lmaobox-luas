local brightness = 0.3

---@param r number
---@param g number
---@param b number
---@param a number
---@param sky boolean
local function apply_color(r, g, b, a, sky)
	a = a or 1
	materials.Enumerate(function(material)
		local group = material:GetTextureGroupName()
		local name = material:GetName()
		if
			(sky and group == "SkyBox textures")
			or group == "World textures"
			or string.find(name, "concrete")
			or string.find(name, "wood")
			or string.find(name, "nature")
			or string.find(name, "wall")
		then
			material:ColorModulate(r, g, b)
			material:AlphaModulate(a)
			material:SetShaderParam("$color2", Vector3(r, g, b))
		end
	end)
end

local function Prop()
	render.SetColorModulation(1 - brightness, 1 - brightness, 1 - brightness)
end

---@param ctx DrawModelContext
local function DrawModel(ctx)
	local ent = ctx:GetEntity()
	if string.find(ctx:GetModelName(), "prop") then
		ctx:SetColorModulation(brightness, brightness, brightness)
	end
end

local function Unload()
	apply_color(1, 1, 1, 1, false)
end

apply_color(brightness, brightness, brightness, 1, false)

callbacks.Register("DrawStaticProps", Prop)
callbacks.Register("DrawModel", DrawModel)
callbacks.Register("Unload", Unload)
