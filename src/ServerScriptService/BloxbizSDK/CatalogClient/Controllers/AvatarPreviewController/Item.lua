local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BloxbizSDK = script.Parent.Parent.Parent.Parent
local CatalogClient = script.Parent.Parent.Parent

local ConfigReader = require(BloxbizSDK:WaitForChild("ConfigReader"))
local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")

local CatalogItemPromptEvent = BloxbizRemotes:WaitForChild("catalogItemPromptEvent")
local PromptPurchaseServer = BloxbizRemotes:WaitForChild("CatalogOnPromptPurchase")

local Classes = CatalogClient.Classes
local AvatarHandler = require(Classes:WaitForChild("AvatarHandler"))
local InventoryModule = require(Classes:WaitForChild("InventoryHandler"))

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local Player = Players.LocalPlayer

local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local New = Fusion.New
local Ref = Fusion.Ref
local Computed = Fusion.Computed
local Observer = Fusion.Observer
local Spring = Fusion.Spring
local Cleanup = Fusion.Cleanup
local Value = Fusion.Value

local BLOCKED_ITEMS = ConfigReader:read("CatalogPurchaseBlockList")

local ITEM_COLOR = {
	Default = Color3.fromRGB(20, 20, 20),
	Hover = Color3.fromRGB(30, 30, 30),
	MouseDown = Color3.fromRGB(0, 0, 0),
}

local BUY_BUTTON_CONST = {
	Color = {
		Default = Color3.fromRGB(79, 173, 116),
		MouseDown = Color3.fromRGB(57, 95, 73),
		Disabled = Color3.fromRGB(77, 121, 95),
	},

	Size = {
		Default = UDim2.fromScale(0.9, 0.2),
		Hover = UDim2.fromScale(0.925, 0.205),
	},
}

local TRY_BUTTON_CONST = {
	Color = {
		Default = Color3.fromRGB(255, 255, 255),
		MouseDown = Color3.fromRGB(153, 153, 153),
	},

	Size = {
		Default = UDim2.fromScale(0.9, 0.2),
		Hover = UDim2.fromScale(0.925, 0.205),
	},
}

local PREVIEW_FORMAT = "rbxthumb://type=%s&id=%s&w=150&h=150"
local DEFAULT_FONT = Font.new("rbxasset://fonts/families/GothamSSm.json")

type SourceBundleInfo = { AssetId: number, Price: number }

export type DataSet = {
	Selected: Fusion.Value<boolean>,
	Disabled: Fusion.Value<boolean>,
	Instance: GuiObject,
}

local function GetPurchaseStatus(assetId: number, isForSale, isBundle, sourceBundleInfo): (string, number, boolean)
	local text
	local purchaseAssetId
	local ownAsset = InventoryModule.ownsAsset(assetId)

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

	return text, purchaseAssetId, purchaseBundle
end

local function GetItemPrice(itemData: AvatarHandler.ItemData, sourceBundleInfo: SourceBundleInfo?): string
	local price = itemData.Price or 0
	local isFromBundle = false
	if not itemData.IsForSale and sourceBundleInfo then
		if sourceBundleInfo.Price then
			price = sourceBundleInfo.Price
			isFromBundle = true
		end
	end

	local text = price > 0 and tostring(price) or "Free"
	text ..= isFromBundle and " (Bundle)" or ""

	return text
end

local function GetLimitedText(limitedType: number, availableQty: number): string
	if limitedType == 1 then
		return string.format(
			'<font color="rgb(23,188,81)">LIMITED</font> <font color="#F2F51C"><b>QTY: %d</b></font>',
			availableQty
		)
	else
		return '<font color="rgb(23,188,81)">LIMITED</font>'
	end
end

