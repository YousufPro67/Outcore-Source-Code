local BloxbizSDK = script.Parent.Parent.Parent
local CatalogClient = BloxbizSDK:FindFirstChild("CatalogClient")

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))

local AvatarHandler = require(CatalogClient.Classes:WaitForChild("AvatarHandler"))

local New = Fusion.New
local Value = Fusion.Value
local Children = Fusion.Children
local Spring = Fusion.Spring
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent

local InteractionFrame = require(script.InteractionFrame)
local BuyButton = require(script.InteractionFrame.BuyButton)
local TryButton = require(script.InteractionFrame.TryButton)
local SeeItemsButton = require(script.InteractionFrame.SeeItemsButton)

type SourceBundleInfo = { AssetId: number, Price: number }
export type Component = {
	Selected: Fusion.Value<boolean>,
	Equipped: Fusion.Value<boolean>,
	Disabled: Fusion.Value<boolean>,
	Instance: GuiObject,
}

local SETTINGS = {
	Color = {
		Default = Color3.fromRGB(79, 84, 95),
		Hover = Color3.fromRGB(107, 114, 129),
		MouseDown = Color3.fromRGB(76, 80, 90),
	},
	PreviewFormat = "rbxthumb://type=%s&id=%s&w=150&h=150",
	Font = Font.new("rbxasset://fonts/families/GothamSSm.json"),
}

local function ItemPrice(
	itemData: AvatarHandler.BundleData & AvatarHandler.ItemData,
	sourceBundleInfo: SourceBundleInfo?
): string
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
				Text = text,
				FontFace = SETTINGS.Font,
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

local function ItemPreview(props): ImageLabel
	props = FusionProps.GetValues(props, {
		IsBundle = false,
		AssetId = FusionProps.Required
	})

	return New("ImageLabel")({
		Name = "Preview",
		Image = Computed(function()
			local assetId = props.AssetId:get()
			local isBundle = props.IsBundle:get()
			return isBundle and SETTINGS.PreviewFormat:format("BundleThumbnail", assetId) or SETTINGS.PreviewFormat:format("Asset", assetId)
		end),

		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromScale(0.9, 0.9),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,
	})
end

local function LimitedText(props): TextLabel
	props = FusionProps.GetValues(props, {
		LimitedType = 0,
		Quantity = FusionProps.Nil,
		IsBundle = false
	})

	local text = Computed(function()
		local limitedType = props.LimitedType:get()

		if limitedType == 1 then
			return string.format(
				'<font color="rgb(23,188,81)">LIMITED</font> <font color="#F2F51C"><b>QTY: %d</b></font>',
				props.Quantity:get()
			)
		else
			return '<font color="rgb(23,188,81)">LIMITED</font>'
		end
	end)
	

	return New("TextLabel")({
		Name = "Limited",
		FontFace = SETTINGS.Font,
		Text = text,
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
		Visible = Computed(function()
			return not props.IsBundle:get() and props.LimitedType:get() > 0
		end),
	})
end

local function ItemName(text: string): TextLabel
	return New("TextLabel")({
		Name = "ItemName",
		Text = text,
		FontFace = SETTINGS.Font,
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
		AutoLocalize = false
	})
end

return function (props)
	props = FusionProps.GetValues(props, {
		Parent = FusionProps.Nil,
		LayoutOrder = 1,

		Size = UDim2.fromOffset(100, 100),

		AvatarPreviewController = FusionProps.Required,
		ItemData = FusionProps.Required,
		CategoryName = FusionProps.Required,
		SourceBundleInfo = FusionProps.Nil,
		InventoryVariant = FusionProps.Nil,
		SelectedId = FusionProps.Nil,
		OnTry = FusionProps.Nil,
		OnSeeItems = FusionProps.Callback,

		BackgroundColor3 = Color3.fromRGB(79, 84, 95),
		BackgroundTransparency = 0,

		NotButton = false,
	})

	local IsBundle = Computed(function()
		return props.ItemData:get().BundleId ~= nil
	end)
	local AssetId = Computed(function()
		return props.ItemData:get().AssetId or props.ItemData:get().BundleId
	end)

	local isHovering = Value(false)
	local isHeldDown = Value(false)

	local isEquipped = Computed(function()
		local APC = props.AvatarPreviewController:get()
		local equippedItems = APC.EquippedItems:get()
		return not not equippedItems[tostring(AssetId:get())]
	end)

	local mainFrameBackgroundHoverSpring = Spring(
		Computed(function()
			if isHeldDown:get() then
				return SETTINGS.Color.MouseDown
			elseif isHovering:get() then
				return SETTINGS.Color.Hover
			else
				return props.BackgroundColor3:get()
			end
		end),
		20,
		1
	)

	local color1, color2
	if props.Color then
		color1 = Computed(function()
			local maybeHexColor = props.Color:get()
			if type(maybeHexColor) ~= "string" then
				return Color3.new(0.6, 0.6, 0.65)
			end

			return Color3.fromHex(maybeHexColor)
		end)
		color2 = Computed(function()
			return color1:get():Lerp(Color3.new(1, 1, 1), 0.6)
		end)
	end

	local button = New("Frame")({
		Parent = props.Parent,
		LayoutOrder = props.LayoutOrder,

		Name = Computed(function()
			return tostring(AssetId:get())
		end),
		BackgroundColor3 = props.Color and Color3.fromRGB(255, 255, 255) or mainFrameBackgroundHoverSpring,
		BackgroundTransparency = props.BackgroundTransparency,
		Size = props.Size,
		Visible = true,
		SizeConstraint = props.SizeConstraint or Enum.SizeConstraint.RelativeXX,

		[Children] = {
            props.Color and New "UIGradient" {
                Color = Computed(function()
                    return ColorSequence.new(color1:get(), color2:get())
                end),
                Rotation = -90
            } or nil,

			ItemName(Computed(function()
				return props.ItemData:get().Name
			end)),
			ItemPreview {
				AssetId = AssetId,
				IsBundle = IsBundle
			},
			Computed(function()
				if not props.InventoryVariant:get() then
					return ItemPrice(props.ItemData:get(), props.SourceBundleInfo:get())
				end
			end, Fusion.cleanup),
			LimitedText {
				LimitedType = Computed(function() return props.ItemData:get().IsLimited end),
				Quantity = Computed(function() return props.ItemData:get().Available end),
				IsBundle = IsBundle
			},
			InteractionFrame {
				Selected = Computed(function()
					return AssetId:get() == props.SelectedId:get()
				end),

				[Children] = {
					BuyButton(
						props.ItemData:get(),
						props.CategoryName:get(),
						props.SourceBundleInfo:get()
					),

					TryButton(
						isEquipped,
						function()
							local cb = props.OnTry:get()

							if cb then
								cb()
							else
								local APC = props.AvatarPreviewController:get()
								APC.AddChange(APC, props.ItemData:get(), props.CategoryName:get())
							end
						end
					),

					Computed(function()
						if IsBundle:get() then
							return SeeItemsButton(function()
								props.OnSeeItems:get()(AssetId:get())
							end)
						end
					end, Fusion.cleanup)
				},
			},

			New("UICorner")({
				Name = "UICorner",
				CornerRadius = UDim.new(0.05, 0),
			}),

			--Main button
			New("TextButton")({
				Name = "Button",
				Text = "",
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextSize = 14,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				AutoLocalize = false,

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

				[OnEvent("Activated")] = not props.NotButton:get() and function()
					if props.SelectedId:get() == AssetId:get() then
						props.SelectedId:set(nil)
					else
						props.SelectedId:set(AssetId:get())
					end
				end or nil,
			}),
		},
	})

	return button
end
