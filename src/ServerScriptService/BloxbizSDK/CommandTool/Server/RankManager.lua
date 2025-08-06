local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")

local Utils = require(script.Parent.Parent.Parent.Utils)

local Config = require(script.Parent.Parent.Config)

local IsStudio = RunService:IsStudio()

local DATASTORE_VERSION = "006"
local DATASTORE_NAME = "COMMAND_TOOL_DATA" .. DATASTORE_VERSION
local AUTOSAVE_INTERVAL = 180
local SAVE_IN_STUDIO = false

local DEFAULT_DATA = {
	Ranks = Config:Read("DefaultRank"),
	RankGamepasses = {}
}

local DataStore = DataStoreService:GetDataStore(DATASTORE_NAME)

local RankManager = {}

local PlayersData = {}

local function updateRankAttribute(player, ranks)
	player:SetAttribute("SBCommandsRanks", table.concat(ranks, ","))
end

function RankManager.GetBoughtGamepasses(player)
	local data = PlayersData[player]
	if not data then
		return
	end

	return data.RankGamepasses
end

function RankManager.SaveGamepass(player, gamepassId)
	local data = PlayersData[player]
	if not data then
		return
	end

	data.RankGamepasses[gamepassId] = true
end

function RankManager.GetRanks(player)
	local data = PlayersData[player]
	if not data then
		return
	end

	return data.Ranks
end

function RankManager.HasRank(player, rankId)
	local ranks = RankManager.GetRanks(player)
	if not ranks then
		return
	end

	local rankIndex = table.find(ranks, rankId)
	return rankIndex ~= nil, rankIndex
end

function RankManager.AddRank(player, rankId)
	local validRanks = Config:Read("Ranks")
	if not validRanks[rankId] then
		warn("[SuperBiz] " .. rankId .. " is not a valid rank!")
		return
	end

	if RankManager.HasRank(player, rankId) then
		return
	end

	local ranks = RankManager.GetRanks(player)
	table.insert(ranks, rankId)

	updateRankAttribute(player, ranks)
end

function RankManager.RemoveRank(player, rankId)
	local validRanks = Config:Read("Ranks")
	if not validRanks[rankId] then
		warn("[SuperBiz] " .. rankId .. " is not a valid rank!")
		return
	end

	local _, rankIndex = RankManager.HasRank(player, rankId)
	if not rankIndex then
		return
	end

	local ranks = RankManager.GetRanks(player)
	table.remove(ranks, rankIndex)

	updateRankAttribute(player, ranks)
end

function RankManager.ClearRanks(player)
	PlayersData[player].Ranks = {}

	updateRankAttribute(player, {})
end

local function loadData(player)
	if not player.Parent then
		return
	end

	local data = Utils.callWithRetry(function()
		return DataStore:GetAsync(player.UserId)
	end, 5)

	if not player.Parent then
		Utils.pprint("[SuperBiz] " .. player.Name .. " left while loading rank data")
		return
	end

	if not data then
		PlayersData[player] = Utils.deepCopy(DEFAULT_DATA)
		updateRankAttribute(player, PlayersData[player].Ranks)
	elseif typeof(data) == "table" then
		PlayersData[player] = data
		updateRankAttribute(player, data.Ranks)
	else
		Utils.pprint("[SuperBiz] Couldn't load ranks data for " .. player.Name .. "\nError: " .. data)
	end
end

local function saveData(player, retries)
	if not SAVE_IN_STUDIO and IsStudio then
		return
	end

	local data = PlayersData[player]
	if not data then
		return
	end

	local result = Utils.callWithRetry(function()
		DataStore:SetAsync(player.UserId, data)
		return
	end, retries)

	if result then
		Utils.pprint("[SuperBiz] Couldn't save ranks data for " .. player.Name .. "\nError: " .. result)
	end
end

local function saveAllData(retries)
	for player in PlayersData do
		task.spawn(function()
			saveData(player, retries)
		end)
	end
end

local function checkGamepassOwnerships(player)
	local data = PlayersData[player]
	if not data then
		return
	end

    local gamepasses = data.RankGamepasses

    for gamepassId, rankId in Config:GetAllRankGamepasses() do
        if gamepasses[gamepassId] then
            continue
        end

        local hasPass = false
        local success = pcall(function()
            hasPass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
        end)

        if not success or not hasPass then
            continue
        end

        RankManager.AddRank(player, rankId)
		RankManager.SaveGamepass(player, gamepassId)
    end
end

function RankManager.Init()
	Players.PlayerAdded:Connect(function(player)
		loadData(player)
		checkGamepassOwnerships(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		saveData(player, 3)
		PlayersData[player] = nil
	end)

	game:BindToClose(function()
		saveAllData(5)
	end)

	task.spawn(function()
		while true do
			saveAllData(1)
			task.wait(AUTOSAVE_INTERVAL)
		end
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(loadData, player)
	end
end

return RankManager