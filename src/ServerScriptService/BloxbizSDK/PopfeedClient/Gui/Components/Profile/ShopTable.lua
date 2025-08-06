local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local PopfeedClient = script.Parent.Parent.Parent.Parent

local Gui = PopfeedClient.Gui
local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local ForValues = Fusion.ForValues

local GuiComponents = Gui.Components
local ActionButton = require(GuiComponents.ActionButton)

local thumbnailFormat = "rbxthumb://type=Asset&id=%s&w=420&h=420"

return function(props)
	local profileData = props.CurrentProfileData:get()
	local shopItems = profileData.shop_items

	return New("Frame")({
		Name = "Container",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,

		[Children] = {
			New("Frame")({
				Name = "Holder",
				Size = UDim2.fromScale(1, 0.756),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				BackgroundTransparency = 1,

				[Children] = {
					New("UIGridLayout")({
						CellSize = UDim2.fromScale(0.482, 0.75),
						CellPadding = UDim2.fromScale(0.035, 0.043),
						SortOrder = Enum.SortOrder.LayoutOrder,
						FillDirection = Enum.FillDirection.Horizontal,
						VerticalAlignment = Enum.VerticalAlignment.Top,
					}),

					ForValues(shopItems, function(item)
						return New("TextButton")({
							Name = item.Name,
							BackgroundColor3 = Color3.fromRGB(55, 56, 56),
							AutoButtonColor = true,

							[OnEvent("Activated")] = function()
								MarketplaceService:PromptPurchase(LocalPlayer, item.Id)
							end,

							[Children] = {
								New("TextLabel")({
									Text = item.Name,
									Size = UDim2.fromScale(0.875, 0.08),
									Position = UDim2.fromScale(0.065, 0.83),
									AnchorPoint = Vector2.new(0, 1),
									FontFace = Font.fromEnum(Enum.Font.Arial),
									TextColor3 = Color3.fromRGB(255, 255, 255),
									TextXAlignment = Enum.TextXAlignment.Left,
									BackgroundTransparency = 1,
									TextScaled = true,
								}),

								ActionButton({
									Name = "Price",
									Text = item.Price,

									Padding = 0.015,
									MiddleOffset = 0.175,

									Size = UDim2.fromScale(0, 0.125),
									Position = UDim2.fromScale(0.06, 0.96),
									AnchorPoint = Vector2.new(0, 1),

									Icon = "rbxassetid://13871293502",
									IconSize = UDim2.fromScale(0.85, 0.85),
								}),

								New("ImageLabel")({
									Size = UDim2.fromScale(0.7, 0.7),
									Position = UDim2.fromScale(0.5, 0.35),
									AnchorPoint = Vector2.new(0.5, 0.5),
									SizeConstraint = Enum.SizeConstraint.RelativeXX,
									Image = thumbnailFormat:format(item.Id),
									BackgroundTransparency = 1,
								}),

								New("UICorner")({
									CornerRadius = UDim.new(0, 8),
								}),
							},
						})
					end, Fusion.cleanup),
				},
			}),
		},
	})
end
