local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Controllers = script.Parent
local CatalogClient = Controllers.Parent
local BloxbizSDK = CatalogClient.Parent

local UtilsStorage = BloxbizSDK:WaitForChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local Promise = require(UtilsStorage:WaitForChild("Promise"))

local InventoryHandler = require(CatalogClient:WaitForChild("Classes"):WaitForChild("InventoryHandler"))

local BuildShopFeed = require(script.BuildShopFeed)
local ShopPreview = require(script.BuildShopFeed.ShopPreview)

local ShopClass = require(script.ShopClass)

local Value = Fusion.Value

local OnRateShop, OnGetFeeds, OnEditShop, OnCreateShop, OnDisplayPopupMessage, OnConfirmShopCreation, OnGetShopFeed, OnGetShopDefinition, OnReportImpression

local ShopFeedController = {}

local FEED_ENABLED = false
local REFRESH_FEEDS_INTERVAL = 60

function ShopFeedController:Init(catalogContainer, controllers)
	self.Controllers = controllers
	self.CatalogContainer = catalogContainer or self.CatalogContainer

	self.Guis = {}

	self.Enabled = Value(false)
	self.Loading = Value(false)

	self.IsEditingShop = Value(false)
	self.IsCreatingShop = Value(false)

	self.CreateShopMode = {
		Loading = Value(false),

		SelectedName = Value(),
		SelectedGroup = Value(),
		SelectedGroupValue = Value(),
		SelectedItems = Value({}),
		SelectedEmoji = Value("🧢"),
		SelectingEmoji = Value(false),
	}

	self.PopupProps = Value({})

	self.EnableBackgroundCover = Value(false)

	self.SelectedShop = Value()
	self.CurrentFeedId = Value()

	self.LikedShops = Value({})

	self.Tabs = {}
	self.Feeds = {}
	self.FeedsById = {}

	self.LastRefresh = 0

	self.LoadingPromises = {}

	return ShopFeedController
end

local function MapFeeds(feed)
	feed.Page = 0
	feed.ScrollY = 0
	feed.CachedShops = {}
	feed.LoadedAll = false
	feed.ShouldRefresh = false -- set this to true for favorites feed on shop like

	feed.GetShops = function()
		return feed.CachedShops
	end

	feed.CacheShops = function(shops)
		local newShops = {}

		for _, shop in shops do
			if shop.own_like == true then
				local likedShops = ShopFeedController.LikedShops:get()
				likedShops[shop.guid] = true

				ShopFeedController.LikedShops:set(likedShops)
			end

			table.insert(feed.CachedShops, shop)
			table.insert(newShops, shop)
		end

		return newShops
	end

	return feed
end

local function MapTabs(feed)
	local id = feed.id
	local name = feed.name

	return {
		Id = id,
		Text = name,
		Data = {
			feed = id
		},
	}
end

