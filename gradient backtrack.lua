--- thanks glich

local start_point = { 255, 255, 0, 0 }
local end_point = { 0, 255, 255, 100 }

local index = 1
local id = 0

---@param a integer
---@param b integer
---@param t number
local function lerp(a, b, t)
	return a + (b - a) * t
end

---@param dme DrawModelContext
local function DrawModel(dme)
	if not dme:IsDrawingBackTrack() then
		index = 1
		id = 0
	end

	if dme:IsDrawingBackTrack() then
		local entity = dme:GetEntity()
		if not entity then
			return
		end

		local current_index = entity:GetIndex()

		if current_index == id then
			index = index + 1
		else
			id = current_index
			index = 1
		end

		local t = index / 15
		local r = lerp(start_point[1], end_point[1], t)
		local g = lerp(start_point[2], end_point[2], t)
		local b = lerp(start_point[3], end_point[3], t)
		local a = lerp(start_point[4], end_point[4], t)

		dme:SetColorModulation(r / 255, g / 255, b / 255)
		dme:SetAlphaModulation(a / 255 or 1)

		index = index + 1
	end
end

callbacks.Register("DrawModel", "gradient backtrack", DrawModel)
