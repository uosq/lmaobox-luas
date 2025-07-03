--- made by navet

--- settings

--- 0 to 100
local brightness = 10

--- end of settings

local value = brightness / 100

---@param r number
---@param g number
---@param b number
local function apply_color(r, g, b)
	materials.Enumerate(function(material)
		local group = material:GetTextureGroupName()
		local name = material:GetName()

		if
			group == "World textures"
			or string.find(name, "concrete")
			or string.find(name, "wood")
			or string.find(name, "nature")
			or string.find(name, "wall")
			or string.find(name, "overlays")
		then
			material:SetShaderParam("$color2", Vector3(r, g, b))
		end

		if string.find(name, "props") then
			if brightness <= 20 then
				material:SetShaderParam(
					"$color2",
					Vector3(((30 + brightness) / 100), ((30 + brightness) / 100), ((30 + brightness) / 100))
				)
			else
				material:SetShaderParam("$color2", Vector3(value, value, value))
			end
		end
	end)
end

local function unapply_color()
	materials.Enumerate(function(material)
		local group = material:GetTextureGroupName()
		local name = material:GetName()
		if
			group == "World textures"
			or string.find(name, "concrete")
			or string.find(name, "wood")
			or string.find(name, "nature")
			or string.find(name, "wall")
			or string.find(name, "props")
			or string.find(name, "overlays")
		then
			material:SetShaderParam("$color2", Vector3(1, 1, 1))
		end
	end)
end

local function Prop()
	if brightness <= 20 then
		render.SetColorModulation((30 + brightness) / 100, (30 + brightness) / 100, (30 + brightness) / 100)
	else
		render.SetColorModulation(value, value, value)
	end
end

---@param ctx DrawModelContext
local function DrawModel(ctx)
	--- does this work 100%? fuck no
	--- but it should work 80% enough
	if string.find(ctx:GetModelName(), "prop", 1, true) then
		if brightness <= 20 then
			ctx:SetColorModulation((30 + brightness) / 100, (30 + brightness) / 100, (30 + brightness) / 100)
		else
			ctx:SetColorModulation(value, value, value)
		end
	end
end

local function Unload()
	unapply_color()
end

apply_color(value, value, value)

callbacks.Register("DrawStaticProps", Prop)
callbacks.Register("DrawModel", DrawModel)
callbacks.Register("Unload", Unload)