local function BuyButton(
	text: string,
	purchaseAssetId: number,
	itemData: AvatarHandler.ItemData,
	categoryName: string,
	purchaseBundle: boolean,
	textSelectionSpring: Fusion.Spring<any>
): (Fusion.Value<boolean>, TextButton)
	local isHovering = Value(false)
	local isHeldDown = Value(false)
	local isDisabled = Value(false)

	local buyTextLabel = Value()
	local equippedObserver = Observer(isDisabled)

	local disconnectObs = equippedObserver:onChange(function()
		local label = buyTextLabel:get()
		if label then
			label.Text = isDisabled:get() and "Owned" or "Buy"
		end
	end)

	local hoverFrameSelectionSpring = Spring(
		Computed(function()
			if isDisabled:get() == false then
				if purchaseAssetId then
					return isHovering:get() and BUY_BUTTON_CONST.Size.Hover or BUY_BUTTON_CONST.Size.Default
				end
			end

			return BUY_BUTTON_CONST.Size.Default
		end),
		40,
		1
	)

	local mouseDownSpring = Spring(
		Computed(function()
			if isDisabled:get() == false then
				if purchaseAssetId then
					return isHeldDown:get() and BUY_BUTTON_CONST.Color.MouseDown or BUY_BUTTON_CONST.Color.Default
				end
			end

			return BUY_BUTTON_CONST.Color.Disabled
		end),
		40,
		1
	)

	local button = New("TextButton")({
		Name = "BuyButton",
		Text = "",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextScaled = true,
		TextSize = 14,
		TextWrapped = true,
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = mouseDownSpring,
		BackgroundTransparency = textSelectionSpring,
		Position = UDim2.fromScale(0.5, 0.275),
		Size = hoverFrameSelectionSpring,

		[Cleanup] = function()
			disconnectObs()
		end,

		[OnEvent("Activated")] = function()
			if textSelectionSpring:get() < 0.1 and purchaseAssetId then
				if not InventoryModule.ownsAsset(purchaseAssetId) then
					CatalogItemPromptEvent:FireServer(categoryName)

					PromptPurchaseServer:InvokeServer(purchaseAssetId, purchaseBundle)
				else
					isDisabled:set(true)
				end
			end
		end,

		[Cleanup] = Fusion.cleanup,

		[OnEvent("MouseButton1Down")] = function()
			isHeldDown:set(true)
		end,

		[OnEvent("MouseButton1Up")] = function()
			isHeldDown:set(false)
		end,

		[OnEvent("MouseEnter")] = function()
			isHovering:set(true)
		end,

		[OnEvent("MouseLeave")] = function()
			isHovering:set(false)
			isHeldDown:set(false)
		end,

		[Children] = {

			New("TextLabel")({
				Name = "TextLabel",
				Text = text,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextTransparency = textSelectionSpring,
				TextWrapped = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.8, 0.4),

				[Ref] = buyTextLabel,
			}),

			New("UICorner")({
				Name = "UICorner",
				CornerRadius = UDim.new(0.15, 0),
			}),
		},
	})

	return isDisabled, button
end

local function UpdateItemButton(tryOnCallback: () -> (), textSelectionSpring: Fusion.Spring<any>)
	local isHovering = Value(false)
	local isHeldDown = Value(false)

	local tryOnTextLabel = Value()

	local hoverFrameSelectionSpring = Spring(
		Computed(function()
			return isHovering:get() and TRY_BUTTON_CONST.Size.Hover or TRY_BUTTON_CONST.Size.Default
		end),
		40,
		1
	)

	local mouseDownSpring = Spring(
		Computed(function()
			return isHeldDown:get() and TRY_BUTTON_CONST.Color.MouseDown or TRY_BUTTON_CONST.Color.Default
		end),
		40,
		1
	)

	local button = New("TextButton")({
		Name = "RemoveButton",
		Text = "",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextScaled = true,
		TextSize = 14,
		TextWrapped = true,
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = mouseDownSpring,
		BackgroundTransparency = textSelectionSpring,
		Position = UDim2.fromScale(0.5, 0.525),
		Size = hoverFrameSelectionSpring,

		[OnEvent("Activated")] = function()
			tryOnCallback()
		end,

		[OnEvent("MouseButton1Down")] = function()
			isHeldDown:set(true)
		end,

		[OnEvent("MouseButton1Up")] = function()
			isHeldDown:set(false)
		end,

		[OnEvent("MouseEnter")] = function()
			isHovering:set(true)
		end,

		[OnEvent("MouseLeave")] = function()
			isHovering:set(false)
			isHeldDown:set(false)
		end,

		[Children] = {
			New("UICorner")({
				Name = "UICorner",
				CornerRadius = UDim.new(0.15, 0),
			}),

			New("TextLabel")({
				Name = "TextLabel",
				Text = "Remove",
				FontFace = DEFAULT_FONT,
				TextColor3 = Color3.fromRGB(20, 20, 20),
				TextScaled = true,
				TextSize = 14,
				TextTransparency = textSelectionSpring,
				TextWrapped = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.8, 0.4),

				[Ref] = tryOnTextLabel,
			}),
		},
	})

	return button
end

local function ItemPrice(amount: string)
	return New("Frame")({
		Name = "ItemPrice",
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.959),
		Size = UDim2.fromScale(0.9, 0.07),

		[Children] = {
			New("TextLabel")({
				Name = "Amount",
				Text = amount,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromScale(0.85, 1),
			}),

			New("ImageLabel")({
				Name = "Icon",
				Image = "rbxassetid://9764949186",
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
			}),
		},
	})
