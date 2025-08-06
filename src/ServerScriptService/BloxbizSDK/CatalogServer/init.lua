local CatalogModuleServer = {}

local AvatarEditorService = game:GetService("AvatarEditorService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")

local Utils = require(script.Parent.Utils)
local BatchHTTP = require(script.Parent.BatchHTTP)
local ConfigReader = require(script.Parent.ConfigReader)
local RateLimiter = require(script.Parent.Utils.RateLimiter)
local Promise = require(script.Parent.Utils.Promise)

local categories
local DataManager = require(script.DataManager)
local SearchModule = require(script.SearchModule)
local CategoryClass = require(script.CategoryClass)
local CatalogAnalytics = require(script.CatalogAnalytics)
local OutfitFeed = require(script.OutfitFeed)
local ShopFeed = require(script.ShopFeed)
local FeaturedCategories = require(script.FeaturedCategories)
local AvatarPreview = require(script.AvatarPreview)
local BodyScaleValues = require(script.Parent.CatalogClient.Libraries.BodyScaleValues)
local HumanoidDescriptionProperties = require(script.Parent.CatalogClient.Controllers.AvatarPreviewController.HumanoidDescriptionProperties)

local IsValidProperty = HumanoidDescriptionProperties.IsValidProperty

local OnDisplayPopupMessage

local ItemsCache = {}
local CachedHumDesc = {}
local CachedRealHumDesc = {}

local BodyColorProperties = {
	"HeadColor",
	"LeftArmColor",
	"LeftLegColor",
	"RightArmColor",
	"RightLegColor",
	"TorsoColor",
}

local SETTINGS = {
	SortType = {
		Proxy = {
			Relevance = 0,
			Favorited = 1,
			Sales = 2,
			Updated = 3,
			PriceAsc = 4,
			PriceDesc = 5,
		},

		Editor = {
			Relevance = Enum.CatalogSortType.Relevance,
			PriceDesc = Enum.CatalogSortType.PriceHighToLow,
			PriceAsc = Enum.CatalogSortType.PriceLowToHigh,
			Favorited = Enum.CatalogSortType.MostFavorited,
			Updated = Enum.CatalogSortType.RecentlyCreated,
			Sales = Enum.CatalogSortType.Bestselling,
		},
	},

	SaveOutfitLimit = 100,
	FetchCategoryRetries = 2,
	PersistentWear = ConfigReader:read("CatalogPersistentWear"),
}

local function FetchCategories()
	local catalogConfig = BloxbizRemotes:WaitForChild("GetCatalogConfigServer"):Invoke()

	if catalogConfig then
		return catalogConfig.categories
	end
end

local function GetCategoryItems(Category): CategoryClass.Category
	return ItemsCache[Category]
end

local function InitCategoryItems()
	local serverCategories = FetchCategories()

	categories = serverCategories or require(script.Parent.CatalogClient.Categories)

	local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")
	local GetCatalogCategories = Instance.new("RemoteFunction")
	GetCatalogCategories.Parent = BloxbizRemotes
	GetCatalogCategories.Name = "GetCatalogCategories"
	GetCatalogCategories.OnServerInvoke = function()
		return categories
	end

	for _, category in categories do
		ItemsCache[category.name] = CategoryClass.new(category)
	end
end

local function ItemsResponse(player: Player, info: { Page: number, SortType: string, Category: string })
	if RateLimiter:checkRateLimiting(player) then
		return
	end

	local page = info.Page
	local sortType = info.SortType
	local category = info.Category

	if type(page) ~= "number" or type(category) ~= "string" then
		return
	end

	local categoryItems = GetCategoryItems(category)
	if not categoryItems then
		return
	end

	return categoryItems:GetItems(player, page, sortType)
end

local function SearchItemsReponse(
	player: Player,
	info: {
		Page: number,
		Keyword: string,
		AllowedTypes: SearchModule.ItemFilter?,
		SortType: number,
		CreatorFilter: SearchModule.CreatorFilter?
	}
)
	if RateLimiter:checkRateLimiting(player) then
		return
	end

	local page = info.Page
	local keyword = info.Keyword
	local allowedTypes = info.AllowedTypes

	if type(page) ~= "number" or type(keyword) ~= "string" then
		return
	end

	return SearchModule.GetItems(player, info.Keyword, info.Page, info.SortType, info.AllowedTypes, info.CreatorFilter)
