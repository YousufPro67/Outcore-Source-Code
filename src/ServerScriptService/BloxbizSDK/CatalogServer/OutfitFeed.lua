--!strict
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TextService = game:GetService("TextService")

local BloxbizSDK = script.Parent.Parent
local BloxbizRemotes = ReplicatedStorage.BloxbizRemotes

local OnGetAllFeedRemote, OnCreateFeedRemote, OnGetFeedRemote, OnFeedActionRemote, OnRequestDataRemote, OnRequestPermissionRemote
local OnBoostData, OnBoostDataResult, OnGetFeedsRemote, OnLoadOutfitsRemote, OnReportImpressionRemote, OnReportTryOnRemote

local Payload = require(ServerScriptService.BloxbizSDK.CatalogShared.FeedUtils.Payload)
local AdRequestStats = require(BloxbizSDK.AdRequestStats)
local BatchHTTP = require(BloxbizSDK.BatchHTTP)
local Utils = require(BloxbizSDK.Utils)
local SearchFilters = require(BloxbizSDK.Utils.SearchFilters)
local Promise = require(BloxbizSDK.Utils.Promise)
local RateLimiter = require(BloxbizSDK.Utils.RateLimiter)

local CatalogShared = BloxbizSDK.CatalogShared
local FeedUtils = require(CatalogShared.FeedUtils)

local VERSION = "TEST_VERSION_5"
local DataStore = DataStoreService:GetDataStore("OUTFIT_FEED_" .. VERSION)

local SAVE_IN_STUDIO = true
local IsStudio = RunService:IsStudio()

type Profile = FeedUtils.Profile
local DEFAULT_DATA: Profile = {
	Posted = {},
	Liked = {},
}

local OutfitFeed = {
	Gamepasses = {},
	PlayerData = {},
	CurrentBoostingPost = {},
}

local READ_ONLY = false

local Feeds = {
	{
		Id = "relevance",
		Name = "Relevance",
		Sort = "relevance",
		Type = "all",
		Searchable = true,
		SearchOnly = true
	},
	{
		Id = "hot",
		Name = "Hot",
		Sort = "hot",
		Type = "all",
		Searchable = true
	},
	{
		Id = "top",
		Name = "Top",
		Sort = "top",
		Type = "all",
		Searchable = true
	},
	{
		Id = "top_weekly",
		Name = "Top",
		Sort = "top_weekly",
		Type = "all",
		Searchable = true,
		Internal = true
	},
	{
		Id = "top_monthly",
		Name = "Top",
		Sort = "top_monthly",
		Type = "all",
		Searchable = true,
		Internal = true
	},
	{
		Id = "new",
		Name = "New",
		Sort = "latest",
		Type = "all",
		Searchable = true
	},
	{
		Id = "posted",
		Name = "Posted",
		Sort = "latest",
		Type = "by-creator",
		ProfileFeed = true,
		Searchable = true
	},
	{
		Id = "liked",
		Name = "Liked",
		Sort = "relevance",
		Type = "liked",
		ProfileFeed = true,
		Searchable = false
	},
}

type SearchOpts = {
	keywords: string?,
	creator: number?,
	has_items: {number}?,
	name_contains: string?,
	min_likes: number?,
	max_likes: number?,
	created_after: string?,
	created_before: string?
}

local userIdCache = {}

local function getUserId(username)
	if not userIdCache[username] then
		local plr = Players:FindFirstChild(username)

		if plr then
			userIdCache[username] = plr.UserId
		else
			local success, userId = pcall(function()
				return Players:GetUserIdFromNameAsync(username)
			end)
			userIdCache[username] = success and userId or -1
		end
	end

	return userIdCache[username]
end

local FeedsById = {}
for _, feed in ipairs(Feeds) do
	FeedsById[feed.Id] = feed
end

local Trackers = {}

local function GetFeeds()
	return {
		Feeds = Feeds,
		FeedsById = FeedsById
	}
end

type BoostAvailableResponse = { status: "ok" | any, available_boosts: { number } }
local function GetBoostsAvailable(player: Player): (boolean, { number } | string)
	local success, result: BoostAvailableResponse = BatchHTTP.request("POST", "/catalog/boosts/available", {
		player_id = player.UserId
	})

	local decodeJson = result
	if not success or decodeJson.status ~= "ok" then
		return false, decodeJson
	end

	return true, decodeJson.available_boosts
end

