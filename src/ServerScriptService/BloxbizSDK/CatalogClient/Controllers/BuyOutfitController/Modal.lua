local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TextService = game:GetService("TextService")

local BloxbizSDK = script.Parent.Parent.Parent.Parent
local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FP = require(UtilsStorage:WaitForChild("FusionProps"))

local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent

local CatalogClient = BloxbizSDK:WaitForChild("CatalogClient")
local Components = CatalogClient.Components
local ScaledText = require(Components.ScaledText)

return function(props)
    props = FP.GetValues(props, {
        Parent = FP.Nil,
        SizeStandard = 0,

        Visible = false,
        RemainingPrice = 0,
        TotalPrice = 0,
        RemainingItems = 0,
        TotalItems = 0,
        OnClose = FP.Callback,

        [Children] = FP.Nil,
    })

    local topBarHeight = props.SizeStandard
	local paddingPX = Computed(function()
		return topBarHeight:get() / 1.5
	end)
	local padding = Computed(function()
		return UDim.new(0, paddingPX:get())
	end)

    local topBarSize = Value(Vector2.zero)

    local textSize = Computed(function()
        return topBarHeight:get() * 0.6
    end)

    local function getTextWidth(text)
        return TextService:GetTextSize(text, textSize:get(), Enum.Font.GothamMedium, Vector2.new(math.huge, math.huge)).X
    end

    local itemsRemainingText = Computed(function()
		local count = props.RemainingItems:get()
        return string.format("%s Item%s Remaining (", count, count == 1 and "" or "s")
    end)
    local itemsRemainingWidth = Computed(function()
        return getTextWidth(itemsRemainingText:get())
    end)

    local priceRemainingText = Computed(function()
        return string.format("%s)", Utils.toLocaleNumber(props.RemainingPrice:get()))
    end)
    local priceRemainingWidth = Computed(function()
        return getTextWidth(priceRemainingText:get())
    end)

    return New "TextButton" {
		Name = "BuyOutfitModal",
		Parent = props.Parent,
		Position = UDim2.fromOffset(0, -36),
		Size = UDim2.new(1, 0, 1, 36),
		BackgroundTransparency = 0.5,
		BackgroundColor3 = Color3.new(0, 0, 0),
		Visible = props.Visible,
		ZIndex = 1000,

		[Children] = {
			New "Frame" {
                Name = "Container",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(0.9, 0.8),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = Color3.new(0, 0, 0),

				[Children] = {
					New "UISizeConstraint" {
						MaxSize = workspace.Camera.ViewportSize * 0.8
					},
					New "UIAspectRatioConstraint" {
						AspectRatio = 1.7,
						DominantAxis = Enum.DominantAxis.Height
					},
					New "UIPadding" {
						PaddingLeft = padding,
						PaddingRight = padding,
						PaddingTop = Computed(function()
							return UDim.new(0, paddingPX:get() * 0.75)
						end),
						PaddingBottom = padding
					},
					New "UICorner" {
						CornerRadius = Computed(function() return UDim.new(0, paddingPX:get() / 2) end)
					},
					New "UIStroke" {
						Color = Color3.fromRGB(79, 84, 95),
						Thickness = 1.5,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					},

					New "Frame" {
                        Name = "Header",
						BackgroundTransparency = 1,
						Size = Computed(function()
							return UDim2.new(1, 0, 0, topBarHeight:get() * 1)
						end),
						[Children] = {
							ScaledText {
								AnchorPoint = Vector2.new(0, 0.5),
								Position = UDim2.fromScale(0, 0.5),
								Size = UDim2.fromScale(0.5, 0.8),
								TextColor3 = Color3.new(1, 1, 1),
								Text = "Buy Outfit",
								TextXAlignment = Enum.TextXAlignment.Left
							},

							New "Frame" {
								BackgroundTransparency = 1,
								AnchorPoint = Vector2.new(1, 0),
								Position = UDim2.fromScale(1, 0),
								Size = UDim2.fromScale(0.5, 1),

								[Children] = {
									New "UIListLayout" {
										FillDirection = Enum.FillDirection.Horizontal,
										SortOrder = Enum.SortOrder.LayoutOrder,
										VerticalAlignment = Enum.VerticalAlignment.Center,
										HorizontalAlignment = Enum.HorizontalAlignment.Right
									},

                                    -- items remaning
                                    New "TextLabel" {
                                        LayoutOrder = -5,
                                        BackgroundTransparency = 1,
                                        Size = Computed(function()
                                            return UDim2.new(0, itemsRemainingWidth:get(), 1, 0)
                                        end),
                                        Text = itemsRemainingText,
                                        TextSize = textSize,
                                        TextColor3 = Color3.new(1, 1, 1),
										TextXAlignment = Enum.TextXAlignment.Right
                                    },

                                    -- robux icon
                                    New "ImageLabel" {
                                        LayoutOrder = -4,
                                        BackgroundTransparency = 1,
                                        Size = UDim2.fromScale(0.66, 0.66),
                                        Image = "rbxassetid://15245041780",
                                        [Children] = New "UIAspectRatioConstraint" {
                                            AspectRatio = 1,
                                            DominantAxis = Enum.DominantAxis.Height
                                        }
                                    },

                                     -- price remaning
                                     New "TextLabel" {
                                        LayoutOrder = -3,
                                        BackgroundTransparency = 1,
                                        Size = Computed(function()
                                            return UDim2.new(0, priceRemainingWidth:get(), 1, 0)
                                        end),
                                        Text = priceRemainingText,
                                        TextSize = textSize,
                                        TextColor3 = Color3.new(1, 1, 1)
                                    },

                                    -- spacer
                                    New "TextButton" {
                                        Name = "Spacer",
                                        BackgroundTransparency = 1,
                                        LayoutOrder = -2,
                                        Size = Computed(function()
                                            return UDim2.fromOffset(paddingPX:get() * 0.9, 0)
                                        end)
                                    },

                                    -- X button
									New "TextButton" {
										BackgroundTransparency = 1,
										Text = "",
										Size = UDim2.fromScale(1, 1),
                                        LayoutOrder = -1,

										[OnEvent "Activated"] = function()
                                            props.OnClose:get()()
                                        end,

										[Children] = {
											New "UIAspectRatioConstraint" {
												AspectRatio = 1,
											},
											New "ImageLabel" {
												AnchorPoint = Vector2.new(0.5, 0.5),
												Position = UDim2.fromScale(0.5, 0.5),
												Size = UDim2.fromScale(0.7, 0.7),
												BackgroundTransparency = 1,
												Image = "rbxassetid://14542644751"
											}
										}
									}
								}
							}
						}
					},
                    New "Frame" {
                        Name = "Content",
						BackgroundTransparency = 1,
						Size = Computed(function()
							return UDim2.new(1, 0, 1, -topBarHeight:get() - paddingPX:get() * 0.5)
						end),
                        AnchorPoint = Vector2.new(0, 1),
                        Position = UDim2.fromScale(0, 1),

                        [Children] = props[Children]
                    }
				}
			}
		}
	}
end