function ShopFeedController:Start()
	local bloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")

	OnRateShop = bloxbizRemotes:WaitForChild("CatalogOnRateShop")
	OnGetFeeds = bloxbizRemotes:WaitForChild("CatalogOnGetShopFeeds")
	OnEditShop = bloxbizRemotes:WaitForChild("CatalogOnEditShop")
	OnCreateShop = bloxbizRemotes:WaitForChild("CatalogOnCreateShop")
	OnGetShopFeed = bloxbizRemotes:WaitForChild("CatalogOnGetShopFeed")
	OnGetShopDefinition = bloxbizRemotes:WaitForChild("CatalogOnGetShopDefinition")
	OnConfirmShopCreation = bloxbizRemotes:WaitForChild("CatalogOnConfirmShopCreation")
	OnReportImpression = bloxbizRemotes:WaitForChild("CatalogOnReportImpression")
	OnDisplayPopupMessage = bloxbizRemotes:WaitForChild("CatalogOnDisplayPopupMessage")

	local response = OnGetFeeds:InvokeServer()
	if not response then
		return
	end

	self.Feeds = response.Feeds
	self.FeedsById = Utils.map(response.FeedsById, MapFeeds)
	self.Tabs = Utils.map(self.Feeds, MapTabs)

	local ShopFrame = BuildShopFeed(self)
	local ShopScrollingFrame = ShopFrame:WaitForChild("ItemGrid"):WaitForChild("ScrollingFrame")
	local ShopListFrame = ShopScrollingFrame:WaitForChild("Content")

	local ShopViewFrame = ShopFrame:WaitForChild("Shop View")
	local ShopViewScrollingFrame = ShopViewFrame:WaitForChild("Content"):WaitForChild("ScrollingFrame")
	local ShopViewListFrame = ShopViewScrollingFrame:WaitForChild("ItemFrame")

	self.Guis = {
		ShopFrame = ShopFrame,
		ShopListFrame = ShopListFrame,
		ShopScrollingFrame = ShopScrollingFrame,

		ShopViewFrame = ShopViewFrame,
		ShopViewListFrame = ShopViewListFrame,
		ShopViewScrollingFrame = ShopViewScrollingFrame,
	}

	local loadDebounce = false

	ShopScrollingFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		local feed = self:GetFeed(self.CurrentFeedId:get())
		if not feed then
			return
		end

		local passedThreshold = math.round(ShopScrollingFrame.CanvasPosition.Y) >= math.round(ShopScrollingFrame.AbsoluteCanvasSize.Y - ShopScrollingFrame.AbsoluteWindowSize.Y) * 0.7
		if passedThreshold and not self.Loading:get() then
			if not loadDebounce then
				loadDebounce = true

				if feed.LoadedAll then
					loadDebounce = nil
					return
				end

				self:LoadNextPage(feed, true)

				loadDebounce = nil
			end
		end
	end)

	OnConfirmShopCreation.OnClientEvent:Connect(function(success, shopData)
		if success then
			ShopClass.Load(shopData, self)

			self.IsEditingShop:set(false)
			self.IsCreatingShop:set(false)

			self.PopupProps:set({
				Visible = true,
				Title = "Success!",
				Text =  "It may take a few minutes for your shop to update.",
			})
		else
			local errorMsg = shopData

			self.PopupProps:set({
				Visible = true,
				Title = "Oops!",
				Text =  errorMsg,
			})
		end

		self.EnableBackgroundCover:set(false)
		self.CreateShopMode.Loading:set(false)
	end)

	OnDisplayPopupMessage.OnClientEvent:Connect(function(message, title)
		self.PopupProps:set({
			Visible = true,
			Title = title or "Oops!",
			Text =  message,
		})
	end)
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

function ShopFeedController:OnCreateShop(newShopData)
	if self.IsCreatingShop:get() == true then
		if not validateShopData(newShopData) then
			self.PopupProps:set({
				Visible = true,
				Title = "Oops!",
				Text =  "Please fill out all the fields before submitting.",
			})
			return
		end

		self.EnableBackgroundCover:set(true)
		self.CreateShopMode.Loading:set(true)

		local oldShopData = self.SelectedShop:get()

		local success, shopData, errorMsg
		if self.IsEditingShop:get() == true then
			local shopId = self.SelectedShop:get().Id
			success, shopData = OnEditShop:InvokeServer(shopId, newShopData)
		else
			success, errorMsg = OnCreateShop:InvokeServer(newShopData)
		end

		if success then
			if shopData then
				-- Has edited the shop
				local shopId = shopData.guid

				local shop = ShopClass.Get(shopId)
				if shop then
					shop:Destroy()
				end

				shopData.views = oldShopData.Data.views
				shopData.up_votes = oldShopData.Data.up_votes
				shopData.own_like = oldShopData.Data.own_like
				shopData.can_edit = oldShopData.Data.can_edit

				ShopClass.Load(shopData, self)

				self.IsEditingShop:set(false)
				self.IsCreatingShop:set(false)

				self.EnableBackgroundCover:set(false)
				self.CreateShopMode.Loading:set(false)

				self.PopupProps:set({
					Visible = true,
					Title = "Success!",
					Text =  "It may take a few minutes for your shop to update.",
				})
			end
		else
			self.EnableBackgroundCover:set(false)
			self.CreateShopMode.Loading:set(false)
			print(success, shopData, errorMsg)
			errorMsg = errorMsg or shopData

			self.PopupProps:set({
				Visible = true,
				Title = "Oops!",
				Text =  errorMsg,
			})
		end
	else
		self.CreateShopMode.SelectedName:set(nil)
		self.CreateShopMode.SelectedGroup:set(nil)
		self.CreateShopMode.SelectedGroupValue:set(nil)
		self.CreateShopMode.SelectedItems:set({})
		self.CreateShopMode.SelectedEmoji:set("🧢")
		self.CreateShopMode.SelectingEmoji:set(false)

		self.IsCreatingShop:set(true)
	end
