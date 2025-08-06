--!strict
local DataManager = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(script.Parent.Parent.Utils)

local IsStudio = RunService:IsStudio()

local DATASTORE_VERSION = "007"
local DATASTORE_NAME = "CATALOG_DATA_TEMP" .. DATASTORE_VERSION
local AUTOSAVE_INTERVAL = 180
local SAVE_IN_STUDIO = false

type Outfit = {
	[number | string]: { [string]: any },
}

export type SaveData = {
	Outfits: {},
	OutfitsCount: number,
}

local DEFAULT_DATA: SaveData = {
	Outfits = {},
	OutfitsCount = 0,
}

local DataStore = DataStoreService:GetDataStore(DATASTORE_NAME)

local PlayersData = {}

local OnReplicateData: RemoteEvent

function DataManager.GetData(Player)
	return PlayersData[Player]
end

function DataManager.SetData(player: Player, key: string, value: { InnerKey: string, InnerValue: Outfit })
	local Data = DataManager.GetData(player)
	if not Data then
		return
	end

	if type(value) == "table" and value.InnerKey then
		local innerKey = value.InnerKey
		local innerValue = value.InnerValue

		Data[key][innerKey] = innerValue
	else
		Data[key] = value
	end

	OnReplicateData:FireClient(player, key, value)
end

function DataManager.LoadData(player: Player)
	if not player.Parent then
		return
	end

	local saveData: SaveData? = Utils.callWithRetry(function()
		return DataStore:GetAsync(player.UserId)
	end, 5)

	if not player.Parent then
		Utils.pprint("[SuperBiz] " .. player.Name .. " left while loading catalog data")
		return
	end

	if not saveData then
		PlayersData[player] = Utils.deepCopy(DEFAULT_DATA)
	elseif typeof(saveData) == "table" then
		for _, outfit in pairs(saveData.Outfits) do
			if outfit.BodyColors then
				for property: string, color: Color3 | string in pairs(outfit.BodyColors) do
					outfit.BodyColors[property] = Color3.fromHex(color :: string)
				end
			end
		end

		PlayersData[player] = saveData
	else
		Utils.pprint("[SuperBiz] Couldn't load catalog data for " .. player.Name .. "\nError: " .. saveData)
	end

	saveData = DataManager.GetData(player)
	if not saveData then
		return
	end

	OnReplicateData:FireClient(player, nil, saveData)
end

function DataManager.SaveData(player: Player, retries: number)
	if not SAVE_IN_STUDIO and IsStudio then
		return
	end

	local saveData = DataManager.GetData(player)
	if not saveData then
		return
	end

	saveData = Utils.deepCopy(saveData)

	for _, outfit: Outfit in saveData.Outfits do
		for Property, Color in outfit.BodyColors do
			outfit.BodyColors[Property] = Color:ToHex()
		end
	end

	local result = Utils.callWithRetry(function()
		DataStore:SetAsync(player.UserId, saveData)
		return
	end, retries)

	if result then
		Utils.pprint("[SuperBiz] Couldn't save catalog data for " .. player.Name .. "\nError: " .. result)
	end
end

function DataManager.SaveAllData(Retries)
	for Player, _ in PlayersData do
		task.spawn(function()
			DataManager.SaveData(Player, Retries)
		end)
	end
end

function DataManager.Init()
	local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")
	OnReplicateData = Instance.new("RemoteEvent")
	OnReplicateData.Name = "OnReplicateData"
	OnReplicateData.Parent = BloxbizRemotes

	Players.PlayerAdded:Connect(function(Player)
		DataManager.LoadData(Player)
	end)

	Players.PlayerRemoving:Connect(function(Player)
		DataManager.SaveData(Player, 5)
		PlayersData[Player] = nil
	end)

	game:BindToClose(function()
		DataManager.SaveAllData(5)
	end)

	task.spawn(function()
		while true do
			DataManager.SaveAllData(1)
			task.wait(AUTOSAVE_INTERVAL)
		end
	end)

	for _, Player in Players:GetPlayers() do
		task.spawn(DataManager.LoadData, Player)
	end
end

return DataManager
