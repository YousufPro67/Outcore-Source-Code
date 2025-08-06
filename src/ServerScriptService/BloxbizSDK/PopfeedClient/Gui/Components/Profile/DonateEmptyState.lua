local PopfeedClient = script.Parent.Parent.Parent.Parent

local Gui = PopfeedClient.Gui
local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed

local STATE_ZINDEX = 5

return function(props)
	local verticalPadding = 0.025
	local font = Font.fromEnum(Enum.Font.Arial)
	local boldFont = Font.fromEnum(Enum.Font.Arial)
	boldFont.Bold = true

	return {
		New("Frame")({
			Name = "SizingFrame",
			Size = Computed(function()
				if props.IsVertical:get() then
					return UDim2.fromScale(1.4, 0.65)
				else
					return UDim2.fromScale(1, 0.65)
				end
			end),
			AnchorPoint = Computed(function()
				if props.IsVertical:get() then
					return Vector2.new(0.5, 0)
				else
					return Vector2.new()
				end
			end),
			Position = Computed(function()
				if props.IsVertical:get() then
					return UDim2.fromScale(0.5, 0)
				else
					return UDim2.new()
				end
			end),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			BackgroundTransparency = 1,
			LayoutOrder = -math.huge,

			[Children] = {
				New("UIListLayout")({
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0, 0),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				New("Frame")({
					Name = "Padding",

					ZIndex = STATE_ZINDEX,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, verticalPadding),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					LayoutOrder = 1,
				}),
				New("ImageLabel")({
					Name = "ButtonsImage",

					ZIndex = STATE_ZINDEX,
					Image = "http://www.roblox.com/asset/?id=13001108350",
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(0.5, 0.15),
					Position = UDim2.fromScale(0.5, 0),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					ScaleType = Enum.ScaleType.Fit,
					LayoutOrder = 2,
				}),
				New("Frame")({
					Name = "Padding",

					ZIndex = STATE_ZINDEX,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, verticalPadding),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					LayoutOrder = 3,
				}),
				New("TextLabel")({
					Text = "Set Up Donate Buttons",
					Name = "TitleLabel",

					ZIndex = STATE_ZINDEX,
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					FontFace = boldFont,
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Size = UDim2.fromScale(0.7, 0.04),
					TextScaled = true,
					TextWrapped = true,
					LayoutOrder = 4,
				}),
				New("Frame")({
					Name = "Padding",

					ZIndex = STATE_ZINDEX,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, verticalPadding / 4),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					LayoutOrder = 5,
				}),
				New("TextLabel")({
					Text = "Start by putting avatar items or gamepasses on-sale in your Roblox account.",
					Name = "DescriptionLabel",

					ZIndex = STATE_ZINDEX,
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					FontFace = font,
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Size = UDim2.fromScale(0.7, 0.08),
					TextScaled = true,
					TextWrapped = true,
					LayoutOrder = 6,
				}),
				New("Frame")({
					Name = "Padding",

					ZIndex = STATE_ZINDEX,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, verticalPadding * 2),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					LayoutOrder = 7,
				}),
				New("TextLabel")({
					Text = "<b>Avatar Item Instructions</b>\n1. Open Roblox\n2. Go to your Create page\n3. Go to Avatar Items\n4. Create an avatar item\n5. Set the item price and put the item to On-Sale\n6. On-Sale Avatar Items become Donate Buttons here",
					Name = "AvatarItemInstructions",

					ZIndex = STATE_ZINDEX,
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					FontFace = font,
					RichText = true,
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Size = UDim2.fromScale(0.7, 0.28),
					TextScaled = true,
					TextWrapped = true,
					LayoutOrder = 8,
				}),
				New("Frame")({
					Name = "Padding",

					ZIndex = STATE_ZINDEX,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(0, verticalPadding),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					LayoutOrder = 9,
				}),
				New("TextLabel")({
					Text = "OR",
					Name = "OrLabel",

					ZIndex = STATE_ZINDEX,
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(158, 158, 158),
					FontFace = boldFont,
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Size = UDim2.fromScale(0.7, 0.035),
					TextScaled = true,
					TextWrapped = true,
					LayoutOrder = 10,
				}),
				New("Frame")({
					Name = "Padding",

					ZIndex = STATE_ZINDEX,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, verticalPadding),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					LayoutOrder = 11,
				}),
				New("TextLabel")({
					Text = "<b>Gamepass Instructions</b>\n1. Open Roblox\n2. Go to your Create page\n3. Select an experience\n4. Go to Associated Items\n5. Go to Passes\n6. Create a pass and put the item On-Sale\n7. On-Sale Passes become Donate Buttons here",
					Name = "GamepassInstructions",

					ZIndex = STATE_ZINDEX,
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					FontFace = font,
					RichText = true,
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Size = UDim2.fromScale(0.7, 0.28),
					TextScaled = true,
					TextWrapped = true,
					LayoutOrder = 12,
				}),
				New("Frame")({
					Name = "Padding",

					ZIndex = STATE_ZINDEX,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, verticalPadding),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					LayoutOrder = 13,
				}),
			},
		}),
	}
end
