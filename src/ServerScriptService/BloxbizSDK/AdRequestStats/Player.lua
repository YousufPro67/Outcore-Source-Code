local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(script.Parent.Parent.Utils)
local merge = Utils.merge

local REMOTES_FOLDER = "BloxbizRemotes"

local module = {}
module.playerStats = {}

local function newPlayerFired(player, clientPlayerStats)
    local AdRequestStats = require(script.Parent)
	local playerStats = merge(clientPlayerStats, AdRequestStats:getPlayerStats(player))
	module.playerStats[player.UserId] = playerStats
end

function module.init()
	local bloxbizFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER)

	bloxbizFolder.NewPlayerEvent.OnServerEvent:Connect(newPlayerFired)
end

return module