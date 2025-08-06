local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")

local BloxbizSDK = script.Parent.Parent.Parent
local CatalogClient = BloxbizSDK.CatalogClient

local OnPurchaseComplete

local Classes = CatalogClient.Classes
local InventoryModule = require(Classes:WaitForChild("InventoryHandler"))

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local Value = Fusion.Value
local Observer = Fusion.Observer

local Components = script.Parent.Parent.Components
local ListFrame = require(Components.ListFrame)
local CatalogItem = require(Components.CatalogItem)
local EmptyState = require(Components.EmptyState)

local AvatarItemsCache: {} = {}

local Inventory = {}
Inventory.__index = Inventory

function Inventory.new(coreContainer: Frame, loadingFrame: Frame)
	local self = setmetatable({}, Inventory)
	self.Enabled = false
	self.Loaded = false

	self.HasAccess = Value(false)
	self.Loading = Value(false)

	self.Container = coreContainer
	self.Observers = {}
	self.GuiObjects = {
		LoadingFrame = loadingFrame,
	}

	self.CurrentSelectedItem = Value()
	self.Content = {}

	self.SelectedId = Value()

	return self
end

function Inventory:Init(controllers: { [string]: { any } })
	self.Controllers = controllers
	local mainFrame, scrollingFrame, itemFrame = ListFrame("Inventory Frame", true)

	local emptyStateFrame = EmptyState({
		Parent = mainFrame,
		Text = "View inventory items by granting access.",
		BackgroundTransparency = 1,
		ButtonText = "Grant Access",
		Size = UDim2.fromScale(1, 0.8),
		Visible = Fusion.Computed(function() 
			local loading = self.Loading:get()
			local hasAccess = self.HasAccess:get()
			return not (loading or hasAccess)
		end),

		Callback = function()
			self:RequestInventory()
		end,
	})
	scrollingFrame.Visible = false

	self.GuiObjects.Frame = mainFrame
	self.GuiObjects.ScrollingFrame = scrollingFrame
	self.GuiObjects.ItemFrame = itemFrame
	self.GuiObjects.EmptyStateFrame = emptyStateFrame

	OnPurchaseComplete = BloxbizRemotes:WaitForChild("CatalogOnPurchaseComplete")
	OnPurchaseComplete.OnClientEvent:Connect(function (itemId, purchased)
		if purchased then
			Utils.pprint("Purchased", itemId)
			InventoryModule.addAsset(itemId)
		end
	end)

	self:Disable()
end

function Inventory:Start()
	local frameContainer = self.Container:WaitForChild("FrameContainer")
	self.GuiObjects.Frame.Parent = frameContainer
end

function Inventory:Enable()
	self.Enabled = true
	self.GuiObjects.Frame.Visible = true

	self.Controllers.TopBarController:ResetSearchBar()
	self.Controllers.OutfitFeedController:Disable()

	if InventoryModule.hasAccess() and not self.Loaded then
		self.HasAccess:set(true)
		self:LoadItems()
	end
end

function Inventory:Disable()
	self.Enabled = false
	self.GuiObjects.Frame.Visible = false
end

function Inventory:RequestInventory()
	if self.Loaded then
		return
	end

	self.GuiObjects.LoadingFrame.Visible = true
	self.Loading:set(true)

	local gotAccess = InventoryModule.requestAccess()
	if gotAccess then
		self.HasAccess:set(true)
		self:LoadItems()
	end

	self.Loading:set(false)
	self.GuiObjects.LoadingFrame.Visible = false
	self.GuiObjects.ScrollingFrame.Visible = gotAccess == true
end

function Inventory:LoadItems()
	if not InventoryModule.hasAccess() then
		return
	end

	self:ClearItemFrame()
	self.GuiObjects.LoadingFrame.Visible = true

	local inventory = Utils.values(InventoryModule.get())
	Utils.sort(inventory, function (item)
		return item.Name:lower()
	end)

	for i, itemData in pairs(inventory) do
		local avatarController = self.Controllers.AvatarPreviewController
		
		local existingItem = CatalogItem {
			Parent = self.GuiObjects.ItemFrame,
			AvatarPreviewController = avatarController,
			ItemData = itemData,
			CategoryName = "Inventory",
			SourceBundleInfo = nil,
			OnTry = function()
				avatarController.AddChange(avatarController, itemData, "Inventory")
			end,
			SelectedId = self.SelectedId
		}

		if existingItem then
			table.insert(self.Content, existingItem)
		end
	end

	self.Loaded = true
	self.GuiObjects.LoadingFrame.Visible = false
end

function Inventory:ClearItemFrame()
	local frame: ScrollingFrame = self.GuiObjects.ScrollingFrame
	if frame then
		frame.Visible = false
		frame.CanvasPosition = Vector2.new(0, 0)

		local currentCategory = self.CurrentSelectedItem:get()
		if currentCategory then
			for _, child in pairs(self.Content) do
				child.Parent = nil
			end

			if currentCategory then
				currentCategory:set(false)
				self.CurrentSelectedItem:set(nil)
			end
		end

		frame.Visible = true
	end
end

function Inventory:GetAvatarItemCache(id: number)
	return AvatarItemsCache[id]
end

return Inventory