end

return function(
	categoryName: string,
	itemData: AvatarHandler.ItemData,
	sourceBundleInfo: SourceBundleInfo?,
	funcs: { OnTry: (...any) -> (), OnActivated: (...any) -> () }
): DataSet?
	local isBundle = itemData.BundleId ~= nil
	local assetId = itemData.AssetId or itemData.BundleId

	local isHovering = Value(false)
	local isHeldDown = Value(false)
	local isSelected = Value(false)

	local textSelectionSpring = Spring(
		Computed(function()
			return isSelected:get() and 0 or 1
		end),
		20,
		1
	)

	local selectedFrameSelectionSpring = Spring(
		Computed(function()
			return isSelected:get() and 0.5 or 1
		end),
		20,
		1
	)

	local mainFrameBackgroundHoverSpring = Spring(
		Computed(function()
			if isHeldDown:get() then
				return ITEM_COLOR.MouseDown
			elseif isHovering:get() then
				return ITEM_COLOR.Hover
			else
				return ITEM_COLOR.Default
			end
		end),
		20,
		1
	)

	local newObs = Observer(textSelectionSpring)

	local hoverLayer = Value()
	local disconnect = newObs:onChange(function()
		if textSelectionSpring:get() < 0.8 then
			local layer = hoverLayer:get()
			layer.Visible = true
		else
			local layer = hoverLayer:get()
			layer.Visible = false
		end
	end)

	local text, purchaseAssetId, purchaseBundle = GetPurchaseStatus(assetId, itemData.IsForSale, isBundle)

	local isPurchaseDisabled, buyButton =
		BuyButton(text, purchaseAssetId, itemData, categoryName, purchaseBundle, textSelectionSpring)
	local updateItemButton = UpdateItemButton(funcs.OnTry, textSelectionSpring)
	local priceTag = ItemPrice(GetItemPrice(itemData, sourceBundleInfo))

	local itemFrame = New("Frame")({
		Name = itemData.AssetId,
		BackgroundColor3 = mainFrameBackgroundHoverSpring,
		BackgroundTransparency = 0.35,
		Size = UDim2.fromOffset(100, 100),
		Visible = true,

		[Cleanup] = function()
			disconnect()
		end,

		[Children] = {
			--Preview
			New("ImageLabel")({
				Name = "Preview",
				Image = PREVIEW_FORMAT:format("Asset", assetId),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.4),
				Size = UDim2.fromScale(0.9, 0.9),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			--Remove/Buy buttons
			New("Frame")({
				Name = "HoverFrame",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = selectedFrameSelectionSpring,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				Visible = false,
				ZIndex = 2,

				[Ref] = hoverLayer,

				[Children] = {
					New("UICorner")({
						Name = "UICorner",
						CornerRadius = UDim.new(0.05, 0),
					}),

					buyButton,
					updateItemButton,
				},
			}),

			priceTag,

			New("UICorner")({
				Name = "UICorner",
				CornerRadius = UDim.new(0.05, 0),
			}),

			--Item name
			New("TextLabel")({
				Name = "ItemName",
				Text = itemData.Name,
				AutoLocalize = false,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.875),
				Size = UDim2.fromScale(0.9, 0.07),
			}),

			--Limited
			New("TextLabel")({
				Name = "Limited",
				FontFace = DEFAULT_FONT,
				Text = GetLimitedText(itemData.IsLimited, itemData.Available),
				RichText = true,
				TextColor3 = Color3.fromRGB(23, 188, 81),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.8),
				Size = UDim2.fromScale(0.9, 0.05),
				Visible = not isBundle and itemData.IsLimited > 0,
			}),

			--Main button
			New("TextButton")({
				Name = "Button",
				Text = "",
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextSize = 14,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),

				[OnEvent("MouseButton1Down")] = function()
					isHeldDown:set(true)
				end,

				[OnEvent("MouseButton1Up")] = function()
					isHeldDown:set(false)
				end,

				[OnEvent("MouseEnter")] = function()
					isHovering:set(true)
				end,

				[OnEvent("MouseLeave")] = function()
					isHovering:set(false)
					isHeldDown:set(false)
				end,

				[OnEvent("Activated")] = function()
					if funcs.OnActivated then
						funcs.OnActivated(isSelected)
					end
				end,
			}),
		},
	})

	return { Selected = isSelected, Disabled = isPurchaseDisabled, Instance = itemFrame }
end