end

local function getShopItemsFromSections(sections)
	local section = sections[1]

	local queries = section.queries
	local featuredItems = section.featured_items

	local items = {}

	local assets = {}
	local bundles = {}

	for _, item in featuredItems do
		if item.itemType == "Bundle" then
			table.insert(bundles, item.id)
		else
			table.insert(assets, item.id)
		end
	end

	local assetInfos = InventoryHandler.GetBatchItemDetails(assets, Enum.AvatarItemType.Asset)
	local bundleInfos = InventoryHandler.GetBatchItemDetails(bundles, Enum.AvatarItemType.Bundle)

	for _, item in assetInfos do
		local id = item.Id
		local name = item.Name

		items[id .. "_Item"] = {
			Data = name,
			Id = id,
			Type = "Item",
		}
	end

	for _, item in bundleInfos do
		local id = item.Id
		local name = item.Name

		items[id .. "_Item"] = {
			Data = name,
			Id = id,
			Type = "Item",
			IsBundle = true,
		}
	end

	for _, query in queries do
		local keyword = query.Keyword
		local creator = query.CreatorType

		if keyword then
			items[keyword .. "_Search term"] = {
				Data = keyword,
				Id = keyword,
				Type = "Search term"
			}
		elseif creator then
			local creatorType = creator == 1 and "User" or "Group"
			local creatorId = query.CreatorTargetId

			local name = "Unknown"
			if creatorType == "User" then
				local success, result = pcall(function()
					return Players:GetNameFromUserIdAsync(creatorId)
				end)

				if success then
					name = result
				end
			else
				local success, result = pcall(function()
					return GroupService:GetGroupInfoAsync(creatorId)
				end)

				if success then
					name = result.Name
				end
			end

			items[creatorId .. "_" .. creatorType] = {
				Data = name,
				Id = creatorId,
				Type = creatorType
			}
		end
	end

	return items
end

local function fillShopDefinitions(definition)
	local createMode = ShopFeedController.CreateShopMode
	local selectedName = createMode.SelectedName
    local selectedGroup = createMode.SelectedGroup
    local selectedGroupValue = createMode.SelectedGroupValue
    local selectedItems = createMode.SelectedItems
    local selectedEmoji = createMode.SelectedEmoji

	local groupId = definition.owner_group
	local groupName

	local success, groupInfo = pcall(function()
        return GroupService:GetGroupInfoAsync(groupId)
    end)

	if success then
		groupName = groupInfo.Name
	end

	selectedName:set(definition.name)
	selectedEmoji:set(definition.thumbnail)

	selectedGroup:set({
		type = "Group",
		value = definition.owner_group,
		label = groupName or "Unknown",
	})
	selectedGroupValue:set(definition.owner_group)

	selectedItems:set(getShopItemsFromSections(definition.sections))
end

function ShopFeedController:ToggleShopEditMode(toggle)
	if toggle then
		self.CreateShopMode.SelectedName:set(nil)
		self.CreateShopMode.SelectedGroup:set(nil)
		self.CreateShopMode.SelectedGroupValue:set(nil)
		self.CreateShopMode.SelectedItems:set({})
		self.CreateShopMode.SelectedEmoji:set("🧢")
		self.CreateShopMode.SelectingEmoji:set(false)

		self.IsEditingShop:set(true)
		self.IsCreatingShop:set(true)
		self.CreateShopMode.Loading:set(true)

		local shop = self.SelectedShop:get()

		local shopId = shop.Id
		local groupId = shop.Data.owner_group

		local success, definition = OnGetShopDefinition:InvokeServer(shopId, groupId)
		if success then
			fillShopDefinitions(definition)
		end

		self.CreateShopMode.Loading:set(false)
	else
		self.IsEditingShop:set(false)
		self.IsCreatingShop:set(false)
	end
