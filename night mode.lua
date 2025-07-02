--- made by navet

--- 1.0 to 0.0, more or less than that and it will simply clamp to 0.0 or 1.0
local brightness = 10

---@param r number
---@param g number
---@param b number
---@param sky boolean
local function apply_color(r, g, b, sky)
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
			--material:SetShaderParam("$color2", Vector3(r, g, b))
			material:ColorModulate(r, g, b)
		end
	end)
end

local function Prop()
	render.SetColorModulation(brightness / 100, brightness / 100, brightness / 100)
end

---@param ctx DrawModelContext
local function DrawModel(ctx)
	--- does this work 100%? fuck no
	--- but it should work 80% enough
	if string.find(ctx:GetModelName(), "prop") then
		if brightness <= 20 then
			ctx:SetColorModulation((30 + brightness) / 100, (30 + brightness) / 100, (30 + brightness) / 100)
		else
			ctx:SetColorModulation(brightness / 100, brightness / 100, brightness / 100)
		end
	end
end

local function Unload()
	apply_color(1, 1, 1, false)
end

apply_color(brightness / 100, brightness / 100, brightness / 100, false)

--callbacks.Register("DrawStaticProps", Prop)
callbacks.Register("DrawModel", DrawModel)
callbacks.Register("Unload", Unload)
