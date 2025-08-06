--[[
    Description: Sends monetization data back to the web server. Sends only valid prompts.
    Data sent: Player's UserId, Price of Item, Purchase Counting (implied: how many purchases), Prompt Counting (implied: how many prompts), Time of Purchase, Success or Not, Item (id, name), Item Type, Prompt GUID, Other stats pulled from client and BillboardServer module
    All successful and unsuccessful prompts are valid prompts. However, invalid prompts are also sent to the server.
    Successful - item purchased
    Unsuccessful - item was able to be purchased but wasn't (declined, not enough robux)
    Valid - item is able to be purchased
    Invalid - item isn't able to be purchased (already owned, not for sale)
]]

local Tracker = {}
local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

--Leave the spacing here to avoid MarketplaceServiceWrappper replacements
local MarketplaceService = game:GetService( "MarketplaceService" )

local MarketplaceServiceWrapper = require(ReplicatedStorage:WaitForChild("BloxbizSDK").MarketplaceServiceWrapper)
local RateLimiter = require(script.Parent.Utils.RateLimiter)
local BatchHTTP = require(script.Parent.BatchHTTP)
local Utils = require(script.Parent.Utils)
local merge = Utils.merge
local AdRequestStats = require(script.Parent.AdRequestStats)

local remotesFolder = game.ReplicatedStorage:WaitForChild("BloxbizRemotes")
local getSubscriptionProductInfoRemote = remotesFolder:WaitForChild("getSubscriptionProductInfo")

local ASSET_TYPES = Enum.AssetType:GetEnumItems()
local REMOTES_FOLDER = "BloxbizRemotes"
local PREMIUM_PROMPT_WAIT_TIME = 30 --the time the server waits after client closes prompt for purchase success signal

local playerMembershipOnJoin = {}
local premiumPromptRecentlyClosed = {}
local membershipRecentlyChanged = {} --[player] = true/nil;

local isPromptedFromPopupShop = {}
local currentPromptedCatalogCategory = {}

local function getAssetTypeName(assetTypeId)
	for _, v in ipairs(ASSET_TYPES) do
		if v.Value == tonumber(assetTypeId) then
			return v.Name
		end
	end

	return ""
end

--Returns dictionary: Name, ItemType, Price, OnSale, and ItemId
--Note: This will immediately drop any failed requests
--Note: ItemIds differ based on the type of item (gamepass, product, asset, etc.)
local function GetProductInfo(itemId, infoType)
	local returnData = {}
	local success, itemData = pcall(function()
		return MarketplaceService:GetProductInfo(itemId, infoType)
	end)

	local baseItemData = {}
	local base_item_id = MarketplaceServiceWrapper:getBaseIdFromGenericId(itemId)
	if base_item_id == itemId then
		base_item_id = nil
	else
		success, baseItemData = pcall(function()
			return MarketplaceService:GetProductInfo(base_item_id, infoType)
		end)
	end

	if success then
		returnData.asset_name = baseItemData.Name or itemData.Name
		returnData.asset_type_id = itemData.AssetTypeId
		returnData.price_in_robux = itemData.PriceInRobux
		returnData.is_for_sale = itemData.IsForSale
		returnData.creator_id = itemData.Creator.CreatorTargetId

		if infoType == Enum.InfoType.Product then
			returnData.item_id = itemData.ProductId
		elseif infoType == Enum.InfoType.GamePass then
			returnData.item_id = itemId
		else
			returnData.item_id = itemData.AssetId
		end

		returnData.base_item_id = base_item_id
		returnData.variant_item_id = MarketplaceServiceWrapper:getVariantIdFromExperimentVariantId(itemId)

		return returnData
	end

	return nil
end