end

function ShopFeedController:OnOpenShop(shopData)
	if shopData then
		OnReportImpression:FireServer(shopData.guid)

		ShopClass.Load(shopData, self)
	end
end

function ShopFeedController:OnRateShop(shopId)
	local likedShops = self.LikedShops:get()

	local isLiked = if likedShops[shopId] then nil else true

	local rating = isLiked and 1 or 0
	local countAdded = isLiked and 1 or -1

	likedShops[shopId] = isLiked
	self.LikedShops:set(likedShops)

	OnRateShop:FireServer(shopId, rating)

	self:GetFeed("liked-by-you").ShouldRefresh = true

	return isLiked, countAdded
end

function ShopFeedController:GetShopsFromFeedId(feedId, page)
	local success, result = OnGetShopFeed:InvokeServer(feedId, page)

	if success then
		return true, result
	else
		return false, result
	end
end

function ShopFeedController:GetFeed(feedId)
	return self.FeedsById[feedId]
end

local function ClearListFrame(ListFrame)
	for _, child in ListFrame:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

function ShopFeedController:SwitchToFeed(feedId)
	local currentFeed = self.CurrentFeedId
	if currentFeed:get() == feedId then
		return
	end
	currentFeed:set(feedId)

	self:CancelLoading()

	local feed = self:GetFeed(feedId)

	if tick() - self.LastRefresh > REFRESH_FEEDS_INTERVAL then
		self:ClearAllFeedsCache()
	elseif feed.ShouldRefresh then
		self:ClearFeedCache(feedId)
	end

	ClearListFrame(self.Guis.ShopListFrame)

	local shops = feed.GetShops()
	if #shops > 0 then
		table.insert(self.LoadingPromises, self:LoadFromCache(shops):andThen(function()
			self.Loading:set(false)
		end))
	else
		self:LoadNextPage(feed)
	end
end

function ShopFeedController:LoadFromCache(shops, fromScrolling)
	return Promise.new(function(resolve, reject)
		local ListFrame = self.Guis.ShopListFrame

		if not fromScrolling then
			self.Loading:set(true)
		end

		for i, shopData in shops do
			local shopFrame = ShopPreview(self, shopData)
			shopFrame.Parent = ListFrame
		end

		resolve()
	end)
end

function ShopFeedController:LoadNextPage(feed, fromScrolling)
	if not fromScrolling then
		self.Loading:set(true)
	end

	feed.Page += 1

	local id = feed.id
	local page = feed.Page

	local success, shops = self:GetShopsFromFeedId(id, page)
	if success then
		if #shops > 0 then
			local newShops = feed.CacheShops(shops)

			table.insert(self.LoadingPromises, self:LoadFromCache(newShops, fromScrolling):andThen(function()
				self.Loading:set(false)
			end))
		else
			if page == 1 then
				ClearListFrame(self.Guis.ShopListFrame)
			end

			feed.LoadedAll = true
			self.Loading:set(false)
		end
	else
		print("Handle page load failed!")
		feed.Page -= 1

		self.Loading:set(false)
	end
end

function ShopFeedController:ClearFeedCache(feedId)
	local feed = self:GetFeed(feedId)
	feed.Page = 0
	feed.ScrollY = 0
	feed.CachedShops = {}
	feed.LoadedAll = false
end

function ShopFeedController:ClearAllFeedsCache()
	for feedId in self.FeedsById do
		self:ClearFeedCache(feedId)
	end

	self.LikedShops:set({})
	self.LastRefresh = tick()
end

function ShopFeedController:CancelLoading()
	for _, promise in self.LoadingPromises do
		promise:cancel()
	end

	self.LoadingPromises = {}
end

function ShopFeedController:Enable()
	if self.Enabled:get() then
		return
	end
	self.Enabled:set(true)

	self.Controllers.CategoryController:Disable(true)
	self.Controllers.OutfitsController:Disable()
	self.Controllers.InventoryController:Disable()
	self.Controllers.BodyEditorController:Disable()

	local firstTab = self.Tabs[1].Id
	self:SwitchToFeed(firstTab)
end

function ShopFeedController:Disable()
	self.Enabled:set(false)

	self:CancelLoading()
end

return ShopFeedController