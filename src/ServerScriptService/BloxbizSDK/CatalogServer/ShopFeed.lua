local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local BloxbizSDK = script.Parent.Parent
local BloxbizRemotes = ReplicatedStorage.BloxbizRemotes

local Utils = require(BloxbizSDK.Utils)
local BatchHTTP = require(BloxbizSDK.BatchHTTP)
local Promise = require(BloxbizSDK.Utils.Promise)

local ShopFeed = {}

local OnGetFeedsRemote, OnConfirmShopCreationRemote, OnGetFeedRemote, OnGetShopDefinitionRemote, OnGetShopRemote, OnEditShopRemote, OnRateShopRemote, OnCreateShopRemote, OnReportImpressionRemote

local FeedsLoaded = Instance.new("BindableEvent")

local CatalogConfig

local Feeds
local FeedsById = {}

local FEED_ENABLED = false
local IMPRESSIONS_REPORT_INTERVAL = 20

local function FetchCatalogConfig()
	if CatalogConfig then
		return false
	end

	CatalogConfig = BloxbizRemotes:WaitForChild("GetCatalogConfigServer"):Invoke()
	if not CatalogConfig then
		Utils.debug_warn("Could not get Shop Feed configurations.")
        FEED_ENABLED = false
		return false
	end

    Feeds = CatalogConfig.shop_discover_sorts

    for _, feed in Feeds do
        FeedsById[feed.id] = feed
    end

	FEED_ENABLED = CatalogConfig.shops_enabled

	FeedsLoaded:Fire()
	FeedsLoaded:Destroy()
	FeedsLoaded = nil
end

-- returns all feed sorts
local function GetFeeds()
	if FeedsLoaded then
		FeedsLoaded.Event:Wait()
	end

	if not FEED_ENABLED then
        return false
    end

    return {
		Feeds = Feeds,
		FeedsById = FeedsById
	}
end

local function GetShopDefinition(player, shopId, groupId)
	if FeedsLoaded then
		FeedsLoaded.Event:Wait()
	end

    if not FEED_ENABLED then
        return false
    end

    local url = "catalog/shops/" .. shopId .. "/definition"

	local data = {
		player_id = player.UserId,
		group_id = groupId,
	}

	local success, result = BatchHTTP.request("POST", url, data)
	if not success then
		Utils.debug_warn("Could not get Shop definition.")
		return false, result
	end

    return true, result.shop
end

-- returns a feed list of shops for a specific sort
local function GetFeed(player, feedId, page)
	if FeedsLoaded then
		FeedsLoaded.Event:Wait()
	end

    if not FEED_ENABLED then
        return false
    end

    local feedExists = FeedsById[feedId]
    if not feedExists then
        return false
    end

    local url = "catalog/shops/discover/" .. feedId

	local data = {
		page = page,
		viewer = player.UserId,
	}

	local success, result = BatchHTTP.request("POST", url, data)
	if not success then
		Utils.debug_warn("Could not get Shop Feed.")
		return false, result
	end

    return true, result.shops
end

-- returns shop items for a specific shop
local function GetShop(player, shopId, sectionId, cursor)
	if FeedsLoaded then
		FeedsLoaded.Event:Wait()
	end

    if not FEED_ENABLED then
        return false
    end

    local url = "catalog/shops/" .. shopId .. "/items/" .. sectionId

	local data = {
		limit = 30,
		cursor = cursor,
		viewer = player.UserId,
	}

	local success, result = BatchHTTP.request("POST", url, data)
	if not success then
		Utils.debug_warn("Could not get Shop items.")
		return false, result
	end

    return true, result.items, result.next_page_cursor
end

-- gives a specific shop a rating (ratings: 1 = like. 0 = unlike, -1 = dislike)
local function RateShop(player, shopId, rating)
	if FeedsLoaded then
		FeedsLoaded.Event:Wait()
	end

    if not FEED_ENABLED then
        return false
    end

    local url = "catalog/shops/" .. shopId .. "/rate"

	local data = {
		rating = rating,
		player_id = player.UserId,
	}

	local success, result = BatchHTTP.request("POST", url, data)
	if not success then
		Utils.debug_warn("Could not get rate the shop.")
		return false, result
	end

    return true
end

local function validateShopData(shopData)
	local name = shopData.Name
	local group = shopData.Group
	local items = shopData.Items
	local emoji = shopData.Emoji

	if typeof(name) ~= "string" or #name < 3 then
		return false
	end

	if typeof(emoji) ~= "string" or #emoji < 1 then
		return false
	end

	if not group or typeof(group.value) ~= "number" then
		return false
	end

	-- if it has at least 1 item then it's valid
	for _ in items do
		return true
	end
end

