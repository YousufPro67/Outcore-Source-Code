local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BloxbizSDK = script.Parent.Parent
local Utils = require(BloxbizSDK.Utils)

local CommandToolConfig = ReplicatedStorage:FindFirstChild("SBCommandsConfig")
if CommandToolConfig then
	CommandToolConfig = require(CommandToolConfig)
end

local COMMANDS = require(script.Parent.Commands)

local DEFAULTS = {
	CommandPrefix = ";",
	DefaultRank = {"default",},

	Ranks = {
		default = {
			Name = "Default",
			CommandPermissions = {
				Commands = {"bighead", "smallhead", "superwalk", "loserwalk", "superjump", "loserjump",},
			},
			ObtainDescription = "This is how to obtain the Default rank.",
		},

		admin = {
			Name = "Admin",
			CommandPermissions = {
				Commands = {"_all",},
			},
			ObtainDescription = "This is how to obtain the Admin rank.",
		},
	},
}

local Config = {}

function Config:Read(property)
	if CommandToolConfig and CommandToolConfig[property] then
		return CommandToolConfig[property]
	else
		return DEFAULTS[property]
	end
end

local Permissions = {}

local Ranks = Config:Read("Ranks")

local AllCommands = {}
for commandId in COMMANDS do
	AllCommands[commandId] = true
end

local IgnoreInheritance = {}

-- Set up commands
for rankId, rankData in Ranks do
	local permissions = rankData.CommandPermissions
	if not permissions then
		continue
	end

	local commands = permissions.Commands
	if typeof(commands) ~= "table" then
		continue
	end
	Permissions[rankId] = {}

	local hasAll = table.find(commands, "_all")
	if hasAll then
		Permissions[rankId] = Utils.copyTable(AllCommands)

		table.remove(commands, hasAll)
		for _, command in commands do
			if command:sub(1, 1) == "-" then
				Permissions[rankId][command] = nil
			end
		end

		IgnoreInheritance[rankId] = true
		continue
	end

	for _, command in commands do
		command = command:lower()
		if command:sub(1, 1) == "-" then
			Permissions[rankId][command:sub(2)] = false
		else
			Permissions[rankId][command] = true
		end
	end
end

-- Set up inheritance
for rankId, rankData in Ranks do
	if IgnoreInheritance[rankId] then
		continue
	end

	local permissions = rankData.CommandPermissions
	if not permissions then
		continue
	end

	local inheritFrom = permissions.InheritFrom
	if not inheritFrom then
		continue
	end

	if typeof(inheritFrom) ~= "table" then
		continue
	end

	for _, inheritedRankId in inheritFrom do
		-- Cannot inherit yourself
		if inheritedRankId == rankId then
			continue
		end

		local isValidRank = Ranks[inheritedRankId]
		if not isValidRank then
			continue
		end

		local inheritedPermissions = isValidRank.CommandPermissions
		if not inheritedPermissions then
			continue
		end

		local inheritedCommands = inheritedPermissions.Commands
		if typeof(inheritedCommands) ~= "table" then
			continue
		end

		for _, command in inheritedCommands do
			if command == "_all" then
				continue
			end

			if command:sub(1, 1) == "-" then
				continue
			end

			if Permissions[rankId][command] == false then
				Permissions[rankId][command] = nil
				continue
			end

			Permissions[rankId][command] = true
		end
	end
end

local RankGamepasses = {}

for rankId, rankData in Ranks do
	local gamepassId = rankData.ObtainButtonGamepass
	if not gamepassId or not tonumber(gamepassId) then
		continue
	end

	RankGamepasses[gamepassId] = rankId
end

function Config:GetAllRankGamepasses()
	return RankGamepasses
end

function Config:IsRankGamepass(gamepassId)
	return RankGamepasses[gamepassId]
end

function Config:CanUseCommand(rankId, command)
	local permissions = Permissions[rankId]
	if not permissions then
		return
	end

	return permissions[command]
end

return Config