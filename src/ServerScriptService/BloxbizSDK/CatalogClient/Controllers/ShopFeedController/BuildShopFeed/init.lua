local Controllers = script.Parent.Parent
local CatalogClient = Controllers.Parent
local BloxbizSDK = CatalogClient.Parent

local Fusion = require(BloxbizSDK.Utils.Fusion)

local New = Fusion.New
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Computed = Fusion.Computed

local Components = CatalogClient.Components
local ItemGrid = require(Components.ItemGrid)
local EmptyState = require(Components.EmptyState)
local LoadingFrame = require(Components.LoadingFrame)

local ContentFrame = Components.ContentFrame
local Sort = require(ContentFrame.Sort)
local ShopView = require(ContentFrame.ShopFrame)
local CreateShopView = require(ContentFrame.CreateShopFrame)
local EmojiSelector = require(ContentFrame.EmojiSelector)
local ShopsPopUp = require(ContentFrame.ShopsPopUp)

local Utilities = require(ContentFrame.Utilities)
local ScaledText = require(Components.ScaledText)
local CreateShopButton = require(ContentFrame.CreateShop)

return function(props)
    local tabs = props.Tabs
    local loading = props.Loading
    local currentFeed = props.CurrentFeedId
    local selectedShop = props.SelectedShop
    local isEditingShop = props.IsEditingShop
    local isCreatingShop = props.IsCreatingShop
    local parentContainer = props.CatalogContainer.FrameContainer

    local screenGui = parentContainer.Parent.Parent

    local createMode = props.CreateShopMode
    local loadingCreateMode = createMode.Loading
    local selectedName = createMode.SelectedName
    local selectedGroup = createMode.SelectedGroup
    local selectedGroupValue = createMode.SelectedGroupValue
    local selectedItems = createMode.SelectedItems
    local selectedEmoji = createMode.SelectedEmoji
	local selectingEmoji = createMode.SelectingEmoji

    ShopsPopUp {
        Parent = screenGui,
        DisplayProps = props.PopupProps,
    }

    EmojiSelector {
        Parent = screenGui,
        Visible = selectingEmoji,
        SelectedEmoji = selectedEmoji,
    }

    New "TextButton" {
		Name = "BackgroundCover",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(2, 2),
		BackgroundTransparency = 0.5,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		Active = true,
		Selectable = false,
		Text = "",
		Visible = props.EnableBackgroundCover,
        Parent = screenGui,
    }

    return New "Frame" {
		Name = "Shops Feed",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
        Active = true,
		Selectable = false,
		BackgroundTransparency = 1,
        Parent = parentContainer,

        Visible = Computed(function()
            return props.Enabled:get()
        end),

        [Children] = {
            New "UIListLayout" {
                SortOrder = Enum.SortOrder.LayoutOrder,
            },

            CreateShopView({
                Loading = loadingCreateMode,
                SelectedName = selectedName,
                SelectedGroup = selectedGroup,
                SelectedGroupValue = selectedGroupValue,
                SelectedItems = selectedItems,
                SelectedEmoji = selectedEmoji,
                SelectingEmoji = selectingEmoji,

                Visible = Computed(function()
                    return isCreatingShop:get()
                end),
            }, props),

            ShopView({
                Name = "Shop View",
                SelectedShop = selectedShop,

                Visible = Computed(function()
                    if isCreatingShop:get() then
                        return false
                    end

                    return not not selectedShop:get()
                end),

                Button = require(script.Button),
                Counter = require(script.Counter),
                ShopInfo = require(script.ShopInfo),
            }, props),

            Utilities {
                ZIndex = 100,

                Visible = Computed(function()
                    return (not selectedShop:get() or isEditingShop:get())
                end),

                HolderChildren = {
                    CreateShopButton {
                        Text = Computed(function()
                            return isEditingShop:get() and "Update" or "Create shop"
                        end),

                        Visible = Value(true),

                        Callback = function()
                            local newShopData = {
                                Name = selectedName:get(),
                                Group = selectedGroup:get(),
                                Items = selectedItems:get(),
                                Emoji = selectedEmoji:get(),
                            }

                            props:OnCreateShop(newShopData)
                        end,
                    },
                },

                LeftChildren = {
                    Sort {
                        Buttons = Value(tabs),
                        Selected = currentFeed,
                        Cooldown = Value(false),
                        Size = UDim2.fromScale(0.5, 0.85),

                        Padding = 10,
                        UIListLayoutIncluded = true,
                        IgnoreSetFunction = true,

                        Visible = Computed(function()
                            return not isCreatingShop:get()
                        end),

                        OnButtonClick = function(feedId)
                            props:SwitchToFeed(feedId)
                        end,
                    },

                    New "TextButton" {
                        Name = "Back",
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2.new(0, 0.5),
                        Position = UDim2.fromScale(0, 0.5),
                        Size = UDim2.fromScale(0.2, 1),
                        Text = "",

                        Visible = Computed(function()
                            return isCreatingShop:get()
                        end),

                        [OnEvent "Activated"] = function()
                            isEditingShop:set(false)
                            isCreatingShop:set(false)
                            loadingCreateMode:set(false)
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
                                Size = UDim2.fromScale(0.6, 0.8),
								SizeConstraint = Enum.SizeConstraint.RelativeYY,
                                ImageColor3 = Color3.fromRGB(66, 168, 255),
                            },
                            ScaledText {
                                LayoutOrder = 2,
                                Size = UDim2.fromScale(0.5, 0.65),
                                TextXAlignment = Enum.TextXAlignment.Left,
                                Text = "<b>Cancel</b>",
                                TextColor3 = Color3.fromRGB(66, 168, 255),
                                RichText = true,
                            }
                        }
                    },
                },
            },

            ItemGrid {
                Size = UDim2.fromScale(1, 0.925),
                LayoutOrder = 2,

                Gap = 15,
                Columns = 2,
                ItemRatio = 3 / 2.5,

                Visible = Computed(function()
                    --[[if isCreatingShop:get() then
                        return false
                    end]]

                    return not selectedShop:get()
                end),

                ContentVisible = Computed(function()
                    if isCreatingShop:get() then
                        return false
                    end

                    return not loading:get()
                end),

                ScrollingFrameChildren = LoadingFrame {
                    Text = "Loading shops...",
                    Size = UDim2.fromScale(1, 0.9),
                    Visible = loading,
                },
            },

            EmptyState {
                Size = UDim2.fromScale(1, 0.8),
                LayoutOrder = 0,

                Visible = Computed(function()
                    if loading:get() then
                        return false
                    end

                    local feedId = currentFeed:get()
                    if not feedId then
                        return false
                    end

                    local feed = props:GetFeed(feedId)
                    return #feed.GetShops() == 0
                end),

                Text = "There's no shops to show",
                ButtonText = "Clear Search",

                ButtonEnabled = Fusion.Computed(function()
                    local q = props.Controllers.TopBarController.SearchQuery:get()
                    q = q or ""

                    return #q > 0
                end),

                Callback = function()

                end,
            },
        },
	}
end