--Returns bool: whether or not player owns an item
--Note: This will immediately drop any failed requests
local function PlayerOwnsAsset(player, item_id, infoType)
	local playerOwns, requestSuccess

	if infoType == Enum.InfoType.Asset then
		requestSuccess, playerOwns = pcall(function()
			return MarketplaceService:PlayerOwnsAsset(player, item_id)
		end)
	elseif infoType == Enum.InfoType.Bundle then
		requestSuccess, playerOwns = pcall(function()
			return MarketplaceService:PlayerOwnsBundle(player, item_id)
		end)
	elseif infoType == Enum.InfoType.GamePass then
		requestSuccess, playerOwns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, item_id)
		end)
	elseif infoType == Enum.InfoType.Product then
		playerOwns = false
	elseif infoType.Name == "Premium" then
		requestSuccess = true

		if membershipRecentlyChanged[player] then
			playerOwns = playerMembershipOnJoin[player] == Enum.MembershipType.Premium
		else
			playerOwns = player.MembershipType == Enum.MembershipType.Premium
		end
	end

	--if requestSuccess is false then playerOwns will be an error msg; this is bad
	--requestSuccess will be nil if infoType == Enum.InfoType.Product
	if requestSuccess == false then
		playerOwns = nil
	end

	return playerOwns
end

--Returns bool: if OnSale and not (whether the player owns it)
--Note: Function requires param itemData because otherwise script would call GetProductInfo twice: once for queuePrompt and once for this function
local function CheckValidity(player, itemData, item_id, infoType)
	local isValid
	local playerOwnsItem = PlayerOwnsAsset(player, item_id, infoType)

	if itemData == nil or playerOwnsItem == nil then
		return nil
	end

	if playerOwnsItem or (itemData.is_for_sale == false) then
		isValid = false
	else
		isValid = true
	end

	return isValid
end

--[[
    Sends all relevant data points after a valid prompt.
    Developer products, unlike Game Passes, aren't considered an asset type so an additional PurchaseType data point is included.

    List of possible PurchaseTypes: https://developer.roblox.com/en-us/api-reference/enum/InfoType
        (only GamePass, Product, and Asset are counted as of Version 1.0)
    List of possible AssetTypes: https://developer.roblox.com/en-us/api-reference/enum/AssetType
]]
local function queuePrompt(player, infoType, itemData, isValid, success)
	local popupShopAdId = isPromptedFromPopupShop[player]
	local catalogCategory = currentPromptedCatalogCategory[player]

	local promptData = {}

	if infoType == Enum.InfoType.Subscription then
		promptData.asset_name = itemData.Name
		promptData.price_tier = itemData.PriceTier
		promptData.display_price = itemData.DisplayPrice
		promptData.subscription_period = itemData.SubscriptionPeriod
		promptData.subscription_provider_name = itemData.SubscriptionProviderName
		promptData.display_subscription_period = itemData.DisplaySubscriptionPeriod
	else
		promptData.asset_name = itemData.asset_name
		promptData.base_item_id = itemData.base_item_id
		promptData.price_in_robux = itemData.price_in_robux
		promptData.third_party_sale = (itemData.creator_id ~= game.CreatorId)
		promptData.item_creator_id = itemData.creator_id
		promptData.catalog_purchase = catalogCategory ~= nil
		promptData.catalog_category = catalogCategory
		promptData.popupshop_purchase = popupShopAdId ~= nil
		promptData.ad_id = popupShopAdId
	end

	promptData.player_id = player.UserId
	promptData.item_id = itemData.item_id
	promptData.player_experiment_group = MarketplaceServiceWrapper:getPlayerExperimentGroup(player.UserId, itemData.variant_item_id)
	promptData.prompt_valid = isValid
	promptData.purchase_successful = success
	promptData.purchase_type = infoType.Name --infoType = Enum object
	promptData.asset_type = getAssetTypeName(itemData.asset_type_id) --table of Enum objects

	promptData.timestamp = os.time() --time tracking for successful AND unsuccessful prompts

	--infoType permutations
	if infoType.Name == "Premium" then
		promptData.asset_name = "Premium"
		promptData.item_id = -1
		promptData.base_item_id = -1
		promptData.price_in_robux = 0
		promptData.asset_type_id = -1
	elseif infoType.Name == "Asset" then
		promptData.asset_type_id = itemData.asset_type_id
	elseif infoType.Name == "Bundle" then
		promptData.asset_type_id = 32
	elseif infoType.Name == "GamePass" or infoType.Name == "Product" then
		promptData.asset_type_id = -1
	end

	--If item is not for sale OR if item is free -> set price to 0
	if itemData.price_in_robux == nil then
		promptData.price_in_robux = 0
	end

	--Gather server data from server functions
	local game_stats = AdRequestStats:getGameStats()
	local playerStats = AdRequestStats:getPlayerStats(player)

	--Gather client data from client functions
	local clientPlayerStats = AdRequestStats:getClientPlayerStats(player)
	local prompt_GUID = { ["prompt_GUID"] = HttpService:GenerateGUID(false) }

	local send_data = merge(merge(merge(merge(promptData, game_stats), playerStats), clientPlayerStats), prompt_GUID)
	Utils.pprint("[SuperBiz] Item prompted and data point sent: ")
	Utils.pprint(send_data)

	local event = { event_type = "purchase", data = send_data }
	table.insert(BatchHTTP.eventQueue, event)

	isPromptedFromPopupShop[player] = nil
	currentPromptedCatalogCategory[player] = nil

	return event