local function getSections(items)
	local sections = {}

	local section = {
		id = "default",
		name = "Default",

		queries = {},
		featured_items = {},
	}

	for _, item in items do
		local id = item.Id
		local type = item.Type
		local isBundle = item.IsBundle

		if type == "Search term" and typeof(id) == "string" then
			table.insert(section.queries, {Keyword = id})
		end

		if type == "Group" and typeof(id) == "number" then
			table.insert(section.queries, {CreatorType = 2, CreatorTargetId = id})
		end

		if type == "User" and typeof(id) == "number" then
			table.insert(section.queries, {CreatorType = 1, CreatorTargetId = id})
		end

		if type == "Item" and typeof(id) == "number" then
			table.insert(section.featured_items, {id = id, item_type = isBundle and "Bundle" or "Asset"})
		end
	end

	if #section.queries == 0 and #section.featured_items == 0 then
		return false
	end

	table.insert(sections, section)

	return sections
end

local function getFilteredShopName(player, shopName)
	local success, result = pcall(function()
		return TextService:FilterStringAsync(shopName, player.UserId)
	end)

	if success then
		local filteredName = result:GetNonChatStringForUserAsync(player.UserId)
		if not filteredName then
			filteredName = "[Unknown]"
		end

		return filteredName
	end

	return false
end

-- edits an existing shop
local function EditShop(player, shopId, shopData)
	if FeedsLoaded then
		FeedsLoaded.Event:Wait()
	end

    if not FEED_ENABLED then
        return false
    end

	if not validateShopData(shopData) then
		return false, "Please fill out all the fields before submitting."
	end

	local shopName = getFilteredShopName(player, shopData.Name)
	if not shopName then
		return false, "Failed to filter shop name."
	end

	local sections = getSections(shopData.Items)
	if not sections then
		return false, "Please select items for your shop before submitting."
	end

	local formatedShopData = {
		name = shopName,
		thumbnail = shopData.Emoji,
		group_id = shopData.Group.value,
		player_id = player.UserId,
		sections = sections,
	}

    local url = "catalog/shops/" .. shopId .. "/edit"

	local success, result = BatchHTTP.request("POST", url, formatedShopData)
	if not success then
		Utils.debug_warn("Could not edit a shop.", result)

		local errorMsg = "Something went wrong.\nPlease, try again."
		return false, errorMsg
	end

	return GetShopDefinition(player, shopId, formatedShopData.group_id)
end

local function GetCreatingGamepasses(player, groupId)
	if FeedsLoaded then
		FeedsLoaded.Event:Wait()
	end

    if not FEED_ENABLED then
        return false
    end

	local url = "catalog/shops/available-gamepasses/" .. player.UserId

	local success, result = BatchHTTP.request("POST", url, {
		player_id = player.UserId,
	})
	if not success then
		Utils.debug_warn("Could not get gamepasses.")
		return false, result
	end

	local createPermissions = result.shop_create_permissions
	for _, data in createPermissions do
		if data.group_id == groupId and data.gamepass_required == false then
			return true, nil, true
		end
	end

	return true, result.gamepasses[1]
end

local PromptedGamepass = {}
local ReadyShopData = {}

local function ShopPurchaseFinished(player, gamepassId, wasPurchased, notRequiresGamepass)
	if not notRequiresGamepass then
		local isCreatingShopGamepass = gamepassId == PromptedGamepass[player]
		if not isCreatingShopGamepass then
			return
		end

		if not wasPurchased then
			ReadyShopData[player] = nil
			PromptedGamepass[player] = nil

			local errorMsg = "The shop purchase was canceled."
			OnConfirmShopCreationRemote:FireClient(player, false, errorMsg)
			return
		end
	end

	local shopData = ReadyShopData[player]
	if not shopData then
		ReadyShopData[player] = nil
		PromptedGamepass[player] = nil

		local errorMsg = "Something went wrong.\nPlease, try again."
		OnConfirmShopCreationRemote:FireClient(player, false, errorMsg)
		return
	end

    local url = "catalog/shops/create"

	local success, result = BatchHTTP.request("POST", url, shopData)
	if not success then
		Utils.debug_warn("Could not create a new shop.")

		ReadyShopData[player] = nil
		PromptedGamepass[player] = nil

		local errorMsg = "Could not create a new shop.\n Please, try again."
		OnConfirmShopCreationRemote:FireClient(player, false, errorMsg)
		return
	end

	local successNewShop, newShop = GetShopDefinition(player, result.shop_id, shopData.group_id)
	if not successNewShop then
		ReadyShopData[player] = nil
		PromptedGamepass[player] = nil

		local errorMsg = "Shop was created successfully but could not be displayed."
		OnConfirmShopCreationRemote:FireClient(player, false, errorMsg)
		return
	end

	OnConfirmShopCreationRemote:FireClient(player, true, newShop)

	ReadyShopData[player] = nil
	PromptedGamepass[player] = nil
end

