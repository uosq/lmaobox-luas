--- I am not smart enough to make this by myself
--- Source: https://www.unknowncheats.me/forum/team-fortress-2-a/700159-simple-glow-outline.html

--- make the lsp stop complaining about nil shit
---@diagnostic disable: param-type-mismatch

---@class Context
---@field mouseX integer
---@field mouseY integer
---@field mouseDown boolean
---@field mouseReleased boolean
---@field mousePressed boolean
---@field tick integer
---@field lastPressedTick integer
---@field windowX integer
---@field windowY integer

local theme = {
    bg_light = { 45, 45, 45 },
    bg = { 35, 35, 35 },
    bg_dark = { 30, 30, 30 },
    primary = { 143, 188, 187 },
    success = { 69, 255, 166 },
    fail = { 255, 69, 69 },
}

local thickness = 1    --- outline thickness
local header_size = 25 --- title height
local tab_section_height = 25

local max_objects_per_column = 9
local column_spacing = 10
local row_spacing = 5
local element_margin = 5

---@class GuiWindow
local window = {
    dragging = false,
    mx = 0,
    my = 0,
    x = 0,
    y = 0,
    w = 0,
    h = 0,
    title = "",
    tabs = {},
    current_tab = 1,
}

local lastPressedTick = 0
local font = draw.CreateFont("TF2 BUILD", 12, 400, FONTFLAG_ANTIALIAS | FONTFLAG_CUSTOM)
local white_texture = draw.CreateTextureRGBA(string.rep(string.char(255, 255, 255, 255), 4), 2, 2)

---@param texture TextureID
---@param centerX integer
---@param centerY integer
---@param radius integer
---@param segments integer
local function DrawFilledCircle(texture, centerX, centerY, radius, segments)
    local vertices = {}

    for i = 0, segments do
        local angle = (i / segments) * math.pi * 2
        local x = centerX + math.cos(angle) * radius
        local y = centerY + math.sin(angle) * radius
        vertices[i + 1] = { x, y, 0, 0 }
    end

    draw.TexturedPolygon(texture, vertices, false)
end

