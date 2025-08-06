local CatalogAnalytics = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdRequestStats = require(script.Parent.Parent.AdRequestStats)
local BatchHTTP = require(script.Parent.Parent.BatchHTTP)
local Utils = require(script.Parent.Parent.Utils)

local BloxbizRemotes = ReplicatedStorage.BloxbizRemotes

local function queueCatalogOpened(player: Player)
	local game_stats = AdRequestStats:getGameStats()
	local playerStats = AdRequestStats:getPlayerStatsWithClientStatsYielding(player)

	local data = {
		timestamp = os.time(),
	}

	local event = { event_type = "catalog_opened", data = Utils.merge(playerStats, Utils.merge(data, game_stats)) }
	table.insert(BatchHTTP.eventQueue, event)
end

local function queueItemTryOn(player: Player, itemId: number, itemName: string, category: string)
	local game_stats = AdRequestStats:getGameStats()
	local playerStats = AdRequestStats:getPlayerStatsWithClientStatsYielding(player)

	local data = {
		item_id = itemId,
		asset_name = itemName,
		item_category = category,
		timestamp = os.time(),
	}

	local event = { event_type = "item_try_on", data = Utils.merge(playerStats, Utils.merge(data, game_stats)) }
	table.insert(BatchHTTP.eventQueue, event)
end

local function queueCategoryOpened(player: Player, category: string)
	local game_stats = AdRequestStats:getGameStats()
	local playerStats = AdRequestStats:getPlayerStatsWithClientStatsYielding(player)

	local data = {
		category = category,
		timestamp = os.time(),
	}

	local event = { event_type = "category_opened", data = Utils.merge(playerStats, Utils.merge(data, game_stats)) }
	table.insert(BatchHTTP.eventQueue, event)
end

local function queueTermSearched(player: Player, searchTerm: string)
	local game_stats = AdRequestStats:getGameStats()
	local playerStats = AdRequestStats:getPlayerStatsWithClientStatsYielding(player)

	local data = {
		keyword = searchTerm,
	}

	local event = { event_type = "term_searched", data = Utils.merge(playerStats, Utils.merge(data, game_stats)) }
	table.insert(BatchHTTP.eventQueue, event)
end

function CatalogAnalytics.init()
	local catalogOpenedEvent = Instance.new("RemoteEvent")
	catalogOpenedEvent.Name = "CatalogOpenedEvent"
	catalogOpenedEvent.Parent = BloxbizRemotes

	catalogOpenedEvent.OnServerEvent:Connect(function(player: Player)
		queueCatalogOpened(player)
	end)

	local catalogItemTryOnEvent = Instance.new("RemoteEvent")
	catalogItemTryOnEvent.Name = "CatalogItemTryOnEvent"
	catalogItemTryOnEvent.Parent = BloxbizRemotes

	catalogItemTryOnEvent.OnServerEvent:Connect(
		function(player: Player, itemId: number, itemName: string, category: string)
			queueItemTryOn(player, itemId, itemName, category)
		end
	)

	local catalogCategoryOpenedEvent = Instance.new("RemoteEvent")
	catalogCategoryOpenedEvent.Name = "CatalogCategoryOpenedEvent"
	catalogCategoryOpenedEvent.Parent = BloxbizRemotes

	catalogCategoryOpenedEvent.OnServerEvent:Connect(function(player: Player, category: string)
		queueCategoryOpened(player, category)
	end)

	local catalogTermSearchedEvent = Instance.new("RemoteEvent")
	catalogTermSearchedEvent.Name = "CatalogTermSearchedEvent"
	catalogTermSearchedEvent.Parent = BloxbizRemotes

	catalogTermSearchedEvent.OnServerEvent:Connect(function(player, searchTerm)
		if typeof(searchTerm) ~= "string" then
			return
		end

		queueTermSearched(player, searchTerm)
	end)
end

return CatalogAnalytics
