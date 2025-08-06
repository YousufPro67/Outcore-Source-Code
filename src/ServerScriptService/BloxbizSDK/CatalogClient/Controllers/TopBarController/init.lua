local ProximityPromptService = game:GetService("ProximityPromptService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BloxbizSDK = script.Parent.Parent.Parent
local ConfigReader = require(BloxbizSDK:WaitForChild("ConfigReader"))
local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")

local SearchBar = require(script.Parent.Parent.Components.SearchBar)
local TopBarFrame = require(script.TopBarFrame)

local CategoryButtons = require(script.CategoryButtons)
local Button = require(script.CategoryButtons.Button)

local Value = Fusion.Value
local Computed = Fusion.Computed

local TopBar = {}
TopBar.__index = TopBar

function TopBar.new(coreContainer: Frame)
	local self = setmetatable({}, TopBar)

	self.Container = coreContainer
	self.Observers = {}
	self.GuiObjects = {}
	self.Debounces = {}

	self.TopBarHeight = Value(0)
	self.TopBarY = Value(0)

	-- search bar

	self.SearchQuery = Value("")
	self.SearchBoxText = Value("")
	self._OnSearch = Instance.new("BindableEvent")
	self.OnSearch = self._OnSearch.Event
	self.SearchInCategory = Value(true)

	self.ShowSearchContext = Fusion.Computed(function()
		local query = self.SearchQuery:get()
		local isLocalSearch = self.SearchInCategory:get()
		return isLocalSearch and query and #query > 0
	end)

	self.ScreenSize = Value(Vector2.zero)
	Fusion.Hydrate(workspace.Camera, {
		[Fusion.Out "ViewportSize"] = self.ScreenSize
	})

	-- categories

	self.CurrentCategory = Value()
	self.DefaultCategory = Value()
	if ConfigReader:read("CatalogOutfitFeedEnabled") then
		self.DefaultCategory:set("feed")
	else
		self.DefaultCategory:set("shop")
		--self.DefaultCategory:set(1)
	end

	return self
end

function TopBar:Init(controllers: { [string]: { any } })
	self.Controllers = controllers

	local GetCatalogCategories = BloxbizRemotes:WaitForChild("GetCatalogCategories") :: RemoteFunction
	local CatalogTermSearchedEvent = BloxbizRemotes:WaitForChild("CatalogTermSearchedEvent")

	local categories = GetCatalogCategories:InvokeServer()
	self.categories = categories

	local searchBoxSize = Fusion.Spring(Fusion.Computed(function()
		local sbText = self.SearchBoxText:get() or ""
		local query = self.SearchQuery:get() or ""

		if #sbText + #query == 0 then
			return UDim2.new(0.15, 0, 1, 0)
		else
			return UDim2.new(0.3, 0, 1, 0)
		end
	end), 25)

	local padding = Fusion.Computed(function()
		return self.TopBarHeight:get() / 8 + 1
	end)

	local featuredButtonSize = Value(Vector2.zero)

	local categoriesSize = Fusion.Computed(function()
		return UDim2.new(1 - searchBoxSize:get().X.Scale, -padding:get() * 2 - featuredButtonSize:get().X, 1, 0)
	end)

	local topBar = TopBarFrame({
		Parent = self.Container,
		Padding = padding,

		[Fusion.Children] = {
			-- featured categories button
			Button({
				LayoutOrder = 1,
				IsSelected = self.Controllers.NavigationController:GetEnabledComputed("Featured"),
				OnClick = function()
					self.Controllers.NavigationController:SwitchTo("Featured")
				end,
				Icon = "rbxassetid://15120083610",
				SizeRef = featuredButtonSize
			}),

			SearchBar({
				LayoutOrder = 2,
				Size = searchBoxSize,
				Position = UDim2.fromScale(0, 0),
				Query = self.SearchQuery,
				PlaceholderText = "Search",
				SearchBoxText = self.SearchBoxText,
				OnSearch = function(query)
					local enabledControllers = self.Controllers.NavigationController.Enabled:get()
					if not (enabledControllers.OutfitFeedController or enabledControllers.CategoryController) then
						self.SearchInCategory:set(false)
					end

					if self.SearchInCategory:get() then
						if query and #query == 0 then
							query = nil
						end

						if self.CurrentCategory:get() == "feed" then
							self.Controllers.OutfitFeedController:SearchFor(query)
						elseif self.CurrentCategory:get() == "shops" then
							print("Search in shops!")
						else
							if query then
								CatalogTermSearchedEvent:FireServer(query)
							end
							self.Controllers.CategoryController:SearchFor(query)
						end
					else
						if query and #query > 0 then
							CatalogTermSearchedEvent:FireServer(query)
							self:SearchAllItems(query)
						else
							self.SearchInCategory:set(true)
							self.Controllers.NavigationController:SwitchTo("Featured")
						end
					end
				end
			}),

			CategoryButtons({
				LayoutOrder = 3,
				Categories = categories,
				Size = categoriesSize,
				CurrentCategory = self.CurrentCategory,
				OnChange = function(categoryId)
					self:OnCategoryClick(categoryId)
				end
			})
		}
	})

	self.GuiObjects.Frame = topBar
	self.TopBarHeight:set(topBar.AbsoluteSize.Y)
	self.TopBarY:set(topBar.AbsolutePosition.Y)
	topBar:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self.TopBarHeight:set(topBar.AbsoluteSize.Y)
	end)
	topBar:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		self.TopBarY:set(topBar.AbsolutePosition.Y)
	end)
