local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BloxbizSDK = script.Parent.Parent.Parent.Parent.Parent
local CatalogClient = BloxbizSDK:FindFirstChild("CatalogClient")

local ConfigReader = require(BloxbizSDK:WaitForChild("ConfigReader"))
local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")
local CatalogItemPromptEvent = BloxbizRemotes:WaitForChild("catalogItemPromptEvent")
local PromptPurchaseServer = BloxbizRemotes:WaitForChild("CatalogOnPromptPurchase")

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local Player = Players.LocalPlayer

local Classes = CatalogClient.Classes
local AvatarHandler = require(Classes:WaitForChild("AvatarHandler"))
local InventoryHandler = require(Classes:WaitForChild("InventoryHandler"))

local Computed = Fusion.Computed
local Observer = Fusion.Observer
local Spring = Fusion.Spring
local Value = Fusion.Value

local Button = require(script.Parent.Parent.ItemButton)

local BLOCKED_ITEMS = ConfigReader:read("CatalogPurchaseBlockList")

local SETTINGS = {
	DefaultFont = Font.new("rbxasset://fonts/families/GothamSSm.json"),
	ItemColor = {
		Default = Color3.fromRGB(79, 84, 95),
		Hover = Color3.fromRGB(107, 114, 129),
		MouseDown = Color3.fromRGB(76, 80, 90),
	},

	ButtonColor = {
		Default = Color3.fromRGB(79, 173, 116),
		MouseDown = Color3.fromRGB(57, 95, 73),
		Disabled = Color3.fromRGB(77, 121, 95),
	},

	TextColor = {
		Enabled = Color3.fromRGB(255, 255, 255),
		Disabled = Color3.fromRGB(120, 125, 136),
	},

	Size = {
		Default = UDim2.fromScale(0.9, 0.2),
		Hover = UDim2.fromScale(0.925, 0.205),
	},
}

type SourceBundleInfo = { AssetId: number, Price: number }

local function GetPurchaseStatus(
	assetId: number,
	isForSale: boolean,
	isBundle: boolean,
	ownAsset: boolean,
	sourceBundleInfo: SourceBundleInfo?
): (string, number, boolean)
	local text
	local purchaseAssetId

	local purchaseBundle = false

	if not isBundle then
		if isForSale == false then
			if sourceBundleInfo then
				purchaseBundle = true
				text = "Buy Bundle"

				purchaseAssetId = sourceBundleInfo.AssetId
			end
		else
			text = "Buy"
			purchaseAssetId = assetId
		end
	else
		text = "Buy Bundle"
		purchaseAssetId = assetId
		purchaseBundle = true
	end

	if table.find(BLOCKED_ITEMS, purchaseAssetId) then
		purchaseAssetId = nil
		purchaseBundle = false
		ownAsset = false
	end

	if ownAsset then
		text = "Update"
	elseif not purchaseAssetId then
		text = "Off-Sale"
	end

	return {
		text = text,
		purchaseId = purchaseAssetId,
		purchaseBundle = purchaseBundle
	}
end

return function(
	itemData: AvatarHandler.ItemData,
	categoryName: string,
	sourceBundleInfo: SourceBundleInfo?,
	textTransparency: Fusion.Spring<any>
): (Fusion.Value<boolean>, TextButton)
	local isBundle = itemData.BundleId ~= nil

	local isOwned = InventoryHandler.ownsAssetComputed(itemData.AssetId or itemData.BundleId)

	local purchaseInfo = Computed(function()
		return GetPurchaseStatus(itemData.AssetId or itemData.BundleId, itemData.IsForSale, isBundle, isOwned:get(), sourceBundleInfo)
	end, Fusion.cleanup)
		

	local isHovering = Value(false)
	local isHeldDown = Value(false)
	local isDisabled = Value(false)

	local button, textLabel

	local buttonSize = Spring(
		Computed(function()
			if isDisabled:get() == false then
				if purchaseInfo:get().purchaseId then
					return isHovering:get() and SETTINGS.Size.Hover or SETTINGS.Size.Default
				end
			end

			return SETTINGS.Size.Default
		end),
		40,
		1
	)

	local buttonBackground = Spring(
		Computed(function()
			if isDisabled:get() == false then
				if purchaseInfo:get().purchaseId then
					return isHeldDown:get() and SETTINGS.ButtonColor.MouseDown or SETTINGS.ButtonColor.Default
				end
			end

			return SETTINGS.ButtonColor.Disabled
		end),
		40,
		1
	)

	local springs = {
		TextTransparency = textTransparency,
		ButtonBackgroundColor = buttonBackground,
		ButtonSize = buttonSize,
	}

	local values = {
		Held = isHeldDown,
		Hovering = isHovering,
	}

	local function purchaseCallback()
		if purchaseInfo:get().purchaseId then
			if isOwned:get() then
				InventoryHandler.requestToWear(itemData)
			else
				CatalogItemPromptEvent:FireServer(categoryName)
				Utils.pprint("prompted in", categoryName)

				PromptPurchaseServer:InvokeServer(purchaseInfo:get().purchaseId, purchaseInfo:get().purchaseBundle)
			end
		end
	end

	local function cleanUpCallback()
	end

	button, textLabel = Button(Computed(function()
		return purchaseInfo:get().text
	end), Color3.new(1, 1, 1), springs, values, cleanUpCallback, purchaseCallback)

	return button
end
