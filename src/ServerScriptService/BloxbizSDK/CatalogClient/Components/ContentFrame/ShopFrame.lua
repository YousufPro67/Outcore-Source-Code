local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local New = Fusion.New
local Ref = Fusion.Ref
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Observer = Fusion.Observer
local Children = Fusion.Children
local Computed = Fusion.Computed

local Components = script.Parent.Parent
local ScrollingFrame = require(Components.Generic.ScrollingFrame)
local LoadingFrame = require(Components.LoadingFrame)
local ScaledText = require(Components.ScaledText)

local camera = workspace.CurrentCamera

return function(shopProps, props)
	local selectedShop = shopProps.SelectedShop

	local ShopInfo = shopProps.ShopInfo
	local Button = shopProps.Button
	local Counter = shopProps.Counter

	local likedShops = props.LikedShops

	local likedShop = Value()
	local likeCount = Value(0)

	local loading = Value()
	local itemHolder = Value()
	local loadDebounce = false

	local scrollProps = {
		Visible = Computed(function()
			return not loading:get()
		end),

        Size = UDim2.fromScale(1, 0.85),
        Position = UDim2.fromScale(0, 0),
        AnchorPoint = Vector2.new(0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        DragScrollDisabled = true,

        Layout = {
            Type = "UIGridLayout",
            FillDirection = Enum.FillDirection.Horizontal,

            Size = UDim2.fromScale(0.243, 0.3),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim2.fromScale(0.009, 0.012),
        },

		[Ref] = itemHolder,

		OnCanvasPositionChange = function()
			local itemFrame = itemHolder:get()
			if not itemFrame then
				return
			end

			local scrollingFrame = itemFrame.Parent

			if not props.CurrentFeedId:get() then
				return
			end

			local passedThreshold = math.round(scrollingFrame.CanvasPosition.Y)
				>= math.round(scrollingFrame.AbsoluteCanvasSize.Y - scrollingFrame.AbsoluteWindowSize.Y) * 0.7
			if passedThreshold then
				if not loadDebounce then
					loadDebounce = true

					local shop = selectedShop:get()
					if not shop or shop.LoadedAll then
						loadDebounce = nil
						return
					end

					shop:LoadNextPage():await()

					loadDebounce = nil
				end
			end
		end,
    }

	local function loadShop()
		local shop = selectedShop:get()
		if not shop then
			return
		end

		loading:set(true)
		shop:LoadItems(loading)

		local shopId = shop.Id
		local likes = shop.Data.up_votes
		local ownLike = shop.Data.own_like

		if not ownLike and likedShops:get()[shopId] then
			likes += 1
		elseif ownLike and not likedShops:get()[shopId] then
			likes -= 1
		end

		likedShop:set(likedShops:get()[shopId])
		likeCount:set(likes)
    end

    local selectedShopSignal = Observer(selectedShop):onChange(loadShop)

    return New "Frame" {
		Name = shopProps.Name or "Frame",
		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Selectable = false,
		Size = UDim2.fromScale(1, 1),
		Parent = shopProps.Parent,
		Visible = shopProps.Visible,

        [Fusion.Cleanup] = function()
            Fusion.cleanup(selectedShopSignal)
        end,

        [Children] = {
			Fusion.New("UIListLayout")({
				Name = "UIListLayout",
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

            New "Frame" {
				Name = "Header",
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0.05),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,

                [Children] = {
                    -- back button.
                    New "TextButton" {
                        Name = "Back",
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2.new(0, 0.5),
                        Position = UDim2.fromScale(0, 0.5),
                        Size = UDim2.fromScale(0.2, 1),
                        Text = "",

                        [OnEvent "Activated"] = function()
							local shop = selectedShop:get()
							if not shop then
								return
							end

							shop:Close()
                        end,

                        [Children] = {
                            New "UIListLayout" {
                                Padding = UDim.new(0.05, 0),
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                FillDirection = Enum.FillDirection.Horizontal,
                            },
                            New "ImageLabel" {
                                BackgroundTransparency = 1,
                                Image = "rbxassetid://15103716412",
                                Size = UDim2.fromScale(0.5, 0.55),
								SizeConstraint = Enum.SizeConstraint.RelativeYY,
                            },
                            ScaledText {
                                LayoutOrder = 2,
                                Size = UDim2.fromScale(0.5, 0.425),
                                TextXAlignment = Enum.TextXAlignment.Left,
                                Text = "All Shops",
                            }
                        }
                    },
                }
            },

			New "Frame" {
				Name = "TopBar",
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0.065),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,

				[Children] = {
					Computed(function()
						local shop = selectedShop:get()

						return shop and ShopInfo {
							Data = {
								Icon = shop.Data.thumbnail,
								Name = shop.Data.name,
								Creator = shop.Creator,
								NameTextSize = camera.ViewportSize.Y / 30,
							},

							Size = UDim2.new(1, 0, 1, 0),
							IconSize = UDim2.fromScale(0.65, 0.65),
							BackgroundColor3 = Color3.fromRGB(41, 43, 48),
							TopLabelSize = UDim2.fromScale(1, 0.55),
							BottomLabelSize = UDim2.fromScale(1, 0.325)
						} or nil
					end, Fusion.cleanup),

					New "Frame" {
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.fromScale(1, 0.5),
						Size = UDim2.fromScale(0.5, 0.7),
						BackgroundTransparency = 1,

						[Children] = {
							New "UIListLayout" {
								Padding = UDim.new(0.04, 0),
								FillDirection = Enum.FillDirection.Horizontal,
								SortOrder = Enum.SortOrder.LayoutOrder,
								VerticalAlignment = Enum.VerticalAlignment.Center,
								HorizontalAlignment = Enum.HorizontalAlignment.Right,
							},
							New "UIPadding" {
								PaddingRight = UDim.new(0, 1)
							},
							-- impressions count
							Counter {
								Text = "Views",
								LayoutOrder = -3,
								Icon = "rbxassetid://15234940872",
								Size = UDim2.fromScale(1, 1),

								Count = Computed(function()
									local shop = selectedShop:get()
									return shop and shop.Data.views or 0
								end),
							},
							-- like button
							Button {
								Text = "Likes",
								LayoutOrder = -2,
								Icon = "rbxassetid://15234302220",

                                IconColor = Computed(function()
                                    return likedShop:get() and Color3.fromRGB(212, 72, 72) or Color3.fromRGB(255, 255, 255)
                                end),

								Count = Computed(function()
									return likeCount:get()
								end),

								OnClick = function()
									local shop = selectedShop:get()
									if not shop then
										return
									end

									local shopId = shop.Id
									local isLiked, countAdded = props:OnRateShop(shopId)

                                    likedShop:set(isLiked)
                                    likeCount:set(likeCount:get() + countAdded)
								end,
							},

							-- edit button
							Button {
								Text = "Edit",
								LayoutOrder = -1,
								Icon = "rbxassetid://98756777169788",

								Visible = Computed(function()
									local shop = selectedShop:get()
									if not shop then
										return false
									end

									return shop.Data.can_edit
								end),

								OnClick = function()
									props:ToggleShopEditMode(true)
								end,
							},
						}
					}
				},
			},

			New "Frame" {
				Name = "Space",
				Size = UDim2.fromScale(0, 0.01),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			},

            New "Frame" {
                Name = "Content",
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),

                [Children] = {
                    LoadingFrame {
                        Visible = loading
                    },

					ScrollingFrame(scrollProps),
                }
            }
        }
    }
end
