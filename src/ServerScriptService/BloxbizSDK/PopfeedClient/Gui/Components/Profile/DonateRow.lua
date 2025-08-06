local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PopfeedClient = script.Parent.Parent.Parent.Parent

local Gui = PopfeedClient.Gui
local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Children = Fusion.Children
local ForValues = Fusion.ForValues
local Computed = Fusion.Computed
local Ref = Fusion.Ref
local Value = Fusion.Value
local OnChange = Fusion.OnChange

local GuiComponents = Gui.Components
local TextButton = require(GuiComponents.TextButton)

return function(props)
	props = {
		donationData = props.donationData,
		LayoutOrder = props.LayoutOrder or 1,
		ZIndex = props.ZIndex,
		Visible = props.Visible or true,
		Size = props.Size or UDim2.fromScale(1, 0.1),
		SizeConstraint = props.SizeConstraint or Enum.SizeConstraint.RelativeXX,
		ScrollingFrameSize = props.ScrollingFrameSize or UDim2.fromScale(1, 1),
		ScrollingFramePosition = props.ScrollingFramePosition or UDim2.fromScale(0, 0),
	}

	local absoluteContentSize = Value(UDim2.new())

	return New("Frame")({
		Name = "DonateRow",
		BackgroundTransparency = 1,
		SizeConstraint = props.SizeConstraint,
		Position = props.Position,
		Size = props.Size,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
		Visible = Computed(function()
			local donationData = props.donationData:get()
			if donationData == nil or #donationData == 0 then
				return false
			end

			local isVisible = props.Visible
			if type(props.Visible) ~= "boolean" then
				isVisible = props.Visible:get()
			end

			return isVisible
		end),

		[Children] = New("ScrollingFrame")({
			Size = props.ScrollingFrameSize,
			Position = props.ScrollingFramePosition,
			CanvasSize = Computed(function()
				return UDim2.new(0, absoluteContentSize:get().X, 1, 0)
			end),
			ScrollBarThickness = 0,
			ScrollingDirection = Enum.ScrollingDirection.X,
			BackgroundTransparency = 1,
			ZIndex = props.ZIndex,

			[Children] = New("Frame")({
				Name = "Container",
				BackgroundTransparency = 1,
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Size = UDim2.fromScale(5, 1),
				ZIndex = props.ZIndex,

				[Children] = {
					New("UIListLayout")({
						Padding = UDim.new(0.05, 0),
						SortOrder = Enum.SortOrder.LayoutOrder,
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
						VerticalAlignment = Enum.VerticalAlignment.Center,

						[OnChange("AbsoluteContentSize")] = function(newValue)
							absoluteContentSize:set(newValue)
						end,
					}),

					ForValues(props.donationData, function(donation)
						return TextButton({
							Text = tostring(donation.robux),
							Name = "DonateButton-" .. tostring(donation.item_id),
							Color = Color3.fromRGB(24, 209, 0),
							TextColor = Color3.fromRGB(255, 255, 255),
							AnchorPoint = Vector2.new(0.5, 0.5),
							AutomaticSize = Enum.AutomaticSize.X,
							TextSize = UDim2.fromScale(0, 0.6),
							Size = UDim2.fromScale(0.5, 1),
							ZIndex = props.ZIndex,
							Bold = true,

							OnActivated = function()
								if donation.item_type == "gamepass" then
									MarketplaceService:PromptGamePassPurchase(LocalPlayer, donation.item_id)
								else
									MarketplaceService:PromptPurchase(LocalPlayer, donation.item_id)
								end
							end,

							[Children] = {
								New("UIListLayout")({
									Padding = UDim.new(0.05, 0),
									SortOrder = Enum.SortOrder.LayoutOrder,
									FillDirection = Enum.FillDirection.Horizontal,
									HorizontalAlignment = Enum.HorizontalAlignment.Center,
									VerticalAlignment = Enum.VerticalAlignment.Center,
								}),
								New("ImageLabel")({
									BackgroundTransparency = 1,
									ZIndex = props.ZIndex,
									LayoutOrder = -1,
									Size = UDim2.fromScale(0.6, 0.6),
									SizeConstraint = Enum.SizeConstraint.RelativeYY,
									Image = "rbxassetid://9764949186",
									Name = "RobuxIcon",
								}),
							},
						})
					end, Fusion.cleanup),
				},
			}),
		}),
	})
end