function window.Draw(self)
    if (not gui.IsMenuOpen()) then
        return
    end

    local x, y = self.x, self.y
    local tab = self.tabs[self.current_tab]
    local w = (tab and tab.w or 200)
    local h = (tab and tab.h or 200)
    local title = self.title

    local mousePressed, tick = input.IsButtonPressed(E_ButtonCode.MOUSE_LEFT)
    local mousePos = input.GetMousePos()

    local numTabs = #self.tabs
    local extra_height = (numTabs > 1) and tab_section_height or 0

    if (title and #title > 0) then
        local header_x1 = x - thickness
        local header_y1 = y - header_size
        local header_x2 = x + w + thickness
        local header_y2 = y - thickness

        local mx, my = mousePos[1], mousePos[2]
        local mouseInHeader = mx >= header_x1 and mx <= header_x2
            and my >= header_y1 and my <= header_y2

        if (mouseInHeader and mousePressed) then
            self.dragging = true
        end
    end

    if (not input.IsButtonDown(E_ButtonCode.MOUSE_LEFT)) then
        self.dragging = false
    end

    local dx, dy = mousePos[1] - self.mx, mousePos[2] - self.my
    if (self.dragging) then
        self.x = self.x + dx
        self.y = self.y + dy
    end

    draw.SetFont(font)

    local total_h = h + extra_height

    draw.Color(theme.primary[1], theme.primary[2], theme.primary[3], 255)
    draw.OutlinedRect(x - thickness, y - thickness, x + w + thickness, y + total_h + thickness)

    draw.Color(theme.bg[1], theme.bg[2], theme.bg[3], 255)
    draw.FilledRect(x, y, x + w, y + total_h)

    -- header
    if (title and #title > 0) then
        draw.Color(theme.primary[1], theme.primary[2], theme.primary[3], 255)
        draw.FilledRect(x - thickness, y - header_size, x + w + thickness, y - thickness)

        local tw, th = draw.GetTextSize(title)
        local tx = (x - thickness + w * 0.5 - tw * 0.5) // 1
        local ty = (y - thickness - header_size * 0.5 - th * 0.5) // 1

        draw.Color(242, 242, 242, 255)
        draw.Text(tx, ty, title)
    end

    local content_x = x
    local content_y = y + extra_height

    local context = {
        mouseX = mousePos[1],
        mouseY = mousePos[2],
        mouseDown = input.IsButtonDown(E_ButtonCode.MOUSE_LEFT),
        mouseReleased = input.IsButtonReleased(E_ButtonCode.MOUSE_LEFT),
        mousePressed = mousePressed,
        tick = tick,
        lastPressedTick = lastPressedTick,
        windowX = content_x,
        windowY = content_y,
    }

    if (tab) then
        for i = #tab.objs, 1, -1 do
            local obj = tab.objs[i]
            if obj then
                obj:Draw(context)
            end
        end
    end

    lastPressedTick = tick
    self.mx, self.my = mousePos[1], mousePos[2]
end

--- recalculates positions of all objs in all tabs
--- and adjusts window size to fit contents
function window:RecalculateLayout(tab_index)
    if not tab_index or not self.tabs[tab_index] then return end
    local tab = self.tabs[tab_index]

    local columns = {}
    local col, row = 1, 0

    for i, obj in ipairs(tab.objs) do
        if not columns[col] then
            columns[col] = {}
        end

        table.insert(columns[col], obj)
        row = row + 1

        if row >= max_objects_per_column then
            row = 0
            col = col + 1
        end
    end

    local num_columns = #columns
    local total_spacing = (num_columns - 1) * column_spacing + element_margin * 2

    local min_window_width = 200

    if #self.tabs > 1 then
        local total_tabs_width = 0
        for i, t in ipairs(self.tabs) do
            local tab_button_width = math.max(80, draw.GetTextSize(t.name) + 20)
            total_tabs_width = (total_tabs_width + tab_button_width) // 1
        end

        if total_tabs_width > min_window_width then
            min_window_width = total_tabs_width // 1
        end
    end

    local available_width = min_window_width - total_spacing
    local column_width = available_width / num_columns

    local max_height = 0

    for col_idx, column in ipairs(columns) do
        local x_offset = element_margin + (col_idx - 1) * (column_width + column_spacing)

        for row_idx, obj in ipairs(column) do
            obj.x = x_offset // 1
            obj.y = (element_margin + (row_idx - 1) * (obj.h + row_spacing)) // 1
            obj.w = column_width // 1

            local obj_bottom = obj.y + obj.h
            if obj_bottom > max_height then
                max_height = obj_bottom
            end
        end
    end

    tab.w = min_window_width // 1
    tab.h = (max_height + element_margin) // 1
end

function window:InsertElement(object, tab_index)
    tab_index = tab_index or self.current_tab or 1
    if (tab_index > #self.tabs or tab_index < 0) then
        error(string.format("Invalid tab index! Received %s", tab_index))
        return false
    end

    local tab = self.tabs[tab_index]
    tab.objs[#tab.objs + 1] = object
    self:RecalculateLayout(tab_index)
    return true
end

---@param func fun(checked: boolean)?
function window:CreateToggle(tab_index, width, height, label, checked, func)
    local btn = {
        x = 0,
        y = 0,
        w = width,
        h = height,
        label = label,
        func = func,
        checked = checked,
    }

    ---@param context Context
    function btn:Draw(context)
        local bx, by, bw, bh
        bx = self.x + context.windowX
        by = self.y + context.windowY
        bw = self.w
        bh = self.h

        local mx, my = context.mouseX, context.mouseY
        local mouseInside = mx >= bx and mx <= bx + bw
            and my >= by and my <= by + bh

        draw.Color(theme.primary[1], theme.primary[2], theme.primary[3], 255)
        draw.OutlinedRect(bx - thickness, by - thickness, bx + bw + thickness, by + bh + thickness)

        if (mouseInside and context.mouseDown) then
            draw.Color(theme.primary[1], theme.primary[2], theme.primary[3], 255)
        elseif (mouseInside) then
            draw.Color(theme.bg_light[1], theme.bg_light[2], theme.bg_light[3], 255)
        else
            draw.Color(theme.bg[1], theme.bg[2], theme.bg[3], 255)
        end
        draw.FilledRect(bx, by, bx + bw, by + bh)

        local tw, th = draw.GetTextSize(self.label)
        local tx, ty
        tx = bx + 2
        ty = (by + bh * 0.5 - th * 0.5) // 1

        draw.Color(242, 242, 242, 255)
        draw.Text(tx, ty, label)

        local circle_x = bx + bw - 10
        local circle_y = (by + bh * 0.5) // 1
        local radius = 8

        if (btn.checked) then
            draw.Color(theme.success[1], theme.success[2], theme.success[3], 255)
        else
            draw.Color(theme.fail[1], theme.fail[2], theme.fail[3], 255)
        end

        DrawFilledCircle(white_texture, circle_x, circle_y, radius, 4)

        if (mouseInside and context.mousePressed and context.tick > context.lastPressedTick) then
            btn.checked = not btn.checked

            if (func) then
                func(btn.checked)
            end
        end
    end

    self:InsertElement(btn, tab_index or self.current_tab)
    return btn
end

---@param func fun(value: number)?
function window:CreateSlider(tab_index, width, height, label, min, max, currentvalue, func)
    local slider = {
        x = 0,
        y = 0,
        w = width,
        h = height,
        label = label,
        func = func,
        min = min,
        max = max,
        value = currentvalue
    }

    ---@param context Context
    function slider:Draw(context)
        local bx, by, bw, bh
        bx = self.x + context.windowX
        by = self.y + context.windowY
        bw = self.w
        bh = self.h

        local mx, my = context.mouseX, context.mouseY
        local mouseInside = mx >= bx and mx <= bx + bw
            and my >= by and my <= by + bh

        --- draw outline
        draw.Color(theme.primary[1], theme.primary[2], theme.primary[3], 255)
        draw.OutlinedRect(bx - thickness, by - thickness, bx + bw + thickness, by + bh + thickness)

        --- draw background based on mouse state
        if (mouseInside and context.mouseDown) then
            draw.Color(theme.bg_light[1], theme.bg_light[2], theme.bg_light[3], 255)
        elseif (mouseInside) then
            draw.Color(theme.bg[1], theme.bg[2], theme.bg[3], 255)
        else
            draw.Color(theme.bg_dark[1], theme.bg_dark[2], theme.bg_dark[3], 255)
        end
        draw.FilledRect(bx, by, bx + bw, by + bh)

        -- calculate percentage for the slider fill
        local percent = (self.value - self.min) / (self.max - self.min)
        percent = math.max(0, math.min(1, percent)) --- clamp it ;)

        --- draw slider fill
        draw.Color(theme.primary[1], theme.primary[2], theme.primary[3], 255)
        draw.FilledRect(bx, by, (bx + (bw * percent)) // 1, by + bh)

        --- draw label text
        local tw, th = draw.GetTextSize(self.label)
        local tx, ty
        tx = bx + 2
        ty = (by + bh * 0.5 - th * 0.5) // 1
        draw.Color(242, 242, 242, 255)
        draw.TextShadow(tx + 2, ty, self.label)

        tw = draw.GetTextSize(string.format("%.0f", self.value))
        tx = bx + bw - tw - 2
        draw.TextShadow(tx, ty, string.format("%.0f", self.value))

        --- handle mouse interaction
        if (mouseInside and context.mousePressed and context.tick > context.lastPressedTick) then
            self.isDragging = true
        end

        --- continue dragging even if mouse is outside the slider
        if (self.isDragging and context.mouseDown) then
            --- update slider value based on mouse position
            local mousePercent = (mx - bx) / bw
            mousePercent = math.max(0, math.min(1, mousePercent))
            self.value = self.min + (self.max - self.min) * mousePercent

            if (self.func) then
                self.func(self.value)
            end
        elseif (not context.mouseDown) then
            --- stop dragging when mouse is released
            self.isDragging = false
        end
    end

    self:InsertElement(slider, tab_index or self.current_tab)
    return slider
end

function window:CreateLabel(tab_index, width, height, text, func)
    local label = {
        x = 0,
        y = 0,
        w = width,
        h = height,
        text = text,
    }

    ---@param context Context
    function label:Draw(context)
        local x, y, tw, th
        tw, th = draw.GetTextSize(self.text)
        x = (context.windowX + self.x + (self.w * 0.5) - (tw * 0.5)) // 1
        y = (context.windowY + self.y + (self.h * 0.5) - (th * 0.5)) // 1
        draw.Color(255, 255, 255, 255)
        draw.TextShadow(x, y, tostring(text))
    end

    self:InsertElement(label, tab_index or self.current_tab)
    return label
end

---@return GuiWindow
function window.New(tbl)
    local newWindow = tbl or {}
    setmetatable(newWindow, { __index = window })
    newWindow.tabs[1] = { name = "", objs = {} }
    return newWindow
end

---

--- config
local stencil = 3
local glow = 0
local weapon = true
local players = true
local sentries = true
local dispensers = true
local teleporters = true
local medammo = true
local viewmodel = true

--- materials
local m_pMatGlowColor = nil
local m_pMatHaloAddToScreen = nil
local m_pMatBlurX = nil
local m_pMatBlurY = nil
local pRtFullFrame = nil
local m_pGlowBuffer1 = nil
local m_pGlowBuffer2 = nil

local function InitMaterials()
	if m_pMatGlowColor == nil then
		m_pMatGlowColor = materials.Find("dev/glow_color")
	end

	if m_pMatHaloAddToScreen == nil then
		m_pMatHaloAddToScreen = materials.Create("GlowMaterialHalo",
		[[UnlitGeneric
		{
			$basetexture "GlowBuffer1"
			$additive "1"
		}]])
	end

	if m_pMatBlurX == nil then
		m_pMatBlurX = materials.Create("GlowMatBlurX",
		[[BlurFilterX
		{
			$basetexture "GlowBuffer1"
		}]]);
	end

	if m_pMatBlurY == nil then
		m_pMatBlurY = materials.Create("GlowMatBlurY",
		[[BlurFilterY
		{
			$basetexture "GlowBuffer2"
		}]])
	end

	if pRtFullFrame == nil then
		pRtFullFrame = materials.FindTexture("_rt_FullFrameFB", "RenderTargets", true);
	end

	if m_pGlowBuffer1 == nil then
		m_pGlowBuffer1 = materials.CreateTextureRenderTarget(
			"GlowBuffer1",
			pRtFullFrame:GetActualWidth(),
			pRtFullFrame:GetActualHeight()
		)
	end

	if m_pGlowBuffer2 == nil then
		m_pGlowBuffer2 = materials.CreateTextureRenderTarget(
			"GlowBuffer2",
			pRtFullFrame:GetActualWidth(),
			pRtFullFrame:GetActualHeight()
		)
	end
end

local STUDIO_RENDER = 0x00000001
local STUDIO_NOSHADOWS = 0x00000080

local function GetGuiColor(option)
    local value = gui.GetValue(option)
    if value == 255 then
        return nil
    elseif value == -1 then
	return {1, 1, 1, 1}
    end

    -- convert signed 32-bit int to unsigned 32-bit
    if value < 0 then
        value = value + 0x100000000
    end

    local r = (value >> 24) & 0xFF
    local g = (value >> 16) & 0xFF
    local b = (value >> 8)  & 0xFF
    local a = value & 0xFF

    return { r * 0.003921, g * 0.003921, b * 0.003921, a * 0.003921 }
end

local function GetColor(entity)
	if entity:GetClass() == "CBaseAnimating" then
		local modelName = models.GetModelName(entity:GetModel())
		if string.find(modelName, "ammopack") then
			return {1.0, 1.0, 1.0, 1.0}
		elseif string.find(modelName, "medkit") then
			return {0.15294117647059, 0.96078431372549, 0.32941176470588, 1.0}
		end
	end

	local color = GetGuiColor("aimbot target color")
	if aimbot.GetAimbotTarget() == entity:GetIndex() and color then
		return color
	end

	if playerlist.GetPriority(entity) > 0 then
		return {1, 1, 0.0, 1}
	elseif playerlist.GetPriority(entity) < 0 then
		return {0, 1, 0.501888, 1}
	end

	if entity:GetTeamNumber() == 3 then
		return GetGuiColor("blue team color") or {0.145077, 0.58815, 0.74499, 1}
	else
		return GetGuiColor("red team color") or {0.929277, 0.250944, 0.250944, 1}
	end
end

local function DrawEntities(players)
	for index, color in pairs (players) do
		local player = entities.GetByIndex(index)
		if player then
			render.SetColorModulation(table.unpack(color))
			player:DrawModel(STUDIO_RENDER | STUDIO_NOSHADOWS)
		end
	end
end

local function GetPlayers(outTable)
	local count = 0
	for _, player in pairs (entities.FindByClass("CTFPlayer")) do
		if player:ShouldDraw() and player:IsDormant() == false then
			local color = GetColor(player)
			outTable[player:GetIndex()] = color
			local child = player:GetMoveChild()
			while child ~= nil do
				if weapon and (child:IsShootingWeapon() or child:IsMeleeWeapon()) then
					outTable[child:GetIndex()] = {1, 1, 1, 1}
				else
					outTable[child:GetIndex()] = color
				end
				count = count + 1
				child = child:GetMovePeer()
			end

			count = count + 1
		end
	end
	return count
end

local function GetClass(className, outTable)
	local count = 0
	for _, building in pairs(entities.FindByClass(className)) do
		if building:ShouldDraw() and building:IsDormant() == false then
			outTable[building:GetIndex()] = GetColor(building)
			count = count + 1
		end
	end
	return count
end

local function OnDoPostScreenSpaceEffects()
	if engine.IsTakingScreenshot() then
		return
	end

	if clientstate.GetNetChannel() == nil then
		return
	end

	InitMaterials()

	local glowEnts = {}
	local entCount = 0
	if players then
		entCount = entCount + GetPlayers(glowEnts)
	end

	if sentries then
		entCount = entCount + GetClass("CObjectSentrygun", glowEnts)
	end

	if dispensers then
		entCount = entCount + GetClass("CObjectDispenser", glowEnts)
	end

	if teleporters then
		entCount = entCount + GetClass("CObjectTeleporter", glowEnts)
	end

	if medammo then
		entCount = entCount + GetClass("CBaseAnimating", glowEnts)
	end

	if viewmodel then
		local plocal = entities.GetLocalPlayer()
		if plocal and plocal:GetPropBool("m_nForceTauntCam") == false and plocal:InCond(E_TFCOND.TFCond_Taunting) == false then
			local _, _, cvar = client.GetConVar("cl_first_person_uses_world_model")
			if cvar == "0" then
				entCount = entCount + GetClass("CTFViewModel", glowEnts)
			end
		end
	end

	if entCount == 0 then
		return
	end

	local origGlowVal = gui.GetValue("glow")
	gui.SetValue("glow", 0)

	local w, h = draw.GetScreenSize()

	--- Stencil Pass
	do
		render.SetStencilEnable(true)

		render.ForcedMaterialOverride(m_pMatGlowColor)
		local savedBlend = render.GetBlend()
		render.SetBlend(0)

		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(E_StencilComparisonFunction.STENCILCOMPARISONFUNCTION_ALWAYS)
		render.SetStencilPassOperation(E_StencilOperation.STENCILOPERATION_REPLACE)
		render.SetStencilFailOperation(E_StencilOperation.STENCILOPERATION_KEEP)
		render.SetStencilZFailOperation(E_StencilOperation.STENCILOPERATION_REPLACE)

		DrawEntities(glowEnts)

		render.SetBlend(savedBlend)
		render.ForcedMaterialOverride(nil)
		render.SetStencilEnable(false)
	end

	--- Color pass
	do
		render.PushRenderTargetAndViewport()

		local r, g, b = render.GetColorModulation()

		local savedBlend = render.GetBlend()
		render.SetBlend(1.0)

		render.SetRenderTarget(m_pGlowBuffer1)
		render.Viewport(0, 0, w, h)

		render.ClearColor3ub(0, 0, 0)
		render.ClearBuffers(true, false, false)

		render.ForcedMaterialOverride(m_pMatGlowColor)

		DrawEntities(glowEnts)

		render.ForcedMaterialOverride(nil)
		render.SetColorModulation(r, g, b)
		render.SetBlend(savedBlend)

		render.PopRenderTargetAndViewport()
	end

	--- Blur pass
	if glow > 0 then
		render.PushRenderTargetAndViewport()
		render.Viewport(0, 0, w, h)

		-- More blur iterations = blurrier (does this word exist?) glow
		for i = 1, glow do
			render.SetRenderTarget(m_pGlowBuffer2)
			render.DrawScreenSpaceRectangle(m_pMatBlurX, 0, 0, w, h, 0, 0, w - 1, h - 1, w, h)
			render.SetRenderTarget(m_pGlowBuffer1)
			render.DrawScreenSpaceRectangle(m_pMatBlurY, 0, 0, w, h, 0, 0, w - 1, h - 1, w, h)
		end

		render.PopRenderTargetAndViewport()
	end

	--- Final pass
	do
		render.SetStencilEnable(true)
		render.SetStencilWriteMask(0)
		render.SetStencilTestMask(0xFF)

		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(E_StencilComparisonFunction.STENCILCOMPARISONFUNCTION_NOTEQUAL)

		render.SetStencilPassOperation(E_StencilOperation.STENCILOPERATION_KEEP)
		render.SetStencilFailOperation(E_StencilOperation.STENCILOPERATION_KEEP)
		render.SetStencilZFailOperation(E_StencilOperation.STENCILOPERATION_KEEP)

		--- my code to make the glow work
		--- not used anymore :(
		--[[render.DrawScreenSpaceRectangle(
			m_pMatHaloAddToScreen,
			0, 0,
			w, h,
			0, 0,
			w - 1, h - 1,
			w, h
		)]]

		--- pasted from amalgam
		--- https://github.com/rei-2/Amalgam/blob/fce4740bf3af0799064bf6c8fbeaa985151b708c/Amalgam/src/Features/Visuals/Glow/Glow.cpp#L65
		if stencil > 0 then
			local iSide = (stencil + 1) // 2
			render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, -iSide, 0, w, h, 0, 0, w - 1, h - 1, w, h);
			render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, 0, -iSide, w, h, 0, 0, w - 1, h - 1, w, h);
			render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, iSide, 0, w, h, 0, 0, w - 1, h - 1, w, h);
			render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, 0, iSide, w, h, 0, 0, w - 1, h - 1, w, h);
			local iCorner = stencil // 2
			if (iCorner > 0) then
				render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, -iCorner, -iCorner, w, h, 0, 0, w - 1, h - 1, w, h);
				render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, iCorner, iCorner, w, h, 0, 0, w - 1, h - 1, w, h);
				render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, iCorner, -iCorner, w, h, 0, 0, w - 1, h - 1, w, h);
				render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, -iCorner, iCorner, w, h, 0, 0, w - 1, h - 1, w, h);
			end
		end

		if glow > 0 then
			render.DrawScreenSpaceRectangle(m_pMatHaloAddToScreen, 0, 0, w, h, 0, 0, w - 1, h - 1, w, h);
		end

		render.SetStencilEnable(false)
	end

	gui.SetValue("glow", origGlowVal)

	render.SetColorModulation(1, 1, 1)
