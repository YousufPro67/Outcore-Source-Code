local AvatarEditorService = game:GetService("AvatarEditorService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local BloxbizSDK = script.Parent.Parent.Parent

local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")
local OnSearchItemsRequest, CatalogCategoryOpenedEvent

local CategoriesLibrary = require(script.Parent.Parent.Categories)

local Player = Players.LocalPlayer

local Classes = script.Parent.Parent.Classes
local AvatarHandler = require(Classes.AvatarHandler)

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local SearchFilters = require(UtilsStorage:WaitForChild("SearchFilters"))
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local New = Fusion.New
local Value = Fusion.Value
local Computed = Fusion.Computed

local Observer = Fusion.Observer

local Components = script.Parent.Parent.Components
local Sort = require(Components.ContentFrame.Sort)
local SearchContext = require(Components.SearchContext)
local ErrorFrame = require(Components.EmptyState)
local QuickSortTabs = require(script.QuickSortTab)

local BundleItemsView = require(Components.Pages.BundleItemsView)
local CatalogItem = require(Components.CatalogItem)
local Banner = require(script.Banner)

local ContentFrame = Components.ContentFrame
local Frame = require(ContentFrame.Frame)

local CategoryLoader = require(script.CategoryLoader)

type Category = { Instance: Frame, Page: Fusion.Value<number>, Children: Fusion.Value<{ Frame }> }
type SourceBundleInfo = { AssetId: number, Price: number }
type CategoryItems = CategoryLoader.ItemData & CategoryLoader.BundleData
type AllowedTypes = { Categories: { number }?, Subcategories: { number }?, AssetTypes: { number }? }

local SORTS = {
	{ Text = "Relevance", SortType = "Relevance" },
	{ Text = "New", SortType = "Updated" },
	{ Text = "Favs", SortType = "Favorited" },
	{ Text = "Sales", SortType = "Sales" },
	{ Text = "Cheap", SortType = "PriceAsc" },
}

local SORTS_BY_ID = {}
for _, sort in ipairs(SORTS) do
	SORTS_BY_ID[sort.SortType] = sort
end


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
}

local CategoriesCache: { [string | number]: CategoryLoader.Category } = {}
local AvatarItemsCache = {}

local allowedExternalLinks = Value({})
task.spawn(function()
    local PolicyService = game:GetService("PolicyService")
    local Players = game:GetService("Players")

    local policy = PolicyService:GetPolicyInfoForPlayerAsync(Players.LocalPlayer)
    allowedExternalLinks:set(Utils.map(policy.AllowedExternalLinkReferences, function (name)
		if name:lower() == "twitter" then
			return "x"
		end
		return name:lower()
	end))
end)


local function GetItemDataTableFromPage(
	page: CatalogPages,
	isBundle: boolean
): { AvatarHandler.ItemData | AvatarHandler.BundleData }
	local itemDataTable = {}
	local currentPage = page:GetCurrentPage()

	for i = 1, #currentPage do
		local item = currentPage[i]
		if typeof(item) == "table" then
			local itemData = isBundle and AvatarHandler.BuildBundleData(item) or AvatarHandler.BuildItemData(item)

			table.insert(itemDataTable, itemData)
		end
	end

	return itemDataTable, page.IsFinished
end

local function SearchFromAssetId(keyword: string): { CategoryItems }
	local t = {}

	local assetId = keyword:match("%d+")
	if assetId then
		local item = AvatarHandler.GetItemDataTable(assetId, 2)
		if not item or not item.AssetType then
			return t
		end

		if not AvatarHandler.IsValidAssetType(item.AssetType) then
			return t
		end

		table.insert(t, item)
		return t
	end

	return t
end

local function GetCategoryIndex(subcategoryKey: string | number): number | string
	local index = subcategoryKey

	for categoryIndex: number, category: CategoriesLibrary.Category in pairs(CategoriesLibrary) do
		if category.name == subcategoryKey then
			index = categoryIndex
			break
		end
	end

	return index
end