end

function TopBar:SwitchToSearchAll()
	self.SearchInCategory:set(false)
	self:SearchAllItems(self.SearchQuery:get())
end

function TopBar:OnCategoryClick(categoryId)
	self.CurrentCategory:set(categoryId)
	self.SearchInCategory:set(true)

	if categoryId == "feed" then
		self.Controllers.NavigationController:SwitchTo("OutfitFeed")
	elseif categoryId == "shops" then
		self.Controllers.NavigationController:SwitchTo("ShopFeed")
	else
		self.Controllers.CategoryController.CurrentCategoryId:set(categoryId, true)
		self.Controllers.NavigationController:SwitchTo("CategoryController")
	end
end

function TopBar:SearchAllItems(keyword)
	if keyword and #keyword == 0 then
		keyword = nil
	end

	if keyword then
		self.CurrentCategory:set(nil)
		self.Controllers.NavigationController:SwitchTo("CategoryController")
		self.Controllers.CategoryController:LoadCategory("Search", keyword)
	else
		self:OnCategoryClick(self.DefaultCategory)
	end
end

function TopBar:Reset()
	self:ResetSearchBar()
	self.CurrentCategory:set(nil)
end

function TopBar:ResetSearchBar()
	self.SearchQuery:set(nil)
end

function TopBar:SearchFor(query: string)
	self.SearchInCategory:set(false)
	self.SearchQuery:set(query)
	self:SearchAllItems(query)
end

function TopBar:GetButton(name: string)
	return self.GuiObjects.Buttons[name]
end

function TopBar:SwitchToCategoryOrSearch(nameOrSearchTerm)
	if nameOrSearchTerm:lower() == "outfits" or nameOrSearchTerm:lower() == "feed" then
		self:OnCategoryClick("feed")
		return
	end

	if nameOrSearchTerm:lower() == "shops" then
		self:OnCategoryClick("shops")
		return
	end

	local categoryId = self.Controllers.CategoryController:GetCategoryId(nameOrSearchTerm)

	if categoryId then
		self:OnCategoryClick(categoryId)
	else
		self:SearchFor(nameOrSearchTerm)
	end
end

function TopBar:OnOpen()
	self.SearchQuery:set(nil)

	task.spawn(function()
		if self.OpenCategory then
			local nameOrSearchTerm = self.OpenCategory
			self.OpenCategory = nil

			self:SwitchToCategoryOrSearch(nameOrSearchTerm)
		else
			if self.CurrentCategory:get() then
				self:OnCategoryClick(self.CurrentCategory:get())
			else
				self.Controllers.NavigationController:SwitchTo("Featured")
			end
		end
	end)
end

return TopBar
