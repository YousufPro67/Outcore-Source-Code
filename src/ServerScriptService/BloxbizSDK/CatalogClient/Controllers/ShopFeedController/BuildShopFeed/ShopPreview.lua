local BloxbizSDK = script.Parent.Parent.Parent.Parent.Parent

local GroupService = game:GetService("GroupService")

local CatalogClient = BloxbizSDK:WaitForChild("CatalogClient")

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local Components = CatalogClient.Components
local Generic = Components.Generic

local ItemGrid = require(Components.ItemGrid)
local GenericButton = require(Generic.Button)

local ShopInfo = require(script.Parent.ShopInfo)
local Button = require(script.Parent.Button)
local Counter = require(script.Parent.Counter)

local New = Fusion.New
local Value = Fusion.Value
local Cleanup = Fusion.Cleanup
local Children = Fusion.Children
local Computed = Fusion.Computed
local Observer = Fusion.Observer

local camera = workspace.CurrentCamera

local function fillCoverImages(coverImages)
    local requiredCount = 20
    local imageCount = #coverImages

    if imageCount >= requiredCount then
        return coverImages
    end

    local imagesNeeded = requiredCount - imageCount
    local cloneCount = math.min(requiredCount, math.ceil(imagesNeeded / imageCount) + 1)

    local filledImages = {}

    for i = 1, cloneCount do
        for _, image in coverImages do
            table.insert(filledImages, image)
        end
    end

    return filledImages
end

return function (props, shopData)
    local shopId = shopData.guid
    local shopName = shopData.name
    local likes = shopData.up_votes
    local ownLike = shopData.own_like
    local coverImageItems = fillCoverImages(shopData.cover_image_items)

    local likedShops = props.LikedShops

    if not ownLike and likedShops:get()[shopId] then
        likes += 1
    elseif ownLike and not likedShops:get()[shopId] then
        likes -= 1
    end

    local likedShop = Value(likedShops:get()[shopId])
    local likeCount = Value(likes)

    local creator = GroupService:GetGroupInfoAsync(shopData.owner_group)

    local itemGrid = ItemGrid {
        LayoutOrder = 2,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1.3, 1.05),
        Columns = 5,
        ItemRatio = 1/1,
        Gap = 15,
    }

    itemGrid.Rotation = 8

    local scrollingFrame = itemGrid.ScrollingFrame
    scrollingFrame.ScrollingEnabled = false

    local list = itemGrid.ScrollingFrame.Content

    New "UICorner" {
        CornerRadius = UDim.new(0.1, 0),
        Parent = itemGrid,
    }

    for j = 1, 20 do
        New "Frame" {
            Name = "Item" .. j,
            Parent = list,
            BackgroundColor3 = Color3.fromRGB(48, 49, 51),

            [Children] = {
                New "ImageLabel" {
                    Size = UDim2.fromScale(0.8, 0.8),
                    Position = UDim2.fromScale(0.5, 0.5),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Image = string.format("rbxthumb://type=%s&id=%s&w=150&h=150", "Asset", coverImageItems[j] or ""),
                    BackgroundTransparency = 1,
                },

                New "UICorner" {
                    CornerRadius = UDim.new(0.1, 0),
                },
            },
        }
    end

    local function OnClickShop()
        props:OnOpenShop(shopData)
    end

    local likeSignal = Observer(likedShops):onChange(function()
        if not likedShop:get() and likedShops:get()[shopId] then
            likes += 1
        elseif likedShop:get() and not likedShops:get()[shopId] then
            likes -= 1
        end

        likedShop:set(likedShops:get()[shopId])
        likeCount:set(likes)
    end)

    return New "Frame" {
        Name = shopId,
        BackgroundTransparency = 1,

        [Cleanup] = function()
            likeSignal()
            likeSignal = nil
        end,

        [Children] = {
            New "CanvasGroup" {
                Name = "TopFrame",
                Size = UDim2.fromScale(1, 0.825),
                BackgroundTransparency = 1,

                [Children] = {
                    GenericButton {
                        Name = "OpenShop",

                        Size = UDim2.fromScale(1, 1),

                        BackgroundTransparency = {
                            Default = 0,
                            Hover = 0.5,
                            MouseDown = 0.7,
                            Disabled = 0.6,
                        },
                        BackgroundColor3 = Color3.fromRGB(38, 38, 38),

                        CornerRadius = UDim.new(0, 0),

                        Callback = OnClickShop,
                    },

                    itemGrid,

                    New "UICorner" {
                        CornerRadius = UDim.new(0.03, 0),
                    }
                },
            },

            New "Frame" {
                Name = "BottomFrame",
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.fromScale(0, 0.86),
                Size = UDim2.new(1, 0, 0.11, 0),

                [Children] = {
                    GenericButton {
                        Name = "OpenShop",

                        Size = UDim2.fromScale(1, 1),

                        BackgroundTransparency = {
                            Default = 1,
                            Hover = 0.5,
                            MouseDown = 0.7,
                            Disabled = 0.6,
                        },

                        CornerRadius = UDim.new(0, 0),

                        Callback = OnClickShop
                    },

                    ShopInfo {
                        Data = {
                            Icon = shopData.thumbnail,
                            Name = shopName,
                            Creator = creator.Name or "Unknown",
                            Truncate = 23,
                            NameTextSize = camera.ViewportSize.Y / 39,
                        },
                        Size = UDim2.new(1, 0, 1, 0),
                        IconSize = UDim2.fromScale(0.65, 0.65),
                    },

                    New "Frame" {
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.fromScale(1, 0),
                        Size = UDim2.fromScale(0.5, 1),
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
                                LayoutOrder = -3,
                                Icon = "rbxassetid://15234940872",
                                Count = shopData.views or 0,
                                Size = UDim2.fromScale(1, 1)
                            },
                            -- like button
                            Button {
                                LayoutOrder = -2,
                                Icon = "rbxassetid://15234302220",
                                Count = Computed(function()
                                    return likeCount:get()
                                end),

                                IconColor = Computed(function()
                                    return likedShop:get() and Color3.fromRGB(212, 72, 72) or Color3.fromRGB(255, 255, 255)
                                end),

                                OnClick = function()
                                    local isLiked, countAdded = props:OnRateShop(shopId)

                                    --likedShop:set(isLiked)
                                    --likeCount:set(likeCount:get() + countAdded)
                                end,
                            },
                        }
                    }
                }
            }
        },
    }
end