end

--- very janky fix
local function OnDrawModel(ctx)
	local entity = ctx:GetEntity()
	if entity == nil or entity:GetClass() ~= "CTFViewModel" then
		return
	end

	OnDoPostScreenSpaceEffects()
end

local wind = window.New()
wind:CreateSlider(1, 100, 20, "Blurriness", 0, 30, glow, function (value)
	glow = value//1
end)

wind:CreateSlider(1, 100, 20, "Stencil", 0, 30, stencil, function (value)
	stencil = value//1
end)

wind:CreateToggle(1, 20, 20, "Weapons", weapon, function (checked)
	weapon = checked
end)

wind:CreateToggle(1, 20, 20, "Players", players, function (checked)
	players = checked
end)

wind:CreateToggle(1, 20, 20, "Dispensers", dispensers, function (checked)
	dispensers = checked
end)

wind:CreateToggle(1, 20, 20, "Teleporters", teleporters, function (checked)
	teleporters = checked
end)

wind:CreateToggle(1, 20, 20, "Med Kit / Ammo", players, function (checked)
	medammo = checked
end)

wind:CreateToggle(1, 20, 20, "ViewModel", viewmodel, function (checked)
	viewmodel = checked
end)

wind.title = "Glow Settings"
wind.x = 10
wind.y = 50

local function OnDraw()
	wind:Draw()
end

callbacks.Register("DoPostScreenSpaceEffects", OnDoPostScreenSpaceEffects)
callbacks.Register("Draw", OnDraw)
callbacks.Register("Unload", function ()
	draw.DeleteTexture(white_texture)
end)
--callbacks.Register("DrawModel", OnDrawModel)