end

local function EmoteResponse(Player, EmoteId)
	if RateLimiter:checkRateLimiting(Player) then
		return
	end

	if type(EmoteId) ~= "number" then
		return
	end

	local Folder = ReplicatedStorage:FindFirstChild("BloxbizCatalogEmotes")
	if not Folder then
		Folder = Instance.new("Folder")
		Folder.Name = "BloxbizCatalogEmotes"
		Folder.Parent = ReplicatedStorage
	end

	local Emote = Folder:FindFirstChild(EmoteId)
	if not Emote then
		local Asset = InsertService:LoadAsset(EmoteId)
		Emote = Asset:FindFirstChildWhichIsA("Animation", true)
		if Emote then
			Emote:ClearAllChildren()
			Emote.Name = EmoteId
			Emote.Parent = Folder
		end

		Asset:Destroy()
	end

	return Emote
end

local function ApplyToRealHumanoid(Player, ApplyData)
	if not SETTINGS.PersistentWear then
		return
	end

	local Char = Player.Character
	if not Char then
		return
	end

	local Hum = Char:FindFirstChild("Humanoid")
	if not Hum then
		return
	end

	local Desc = Hum:GetAppliedDescription()

	if ApplyData.Property then
		if IsValidProperty(ApplyData.Property) then
			Desc[ApplyData.Property] = ApplyData.AssetId
		end
	elseif ApplyData.BodyColor then
		if type(ApplyData.BodyColor) == "table" then
			for Property, Color in ApplyData.BodyColor do
				if IsValidProperty(Property) then
					Desc[Property] = Color
				end
			end
		else
			for _, Property in BodyColorProperties do
				if IsValidProperty(Property) then
					Desc[Property] = ApplyData.BodyColor
				end
			end
		end
	elseif ApplyData.BodyScale then
		for ScaleName, ScaleValue in ApplyData.BodyScale do
			if not IsValidProperty(ScaleName) then
				continue
			end

			local Value = BodyScaleValues[ScaleName]
			if not Value then
				continue
			end

			ScaleValue = math.clamp(ScaleValue, Value.Min, Value.Max)

			Desc[ScaleName] = ScaleValue
		end
	else
		local asset = ApplyData.AccessoryData
		local Accessories = Desc:GetAccessories(true)
		if asset then
			asset.Position = Vector3.zero
			asset.Rotation = Vector3.zero
			asset.Scale = Vector3.one

			table.insert(Accessories, asset)
		else
			for i, Accessory in Accessories do
				if Accessory.AssetId == ApplyData.AssetId then
					table.remove(Accessories, i)
					break
				end
			end
		end
		Desc:SetAccessories(Accessories, true)
	end

	if Player:IsDescendantOf(Players) then
		local succ, err = pcall(function()
			Hum:ApplyDescription(Desc)
		end)

		CachedHumDesc[Player] = Desc
	end
end

local function GetDictionarySize(Dictionary)
	local Count = 0
	for _ in Dictionary do
		Count = Count + 1
	end
	return Count
end

local function IsValidOutfit(NewOutfitAssetsCount, NewOutfit, Outfit)
	local NewOutfitBodyColors = NewOutfit.BodyColors

	local OutfitAssetsCount = GetDictionarySize(Outfit)
	if OutfitAssetsCount ~= NewOutfitAssetsCount then
		-- Outfits have different amounts of assets
		return true
	end

	for Id in Outfit do
		if Id == "BodyColors" then
			for Property, Color in Outfit.BodyColors do
				if NewOutfitBodyColors[Property] ~= Color then
					-- New outfit doesn't contain this body color
					return true
				end
			end
		elseif not NewOutfit[tonumber(Id)] then
			-- New outfit doesn't contain this assed id
			return true
		end
	end

	-- New outfit already exists
	return false