local function GetSubcategoryIndex(category: string | number): (string | number)?
	return CategoriesLibrary[category] and CategoriesLibrary[category].name or nil
end

local function GetCategory(category: string | number): CategoryLoader.Category?
	local categoryItems = CategoriesCache[category]
	if not categoryItems then
		local newIndex = GetSubcategoryIndex(category)
		if newIndex then
			categoryItems = CategoriesCache[newIndex]
		end
	end

	return categoryItems
end

local Category = {}
Category.__index = Category

function Category.new(coreContainer: Frame, loadingFrame: Frame): ()
	local self = setmetatable({} :: any, Category)
	self.Container = coreContainer
	self.Enabled = false

	self.Observers = {}
	self.GuiObjects = {
		LoadingFrame = loadingFrame,
	}
	self.Debounces = {}
	self.CurrentSort = Fusion.Value("Relevance")
	self.CurrentCategoryId = Fusion.Value(nil)
	self.CurrentCategoryName = Fusion.Computed(function()
		local catId = self.CurrentCategoryId:get()

		if catId == "feed" then
			return "Outfits"
		elseif catId == "shops" then
			return "Shops"
		elseif catId then
			return CategoriesLibrary[catId].name
		else
			return "Search"
		end
	end)
	self.SearchFailed = Fusion.Value(false)
	self.NoResults = Fusion.Value(false)
	self.Loading = Fusion.Value(false)
	Fusion.Observer(self.Loading):onChange(function()
		loadingFrame.Visible = self.Loading:get()
	end)

	self.ViewingBundleId = Fusion.Value(nil)

	self.SelectedItemId = Fusion.Value(nil)

	self.OpenCategory = nil

	return self
end