-- creates a new shop
local function CreateShop(player, shopData)
	if FeedsLoaded then
		FeedsLoaded.Event:Wait()
	end

    if not FEED_ENABLED then
        return false
    end

	if not validateShopData(shopData) then
		return false, "Please fill out all the fields before submitting."
	end

	local shopName = getFilteredShopName(player, shopData.Name)
	if not shopName then
		return false, "Failed to filter shop name."
	end

	local sections = getSections(shopData.Items)
	if not sections then
		return false, "Please select items for your shop before submitting."
	end

	local groupId = shopData.Group.value

	local success, gamepassId, notRequiresGamepass = GetCreatingGamepasses(player, groupId)
	if success == true and (gamepassId or notRequiresGamepass) then
		ReadyShopData[player] = {
			name = shopName,
			group_id = groupId,
			thumbnail = shopData.Emoji,
			player_id = player.UserId,
			sections = sections,
			activate_with_gamepass = gamepassId,
		}
		PromptedGamepass[player] = gamepassId

		if notRequiresGamepass then
			ShopPurchaseFinished(player, gamepassId, false, true)
		else
			MarketplaceService:PromptGamePassPurchase(player, gamepassId)
		end
		return true
	end

	ReadyShopData[player] = nil
	PromptedGamepass[player] = nil

	return false, "Could not prompt a shop purchase."
end

local QueuedImpressions = {}

local function QueueImpression(player, shopId)
	if typeof(shopId) ~= "string" then
		return
	end

	local playerImpressions = QueuedImpressions[player]
	if not playerImpressions then
		QueuedImpressions[player] = {
			user = player.UserId,
			shops = {},
		}
		playerImpressions = QueuedImpressions[player]
	end

	table.insert(playerImpressions.shops, shopId)
end

local function ProcessImpressionsQueue(queuedImpressions)
	local impressions = {}

	for _, impression in queuedImpressions do
		table.insert(impressions, impression)
	end

	if #impressions > 0 then
		Utils.pprint("Shop feed impressions:", impressions)

		local success, result = BatchHTTP.request("POST", "/catalog/shops/record-stats", {
			impressions = impressions,
		})
	end
end

local function StartReportingImpressions()
	task.spawn(function()
		while true do
			task.wait(IMPRESSIONS_REPORT_INTERVAL)

			local recordedImpressions = Utils.deepCopy(QueuedImpressions)
			QueuedImpressions = {}

			if FEED_ENABLED then
				Promise.try(ProcessImpressionsQueue, recordedImpressions):await()
			end
		end
	end)
end

local function CreateRemotes()
    OnGetFeedsRemote = Instance.new("RemoteFunction")
	OnGetFeedsRemote.Name = "CatalogOnGetShopFeeds"
	OnGetFeedsRemote.OnServerInvoke = GetFeeds
	OnGetFeedsRemote.Parent = BloxbizRemotes

    OnGetFeedRemote = Instance.new("RemoteFunction")
	OnGetFeedRemote.Name = "CatalogOnGetShopFeed"
	OnGetFeedRemote.OnServerInvoke = GetFeed
	OnGetFeedRemote.Parent = BloxbizRemotes

    OnGetShopRemote = Instance.new("RemoteFunction")
	OnGetShopRemote.Name = "CatalogOnGetShop"
	OnGetShopRemote.OnServerInvoke = GetShop
	OnGetShopRemote.Parent = BloxbizRemotes

	OnGetShopDefinitionRemote = Instance.new("RemoteFunction")
	OnGetShopDefinitionRemote.Name = "CatalogOnGetShopDefinition"
	OnGetShopDefinitionRemote.OnServerInvoke = GetShopDefinition
	OnGetShopDefinitionRemote.Parent = BloxbizRemotes

    OnRateShopRemote = Instance.new("RemoteEvent")
	OnRateShopRemote.Name = "CatalogOnRateShop"
	OnRateShopRemote.OnServerEvent:Connect(RateShop)
	OnRateShopRemote.Parent = BloxbizRemotes

	OnEditShopRemote = Instance.new("RemoteFunction")
	OnEditShopRemote.Name = "CatalogOnEditShop"
	OnEditShopRemote.OnServerInvoke = EditShop
	OnEditShopRemote.Parent = BloxbizRemotes

	OnCreateShopRemote = Instance.new("RemoteFunction")
	OnCreateShopRemote.Name = "CatalogOnCreateShop"
	OnCreateShopRemote.OnServerInvoke = CreateShop
	OnCreateShopRemote.Parent = BloxbizRemotes

	OnConfirmShopCreationRemote = Instance.new("RemoteEvent")
	OnConfirmShopCreationRemote.Name = "CatalogOnConfirmShopCreation"
	OnConfirmShopCreationRemote.Parent = BloxbizRemotes

	OnReportImpressionRemote = Instance.new("RemoteEvent")
	OnReportImpressionRemote.Name = "CatalogOnReportImpression"
	OnReportImpressionRemote.OnServerEvent:Connect(QueueImpression)
	OnReportImpressionRemote.Parent = BloxbizRemotes
end

function ShopFeed.Init()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(ShopPurchaseFinished)

	Players.PlayerRemoving:Connect(function(player)
		ReadyShopData[player] = nil
		PromptedGamepass[player] = nil
	end)

    CreateRemotes()
    FetchCatalogConfig()

	StartReportingImpressions()
end

return ShopFeed