end

local function DoesOutfitExist(Player, NewOutfit)
	local Outfits = DataManager.GetData(Player).Outfits
	local NewOutfitAssetsCount = GetDictionarySize(NewOutfit)

	for _, Outfit in Outfits do
		if not IsValidOutfit(NewOutfitAssetsCount, NewOutfit, Outfit) then
			return true
		end
	end

	return false
end

local function SaveOutfit(
	player: Player,
	outfit: { [string | number]: { [string]: Color3 | any } },
	bodyColors: { [string]: Color3 }
)
	if type(outfit) ~= "table" then
		return
	end

	local saveData = DataManager.GetData(player)
	if not saveData then
		return
	end

	local outfitsCount = GetDictionarySize(saveData.Outfits)
	if outfitsCount + 1 > SETTINGS.SaveOutfitLimit then
		return
	end

	outfit.BodyColors = bodyColors

	if DoesOutfitExist(player, outfit) then
		return
	end

	DataManager.SetData(player, "OutfitsCount", saveData.OutfitsCount + 1)

	local outfitId = "Outfit" .. saveData.OutfitsCount
	DataManager.SetData(player, "Outfits", {
		InnerKey = outfitId,
		InnerValue = outfit,
	})

	return true
end

local function DeleteOutfit(Player, OutfitId)
	if type(OutfitId) ~= "string" then
		return
	end

	local Data = DataManager.GetData(Player)
	if not Data then
		return
	end

	DataManager.SetData(Player, "Outfits", {
		InnerKey = OutfitId,
		InnerValue = nil,
	})
end

local function ApplyOutfit(player, outfit)
	if not SETTINGS.PersistentWear then
		return
	end

	if type(outfit) ~= "table" then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	if outfit.Accessories and typeof(outfit.Accessories) == "table" then
		for _, asset in outfit.Accessories do
			asset.Position = Vector3.zero
			asset.Rotation = Vector3.zero
			asset.Scale = Vector3.one
		end
	end

	local description = Instance.new("HumanoidDescription")
	description:SetAccessories(outfit.Accessories, true)

	for property, value in outfit do
		if property == "Accessories" then
			continue
		end

		if not HumanoidDescriptionProperties.IsValidProperty(property) then
			continue
		end

		local bodyScale = BodyScaleValues[property]
		if bodyScale then
			value = math.clamp(value, bodyScale.Min, bodyScale.Max)
		end

		description[property] = value
	end

	if player:IsDescendantOf(Players) then
		humanoid:ApplyDescription(description)
		CachedHumDesc[player] = description
	end
end

local function resetRealCharacterOutfit(player)
	if not SETTINGS.PersistentWear then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	if player:IsDescendantOf(Players) then
		local realDescription = Players:GetHumanoidDescriptionFromUserId(player.UserId)
		humanoid:ApplyDescription(realDescription)
		CachedHumDesc[player] = realDescription
	end
end

local function checkForLimitedLocked(itemId, isBundle)
	local allowlist = ConfigReader:read("CatalogPurchaseAllowList")
	local blocklist = ConfigReader:read("CatalogPurchaseBlockList")

	if table.find(allowlist, itemId) then
		return false
	elseif table.find(blocklist, itemId) then
		return true
	end

	local success, itemInfo = pcall(function()
		return MarketplaceService:GetProductInfo(itemId, isBundle and Enum.InfoType.Bundle or Enum.InfoType.Asset)
	end)

	if not success then
		return true
	end

	if itemInfo.CollectiblesItemDetails and itemInfo.CollectiblesItemDetails.IsLimited then
		local resalePrice = itemInfo.CollectiblesItemDetails.CollectibleLowestResalePrice
		return not (resalePrice and itemInfo.Remaining == 0)
	end

	return false
end

local function PromptPurchase(player, itemId, isBundle, categoryName)
	local isLocked = checkForLimitedLocked(itemId, isBundle)
	if isLocked then
		OnDisplayPopupMessage:FireClient(player, "This item cannot be purchased in this experience.")
		return
	end

	if categoryName then
		
	end

	if not isBundle then
		MarketplaceService:PromptPurchase(player, itemId)
	else
		MarketplaceService:PromptBundlePurchase(player, itemId)
	end