function Category:Init(controllers: { [string]: { any } })
	self.Controllers = controllers
	
	local isEnabled = self.Controllers.NavigationController:GetEnabledComputed("CategoryController")

	-- Initializing library
	local GetCatalogCategories = BloxbizRemotes:WaitForChild("GetCatalogCategories") :: RemoteFunction
	CategoriesLibrary = GetCatalogCategories:InvokeServer()

	for _, category in pairs(CategoriesLibrary) do
		CategoriesCache[category.name] = CategoryLoader.new(category)
	end

	local categoryChangeObserver = Fusion.Observer(self.CurrentCategoryName)

	table.insert(
		self.Observers,
		categoryChangeObserver:onChange(function()
			self.ViewingBundleId:set(nil)
			local id = self.CurrentCategoryId:get()

			if id and id ~= "feed" and id ~= "shops" then
				self:LoadCategory(id)
				self.CurrentSort:set("Relevance")

				local query = self.Controllers.TopBarController.SearchQuery:get()
				if query and #query > 0 then
					self:SearchFor(query)
				end
			end
		end)
	)
	-- categoryButtonData.Instance.Parent = self.Container

	-- Category Frame --

	local mainFrameProps: Frame.Props = {
		Name = "Category Frame",
		UtilitiesHolder = {
		},
		SkipListLayout = false,
	}

	local mainFrame = Frame(mainFrameProps)
	local filterFrame = mainFrame:WaitForChild("UtilitiesHolder")
	local filterFrameHolder = filterFrame:WaitForChild("Holder")
	local scrollingFrame = mainFrame:WaitForChild("ScrollingFrame")
	local itemFrame = scrollingFrame:WaitForChild("ItemFrame")

	self.GuiObjects.Frame, self.GuiObjects.ScrollingFrame, self.GuiObjects.ItemFrame, self.GuiObjects.FilterFrame =
		mainFrame, scrollingFrame, itemFrame, filterFrame
	local frameContainer = self.Container:WaitForChild("FrameContainer")

	mainFrame.Parent = frameContainer
	scrollingFrame.LayoutOrder = 2

	-- banners

	New "UIListLayout" {
		Parent = scrollingFrame,
		Padding = UDim.new(0.016, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalFlex = Enum.UIFlexAlignment.Fill
	}

	Fusion.Hydrate (scrollingFrame) {
		[Fusion.Children] = {
			Computed(function()
				local categoryId = self.CurrentCategoryId:get()
				local loading = self.Loading:get()
				local playerAllowedExternalLinks = allowedExternalLinks:get()

				local category = self.Controllers.TopBarController.categories[categoryId]

				if category and category.display_banner and not loading then
					local externalLinks = Utils.map(category.banner_external_sites or {}, function (name)
						if name:lower() == "twitter" then
							return "x"
						end
						return name:lower()
					end)
					for _, platformName in ipairs(externalLinks) do
						if not table.find(playerAllowedExternalLinks, platformName) then
							return
						end
					end

					return Banner {
						Parent = scrollingFrame,
						LayoutOrder = -1,
						HeaderText = category.banner_header,
						SubheaderText = category.banner_subheader,
						BackgroundColorHex = category.banner_bg_color,
						BackgroundImageId = category.banner_asset_id,
						TextColorHex = category.banner_text_color
					}
				end
			end, Fusion.cleanup),
			itemFrame
		}
	}
	

	-- error state for empty search results --
	
	ErrorFrame({
		Parent = scrollingFrame,
		LayoutOrder = 1,
		Size = UDim2.fromScale(1, 0.7),
		BackgroundTransparency = 1,

		Text = Fusion.Computed(function()
			if self.SearchFailed:get() then
				return string.format('No results for "%s"', self.Controllers.TopBarController.SearchQuery:get() or "")
			else
				return "There's no items to show."
			end
		end),
		ButtonText = "Clear Search",
		ButtonEnabled = self.SearchFailed,

		Visible = Fusion.Computed(function()
			return self.SearchFailed:get() or self.NoResults:get()
		end),
		Callback = function()
			if not self.SearchFailed:get() then
				return
			end

			self.Controllers.TopBarController:ResetSearchBar()

			if not self.CurrentCategoryName:get() then
				self.Controllers.NavigationController:SwitchTo("Featured")
			else
				self:SearchFor(nil)
			end
		end,
	})

	-- item loading --

	local loadDebounce = false

	table.insert(
		self.Observers,
		scrollingFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			if self.CurrentCategory then
				local passedThreshold = math.round(scrollingFrame.CanvasPosition.Y)
					>= math.round(scrollingFrame.AbsoluteCanvasSize.Y - scrollingFrame.AbsoluteWindowSize.Y) * 0.7
				if passedThreshold then
					if not loadDebounce then
						loadDebounce = true
						self.CurrentCategory.Page += 1

						self:LoadItems()
						loadDebounce = nil
					end
				end
			end
		end)
	)

	-- search context --

	SearchContext({
		Parent = filterFrameHolder,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromScale(0.5, 0.6),
		Visible = self.Controllers.TopBarController.ShowSearchContext,
		SearchTerm = self.Controllers.TopBarController.SearchQuery,
		SearchingIn = self.CurrentCategoryName,
		OnSearchAll = function()
			self.Controllers.TopBarController:SwitchToSearchAll()
		end
	})

	-- Filter Frame
	local sortButtons = Utils.map(SORTS, function(sort)
		sort.Id = sort.SortType
		sort.Hidden = false
		sort.Data = sort.SortType

		return sort
	end)

	self.CurrentSort:set("Relevance")
	self.SortTabs = Sort({
		Parent = filterFrameHolder,
		Selected = self.CurrentSort,
		Size = UDim2.fromScale(0.45, 1),
		Cooldown = false,
		Buttons = sortButtons,
		Alignment = "Left"
	})

	local quickSortObs = Observer(self.CurrentSort)
	table.insert(
		self.Observers,
		quickSortObs:onChange(function()
			task.spawn(function()
				if not self.CurrentCategory then
					return
				end
				
				local currentQuickSort: QuickSortTabs.QuickSortValue = self.CurrentSort:get()
				self:LoadSorting(SORTS_BY_ID[currentQuickSort].SortType)
			end)
		end)
	)

	-- Bundle items view page

	Fusion.New "Frame" {
		Name = "BundleItemsView",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = mainFrame.Parent,
		Visible = Fusion.Computed(function()
			return isEnabled:get() and self.ViewingBundleId:get() ~= nil
		end),

		[Fusion.Children] = {
			Fusion.Computed(function()
				if isEnabled:get() and self.ViewingBundleId:get() ~= nil then
					return BundleItemsView({
						BundleId = self.ViewingBundleId,
						AvatarPreviewController = self.Controllers.AvatarPreviewController,
						CurrentCategory = self.CurrentCategoryName,
						HeaderHeight = self.Controllers.TopBarController.TopBarHeight,
						OnBack = function()
							self.ViewingBundleId:set(nil)
						end
					})
				end
			end, Fusion.cleanup)
		}
	}

	local isEnabled = self.Controllers.NavigationController:GetEnabledComputed("CategoryController")
	Fusion.Hydrate(mainFrame)({
		Visible = Fusion.Computed(function()
			local enabled = isEnabled:get()
			return enabled and (self.ViewingBundleId:get() == nil)
		end)
	})

	-- events

	local playerGui: PlayerGui = Player:WaitForChild("PlayerGui")
	playerGui:GetPropertyChangedSignal("CurrentScreenOrientation"):Connect(function()
		self.CurrentSort:set(self.CurrentSort:get(), true)
	end)

	OnSearchItemsRequest = BloxbizRemotes:WaitForChild("CatalogOnSearchItemsRequest") :: RemoteFunction
	CatalogCategoryOpenedEvent = BloxbizRemotes:WaitForChild("CatalogCategoryOpenedEvent") :: RemoteEvent