local function ProcessBoostPost(player: Player, postId: string, gamePassId: number): any
	local url = string.format("catalog/outfits/%s/boost", postId)
 
	local data = {
		player_id = player.UserId,
		gamepass_id = gamePassId,
	}

	local success, result = BatchHTTP.request("POST", url, data)

	if not success then
		return
	end

	return result
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, success: boolean)
	local postId = OutfitFeed.CurrentBoostingPost[player]
	if postId then
		--edge-case: if backend failed before but gamepass still purchased
		local _, boostPassAlreadyOwned = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)

		local shouldProcessBoost = success or (not success and boostPassAlreadyOwned)
		if shouldProcessBoost and postId then
			local result = ProcessBoostPost(player, postId, passId)
			if not result or result.status ~= "ok" then
				success = false
			end
		end

		OnBoostDataResult:FireClient(player, postId, success)
	end
end)

type Action = FeedUtils.ServerFeedAction
local function ProcessActionData(
	player: Player,
	outfitId: string,
	action: Action,
	actionData: any
): (boolean, { [any]: any }?, string?)
	local extraData = {}
	local errorMessage = nil

	if action == "rename" then
		local success, result = pcall(function()
			return TextService:FilterStringAsync(actionData, player.UserId)
		end)

		if not success then
			errorMessage = "Failed to filter outfit name."
			warn(errorMessage, result)
		else
			local filteredString = result:GetNonChatStringForUserAsync(player.UserId)
			if not filteredString then
				filteredString = "[Unknown]"
			end

			extraData.name = filteredString
		end
	end

	return Utils.getArraySize(extraData) > 0, extraData, errorMessage
end

local function ProcessActionResult(
	player: Player,
	outfitId: string,
	action: Action,
	actionResult: { status: string, [string]: any }
): (boolean, any)
	if actionResult.status ~= "ok" then
		return false
	end

	if action == "like" then
		-- local setDataSuccessful, errorMessage = OutfitFeed.SetData(player, "Liked", outfitId)
		-- if not setDataSuccessful then
		-- 	warn(string.format("Setting %s's data unsuccessful, error message: %s", player.Name, errorMessage))
		-- end

		return true, actionResult.likes
	elseif action == "unlike" then
		return true, actionResult.likes
	end

	return false
end

type FeedType = FeedUtils.ServerFeedType
type SortType = FeedUtils.ServerFeedSort
local function OnGetAllFeed(
	player: Player,
	feedType: FeedType,
	page: number,
	sortType: SortType,
	pageSize: number?
): (boolean, string | { FeedUtils.BackendOutfit })
	local url = "catalog/outfits/feed/" .. (feedType or "all")

	local data = {
		page = page,
		sort = sortType,
		viewer = player.UserId,
		page_size = pageSize,
	}

	local success, decodedResult = BatchHTTP.request("POST", url, data)
	
	if not success then
		return false, decodedResult
	end

	if not Trackers[player] then
		Trackers[player] = {}
	end

	for _, outfit in pairs(decodedResult.outfits) do
		table.insert(Trackers[player], outfit.guid)
	end

	return true, decodedResult.outfits
end

local function nullifyQuery(query)
	local queryItems = 0
	for k, v in pairs(query or {}) do
		if type(v) == "string" and #v == 0 then
			v = nil
		end

		query[k] = v

		if v then
			queryItems += 1
		end
	end

	if queryItems == 0 then
		query = nil
	end

	return query
end

local function OnLoadOutfits(
	player: Player,
	feedId: string,
	page: number,
	query: SearchOpts?
): (boolean, string | { FeedUtils.BackendOutfit })
	local feed = FeedsById[feedId]

	if not feed then
		error("Feed " .. feedId .. " doesn't exist!")
	end

	if feed.Searchable then
		query = nullifyQuery(query)
	else
		query = nil
	end
	
	local data, endpoint
	if not query then
		endpoint = "catalog/outfits/feed/" .. (feed.Type)

		data = {
			page = page,
			sort = feed.Sort,
			viewer = player.UserId,
			page_size = 15
		}

		if feed.ProfileFeed then
			data.player_id = player.UserId
		end
	else
		-- use search endpoint instead of feed, but use sort from feed

		endpoint = "catalog/outfits/search"

		if feed.ProfileFeed and not query.creator then
			query.creator = player.UserId
		end

		local newKeywords, creatorFilter = SearchFilters.getCreatorFilter(query.keywords)

		if creatorFilter then
			if creatorFilter.CreatorType == 1 then
				query.creator = creatorFilter.CreatorTargetId or getUserId(creatorFilter.CreatorName)
				query.keywords = newKeywords
			else
				-- if a group creator is passed, return nothing

				query.creator = -1
				query.keywords = newKeywords
			end
		end

		if query.keywords and #query.keywords:gsub("%s", "") == 0 then
			query.keywords = nil
		end

		data = {
			query = query,
			page = page,
			sort = feed.Sort,
			viewer = player.UserId,
			page_size = 15
		}

		if feed.ProfileFeed then
			data.player_id = player.UserId
		end
	end

	local success, result = BatchHTTP.request("POST", endpoint, data)

	if not success then
		return false, result
	end

	if not Trackers[player] then
		Trackers[player] = {}
	end

	for _, outfit in pairs(result.outfits) do
		table.insert(Trackers[player], outfit.guid)
	end

	return true, result.outfits
