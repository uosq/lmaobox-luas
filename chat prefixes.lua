---@param str StringCmd
local function SendStringCmd(str)
	local text = str:Get()
	print(text)
end

callbacks.Register("SendStringCmd", SendStringCmd)