end


function Category:GetCategoryId(name)
	if name:lower() == "feed" then
		return "feed"
	end

	if name:lower() == "shops" then
		return "shops"
	end

	return Utils.find(CategoriesLibrary, function (cat)
		return cat.name:lower() == name:lower()
	end)
end

function Category:SwitchToCategoryOrSearch(name)
	local categoryId = self:GetCategoryId(name)

	if categoryId then
		self:SwitchToCategoryId(categoryId)
	else
		task.spawn(function()
			self.Controllers.TopBarController:SearchFor(name)
		end)
	end
end

function Category:Reset()
	self:SwitchToCategoryId(self.CurrentCategoryId.Default)
	self.Resetting = true
end

function Category:Enable()
	-- error()
	self.Enabled = true
	self.GuiObjects.Frame.Visible = true

	for _, controller in pairs(self.Controllers) do
		if controller ~= self then
			if controller.Disable then
				controller:Disable()
			end
		end
	end
end

function Category:Disable(skipDeselect: boolean?)
	self.Enabled = false
	self.GuiObjects.Frame.Visible = false
	self.ViewingBundleId:set(nil)
	self.SelectedItemId:set(nil)

	if not skipDeselect then
		self:Deselect()
	end
end

function Category:Deselect()
	self.CurrentCategoryId:set(nil)
end

local prevCategoryName

function Category:LoadCategory(categoryId: string | number, keyword: string?, allowedTypes: AllowedTypes?): ()
	categoryId = tonumber(categoryId)

	self.Loading:set(true)

	self:Enable()
	self:ClearItemFrame()

	local categoryLoader, categoryName

	if keyword and #keyword == 0 then
		keyword = nil
	end

	if keyword and keyword ~= "KEY_INCATEGORY" then
		categoryName = "Search"

		if not allowedTypes then
			self:Deselect()
		end
	else
		-- categoryId = GetCategoryIndex(categoryIdx)
		-- if not CategoriesLibrary[categoryId] then
		-- 	return
		-- end

		local category = CategoriesLibrary[categoryId]
		if not category then
			error(string.format("Category %s is not found.", tostring(categoryId)), 2)
			return
		end

		categoryName = category.name

		if not self.Resetting then
			if self.Controllers and self.Controllers.TopBarController then
				self.Controllers.OutfitFeedController:Disable()
			end
		else
			self.Resetting = false
		end

		categoryLoader = GetCategory(categoryId)

		if not categoryLoader then
			error(string.format("Category loader for %s is not found.", tostring(categoryId)), 2)
		end
	end

	self.CurrentCategory = {
		Id = tonumber(categoryId) or 0,
		Name = categoryId,

		Page = 1,
		SortType = "Relevance",
		Keyword = keyword,
		AllowedTypes = allowedTypes,
		Loader = categoryLoader,
		SearchPages = {},

		Content = {},
	}

	if categoryName ~= prevCategoryName then
		CatalogCategoryOpenedEvent:FireServer(categoryName)
		prevCategoryName = categoryName
		Utils.pprint("Category: " .. categoryName)
	end

	self:LoadItems()

	self.Loading:set(false)
