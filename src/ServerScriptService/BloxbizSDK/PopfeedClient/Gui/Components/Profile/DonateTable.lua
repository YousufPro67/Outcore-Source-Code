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
local Value = Fusion.Value

local GuiComponents = Gui.Components
local TextButton = require(GuiComponents.TextButton)
local DonationEmptyState = require(GuiComponents.Profile.DonateEmptyState)

local function donationTable(props, donationItems)
	local donationData = Value(donationItems)

	return {
		New("Frame")({
			Name = "SizingFrame",
			Size = Computed(function()
				local emptyState = #donationItems == 0
				if emptyState and props.IsVertical:get() then
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
				New("UIGridLayout")({
					CellSize = UDim2.fromScale(0.32, 0.26),
					CellPadding = UDim2.fromScale(0.02, 0.035),
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Top,
				}),

				ForValues(donationData, function(donation)
					return TextButton({
						Text = tostring(donation.robux),
						Name = "DonateButton-" .. tostring(donation.item_id),
						Color = Color3.fromRGB(24, 209, 0),
						TextColor = Color3.fromRGB(255, 255, 255),
						AutomaticSize = Enum.AutomaticSize.X,
						AnchorPoint = Vector2.new(0.5, 0.5),
						TextSize = UDim2.fromScale(0, 0.3),
						ZIndex = 1,
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
								LayoutOrder = -1,
								Size = UDim2.fromScale(0.2, 0.2),
								SizeConstraint = Enum.SizeConstraint.RelativeXX,
								Image = "rbxassetid://9764949186",
								Name = "RobuxIcon",
							}),
						},
					})
				end, Fusion.cleanup),
			},
		}),
	}
end

return function(props, donationItems)
	return New("Frame")({
		Name = "DonationContainer",
		Size = UDim2.fromScale(1, 0.65),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,

		[Children] = Computed(function()
			if #donationItems.donations == 0 then
				return DonationEmptyState(props)
			else
				return donationTable(props, donationItems.donations)
			end
		end),
	})
end