end

local function OnCreateFeed(
	player: Player,
	outfit: FeedUtils.Payload
	): (boolean, FeedUtils.BackendOutfit | Payload.ServerResponse | string)

	if outfit.name then
		local success, result = pcall(function()
			return TextService:FilterStringAsync(outfit.name, player.UserId)
		end)

		if not success then
			warn("Failed to filter outfit name", result)
			return false, result
		end

		local filteredString = result:GetNonChatStringForUserAsync(player.UserId)
		if not filteredString then
			filteredString = "[Unknown]"
		end

		outfit.name = filteredString
	end

	local url = "catalog/outfits/create"
	local data = Utils.merge(outfit, {creator = player.UserId})

	if FeedUtils.GetOfflineMode() then
		return true, Utils.merge(data, {guid = "Test" .. tostring(tick()), created_at = (DateTime.now():ToIsoDate())})
	end

	local success, result = BatchHTTP.request("POST", url, data)

	if not success then
		return false, result.message
	end

	local decodedResponse = result

	local outfitId = decodedResponse.guid
	local setDataSuccessful, errorMessage = OutfitFeed.SetData(player, "Posted", outfitId)
	if not setDataSuccessful then
		warn(string.format("Setting %s's data unsuccessful, error message: %s", player.Name, errorMessage))
	end

	local final = Utils.merge(data, decodedResponse)

	return true, final
end

local function OnGetFeed(player: Player, outfitId: string): (boolean, FeedUtils.Outfit? | string)
	local url = "catalog/outfits/" .. outfitId
	local data = {
		viewer = player.UserId,
	}

	local success, decodedResult = BatchHTTP.request("POST", url, data)

	if not success or decodedResult.status ~= "ok" then
		warn("Get outfit failed!", decodedResult)
		return false, decodedResult
	end

	return true, decodedResult.outfit
end

local function OnFeedAction(player: Player, outfitId: string, action: Action, actionData: any): (boolean, any)
	local processDataSuccessful, extraData, errorMessage = ProcessActionData(player, outfitId, action, actionData)

	if not errorMessage then
		local url = string.format("catalog/outfits/%s/%s", outfitId, action)

		local data = {
			player_id = player.UserId,
		}

		if processDataSuccessful and extraData then
			data = Utils.merge(data, extraData)
		end

		local success, result = BatchHTTP.request("POST", url, data)

		if not success then
			return false, result.message
		end

		local decodedResult = result
		success, result = ProcessActionResult(player, outfitId, action, decodedResult)

		return success, result
	end

	return false, errorMessage
end

local function OnBoostAction(player: Player, outfitId: string): (boolean, string)
	local errorMessage = ""
	local success, gamepasses = GetBoostsAvailable(player)
	if success and typeof(gamepasses) == "table" then
		local firstPass = gamepasses[1]
		if not firstPass then
			errorMessage = "No boosting gamepass found!"
			warn(errorMessage)
		else
			MarketplaceService:PromptGamePassPurchase(player, firstPass)
			OutfitFeed.CurrentBoostingPost[player] = outfitId

			return true, tostring(firstPass)
		end
	end

	return false, errorMessage
end

local function OnRequestData(player: Player, dataType: "Liked" | "Posted"): { number }?
	if dataType ~= "Liked" and dataType ~= "Posted" then
		warn(string.format("Invalid data type: %s", dataType))
		return
	end

	local playerData = OutfitFeed.GetData(player)
	if playerData then
		return playerData[dataType]
	end

	warn(string.format("No %s data.", player.Name))
	return
end

local feedEnabled, feedPerms = nil, nil
local function OnRequestFeedEnabled(player: Player?): (boolean, string)
	if feedEnabled ~= nil then
		return feedEnabled, feedPerms
	end
	
	if READ_ONLY then
		feedEnabled, feedPerms = false, nil
		return feedEnabled, feedPerms
	end

	local success, result = BatchHTTP.request("POST", "/catalog/config", {
		viewer = player and player.UserId or 1
	}, true)

	if not success or result.status ~= "ok" then
		if result.status == "feature_blocked" then
			Utils.debug_warn("Could not get Outfit Feed permissions. Outfit Feed will be read-only.")
			READ_ONLY = true
		end

		feedEnabled, feedPerms = false, result
		return feedEnabled, feedPerms
	end

	feedEnabled, feedPerms = result.permissions == "APPROVED", result
	return feedEnabled, feedPerms