end

--Fired when "affiliate gear sale or other asset" prompt closes
function Tracker.RegularPurchase(player, assetId, success)
	local infoType = Enum.InfoType.Asset
	local itemData = GetProductInfo(assetId, infoType)
	local isValid

	--To prevent bug: after player purchases item, it detects it as an invalid prompt because they own it already
	--This happens because the purchased event (and consequently CheckValidity) is ran after the purchase
	if success then
		isValid = true
	else
		isValid = CheckValidity(player, itemData, assetId, infoType)
	end

	if isValid ~= nil then
		return queuePrompt(player, infoType, itemData, isValid, success)
	end
end

MarketplaceService.PromptPurchaseFinished:Connect(Tracker.RegularPurchase)

function Tracker.GamepassPurchase(player, passId, success)
	local infoType = Enum.InfoType.GamePass
	local itemData = GetProductInfo(passId, infoType)
	local isValid

	if success then
		isValid = true
	else
		isValid = CheckValidity(player, itemData, passId, infoType)
	end

	if isValid ~= nil then
		return queuePrompt(player, infoType, itemData, isValid, success)
	end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(Tracker.GamepassPurchase)

local function ProductPurchase(userId, productId, success)
	local player = Players:GetPlayerByUserId(userId)
	local infoType = Enum.InfoType.Product
	local itemData = GetProductInfo(productId, infoType)
	local isValid = CheckValidity(player, itemData, productId, infoType)

	if isValid ~= nil then
		queuePrompt(player, infoType, itemData, isValid, success)
	end
end

MarketplaceService.PromptProductPurchaseFinished:Connect(ProductPurchase)

local function BundlePurchase(player, bundleId, success)
	local details = AvatarEditorService:GetItemDetails(bundleId, Enum.AvatarItemType.Bundle)

	local itemData = {}
	itemData.asset_name = details.Name
	itemData.asset_type_id = details.AssetTypeId
	itemData.price_in_robux = details.Price
	itemData.is_for_sale = details.IsPurchasable
	itemData.creator_id = details.CreatorTargetId
	itemData.item_id = bundleId

	local infoType = Enum.InfoType.Bundle

	local isValid = CheckValidity(player, itemData, bundleId, infoType)
	if isValid ~= nil then
		queuePrompt(player, infoType, itemData, isValid, success)
	end
end

MarketplaceService.PromptBundlePurchaseFinished:Connect(BundlePurchase)

local function isValidSubscription(player, subscriptionId)
	local success, response = pcall(function()
		return MarketplaceService:GetUserSubscriptionStatusAsync(player, subscriptionId)
	end)

	if not success then
		return
	end

	if response.IsSubscribed then
		return true
	end

	return false
end