end

local function PromptPurchaseOutfit(player, outfit)
	local itemPromises = {}
	for id, outfitItem in pairs(outfit) do
		table.insert(itemPromises, Promise.new(function (resolve)
			local isLocked = checkForLimitedLocked(outfitItem.BundleId or outfitItem.AssetId, not not outfitItem.BundleId)
			if isLocked then
				outfit[id] = nil
			end
			resolve()
		end))
	end

	Promise.all(itemPromises):await()

	local items = {}
	for _, outfitItem in pairs(outfit) do
		table.insert(items, {
			Id = tostring(outfitItem.BundleId or outfitItem.AssetId),
			Type = outfitItem.BundleId and Enum.MarketplaceProductType.AvatarBundle or Enum.MarketplaceProductType.AvatarAsset,
		})
	end
	
	MarketplaceService:PromptBulkPurchase(player, items, {})
end

local catalogConfig = nil
local loadingCatalogConfig = true
task.spawn(function()
	local success, result = BatchHTTP.request("POST", "/catalog/config")
	if not success or result.status ~= "ok" then
		warn("COULD NOT FETCH POPMALL CONFIG FROM SERVER")
	else
		catalogConfig = result
	end
	loadingCatalogConfig = false
end)

local function getCatalogConfig()
	repeat task.wait() until not loadingCatalogConfig
	return catalogConfig
end

local cachedConfigs = {}
local function getCatalogConfigForPlayer(player: Player)
	if not player then
		error("Player is required")
		return
	end

	if cachedConfigs[player.UserId] then
		return true, cachedConfigs[player.UserId]
	end

	local success, result = BatchHTTP.request("POST", "/catalog/config", {
		viewer = player.UserId
	})

	if success then
		cachedConfigs[player.UserId] = result
	end

	return success, result
end

