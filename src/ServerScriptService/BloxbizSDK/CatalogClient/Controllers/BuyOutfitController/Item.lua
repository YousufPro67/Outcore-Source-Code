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
local Spring = Fusion.Spring
local OnEvent = Fusion.OnEvent

local CatalogClient = BloxbizSDK:WaitForChild("CatalogClient")
local Components = CatalogClient.Components
local ScaledText = require(Components.ScaledText)

return function (props)
    props = FP.GetValues(props, {
        Parent = FP.Nil,
        LayoutOrder = 0,

        AssetId = FP.Required,
        IsBundle = false,
        IsPurchased = FP.Required,
        IsForSale = FP.Required,
        Price = FP.Required,
        Name = "Some Asset",

        OnClick = FP.Callback
    })

    local isHovering = Value(false)

    return New "CanvasGroup" {
        Parent = props.Parent,
        Name = props.Name,
        LayoutOrder = props.LayoutOrder,

        BackgroundColor3 = Color3.fromHex("373B43"),
        GroupColor3 = Spring(Computed(function()
            if isHovering:get() then
                return Color3.new(0.85, 0.85, 0.85)
            else
                return Color3.new(1, 1, 1)
            end
        end), 30),

        [Children] = {
            New "UICorner" {
                CornerRadius = UDim.new(0, 8)
            },
            New "TextButton" {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Active = true,
                ZIndex = 10,

                [OnEvent "MouseEnter"] = function () isHovering:set(true) end,
                [OnEvent "MouseLeave"] = function () isHovering:set(false) end,
                [OnEvent "Activated"] = function()
                    props.OnClick:get()()
                end,

                [Children] = {
                    -- thumbnail
                    New "ImageLabel" {
                        Size = UDim2.fromScale(1, 0.75),
                        BackgroundTransparency = 1,
                        Image = Computed(function()
                            return string.format("rbxthumb://type=%s&id=%s&w=150&h=150", props.IsBundle:get() and "BundleThumbnail" or "Asset", props.AssetId:get())
                        end),
                        ScaleType = Enum.ScaleType.Crop
                    },

                    -- info bar
                    New "Frame" {
                        AnchorPoint = Vector2.new(0, 1),
                        Position = UDim2.fromScale(0, 1),
                        Size = UDim2.fromScale(1, 0.25),
                        BackgroundTransparency = 1,

                        [Children] = {
                            New "UIPadding" {
                                PaddingLeft = UDim.new(0.05, 0),
                                PaddingRight = UDim.new(0.05, 0),
                                PaddingTop = UDim.new(0.05, 0),
                                PaddingBottom = UDim.new(0.1, 0)
                            },

                            ScaledText {
                                Position = UDim2.fromScale(0, 0.05),
                                Size = UDim2.fromScale(0.95, 0.4),
                                TextXAlignment = Enum.TextXAlignment.Left,
                                Text = props.Name
                            },

                            New "Frame" {
                                AnchorPoint = Vector2.new(0, 1),
                                Position = UDim2.fromScale(0, 1),
                                Size = UDim2.fromScale(1, 0.5),
                                BackgroundTransparency = 1,
                                [Children] = {
                                    New "UIListLayout" {
                                        FillDirection = Enum.FillDirection.Horizontal,
                                        HorizontalAlignment = Enum.HorizontalAlignment.Left,
                                        VerticalAlignment = Enum.VerticalAlignment.Center,
                                        SortOrder = Enum.SortOrder.LayoutOrder,
                                        Padding = UDim.new(0.02, 0)
                                    },

                                    -- item is for sale - show robux price
                                    Computed(function()
                                        if not props.IsPurchased:get() and props.IsForSale:get() then
                                            local price = props.Price:get()
                                            if price > 0 then
                                                price = Utils.toLocaleNumber(price)
                                            else
                                                price = "Free"
                                            end

                                            return {
                                                New "ImageLabel" {
                                                    LayoutOrder = 1,
                                                    BackgroundTransparency = 1,

                                                    Image = "rbxassetid://15252350653",
                                                    Size = UDim2.fromScale(0.7, 0.7),
                                                    [Children] = New "UIAspectRatioConstraint" {
                                                        AspectRatio = 1,
                                                        DominantAxis = Enum.DominantAxis.Height
                                                    }
                                                },

                                                ScaledText {
                                                    LayoutOrder = 2,
                                                    TextXAlignment = Enum.TextXAlignment.Left,
                                                    Size = UDim2.fromScale(0.8, 0.7),
                                                    Text = price
                                                }
                                            }
                                        end
                                    end, Fusion.cleanup),

                                    -- item is owned - show owned check mark
                                    Computed(function()
                                        if props.IsPurchased:get() then
                                            return {
                                                New "ImageLabel" {
                                                    LayoutOrder = 1,
                                                    BackgroundTransparency = 1,
                                                    Image = "rbxassetid://15252505604",
                                                    ImageColor3 = Color3.fromHex("#22c55e"),

                                                    Size = UDim2.fromScale(0.7, 0.7),
                                                    [Children] = New "UIAspectRatioConstraint" {
                                                        AspectRatio = 1,
                                                        DominantAxis = Enum.DominantAxis.Height
                                                    }
                                                },

                                                ScaledText {
                                                    LayoutOrder = 2,
                                                    TextXAlignment = Enum.TextXAlignment.Left,
                                                    Size = UDim2.fromScale(0.8, 0.7),
                                                    Text = "Owned",
                                                    TextColor3 = Color3.fromHex("#22c55e"),
                                                }
                                            }
                                        end
                                    end, Fusion.cleanup),

                                    -- item is not for sale
                                    Computed(function()
                                        if not props.IsForSale:get() and not props.IsPurchased:get() then
                                            return {
                                                -- New "ImageLabel" {
                                                --     LayoutOrder = 1,
                                                --     BackgroundTransparency = 1,
                                                --     Image = "rbxassetid://15252505604",
                                                --     ImageColor3 = Color3.fromHex("#22c55e"),

                                                --     Size = UDim2.fromScale(0.7, 0.7),
                                                --     [Children] = New "UIAspectRatioConstraint" {
                                                --         AspectRatio = 1,
                                                --         DominantAxis = Enum.DominantAxis.Height
                                                --     }
                                                -- },

                                                ScaledText {
                                                    LayoutOrder = 2,
                                                    TextXAlignment = Enum.TextXAlignment.Left,
                                                    Size = UDim2.fromScale(0.8, 0.7),
                                                    Text = "Not For Sale",
                                                    TextColor3 = Color3.new(0.75, 0.75, 0.75),
                                                }
                                            }
                                        end
                                    end, Fusion.cleanup),
                                }
                            }
                        }
                    }
                }
            }
        }
    }
end