local function validateParams(subscriptionInfo)
	local name = subscriptionInfo.Name
	local isForSale = subscriptionInfo.IsForSale
	local priceTier = subscriptionInfo.PriceTier
	local displayPrice = subscriptionInfo.DisplayPrice
	local subscriptionPeriod = subscriptionInfo.SubscriptionPeriod
	local subscriptionProviderName = subscriptionInfo.SubscriptionProviderName
	local displaySubscriptionPeriod = subscriptionInfo.DisplaySubscriptionPeriod

	if typeof(name) ~= "string" then
		return
	end

	if typeof(isForSale) ~= "boolean" then
		return
	end

	if typeof(priceTier) ~= "number" then
		return
	end

	if typeof(displayPrice) ~= "string" then
		return
	end

	if typeof(subscriptionPeriod) ~= "EnumItem" then
		return
	end

	local validEnumItems = Enum.SubscriptionPeriod:GetEnumItems()
	local found = table.find(validEnumItems, subscriptionPeriod)
	if not found then
		return
	end

	if typeof(subscriptionProviderName) ~= "string" then
		return
	end

	if typeof(displaySubscriptionPeriod) ~= "string" then
		return
	end

	return true
end

local function SubscriptionPurchase(player, subscriptionId)
	local isValid = isValidSubscription(player, subscriptionId)
	if isValid == nil then
		return
	end

	local infoType = Enum.InfoType.Subscription
	local success, response = getSubscriptionProductInfoRemote:InvokeClient(player, subscriptionId)
	if not success then
		return
	end

	isValid = validateParams(response)
	if not isValid then
		return
	end

	response.item_id = subscriptionId
	queuePrompt(player, infoType, response, isValid, isValid)
end

Players.UserSubscriptionStatusChanged:Connect(SubscriptionPurchase)

--[[
    Premium checking requires a different implementation than the rest.
    It includes an odd collaboration of server and client with two events to know the usual arguments (player and success).
    If membership changed is not detected after a certain wait time, the purchase is assumed to be false.
]]

local function promptWaitTimePassed(player)
	local infoType = { Name = "Premium" }
	local success
	local itemData = { creator_id = -1 }
	local isValid = CheckValidity(player, itemData, 0, infoType)

	if premiumPromptRecentlyClosed[player] and membershipRecentlyChanged[player] then
		success = true
	else
		success = false
	end

	queuePrompt(player, infoType, itemData, isValid, success)

	premiumPromptRecentlyClosed[player] = nil
	membershipRecentlyChanged[player] = nil
end

Players.PlayerMembershipChanged:Connect(function(player)
	membershipRecentlyChanged[player] = true

	--stop using membership status on join to determine prompt validity
	playerMembershipOnJoin[player] = nil
end)

Players.PlayerAdded:Connect(function(player)
	playerMembershipOnJoin[player] = player.MembershipType
end)

Players.PlayerRemoving:Connect(function(player)
	playerMembershipOnJoin[player] = nil
end)

function Tracker:createMonetizationRemotes()
	local bloxbiz_folder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER)

	--RemoteEvents
	local premiumPromptEvent = Instance.new("RemoteEvent")
	premiumPromptEvent.Name = "PremiumPromptEvent"
	premiumPromptEvent.Parent = bloxbiz_folder

	premiumPromptEvent.OnServerEvent:Connect(function(player)
		if RateLimiter:checkRateLimiting(player) then
			return
		end

		task.delay(PREMIUM_PROMPT_WAIT_TIME, function()
			--Make sure that another premium prompt isn't closed within PREMIUM_PROMPT_WAIT_TIME
			if not premiumPromptRecentlyClosed[player] then
				return
			end

			if tick() - premiumPromptRecentlyClosed[player] >= (PREMIUM_PROMPT_WAIT_TIME - 1) then
				promptWaitTimePassed(player)
			end
		end)
	end)

	bloxbiz_folder:WaitForChild("catalogItemPromptEvent").OnServerEvent:Connect(function(player, itemCategory)
		if RateLimiter:checkRateLimiting(player) then
			return
		end

		if type(itemCategory) ~= "string" then
			return
		end

		currentPromptedCatalogCategory[player] = itemCategory
	end)

	bloxbiz_folder:WaitForChild("popupShopItemPromptEvent").Event:Connect(function(player, ad_id)
		if RateLimiter:checkRateLimiting(player) then
			return
		end

		isPromptedFromPopupShop[player] = ad_id
	end)
end

function Tracker:init()
	Tracker:createMonetizationRemotes()
end

return Tracker