end

function OutfitFeed.LoadData(player: Player)
	if OutfitFeed.PlayerData[player] then
		return
	end
	if not player.Parent then
		return
	end

	local saveData: Profile? = Utils.callWithRetry(function()
		return DataStore:GetAsync(player.UserId)
	end, 5)

	if not player.Parent then
		Utils.pprint("[SuperBiz] " .. player.Name .. " left while loading outfit feed data")
		return
	end

	if not saveData then
		OutfitFeed.PlayerData[player] = Utils.deepCopy(DEFAULT_DATA)
	elseif typeof(saveData) == "table" then
		OutfitFeed.PlayerData[player] = saveData
	else
		Utils.pprint("[SuperBiz] Couldn't load catalog data for " .. player.Name .. "\nError: " .. saveData)
	end
end

function OutfitFeed.SaveData(player: Player, retries: number)
	if not SAVE_IN_STUDIO and IsStudio then
		return
	end

	local saveData = OutfitFeed.GetData(player)
	if not saveData then
		return
	end

	saveData = Utils.deepCopy(saveData)
	local result = Utils.callWithRetry(function()
		DataStore:SetAsync(player.UserId, saveData)
		return
	end, retries)

	if result then
		Utils.pprint("[SuperBiz] Couldn't save outfit feed data for " .. player.Name .. "\nError: " .. result)
	end
end

function OutfitFeed.SetData(player: Player, action: "Posted" | "Liked", outfitId: string): (boolean, string)
	if action ~= "Posted" and action ~= "Liked" then
		local warning = string.format("Invalid action: %s. The only accepted actions are: Posted | Liked.", action)
		warn(warning)
		return false, warning
	end

	local data = OutfitFeed.GetData(player)
	if not data then
		local warning = string.format("Can't retrieve player's data %s", player.Name)
		return false, warning
	end

	table.insert(data[action], outfitId)

	return true, data[action]
end

function OutfitFeed.GetData(player: Player): Profile?
	return OutfitFeed.PlayerData[player]
end

-- Impression & try on batch reporting --

local IMPRESSIONS_QUEUE = {}
local TRY_ONS_QUEUE = {}

local RECORDED_IMPRESSIONS = {}
local RECORDED_TRY_ONS = {}

-- store every try on & impression reported so that none are double reported -
-- the rule is only one try on or impression recorded per outfit/user/session
local function getImpressionKey(player, outfitId)
	return string.format("%s:%s", player.UserId, outfitId)
end

local function AddImpressionToQueue(player, outfitId)
	if not RECORDED_IMPRESSIONS[getImpressionKey(player, outfitId)] then
		IMPRESSIONS_QUEUE[player.UserId] = IMPRESSIONS_QUEUE[player.UserId] or {}
		table.insert(IMPRESSIONS_QUEUE[player.UserId], outfitId)
		
		RECORDED_IMPRESSIONS[getImpressionKey(player, outfitId)] = true
		return true
	else
		return false
	end

end

local function AddTryOnToQueue(player, outfitId)
	if not RECORDED_TRY_ONS[getImpressionKey(player, outfitId)] then
		TRY_ONS_QUEUE[player.UserId] = TRY_ONS_QUEUE[player.UserId] or {}
		table.insert(TRY_ONS_QUEUE[player.UserId], outfitId)

		RECORDED_TRY_ONS[getImpressionKey(player, outfitId)] = true
		return true
	else
		return false
	end
end

type ViewerOutfit = {
	viewer: number,
	outfits: {number}
}

local function ProcessImpressionsQueue(recordedImpressions, recordedTryOns)
	local impressions: {ViewerOutfit} = {}
	local try_ons: {ViewerOutfit} = {}

	for playerId, outfits in pairs(recordedImpressions) do
		table.insert(impressions, {
			viewer = playerId,
			outfits = outfits
		})
	end
	for playerId, outfits in pairs(recordedTryOns) do
		table.insert(try_ons, {
			viewer = playerId,
			outfits = outfits
		})
	end
	
	if #impressions + #try_ons > 0 then
		Utils.pprint("Outfit impressions:", impressions)
		Utils.pprint("Outfit try ons:", try_ons)

		local success, result = BatchHTTP.request("POST", "/catalog/outfits/record-stats", {
			impressions = impressions,
			try_ons = try_ons
		})
	end