function CatalogModuleServer.Init()
	local GetCatalogConfigServer = Instance.new("BindableFunction")
	GetCatalogConfigServer.Name = "GetCatalogConfigServer"
	GetCatalogConfigServer.Parent = ReplicatedStorage.BloxbizRemotes
	GetCatalogConfigServer.OnInvoke = getCatalogConfig

	local GetCatalogConfigForPlayer = Instance.new("RemoteFunction")
	GetCatalogConfigForPlayer.Name = "GetCatalogConfigForPlayer"
	GetCatalogConfigForPlayer.Parent = ReplicatedStorage.BloxbizRemotes
	GetCatalogConfigForPlayer.OnServerInvoke = getCatalogConfigForPlayer

	local OnItemsPageRequest = Instance.new("RemoteFunction")
	OnItemsPageRequest.Name = "CatalogOnItemsPageRequest"
	OnItemsPageRequest.OnServerInvoke = ItemsResponse
	OnItemsPageRequest.Parent = ReplicatedStorage.BloxbizRemotes

	local OnSearchItemsRequest = Instance.new("RemoteFunction")
	OnSearchItemsRequest.Name = "CatalogOnSearchItemsRequest"
	OnSearchItemsRequest.OnServerInvoke = SearchItemsReponse
	OnSearchItemsRequest.Parent = ReplicatedStorage.BloxbizRemotes

	local OnLoadEmoteRequest = Instance.new("RemoteFunction")
	OnLoadEmoteRequest.Name = "CatalogOnLoadEmoteRequest"
	OnLoadEmoteRequest.OnServerInvoke = EmoteResponse
	OnLoadEmoteRequest.Parent = ReplicatedStorage.BloxbizRemotes

	local OnApplyToRealHumanoid = Instance.new("RemoteEvent")
	OnApplyToRealHumanoid.Name = "CatalogOnApplyToRealHumanoid"
	OnApplyToRealHumanoid.OnServerEvent:Connect(ApplyToRealHumanoid)
	OnApplyToRealHumanoid.Parent = ReplicatedStorage.BloxbizRemotes

	local OnApplyOutfit = Instance.new("RemoteEvent")
	OnApplyOutfit.Name = "CatalogOnApplyOutfit"
	OnApplyOutfit.OnServerEvent:Connect(ApplyOutfit)
	OnApplyOutfit.Parent = ReplicatedStorage.BloxbizRemotes

	local OnSaveOutfit = Instance.new("RemoteFunction")
	OnSaveOutfit.Name = "CatalogOnSaveOutfit"
	OnSaveOutfit.OnServerInvoke = SaveOutfit
	OnSaveOutfit.Parent = ReplicatedStorage.BloxbizRemotes

	local OnDeleteOutfit = Instance.new("RemoteEvent")
	OnDeleteOutfit.Name = "CatalogOnDeleteOutfit"
	OnDeleteOutfit.OnServerEvent:Connect(DeleteOutfit)
	OnDeleteOutfit.Parent = ReplicatedStorage.BloxbizRemotes

	local OnResetOutfit = Instance.new("RemoteEvent")
	OnResetOutfit.Name = "CatalogOnResetOutfit"
	OnResetOutfit.OnServerEvent:Connect(resetRealCharacterOutfit)
	OnResetOutfit.Parent = ReplicatedStorage.BloxbizRemotes

	local OnPromptPurchase = Instance.new("RemoteFunction")
	OnPromptPurchase.Name = "CatalogOnPromptPurchase"
	OnPromptPurchase.OnServerInvoke = PromptPurchase
	OnPromptPurchase.Parent = ReplicatedStorage.BloxbizRemotes

	local OnPromptPurchaseOutfit = Instance.new("RemoteFunction")
	OnPromptPurchaseOutfit.Name = "CatalogOnPromptPurchaseOutfit"
	OnPromptPurchaseOutfit.OnServerInvoke = PromptPurchaseOutfit
	OnPromptPurchaseOutfit.Parent = ReplicatedStorage.BloxbizRemotes

	local OnPurchaseComplete = Instance.new("RemoteEvent")
	OnPurchaseComplete.Name = "CatalogOnPurchaseComplete"
	OnPurchaseComplete.Parent = ReplicatedStorage.BloxbizRemotes

	OnDisplayPopupMessage = Instance.new("RemoteEvent")
	OnDisplayPopupMessage.Name = "CatalogOnDisplayPopupMessage"
	OnDisplayPopupMessage.Parent = ReplicatedStorage.BloxbizRemotes

	local function afterPurchase(plr, itemId, owns)
		OnPurchaseComplete:FireClient(plr, itemId, owns)
	end

	MarketplaceService.PromptPurchaseFinished:Connect(afterPurchase)
	-- MarketplaceService.PromptBundlePurchaseFinished:Connect(afterPurchase)

	InitCategoryItems()

	if SETTINGS.PersistentWear then
		local function applyCachedHumDesc(Player)
			local HumDesc = CachedHumDesc[Player]
			if not HumDesc then
				return
			end

			local Hum = Player.Character:WaitForChild("Humanoid")

			task.wait()

			if Player:IsDescendantOf(Players) then
				Hum:ApplyDescription(HumDesc)
			end
		end

		local function onPlayerAdded(player)
			player.CharacterAdded:Connect(function()
				applyCachedHumDesc(player)
			end)

			local RealHumDesc = Utils.callWithRetry(function()
				return Players:GetHumanoidDescriptionFromUserId(math.max(player.UserId, 1))
			end, 5)

			CachedRealHumDesc[player] = RealHumDesc
		end

		Players.PlayerAdded:Connect(onPlayerAdded)

		for _, Player in Players:GetPlayers() do
			onPlayerAdded(Player)
		end
	end

	Players.PlayerRemoving:Connect(function(Player)
		CachedHumDesc[Player] = nil
		CachedRealHumDesc[Player] = nil

		SearchModule.ResetPlayerCache(Player)
	end)

	DataManager.Init()
	CatalogAnalytics.init()
	OutfitFeed.Init()
	FeaturedCategories.Init()
	AvatarPreview.Init()
	ShopFeed.Init()
end

return CatalogModuleServer
