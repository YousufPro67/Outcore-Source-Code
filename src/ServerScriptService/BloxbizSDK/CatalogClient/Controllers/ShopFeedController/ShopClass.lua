local GroupService = game:GetService("GroupService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Controllers = script.Parent.Parent
local CatalogClient = Controllers.Parent
local BloxbizSDK = CatalogClient.Parent

local UtilsStorage = BloxbizSDK:WaitForChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local Promise = require(UtilsStorage:WaitForChild("Promise"))

local AvatarHandler = require(script.Parent.Parent.Parent.Classes:WaitForChild("AvatarHandler"))
local InventoryHandler = require(script.Parent.Parent.Parent.Classes:WaitForChild("InventoryHandler"))

local BloxbizRemotes = ReplicatedStorage.BloxbizRemotes
local CatalogOnGetShop = BloxbizRemotes:WaitForChild("CatalogOnGetShop")

local Value = Fusion.Value

local Components = CatalogClient.Components
local CatalogItem = require(Components.CatalogItem)

local ShopClass = {}
ShopClass.__index = ShopClass

local CachedShops = {}

function ShopClass.Get(shopId)
	return CachedShops[shopId]
end

function ShopClass.Load(shopData, shopFeedController)
	local shop = ShopClass.Get(shopData.guid)
	if shop then
		shop:Open()
	else
		ShopClass.new(shopData, shopFeedController)
	end
end

function ShopClass.new(shopData, shopFeedController)
	local shopId = shopData.guid

    local self = setmetatable({
		Id = shopId,
		ShopFeedController = shopFeedController,

		Items = {},
		NextCursor = nil,
		SelectedShop = shopFeedController.SelectedShop,

		Data = shopData,
		Creator = nil,
		SelectedItemId = Value(),

		Guis = {},

		LoadedAll = false,
		LoadingPromises = {},
	}, ShopClass)

	CachedShops[shopId] = self

	self:Init()
	self:Open()
end

function ShopClass:Open()
	self.SelectedShop:set(self)
end

function ShopClass:Close()
	self.SelectedShop:set(nil)

	self:CancelLoading()
	self:ClearListFrame()
end

function ShopClass:LoadItems(loading)
	self:ClearListFrame()

	local hasCachedItems = #self.Items > 0
	if hasCachedItems then
		self:LoadFromCache(self.Items)
		loading:set(false)
	else
		table.insert(self.LoadingPromises, self:LoadNextPage():andThen(function()
			loading:set(false)
		end))
	end

	self.Guis.ScrollingFrame.CanvasPosition = Vector2.zero
end

function ShopClass:CacheItems(items)
	local newItems = {}

	local itemDetailsMap = InventoryHandler.GetBatchItemDetails(
		Utils.map(items, function(item) return item.id end)
	)

	for _, item in itemDetailsMap do
		local itemData = AvatarHandler.BuildItemData(item)

		table.insert(self.Items, itemData)
		table.insert(newItems, itemData)
	end

	return newItems
end

function ShopClass:LoadFromCache(newItems)
	if self.Id ~= self.SelectedShop:get().Id then
		return
	end

	local AvatarPreviewController = self.ShopFeedController.Controllers.AvatarPreviewController

	local ListFrame = self.Guis.ListFrame

	local itemFrames = {}

	for i, item in newItems do
		local catalogItem = CatalogItem({
			ItemData = item,
			SelectedId = self.SelectedItemId,
			CategoryName = Value("Shops"),
			AvatarPreviewController = AvatarPreviewController,

			OnTry = function()
				AvatarPreviewController:AddChange(item, "Shops")
			end,
		})
		catalogItem.Parent = ListFrame

		table.insert(itemFrames, catalogItem)

		if i % 10 == 0 then
			task.wait()
		end
	end
end

function ShopClass:LoadNextPage()
	return Promise.new(function(resolve, reject)
		local id = self.Id
		local nextCursor = self.NextCursor
		local selectedShop = self.SelectedShop:get().Data

		local shopSection = selectedShop.sections[1].id

		local success, items, nextPageCursor = CatalogOnGetShop:InvokeServer(id, shopSection, nextCursor)
		if not success then
			print("Handle page load failed!")
			reject()
			return
		end

		if #items > 0 then
			local newItems = self:CacheItems(items)
			self:LoadFromCache(newItems)

			if not nextPageCursor then
				self.LoadedAll = true
			end
		else
			if not nextCursor then
				self:ClearListFrame()
			end

			self.LoadedAll = true
		end

		self.NextCursor = nextPageCursor

		resolve()
	end)
end

function ShopClass:ClearListFrame()
	for _, child in self.Guis.ListFrame:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

function ShopClass:Init()
	local data = self.Data
	local shopFeedController = self.ShopFeedController

	local creator = GroupService:GetGroupInfoAsync(data.owner_group)
	self.Creator = creator and creator.Name or "Unknown"

	self.Guis.MainFrame = shopFeedController.Guis.ShopViewFrame
	self.Guis.ListFrame = shopFeedController.Guis.ShopViewListFrame
	self.Guis.ScrollingFrame = shopFeedController.Guis.ShopViewScrollingFrame
end

function ShopClass:CancelLoading()
	for _, promise in self.LoadingPromises do
		promise:cancel()
	end

	self.LoadingPromises = {}
end

function ShopClass:Destroy()
	self:CancelLoading()
	self:ClearListFrame()

	self.Guis = {}
	self.Items = {}

	CachedShops[self.Id] = nil
end

return ShopClass