end

local function startReportingImpressions()
	task.spawn(function()
		while true do
			task.wait(20)

			local recordedImpressions = Utils.deepCopy(IMPRESSIONS_QUEUE)
			local recordedTryOns = Utils.deepCopy(TRY_ONS_QUEUE)
			IMPRESSIONS_QUEUE = {}
			TRY_ONS_QUEUE = {}

			if not READ_ONLY then
				Promise.try(ProcessImpressionsQueue, recordedImpressions, recordedTryOns):await()
			end
		end
	end)
end

function OutfitFeed.Init() 
	-- impressions / try ons --

	OnReportImpressionRemote = Instance.new("RemoteFunction")
	OnReportImpressionRemote.Name = "CatalogOnImpression"
	OnReportImpressionRemote.OnServerInvoke = AddImpressionToQueue
	OnReportImpressionRemote.Parent = BloxbizRemotes

	OnReportTryOnRemote = Instance.new("RemoteFunction")
	OnReportTryOnRemote.Name = "CatalogOnTryOn"
	OnReportTryOnRemote.OnServerInvoke = AddTryOnToQueue
	OnReportTryOnRemote.Parent = BloxbizRemotes

	startReportingImpressions()

	-- outfits handling --

	OnGetFeedsRemote = Instance.new("RemoteFunction")
	OnGetFeedsRemote.Name = "CatalogOnGetFeeds"
	OnGetFeedsRemote.OnServerInvoke = GetFeeds
	OnGetFeedsRemote.Parent = BloxbizRemotes

	OnLoadOutfitsRemote = Instance.new("RemoteFunction")
	OnLoadOutfitsRemote.Name = "CatalogOnLoadOutfits"
	OnLoadOutfitsRemote.OnServerInvoke = OnLoadOutfits
	OnLoadOutfitsRemote.Parent = BloxbizRemotes

	OnGetAllFeedRemote = Instance.new("RemoteFunction")
	OnGetAllFeedRemote.Name = "CatalogOnGetAllFeed"
	OnGetAllFeedRemote.OnServerInvoke = OnGetAllFeed
	OnGetAllFeedRemote.Parent = BloxbizRemotes

	OnCreateFeedRemote = Instance.new("RemoteFunction")
	OnCreateFeedRemote.Name = "CatalogOnCreateFeed"
	OnCreateFeedRemote.OnServerInvoke = OnCreateFeed
	OnCreateFeedRemote.Parent = BloxbizRemotes

	OnGetFeedRemote = Instance.new("RemoteFunction")
	OnGetFeedRemote.Name = "CatalogOnGetFeed"
	OnGetFeedRemote.OnServerInvoke = OnGetFeed
	OnGetFeedRemote.Parent = BloxbizRemotes

	OnFeedActionRemote = Instance.new("RemoteFunction")
	OnFeedActionRemote.Name = "CatalogOnFeedAction"
	OnFeedActionRemote.OnServerInvoke = OnFeedAction
	OnFeedActionRemote.Parent = BloxbizRemotes

	OnRequestDataRemote = Instance.new("RemoteFunction")
	OnRequestDataRemote.Name = "CatalogOnRequestData"
	OnRequestDataRemote.OnServerInvoke = OnRequestData
	OnRequestDataRemote.Parent = BloxbizRemotes

	OnBoostData = Instance.new("RemoteFunction")
	OnBoostData.Name = "CatalogOnBoostFeed"
	OnBoostData.OnServerInvoke = OnBoostAction
	OnBoostData.Parent = BloxbizRemotes

	OnRequestPermissionRemote = Instance.new("RemoteFunction")
	OnRequestPermissionRemote.Name = "CatalogOnRequestPermissionRemote"
	OnRequestPermissionRemote.OnServerInvoke = OnRequestFeedEnabled
	OnRequestPermissionRemote.Parent = BloxbizRemotes

	OnBoostDataResult = Instance.new("RemoteEvent")
	OnBoostDataResult.Name = "CatalogOnBoostResult"
	OnBoostDataResult.Parent = BloxbizRemotes

	Players.PlayerAdded:Connect(function(player: Player)
		OutfitFeed.LoadData(player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		OutfitFeed.SaveData(player, 5)
		OutfitFeed.PlayerData[player] = nil
	end)

	for _, player in pairs(Players:GetPlayers()) do
		if not OutfitFeed.PlayerData[player] then
			OutfitFeed.LoadData(player)
		end
	end

	-- detect readonly on server start
	OnRequestFeedEnabled()
end

return OutfitFeed
