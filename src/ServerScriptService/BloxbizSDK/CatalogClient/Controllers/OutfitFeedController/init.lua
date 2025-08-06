--!strict
local AvatarEditorService = game:GetService("AvatarEditorService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local BloxbizSDK = script.Parent.Parent.Parent

local CatalogCategoryOpenedEvent, OnCreateFeed, OnGetFeed, OnFeedAction, OnRequestData, OnGetAllFeed, OnBoostFeed, OnBoostResult, OnGetFeedsRemote
local OnRequestPermissionRemote, OnLoadOutfitsRemote, OnReportImpressionRemote, OnReportTryOnRemote

local CatalogShared = BloxbizSDK.CatalogShared
local CatalogClient = BloxbizSDK.CatalogClient

local FeedUtils = require(CatalogShared.FeedUtils)
local Payload = require(CatalogShared.FeedUtils.Payload)
local GeneralUtils = require(CatalogShared.CatalogUtils)
local InventoryHandler = require(CatalogClient.Classes.InventoryHandler)

local Player = Players.LocalPlayer
local Classes = CatalogClient.Classes

local AvatarHandler = require(Classes.AvatarHandler)
local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local Promise = require(UtilsStorage:WaitForChild("Promise"))

local Components = script.Parent.Parent.Components
local Generic = Components.Generic

local EmptyState = require(Components.EmptyState)

local ActionButton = require(Components.ActionButton)
local FeedComponents = Components.Feed
local SearchBar = require(Components.SearchBar)
local ShareOutfit = require(FeedComponents.ShareOutfit)
local ShareOutfitModal = require(FeedComponents.ShareOutfitModal)
local FeedFrame = require(FeedComponents.Frame)
local ItemFrame = require(FeedComponents.Item)
local LoadingFrame = require(Components.LoadingFrame)
local RetryFrame = require(Components.RetryFrame)
local Dropdown = require(Components.Dropdown)
local SearchContext = require(Components.SearchContext)
local ItemGrid = require(Components.ItemGrid)

local OutfitFrame = require(script.OutfitFrame)

local ContentFrame = Components.ContentFrame
local Frame = require(ContentFrame.Frame)
local Sort = require(ContentFrame.Sort)

local ENABLED = true

local DEFAULT_CLOTHES = {
	Pants = 855781078,
	Shirt = 855766176,
}

type FeedType = FeedUtils.ServerFeedType
type SortType = FeedUtils.ServerFeedSort
type Outfit = { [string | number]: AvatarHandler.ItemData | { [string]: Color3 } }
export type OutfitFeedController = {
	__index: OutfitFeedController,
	new: (coreContainer: Frame, loadingFrame: Frame) -> OutfitFeedController,

	Init: (self: OutfitFeedController, controllers: { [string]: any }) -> (),
	Start: (self: OutfitFeedController) -> (),
	Enable: (self: OutfitFeedController) -> (),
	Disable: (self: OutfitFeedController) -> (),
	ClearWindow: (self: OutfitFeedController) -> (),
	LoadFeed: (self: OutfitFeedController, items: { string | FeedUtils.BackendOutfit }) -> (),
	CreateFeed: (
		self: OutfitFeedController,
		id: string,
		backendOutfit: FeedUtils.BackendOutfit?
	) -> Frame?,
	GetFeedFromServer: (self: OutfitFeedController, page: number, feedType: FeedType, sortType: SortType) -> boolean,
	ProcessOutfit: (
		self: OutfitFeedController,
		outfit: FeedUtils.Outfit,
		rawItems: { any }
	) -> (HumanoidDescription, Outfit, { TextButton }),
	UpdateTryButton: (self: OutfitFeedController, id: number, triedOn: boolean) -> (),

	Enabled: boolean,
	Controllers: { [string]: any },
	Container: Frame,
	Observers: { () -> () },
	Connections: { RBXScriptConnection },
	GuiObjects: { [string]: GuiObject },

	Item: Fusion.Value<any>,
	Tabs: {
		Default: Fusion.Value<Sort.ButtonData?>,
		Current: Fusion.Value<Sort.ButtonData?>,
	},
	States: {
		Page: Fusion.Value<number>,
		Sort: Fusion.Value<string>,
		Type: Fusion.Value<string>,
		Loading: Fusion.Value<boolean>,
		OutOfContent: Fusion.Value<boolean>,
	},
	CachedRawData: {
		[number]: { [string]: any },
	},

	TaskId: number,
	OutfitsCache: Fusion.Value<{ [string]: FeedFrame.FeedData }>,
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

local DEFAULT_QUERY = {
	keywords = ""
}

local OutfitFeed = {}
OutfitFeed.__index = OutfitFeed

function OutfitFeed.new(coreContainer: Frame, loadingFrame: Frame)
	local self = setmetatable({} :: any, OutfitFeed)
	self.Container = coreContainer
	self.Enabled = false

	self.Observers = {}
	self.Connections = {}
	self.GuiObjects = {}

	self.Feeds = {}
	self.FeedsById = {}

	self.Item = Fusion.Value(nil)
	self.Tabs = {
		Default = Fusion.Value(nil),
		Current = Fusion.Value(nil),
	}

	self.States = {
		CurrentFeedId = Fusion.Value(nil),
		Page = Fusion.Value(1),
		Sort = Fusion.Value("hot"),
		Type = Fusion.Value("all"),
		OutfitOffset = Fusion.Value(0),
		Loading = Fusion.Value(false),
		SwitchingFeed = Fusion.Value(false),
		OutOfContent = Fusion.Value(false),
		Query = Fusion.Value(DEFAULT_QUERY)
	}

	self.OutfitsCache = {}
	self.TaskId = 1
	self.OutfitsCreated = 0

	self.SelectedOutfit = Fusion.Value()

	self.GuiObjects.LoadingFrame = nil

	self.LoadingPromises = {}

	return self
end

function OutfitFeed:CancelLoading()
	for _, prom in ipairs(self.LoadingPromises) do
		prom:cancel()
	end

	self.LoadingPromises = {}
end

function OutfitFeed:Init(controllers: { [string]: { any } })
	local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")
	CatalogCategoryOpenedEvent = BloxbizRemotes:WaitForChild("CatalogCategoryOpenedEvent")
	OnCreateFeed = BloxbizRemotes:WaitForChild("CatalogOnCreateFeed") :: RemoteFunction
	OnGetFeed = BloxbizRemotes:WaitForChild("CatalogOnGetFeed") :: RemoteFunction
	OnFeedAction = BloxbizRemotes:WaitForChild("CatalogOnFeedAction") :: RemoteFunction
	OnRequestData = BloxbizRemotes:WaitForChild("CatalogOnRequestData") :: RemoteFunction
	OnGetAllFeed = BloxbizRemotes:WaitForChild("CatalogOnGetAllFeed") :: RemoteFunction
	OnBoostFeed = BloxbizRemotes:WaitForChild("CatalogOnBoostFeed") :: RemoteFunction
	OnBoostResult = BloxbizRemotes:WaitForChild("CatalogOnBoostResult") :: RemoteEvent
	OnGetFeedsRemote = BloxbizRemotes:WaitForChild("CatalogOnGetFeeds") :: RemoteFunction
	OnLoadOutfitsRemote = BloxbizRemotes:WaitForChild("CatalogOnLoadOutfits") :: RemoteFunction
	OnReportImpressionRemote = BloxbizRemotes:WaitForChild("CatalogOnImpression") :: RemoteFunction
	OnReportTryOnRemote = BloxbizRemotes:WaitForChild("CatalogOnTryOn") :: RemoteFunction

	OnRequestPermissionRemote = BloxbizRemotes:WaitForChild("CatalogOnRequestPermissionRemote") :: RemoteFunction
	ENABLED = OnRequestPermissionRemote:InvokeServer()

	-- get feeds to show to player.
	-- having these on the server with predetermined types/sorts prevents players from using exploits to send custom sorts & searches to outfit feed

	local resp = OnGetFeedsRemote:InvokeServer()
	self.Feeds = resp.Feeds
	self.FeedsById = Utils.map(resp.FeedsById, function (feed)
		feed.ShouldRefresh = Fusion.Value(false)
		feed.LoadedOutfits = Fusion.Value({})
		feed.Page = Fusion.Value(0)
		feed.LoadedAll = Fusion.Value(false)
		feed.LastRefresh = Fusion.Value(-1)
		feed.ScrollY = Fusion.Value(0)

		-- handle 429 errors
		feed.LoadFailed = Fusion.Value(false)
		feed.SwitchFailed = Fusion.Value(false)
		feed.ErrorType = Fusion.Value(nil)

		return feed
	end)


	OnBoostResult.OnClientEvent:Connect(function(outfitId: string, success: boolean)
		if not success then
			warn("[SuperBiz] Boost failed for outfit " .. outfitId)
			return
		end

		local outfits = self.OutfitsCache
		local outfit = outfits[outfitId]
		if outfit then
			outfit.Boosts:set(outfit.Boosts:get() + 1)
		end
	end)

	self.Controllers = controllers
	local frameContainer = self.Container:WaitForChild("FrameContainer")

	-- OutfitFeed Frame
	local mainFrameProps: Frame.Props = {
		Name = "Outfit Feed",
		UtilitiesHolder = {},
		ScrollingFrame = {
			Position = UDim2.fromScale(0.5, 0),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Size = UDim2.fromScale(1, 1),

			Layout = {
				FillDirection = Enum.FillDirection.Horizontal,
				Type = "UIGridLayout",
				Padding = UDim2.fromScale(0.009, 0.012),
				Size = UDim2.fromScale(1, 0.19),
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
			DragScrollDisabled = true,
		},
		SkipListLayout = false,
	}

	local mainFrame = Frame(mainFrameProps)
	local utilFrame = mainFrame:WaitForChild("UtilitiesHolder") :: Frame
	local utilFrameHolder = utilFrame:WaitForChild("Holder") :: Frame
	local scrollingFrame = mainFrame:WaitForChild("ScrollingFrame") :: ScrollingFrame
	scrollingFrame:Destroy()

	self.IsEmpty = Fusion.Computed(function()
		local feedId = self.States.CurrentFeedId:get()

		if self.States.Loading:get() then
			return false
		end

		local feed = self.FeedsById[feedId]
		if not feed then
			return false
		end

		local loadedCount = #feed.LoadedOutfits:get()
		if loadedCount == 0 then
			return true
		end
	end)

	local itemGrid = ItemGrid {
		Parent = mainFrame,
		LayoutOrder = 2,
		Size = UDim2.fromScale(1, 0.9),
		Columns = 2,
		ItemRatio = 3/2,
		Gap = 8,
		Visible = Fusion.Computed(function()
			local feedId = self.States.CurrentFeedId:get()
			local feed = self.FeedsById[feedId]
			local isErr = feed and feed.LoadFailed:get() or false
			
			local empty = self.IsEmpty:get()
			return not (isErr or empty)
		end),
		DragScroll = true
	}
	scrollingFrame = itemGrid.ScrollingFrame
	local itemFrame = scrollingFrame.Content

	self.GuiObjects.Frame = mainFrame
	self.GuiObjects.ScrollingFrame = scrollingFrame
	self.GuiObjects.ItemFrame = itemFrame
	self.GuiObjects.FilterFrame = utilFrame

	utilFrame.ZIndex = 100

	mainFrame.Visible = false
	mainFrame.Parent = frameContainer

	-- loading frame

	local isScrollLoad = Fusion.Computed(function()
		local isSwitching = self.States.SwitchingFeed:get()
		local curFeed = self.FeedsById[self.States.CurrentFeedId:get()]
		
		if isSwitching or not curFeed then
			return false
		end

		local loadedFits = curFeed.LoadedOutfits:get()
		if #loadedFits == 0 then
			return false
		else
			return true
		end
	end)
	
	self.GuiObjects.LoadingFrame = LoadingFrame({
		Parent = Fusion.Computed(function()
			if isScrollLoad:get() then
				return self.GuiObjects.ItemFrame
			else
				return self.GuiObjects.ScrollingFrame
			end
		end, function()
			-- empty destructor function to ignore fusion warning. the instances returned by this computed are not being created by this computed
		end),
		Visible = self.States.Loading,
		Text = Fusion.Computed(function()
			if isScrollLoad:get() then
				return "Loading more..."
			else
				return "Loading outfits..."
			end
		end)
	})

	-- 429 handler frame
	
	self.GuiObjects.RetryFrame = EmptyState({
		Parent = self.GuiObjects.Frame,
		Size = UDim2.fromScale(1, 0.8),
		Visible = Fusion.Computed(function()
			local curFeedId = self.States.CurrentFeedId:get()
			local curFeed = self.FeedsById[curFeedId]
			if not curFeed then
				return false
			end

			local allFailed, switchFailed = curFeed.LoadFailed:get(), curFeed.SwitchFailed:get()
			return allFailed or switchFailed
		end),
		Text = Fusion.Computed(function()
			local curFeedId = self.States.CurrentFeedId:get()
			local curFeed = self.FeedsById[curFeedId]
			if not curFeed then
				return ""
			end

			local errType = curFeed.ErrorType:get()

			if errType == "rate_limit_exceeded" then
				return "You're searching too fast! Slow down."
			else
				Utils.pprint(errType)
				return "There was an issue loading outfits."
			end
		end),
		ButtonText = "Retry",
		Callback = function()
			local curFeedId = self.States.CurrentFeedId:get()
			local curFeed = self.FeedsById[curFeedId]
			if not curFeed then
				return false
			end

			local switchFailed = curFeed.SwitchFailed:get()

			if switchFailed then
				self:SwitchToFeed(curFeedId, true)
			else
				self:LoadNextPage()
			end
		end
	})

	-- load more on scroll down
	scrollingFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		local feedId = self.States.CurrentFeedId:get()
		local feed = self.FeedsById[feedId]

		feed.ScrollY:set(scrollingFrame.CanvasPosition.Y)

		local passedThreshold = math.round(scrollingFrame.CanvasPosition.Y) >= math.round(scrollingFrame.AbsoluteCanvasSize.Y - scrollingFrame.AbsoluteWindowSize.Y) * 0.7
		if passedThreshold and not self.States.Loading:get() then
			if feed.LoadedAll:get() then
				return
			end

			self:LoadNextPage()
		end
	end)

	-- handle tab switches
	Fusion.Observer(self.States.CurrentFeedId):onChange(function ()
		if not self.Enabled then
			return
		end

		Promise.try(function()
			self:SwitchToFeed(self.States.CurrentFeedId:get())
		end):andThen():catch(error)
	end)

	-- Filter Frame
	local paddingIncluded = (
		mainFrameProps
		and mainFrameProps.UtilitiesHolder
		and mainFrameProps.UtilitiesHolder.Padding
	)
			and true
		or false

	self.FilterTabs = Fusion.Value(Utils.map(self.Feeds, function (feed)
		return {
			Text = feed.Name,
			Data = {
				feed = feed.Id
			},
			Id = feed.Id,
			Hidden = feed.Internal or feed.SearchOnly,
			Internal = feed.Internal,
			Searchable = feed.Searchable,
			SearchOnly = feed.SearchOnly
		}
	end))

	local sortProps = {
		Size = UDim2.new(0.35, 0, 1, 0),
		Buttons = self.FilterTabs,

		Cooldown = Fusion.Value(false),
		Selected = self.States.CurrentFeedId,
		UIListLayoutIncluded = paddingIncluded
	}

	local selectedObs = Fusion.Observer(self.Tabs.Current)
	table.insert(
		self.Observers,
		selectedObs:onChange(function()
			local buttonData = self.Tabs.Current:get()
			self.TaskId += 1

			if buttonData then
				self:CancelLoading()

				local data = buttonData.Data
				local feed = data.feed
				self.States.CurrentFeedId:set(feed)
			end
		end)
	)

	sortProps.OnButtonClick = function(id: string)
		if id == self.States.CurrentFeedId:get() then
			self:SwitchToFeed(id, true)
		end
	end

	local sortFrame, setSortTab = Sort(sortProps)
	self.setSortTab = setSortTab
	sortFrame.Parent = utilFrameHolder.Left

	-- top feed dropdown & outfit feed search bar
	self.ShowSearchBar = Fusion.Value(false)
	self.ShowTopDropdown = Fusion.Computed(function()
		local curFeed = self.States.CurrentFeedId:get()
		return curFeed == "top"
	end)
	self.TopDropdownOpen = Fusion.Value(false)
	self.TopDropdownValue = Fusion.Value("top_weekly")

	local dropdownSize = Fusion.Spring(Fusion.Computed(function()
		if self.ShowTopDropdown:get() then
			return UDim2.new(0.15, 0, 1, 0)
		else
			return UDim2.fromScale(0, 1)
		end
	end), 25)
	local dropdownVisible = Fusion.Computed(function()
		return dropdownSize:get().X.Scale >= 0.01
	end)

	Dropdown({
		Parent = utilFrameHolder.Left,
		Size = dropdownSize,
		Visible = dropdownVisible,
		LayoutOrder = 2,
		Options = {
			{
				label = "This Week",
				value = "top_weekly"
			},
			{
				label = "This Month",
				value = "top_monthly"
			},
			{
				label = "All Time",
				value = "top",
			},
		},
		Value = self.TopDropdownValue,
		TrayOpen = self.TopDropdownOpen,
		TextTransparency = Fusion.Spring(Fusion.Computed(function()
			if self.ShowTopDropdown:get() then
				return 0
			else
				return 1
			end
		end), 30)
	})

	-- search info
	SearchContext({
		Parent = utilFrameHolder,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.new(0.5, -32, 0.6, 0),
		Visible = self.Controllers.TopBarController.ShowSearchContext,
		SearchTerm = self.Controllers.TopBarController.SearchQuery,
		SearchingIn = "Outfits",
		OnSearchAll = function()
			self.Controllers.TopBarController:SwitchToSearchAll()
		end
	})

	-- refresh when top dropdown changes
	Fusion.Observer(self.TopDropdownValue):onChange(function()
		if self.States.CurrentFeedId:get() == "top" then
			self:SwitchToFeed("top", true)
		end
	end)

	Fusion.Observer(self.States.Query):onChange(function()
		self:UpdateFilters()
	end)
end

function OutfitFeed:MarkAllForRefresh(predicate: (() -> boolean)?)
	for _, feed in pairs(self.FeedsById) do
		if (not predicate) or predicate(feed) then
			feed.ShouldRefresh:set(true)
		end
	end
end

function OutfitFeed:ResetFeed(feedId: string)
	local feed = self.FeedsById[feedId]

	local loadedOutfits = feed.LoadedOutfits:get()
	local outfitsCache = self.OutfitsCache
	for _, outfit in ipairs(loadedOutfits) do
		local outfitId = type(outfit) == "string" and outfit or outfit.guid
		
		if outfitsCache[outfitId] then
			outfitsCache[outfitId].Frame:Destroy()
			outfitsCache[outfitId].Frame = nil
			outfitsCache[outfitId] = nil
		end
	end

	feed.Page:set(0)
	feed.LastRefresh:set(tick())
	feed.LoadedOutfits:set({})
	feed.LoadedAll:set(false)
	feed.ScrollY:set(0)
end

function OutfitFeed:SwitchToFeed(feedId: string, refresh: boolean?)
	self:CancelLoading() -- cancel currently loading feed

	if feedId ~= "top" then
		self.TopDropdownOpen:set(false)
	end

	self.States.Loading:set(true)
	self.States.SwitchingFeed:set(true)

	local feed = self.FeedsById[feedId]

	feed.SwitchFailed:set(false)
	feed.LoadFailed:set(false)

	if feed.ShouldRefresh:get() then
		refresh = true
	end

	if not feed.Searchable then
		self.States.Query:set(DEFAULT_QUERY)
	end

	if refresh or tick() - feed.LastRefresh:get() > 60 then
		feed.ShouldRefresh:set(false)
		self:ResetFeed(feedId)
	end

	-- reset scroll on refresh for loading frame
	local scrollingFrame = self.GuiObjects.ScrollingFrame :: ScrollingFrame
	scrollingFrame.CanvasPosition = Vector2.zero

	self:ClearWindow()
	task.wait(0.1)

	local loadedOutfits = refresh and {} or feed.LoadedOutfits:get()
	if #loadedOutfits > 0 then
		self:RenderOutfits(loadedOutfits, 0, true)
			:andThen(function()
				scrollingFrame.CanvasPosition = Vector2.new(0, feed.ScrollY:get() or 0)
			end)
			:catch(function()
			end)
			:finally(function()
				self.States.Loading:set(false)
				self.States.SwitchingFeed:set(false)
			end)
	else
		self:LoadNextPage()
		scrollingFrame.CanvasPosition = Vector2.new(0, 0)
	end
end

function OutfitFeed:UpdateFilters()
	local query = self.States.Query:get().keywords
	local searching = query and #query > 0

	local filters = Utils.deepCopy(self.FilterTabs:get())
	for k, v in pairs(filters) do
		if searching then
			filters[k].Hidden = v.Internal or (not (v.Searchable or v.SearchOnly))
		else
			filters[k].Hidden = v.Internal or v.SearchOnly
		end
	end
	
	self.FilterTabs:set(filters)
	self:MarkAllForRefresh()

	local curFeedId = self.States.CurrentFeedId:get()
	local feedFilterItem = Utils.search(filters, function (f) return f.Id == curFeedId end)

	if self.Enabled and ((not feedFilterItem) or feedFilterItem.Hidden) then
		local defaultFeed = Utils.search(filters, function (f) return not f.Hidden end)
		self.States.CurrentFeedId:set(defaultFeed.Id)
		self:SwitchToFeed(defaultFeed.Id, true)
	end
end

function OutfitFeed:LoadNextPage()
	self.States.Loading:set(true)

	local feedId = self.States.CurrentFeedId:get()
	local feed = self.FeedsById[feedId]

	feed.SwitchFailed:set(false)
	feed.LoadFailed:set(false)

	feed.Page:set(feed.Page:get() + 1)
	local page = feed.Page:get()

	local alreadyLoaded = feed.LoadedOutfits:get()
	local success, outfits = self:GetOutfitsFromFeedId(feed.Id, self.States.Query:get(), page)

	if success then
		if #outfits > 0 then
			self:RenderOutfits(outfits, #alreadyLoaded, page == 1)
				:andThen(function()
				end)
				:catch(function()
				end)
				:finally(function()
					self.States.Loading:set(false)
					self.States.SwitchingFeed:set(false)
				end)
	
			for _, outfit in outfits do
				table.insert(alreadyLoaded, outfit)
			end
	
			feed.LoadedOutfits:set(alreadyLoaded)
		else
			feed.LoadedAll:set(true)
			self.States.Loading:set(false)
			self.States.SwitchingFeed:set(false)
		end
	else
		self.States.Loading:set(false)
		self.States.SwitchingFeed:set(false)
		feed.LoadFailed:set(true)
		feed.SwitchFailed:set(page == 1)
		feed.Page:set(page - 1)

		feed.ErrorType:set(outfits.status)
	end
end

function OutfitFeed:GetOutfitsFromFeedId(feedId: string, query: SearchOpts, page: number)
	if feedId == "top" then
		feedId = self.TopDropdownValue:get()
	end

	local success, result = OnLoadOutfitsRemote:InvokeServer(feedId, page, query)

	if success then
		return true, result
	else
		warn(result.message)
		return false, result
	end
end

function OutfitFeed:GetServerOutfit(name, humDesc)
	local accessories = humDesc:GetAccessories(true)

	-- first batch fetch item info so we can send names and prices to server
	local assetIds = Utils.concat(
		Utils.map(accessories, function (item) return item.AssetId end),
		Utils.filter({
			humDesc.Shirt,
			humDesc.Pants,
			humDesc.Torso,
			humDesc.RightArm,
			humDesc.LeftArm,
			humDesc.RightLeg,
			humDesc.LeftLeg,
			humDesc.Head,
			humDesc.GraphicTShirt
		}, function (id) return id and id > 0 end)
	)

	local itemDetails = Utils.defaultdict(
		function () return {} end,
		InventoryHandler.GetBatchItemDetails(assetIds)
	)

	-- create payload
	local items = {}
	table.sort(accessories, function (a, b)
		local orderA = a.Order or 0
		local orderB = b.Order or 0
		return orderA < orderB
	end)

	for _, item in pairs(accessories) do
		local slot = FeedUtils.GetAllowedSlot(item.AccessoryType.Name)

		if slot then
			local data = {
				slot = slot,
				id = item.AssetId,
				name = itemDetails[item.AssetId].Name,
				price = itemDetails[item.AssetId].Price
			}
	
			table.insert(items, data)
		end
	end

	do -- Shirts and Pants
		table.insert(items, {
			id = humDesc.Shirt,
			slot = Payload.Slots.Shirt,
			name = itemDetails[humDesc.Shirt].Name,
			price = itemDetails[humDesc.Shirt].Price
		})

		table.insert(items, {
			id = humDesc.Pants,
			slot = Payload.Slots.Pants,
			name = itemDetails[humDesc.Pants].Name,
			price = itemDetails[humDesc.Pants].Price
		})

		-- table.insert(items, {
		-- 	id = humDesc.GraphicTShirt,
		-- 	slot = Payload.Slots.TShirt,
		-- 	name = itemDetails[humDesc.GraphicTShirt].Name,
		-- 	price = itemDetails[humDesc.GraphicTShirt].Price
		-- })
	end

	do -- Body parts
		table.insert(items, {
			id = humDesc.Torso,
			slot = Payload.Slots.Torso,
			name = itemDetails[humDesc.Torso].Name,
			price = itemDetails[humDesc.Torso].Price
		})

		table.insert(items, {
			id = humDesc.RightArm,
			slot = Payload.Slots.RightArm,
			name = itemDetails[humDesc.RightArm].Name,
			price = itemDetails[humDesc.RightArm].Price
		})

		table.insert(items, {
			id = humDesc.RightLeg,
			slot = Payload.Slots.RightLeg,
			name = itemDetails[humDesc.RightLeg].Name,
			price = itemDetails[humDesc.RightLeg].Price
		})

		table.insert(items, {
			id = humDesc.LeftArm,
			slot = Payload.Slots.LeftArm,
			name = itemDetails[humDesc.LeftArm].Name,
			price = itemDetails[humDesc.LeftArm].Price
		})

		table.insert(items, {
			id = humDesc.LeftLeg,
			slot = Payload.Slots.LeftLeg,
			name = itemDetails[humDesc.LeftLeg].Name,
			price = itemDetails[humDesc.LeftLeg].Price
		})

		table.insert(items, {
			id = humDesc.Head,
			slot = Payload.Slots.Head,
			name = itemDetails[humDesc.Head].Name,
			price = itemDetails[humDesc.Head].Price
		})
	end

	local outfitPayload = {
		name = name,
		items = items,

		head_color = humDesc.HeadColor:ToHex(),
		torso_color = humDesc.TorsoColor:ToHex(),
		left_arm_color = humDesc.LeftArmColor:ToHex(),
		right_arm_color = humDesc.RightArmColor:ToHex(),
		left_leg_color = humDesc.LeftLegColor:ToHex(),
		right_leg_color = humDesc.RightLegColor:ToHex(),
	}
	
	return outfitPayload
end

function OutfitFeed:Start()
	local creatingOutfit = Fusion.Value(false)

	local shareOutfitModal = ShareOutfitModal({
		Creating = creatingOutfit,
		Enabled = Fusion.Value(ENABLED),

		CancelCallback = function()
			creatingOutfit:set(false)
		end,

		CreateCallback = function(name: string)
			-- create oufit

			creatingOutfit:set(false)
			task.spawn(function()
				local AvatarPreviewController = self.Controllers.AvatarPreviewController

				local humanoid: Humanoid = AvatarPreviewController:GetHumanoid()
				if humanoid then
					local description = humanoid:GetAppliedDescription()

					local outfit = self:GetServerOutfit(name, description)
					local success, result = OnCreateFeed:InvokeServer(outfit)

					if success then
						local frame = self:RenderOutfit(result.guid, result)
						if frame then
							local currentTab = self.States.CurrentFeedId:get()
							if currentTab == "posted" or currentTab == "new" then
								self.OutfitsCreated += 1

								frame.LayoutOrder = -self.OutfitsCreated  -- put new outfit at top of posted/new feed
								frame.Parent = self.GuiObjects.ItemFrame
								
								-- scroll to top

								local tween = TweenService:Create(
									self.GuiObjects.ScrollingFrame,
									TweenInfo.new(0.5),
									{
										CanvasPosition = Vector2.new(0, 0)
									}
								)

								tween:Play()

								self:MarkAllForRefresh()
							else
								self.States.Query:set(DEFAULT_QUERY)
								self:MarkAllForRefresh()
								self.setSortTab("posted")
							end
						end
					else
						warn(result)
					end
				end
			end)
		end,
	})

	local shareOutfit = ShareOutfit({
		Creating = creatingOutfit,
		Enabled = Fusion.Computed(function()
			if not ENABLED then
				return false
			end

			return self.Controllers.AvatarPreviewController.EquippedCount:get() <= 50
		end),
		Visible = Fusion.Computed(function()
			return not self.Controllers.TopBarController.ShowSearchContext:get()
		end),
		Callback = function()
			if ENABLED then
				if not creatingOutfit:get() then
					creatingOutfit:set(true)
				else
					return
				end
			end
		end,
	})

	local holder = self.GuiObjects.FilterFrame:WaitForChild("Holder") :: Frame
	if holder then
		shareOutfit.Parent = holder
	end

	-- handle empty feeds

	-- Fusion.Hydrate(self.GuiObjects.ItemGrid)({
	-- 	Visible = Fusion.Computed(function()
	-- 		local feedId = self.States.CurrentFeedId:get()
	-- 		local feed = self.FeedsById[feedId]
	-- 		local isErr = feed and feed.LoadFailed:get() or false
			
	-- 		local empty = isEmpty:get()
	-- 		return isErr or not empty
	-- 	end)
	-- })

	self.GuiObjects.EmptyStateFrame = EmptyState({
		Parent = self.GuiObjects.Frame,
		Size = UDim2.fromScale(1, 0.8),
		Visible = Fusion.Computed(function()
			local feedId = self.States.CurrentFeedId:get()
			local feed = self.FeedsById[feedId]
			local isErr = feed and feed.LoadFailed:get() or false
			
			local empty = self.IsEmpty:get()
			return empty and not isErr
		end),
		Text = "There's no outfits to show",
		ButtonText = "Clear Search",
		ButtonEnabled = Fusion.Computed(function()
			local q = self.Controllers.TopBarController.SearchQuery:get()
			q = q or ""

			return #q > 0
		end),
		Callback = function()
			self.Controllers.TopBarController:ResetSearchBar()
			self:SearchFor(nil)
		end,
	})

	if ENABLED then
		shareOutfitModal.Parent = self.Container.Parent
	else
		shareOutfitModal:Destroy()
	end
end

function OutfitFeed:Enable()
	if self.Enabled then
		return
	end

	self.Enabled = true
	self.GuiObjects.Frame.Visible = true

	self.Controllers.CategoryController:Disable(true)
	self.Controllers.OutfitsController:Disable()
	self.Controllers.InventoryController:Disable()
	self.Controllers.BodyEditorController:Disable()

	CatalogCategoryOpenedEvent:FireServer("Feed")

	local query = self.Controllers.TopBarController.SearchQuery:get()
	if query and #query > 0 then
		self:SearchFor(query)
	else
		if self.States.CurrentFeedId:get() == "hot" then
			self:SwitchToFeed("hot", true)
		else
			self.FeedsById.hot.ShouldRefresh:set(true)
			self.setSortTab("hot")
		end

		self:UpdateFilters()
	end
end

function OutfitFeed:Disable()
	self.Enabled = false
	self.GuiObjects.Frame.Visible = false
	self.States.Query:set({
		keywords = nil
	})
	self:CancelLoading()
end

function OutfitFeed:ClearWindow()
	self.GuiObjects.ItemFrame.Visible = false

	local ofCache = self.OutfitsCache
	for _, item in ipairs(self.GuiObjects.ItemFrame:GetChildren()) do
		if item:IsA("Frame") then
			if ofCache[item.Name] then
				ofCache[item.Name].Frame = nil
				ofCache[item.Name] = nil
			end
			item:Destroy()
		end
	end
	self.GuiObjects.ItemFrame.Visible = true
end

function OutfitFeed:GetFeedFromServer(page: number, feedType: FeedType, sortType: SortType): boolean
	self.States.Loading:set(true)

	if page == 1 then
		local scrollingFrame = self.GuiObjects.ScrollingFrame :: ScrollingFrame
		scrollingFrame.CanvasPosition = Vector2.new(0, 0)

		self:ClearWindow()
	end

	local success, result = OnGetAllFeed:InvokeServer(feedType, page, sortType, 20)
	if success and #result > 0 then
		self:RenderOutfits(result)
			:andThen(function()
				self.States.Loading:set(false)
			end)
	else
		self.States.Loading:set(false)
	end

	return success and #result > 0
end

function OutfitFeed:RenderOutfits(items: { string | FeedUtils.BackendOutfit }, offset: number?, isFirstPage: boolean?)
	offset = offset or 0

	local prom = Promise.new(function(resolve, reject)
		-- precache avatar item details using larger batch call to prevent 429s

		local ids = {}

		for _, backendOutfit in ipairs(items) do
			if type(backendOutfit) == "string" then
				continue
			end

			local outfit = FeedUtils.GetOutfitFromServerData(backendOutfit)
			for _, item in pairs(outfit.Items) do
				if item.AssetId > 0 and not InventoryHandler.ItemDetailsCache[item.AssetId] then
					table.insert(ids, item.AssetId)
				end
			end
		end
		
		for _, chunkedIds in ipairs(Utils.chunk(ids, 100)) do
			Utils.pprint(string.format("Getting %s batch items", #chunkedIds))
			local batchItemData, success = Utils.callWithRetry(function()
				if #ids > 0 then
					return AvatarEditorService:GetBatchItemDetails(chunkedIds, 1)
				else
					return {}
				end
			end, 2)
			Utils.pprint("done")
	
			if success then
				for _, rawData in pairs(batchItemData) do
					InventoryHandler.ItemDetailsCache[rawData.Id] = rawData
				end
			end
		end

		-- setup load coros

		local createOutfitFramePromises = {}
	
		local frames = {}
		for i, item in ipairs(items) do
			table.insert(createOutfitFramePromises, Promise.new(function (resolve, reject)
				local timedOut = false

				Promise.try(function()
					local frame
					if typeof(item) == "string" then
						frame = self:RenderOutfit(item)
					elseif typeof(item) == "table" then
						local id = item.guid
						frame = self:RenderOutfit(id, item)
					end
		
					if frame then
						frames[item.guid] = frame

						return frame
					end
				end)
					:timeout(4)
					:andThen(function()
						if not timedOut then
							resolve()
						end
					end)
					:catch(function(err)
						Utils.pprint("outfit load timed out", err)
						timedOut = true
						resolve(nil)
					end)
			end))
		end

		local success, result = Promise.all(createOutfitFramePromises):await()
		if not success then
			reject(result)
			warn(result)
			return
		end

		local failedCount = 0
		local framesList = {}
		for idx, item in ipairs(items) do
			local frame
			if typeof(item) == "string" then
				frame = frames[item]
			elseif typeof(item) == "table" then
				local id = item.guid
				frame = frames[id]
			end

			if frame then
				frame.LayoutOrder = offset + idx
				frame.Parent = self.GuiObjects.ItemFrame

				table.insert(framesList, frame)
			else
				failedCount += 1
			end
		end

		if failedCount / #items > 0.5 then
			for _, frame in ipairs(framesList) do
				frame:Destroy()
			end

			local curFeedId = self.States.CurrentFeedId:get()
			local curFeed = self.FeedsById[curFeedId]

			curFeed.LoadFailed:set(true)
			curFeed.ErrorType:set("avatar")
			curFeed.Page:set(curFeed.Page:get() - 1)

			if isFirstPage then
				curFeed.SwitchFailed:set(true)
			end
		end

		-- self.States.Loading:set(false)
		resolve()
	end)

	table.insert(self.LoadingPromises, prom)
	return prom
end

function OutfitFeed:RenderOutfit(id: string, backendOutfit: FeedUtils.BackendOutfit?): Frame?
	if not id then
		warn("No ID passed to create new feed.")
		return
	end

	local feedLists = self.OutfitsCache
	local feedData = feedLists[id]
	local feedInstance

	if not feedData then
		if not backendOutfit then
			local success, data = OnGetFeed:InvokeServer(id)
			if success then
				backendOutfit = data
			end
		end

		if backendOutfit then
			local outfit = FeedUtils.GetOutfitFromServerData(backendOutfit)
			local ids = {}
			for _, item in pairs(outfit.Items) do
				if item.AssetId > 0 and not InventoryHandler.ItemDetailsCache[item.AssetId] then
					table.insert(ids, item.AssetId)
				end
			end

			if #ids > 0 then
				Utils.pprint(string.format("%s missing items", #ids))
			end

			local batchItemData, success = Utils.callWithRetry(function()
				if #ids > 0 then
					return AvatarEditorService:GetBatchItemDetails(ids, 1)
				else
					return {}
				end
			end, 3)

			if not success then
				return
			end

			task.wait()

			for _, rawData in pairs(batchItemData) do
				InventoryHandler.ItemDetailsCache[rawData.Id] = rawData
			end

			local allRawData = {}
			for _, item in pairs(outfit.Items) do
				if InventoryHandler.ItemDetailsCache[item.AssetId] then
					table.insert(allRawData, InventoryHandler.ItemDetailsCache[item.AssetId])
				end
			end

			local humDesc, items, itemFrames = self:ProcessOutfit(outfit, allRawData)
			if humDesc.Pants == 0 then
				humDesc.Pants = DEFAULT_CLOTHES.Pants

				if humDesc.Shirt == 0 then
					humDesc.Shirt = DEFAULT_CLOTHES.Shirt
				end
			end

			local outfitData = {
				Likes = Fusion.Value(outfit.Likes or 0),
				Boosts = Fusion.Value(outfit.Boosts or 0),
				TryOns = Fusion.Value(outfit.TryOns or 0),
				Impressions = Fusion.Value(outfit.Impressions or 0),
				OwnLike = Fusion.Value(outfit.OwnLike or false),
				CreatedAt = Fusion.Value(outfit.CreatedAt),
				Name = Fusion.Value(outfit.Name),
				CreatorId = Fusion.Value(outfit.CreatorId),
				-- CreatorDisplayName = Fusion.Value(Players:GetNameFromUserIdAsync(outfit.CreatorId) or "N/A"),

				AlreadySeen = Fusion.Value(false),
				AlreadyTriedOn = Fusion.Value(false)
			}

			feedInstance = OutfitFrame {
				Outfit = outfit,
				Id = id,
				CreatorId = outfit.CreatorId,
				SelectedId = self.SelectedOutfit,
				Items = items,
				Enabled = ENABLED,
				Likes = outfitData.Likes,
				Boosts = outfitData.Boosts,
				TryOns = outfitData.TryOns,
				Impressions = outfitData.Impressions,
				OwnLike = outfitData.OwnLike,
				HumanoidDescription = humDesc,
				ReadOnly = not ENABLED,
				OnImpression = function()
					OnReportImpressionRemote:InvokeServer(id)
				end,
				OnTry = function()
					self.Controllers.AvatarPreviewController:ApplyOutfit(items, humDesc)

					if OnReportTryOnRemote:InvokeServer(id) then
						self.OutfitsCache[id].TryOns:set(self.OutfitsCache[id].TryOns:get() + 1)
					end
				end,
				OnLike = function(isLiked)
					local action = isLiked and "like" or "unlike"
					local success, result = OnFeedAction:InvokeServer(outfit.GUID, action)
					Utils.pprint(
						string.format(
							"%s %s! Result: %s",
							string.upper(action),
							success and "successful" or "unsuccessful",
							result or ""
						)
					)

					self.FeedsById.liked.ShouldRefresh:set(true)

					return success
				end,
				OnBoost = function()
					local success, result = OnBoostFeed:InvokeServer(outfit.GUID)
					Utils.pprint(string.format("BOOST Prompt %s! Result: %s", success and "successful" or "unsuccessful", result))
				end,
				AvatarPreviewController = self.Controllers.AvatarPreviewController,

				AlreadySeen = outfitData.AlreadySeen,
				AlreadyTriedOn = outfitData.AlreadyTriedOn
			}

			outfitData.Frame = feedInstance
			self.OutfitsCache[outfit.GUID] = outfitData
		end
	else
		feedInstance = feedData.Frame
	end
	return feedInstance
end

function OutfitFeed:ProcessOutfit(
	outfit: FeedUtils.Outfit,
	rawItems: { any }
): (HumanoidDescription, Outfit, { TextButton })
	local humDesc = Instance.new("HumanoidDescription")
	local updatedSpecifications = humDesc:GetAccessories(false) :: any

	local items: Outfit = {}
	local itemFrames = {}

	for i, item in pairs(rawItems) do
		local humanoidItem = AvatarHandler.BuildItemData(item, true)
		if humanoidItem then
			local assetType = humanoidItem.AssetType :: any
			if assetType == "Shirt" then
				humDesc.Shirt = humanoidItem.AssetId
			elseif assetType == "TShirt" then
				humDesc.GraphicTShirt = humanoidItem.AssetId
			elseif assetType == "Pants" then
				humDesc.Pants = humanoidItem.AssetId
			elseif assetType == "Torso" then
				humDesc.Torso = humanoidItem.AssetId
			elseif assetType == "Head" or assetType == "DynamicHead" or assetType == 79 then
				humDesc.Head = humanoidItem.AssetId
			elseif assetType == "RightArm" then
				humDesc.RightArm = humanoidItem.AssetId
			elseif assetType == "LeftArm" then
				humDesc.LeftArm = humanoidItem.AssetId
			elseif assetType == "RightLeg" then
				humDesc.RightLeg = humanoidItem.AssetId
			elseif assetType == "LeftLeg" then
				humDesc.LeftLeg = humanoidItem.AssetId
			else
				local newIndividualSpecification = {
					AccessoryType = humanoidItem.AssetType,
					AssetId = humanoidItem.AssetId,
					Order = i,
				}
				updatedSpecifications[#updatedSpecifications + 1] = newIndividualSpecification
				humDesc:SetAccessories(updatedSpecifications, true)
			end
		end

		local outfitItem = AvatarHandler.BuildItemData(item, false)
		if outfitItem then
			outfitItem.Order = i
			items[outfitItem.AssetId] = outfitItem
		end
	end

	humDesc.HeadColor = outfit.Colors.Head and Color3.fromHex(outfit.Colors.Head) or Color3.new()
	humDesc.TorsoColor = outfit.Colors.Torso and Color3.fromHex(outfit.Colors.Torso) or Color3.new()
	humDesc.LeftArmColor = outfit.Colors.LeftArm and Color3.fromHex(outfit.Colors.LeftArm) or Color3.new()
	humDesc.LeftLegColor = outfit.Colors.LeftLeg and Color3.fromHex(outfit.Colors.LeftLeg) or Color3.new()
	humDesc.RightArmColor = outfit.Colors.RightArm and Color3.fromHex(outfit.Colors.RightArm) or Color3.new()
	humDesc.RightLegColor = outfit.Colors.RightLeg and Color3.fromHex(outfit.Colors.RightLeg) or Color3.new()

	items.BodyColors = {
		["HeadColor"] = humDesc.HeadColor,
		["TorsoColor"] = humDesc.TorsoColor,
		["LeftArmColor"] = humDesc.LeftArmColor,
		["LeftLegColor"] = humDesc.LeftLegColor,
		["RightArmColor"] = humDesc.RightArmColor,
		["RightLegColor"] = humDesc.RightLegColor,
	}

	return humDesc, items, itemFrames
end

function OutfitFeed:SearchFor(query)
	local isFirstQuery = false
	if query and #query > 0 then
		local prevKeywords = self.States.Query:get().keywords or ""
		isFirstQuery = #prevKeywords == 0
	end

	self.States.Query:set({
		keywords = query
	})

	self:MarkAllForRefresh(function(feed)
		return feed.Searchable
	end)

	if isFirstQuery then
		self.States.CurrentFeedId:set("relevance")
		self:SwitchToFeed("relevance", true)
	else
		self:SwitchToFeed(self.States.CurrentFeedId:get(), true)
	end
end

return OutfitFeed