end

function Category:SearchFor(keyword)
	self.ViewingBundleId:set(nil)

	if keyword and #keyword > 0 then
		self:LoadCategory(self.CurrentCategory.Id, "KEY_INCATEGORY")

		local categoryData = CategoriesLibrary[self.CurrentCategory.Id]
		local allowed = {
			Categories = {},
			Subcategories = {},
			AssetTypes = {},
		}
		local query = categoryData.query

		if query then
			if query.AssetTypeId then
				table.insert(allowed.AssetTypes, query.AssetTypeId)
			end

			if query.Subcategory then
				table.insert(allowed.Subcategories, query.Subcategory)
			end

			if query.Category then
				table.insert(allowed.Categories, query.Category)
			end
		end

		self:LoadCategory(self.CurrentCategory.Name, keyword, allowed)
	else
		self:LoadCategory(self.CurrentCategory.Name)
		self.CurrentSort:set("Relevance")
	end
end

function Category:LoadSorting(sortType: number)
	self.Loading:set(true)

	self.CurrentCategory.SortType = sortType
	self.CurrentCategory.Page = 1

	self:ClearItemFrame()
	self:LoadItems()

	self.Loading:set(false)
end

function Category:LoadItems()
	self.SearchFailed:set(false)
	self.NoResults:set(false)

	local itemDataTable: { CategoryItems } = {}
	local data = self.CurrentCategory

	local keyword = data.Keyword
	local creatorFilter
	keyword, creatorFilter = SearchFilters.getCreatorFilter(keyword)

	if (keyword and keyword ~= "KEY_INCATEGORY") and (not data.AllowedTypes) and not creatorFilter then
		if self.CurrentCategory.Page == 1 then
			itemDataTable = SearchFromAssetId(keyword)

			if #itemDataTable == 0 then
				local sortTypeEnum = SETTINGS.SortType.Editor[data.SortType]

				local params = CatalogSearchParams.new()
				params.SearchKeyword = keyword
				params.SortType = sortTypeEnum
				params.IncludeOffSale = true
				local success, assetPages = pcall(function()
					return AvatarEditorService:SearchCatalog(params)
				end)

				if not success then
					self.SearchFailed:set(true)
					return
				end

				params.BundleTypes = {
					Enum.BundleType.Animations,
					Enum.BundleType.BodyParts,
				}

				local bundlePages = AvatarEditorService:SearchCatalog(params)

				local items, itemsFinished = GetItemDataTableFromPage(assetPages, false)
				local bundles, bundleFinished = GetItemDataTableFromPage(bundlePages, true)

				self.SearchPages = {
					AssetPages = not itemsFinished and assetPages or nil,
					BundlePages = not bundleFinished and bundlePages or nil,
				}

				itemDataTable = { table.unpack(bundles) }
				for _, item in pairs(items) do
					table.insert(itemDataTable, item)
				end
			end
		else
			for _, page: CatalogPages in pairs(self.SearchPages) do
				if not page.IsFinished then
					page:AdvanceToNextPageAsync()
				end
			end

			itemDataTable = {}
			if self.SearchPages.BundlePages then
				local items, finished = GetItemDataTableFromPage(self.SearchPages.BundlePages, true)
				if finished then
					self.SearchPages.BundlePages = nil
				end

				itemDataTable = { table.unpack(items) }
			end

			if self.SearchPages.AssetPages then
				local items, itemsFinished = GetItemDataTableFromPage(self.SearchPages.AssetPages, false)
				if itemsFinished then
					self.SearchPages.AssetPages = nil
				end

				for _, item in pairs(items) do
					table.insert(itemDataTable, item)
				end
			end
		end
	else
		local sortTypeValue = SETTINGS.SortType.Proxy[data.SortType]

		if data.Loader then
			itemDataTable = data.Loader:GetItems(data.Page, sortTypeValue)
		else
			itemDataTable = OnSearchItemsRequest:InvokeServer({
				Page = data.Page,
				SortType = sortTypeValue,
				AllowedTypes = data.AllowedTypes,
				Keyword = keyword,
				CreatorFilter = creatorFilter
			})
		end
	end

	if type(itemDataTable) == "string" and itemDataTable == "No more pages" then
		Utils.pprint(itemDataTable)
		return
	else
		if not itemDataTable or #itemDataTable == 0 then
			if self.CurrentCategory.Page == 1 then
				if data.Keyword then
					-- no search results
					self.SearchFailed:set(true)
				else
					-- TODO: no results message
					self.NoResults:set(true)
				end
			end

			return
		end

		local avatarController = self.Controllers.AvatarPreviewController

		if data.Page == 1 then
			self:ClearItemFrame()
		end

		for _, itemData in pairs(itemDataTable) do
			local existingItem = CatalogItem {
				Parent = self.GuiObjects.ItemFrame,

				AvatarPreviewController = self.Controllers.AvatarPreviewController,
				ItemData = itemData,
				CategoryName = self.CurrentCategoryName,
				SourceBundleInfo = data.Source,
				SelectedId = self.SelectedItemId,
				OnTry = function()
					local _itemData = itemData

					if itemData.BundleType == 4 then
						-- dynamic head bundle. we should only try on the dynamic head, trying to the bundle will erase the other items
						-- the player is wearing

						local success, details = pcall(function()
							return AvatarEditorService:GetItemDetails(itemData.BundleId, Enum.AvatarItemType.Bundle)
						end)
						if success and details and details.BundledItems then
							local headInfo = Utils.search(details.BundledItems, function (item)
								return item.Type == "Asset" and item.Name:match("Head")
							end)
							if headInfo then
								local headDetails = AvatarEditorService:GetItemDetails(headInfo.Id, Enum.AvatarItemType.Asset)
								_itemData = AvatarHandler.BuildItemData(headDetails)
							end
						end
					end

					avatarController.AddChange(avatarController, _itemData, self.CurrentCategoryName:get())
				end,
				OnSeeItems = function(bundleId)
					Utils.pprint("View bundle", bundleId)
					self.ViewingBundleId:set(bundleId)
				end
			}

			if existingItem then
				table.insert(self.CurrentCategory.Content, existingItem)
			end
		end
	end
end

function Category:ClearItemFrame()
	local frame: ScrollingFrame = self.GuiObjects.ScrollingFrame
	if frame then
		frame.Visible = false
		frame.CanvasPosition = Vector2.new(0, 0)

		local currentCategory = self.CurrentCategory
		if currentCategory then
			for _, child in pairs(currentCategory.Content) do
				child:Destroy()
			end

			if currentCategory.Selected then
				currentCategory.Selected:set(false)
				currentCategory.Selected = nil
			end
		end

		frame.Visible = true
	end
end

function Category:GetCurrentCategory()
	return self.CurrentCategory
end

function Category:GetAvatarItemCache(id: number)
	return AvatarItemsCache[id]
end

function Category:OnOpen()
	-- if self.OpenCategory then
	-- 	self:SwitchToCategoryOrSearch(self.OpenCategory)
	-- 	self.OpenCategory = nil
	-- else
	-- 	self:Reset()
	-- end
end

return Category
