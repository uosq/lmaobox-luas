local events = {}

---@param arguments string
local function ChangeClass(arguments) end

local event_type <const> = {
	changeclass = ChangeClass,
	death = "death",
	respawn = "respawn",
	weapon = "weapon",
}

local default_command <const> = "setevent"

local function AddEvent(cmd_type, name, args)
	events[cmd_type][name] = args
end

--- setevent "NAME" changeclass soldier option="aim bot"

---@param cmd StringCmd
local function RunCommand(cmd)
	local command = cmd:Get()
	if string.find(command, "%s") then
		local words = {}
		for word in string.gmatch(command, "%S+") do
			words[#words + 1] = word
		end

		local cmd_name <const> = words[1]
		if cmd_name == default_command then
			table.remove(words, 1)
			local event_name <const> = table.concat(words, " ", 1, 3):match('"(.-)"')
			local cmd_type <const> = table.remove(words, 2)
			local args <const> = table.concat(words, " ")
			--AddEvent(cmd_type, event_name, args)
			print(string.format("event_name: %s, cmd_type: %s, args: %s", event_name, cmd_type, args))
			cmd:Set("")
		end
	end
end

callbacks.Register("SendStringCmd", "SetEventStuff", RunCommand)
