local Controllers = script.Parent.Parent
local CatalogClient = Controllers.Parent
local BloxbizSDK = CatalogClient.Parent

local UtilsStorage = BloxbizSDK:WaitForChild("Utils")
local Utils = require(UtilsStorage)

local AvatarHandler = require(script.Parent.Parent.Parent.Classes:WaitForChild("AvatarHandler"))
local InventoryHandler = require(script.Parent.Parent.Parent.Classes:WaitForChild("InventoryHandler"))

local Fusion = require(BloxbizSDK.Utils.Fusion)

local New = Fusion.New
local Out = Fusion.Out
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Computed = Fusion.Computed
local ForPairs = Fusion.ForPairs

local Components = CatalogClient.Components
local CatalogItem = require(Components.CatalogItem)

local ShopsButton = require(script.ShopsButton)

local function Break(Size)
    return New "Frame" {
        Name = "LineBreak",
        Size = UDim2.fromScale(0, Size),
        SizeConstraint = Enum.SizeConstraint.RelativeXX,
    }
end

local function Header(controllers)
    return New "Frame" {
        Name = "Top",
        Size = UDim2.fromScale(1, 0.2),
        SizeConstraint = Enum.SizeConstraint.RelativeXX,
        BackgroundTransparency = 1,
        LayoutOrder = -9999999,

        [Children] = {
            ShopsButton {
                Size = UDim2.fromScale(0.35, 0.65),
                Position = UDim2.fromScale(1, 0.5),
                AnchorPoint = Vector2.new(1, 0.5),
                Controllers = controllers,
            },

            New "ImageLabel" {
                Name = "Logo",
                Image = "rbxassetid://14555107778",
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0, 0.2),
                Size = UDim2.fromScale(0.275, 0.275),

                [Children] = {
                    New "UIAspectRatioConstraint" {
                        Name = "UIAspectRatioConstraint",
                        AspectRatio = 902 / 190,  -- logo dimensions
                        DominantAxis = Enum.DominantAxis.Height,
                    },
                },
            },

            New "TextLabel" {
                Name = "Info",
                FontFace = Font.new(
                    "rbxasset://fonts/families/GothamSSm.json",
                    Enum.FontWeight.Bold,
                    Enum.FontStyle.Normal
                ),
                Text = "Explore categories, try-on items, and build outfits.",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                TextSize = 14,
                TextWrapped = false,
                TextXAlignment = Enum.TextXAlignment.Left,
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0, 0.6),
                Size = UDim2.new(0.7, 0, 0.12, 0),
            },

            New "TextLabel" {
                Name = "Info",
                FontFace = Font.new(
                    "rbxasset://fonts/families/GothamSSm.json",
                    Enum.FontWeight.Bold,
                    Enum.FontStyle.Normal
                ),
                Text = "Purchase items to use in all experiences.",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                TextSize = 14,
                TextWrapped = false,
                TextXAlignment = Enum.TextXAlignment.Left,
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0, 0.725),
                Size = UDim2.new(0.7, 0, 0.12, 0),
            },
        },
    }
end

local function getDisplayItems(items)
    local itemDetailsMap = InventoryHandler.GetBatchItemDetails(
        Utils.map(items, function(item) return item.id end)
    )
    local count = 1
    local rawItems = {}
    for _, item in itemDetailsMap do
        if count > 4 then
            break
        end
        count += 1

        table.insert(rawItems, AvatarHandler.BuildItemData(item))
    end

    return rawItems
end

local function CategoryFrame(category, props, SelectedItem)
    local AvatarPreviewController = props.Controllers.AvatarPreviewController

    local name = category.name
    local items = category.items

    local itemList = Value({})

    task.spawn(function()
        itemList:set(getDisplayItems(items))
    end)

    return New "Frame" {
        Name = name,
        Size = UDim2.fromScale(1, 0.36),
        SizeConstraint = Enum.SizeConstraint.RelativeXX,
        LayoutOrder = -category.priority or 1,
        BackgroundTransparency = 1,

        [Children] = {
            New "UIListLayout" {
                SortOrder = Enum.SortOrder.LayoutOrder,
            },

            New "TextButton" {
                Text = "",
                Size = UDim2.fromScale(1, 0.1),
                BackgroundTransparency = 1,

                [OnEvent "Activated"] = function()
                    props.Controllers.TopBarController:SwitchToCategoryOrSearch(name)
                end,

                [Children] = {
                    New "UIListLayout" {
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        FillDirection = Enum.FillDirection.Horizontal,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    },

                    New "TextLabel" {
                        Name = "Info",
                        FontFace = Font.new(
                            "rbxasset://fonts/families/GothamSSm.json",
                            Enum.FontWeight.Medium,
                            Enum.FontStyle.Normal
                        ),
                        Text = "<b>" .. name .. "</b>",
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        RichText = true,
                        TextScaled = true,
                        TextWrapped = false,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(0, 1),
                        AutomaticSize = Enum.AutomaticSize.X,
                    },

                    New "Frame" {
                        Name = "LineBreak",
                        Size = UDim2.fromScale(0.01, 0),
                        SizeConstraint = Enum.SizeConstraint.RelativeXX,
                    },

                    New "ImageLabel" {
                        Image = "rbxassetid://134114719141022",
                        Size = UDim2.fromScale(0.9, 0.9),
                        SizeConstraint = Enum.SizeConstraint.RelativeYY,
                        BackgroundTransparency = 1,
                        ImageTransparency = 0.8,
                    },
                },
            },

            Break(0.009),

            New "Frame" {
                Size = UDim2.fromScale(1, 0.875),
                BackgroundTransparency = 1,

                [Children] = {
                    New "UIListLayout" {
                        Padding = UDim.new(0.01, 0),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        FillDirection = Enum.FillDirection.Horizontal,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                    },

                    ForPairs(itemList, function(itemIndex, item)
                        return itemIndex, CatalogItem({
                            Size = UDim2.fromScale(0.243, 0.928),
                            SizeConstraint = Enum.SizeConstraint.RelativeXY,
                            Color = category.bg_color,
                            ItemData = item,
                            SelectedId = SelectedItem,
                            CategoryName = Value("Homepage_" .. name),
                            AvatarPreviewController = AvatarPreviewController,

                            OnTry = function()
                                AvatarPreviewController:AddChange(item, "CoinShop")
                            end,
                        })
                    end, Fusion.cleanup),
                },
            },
        }
    }
end

return function(props)
    local categories = props.Categories
    local controllers = props.Controllers
    local parentContainer = props.Container

    local ContentSize = Value(Vector2.zero)
    local SelectedItem = Value()

    return New "ScrollingFrame" {
        Parent = parentContainer,
		Name = "Container",
		Size = UDim2.new(1, -1, 1, 0),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,

        CanvasSize = Computed(function()
            return UDim2.fromOffset(0, ContentSize:get().Y)
        end),

        Visible = Computed(function()
            return #categories:get() > 0
        end),

        [Children] = {
            New "UIListLayout" {
                SortOrder = Enum.SortOrder.LayoutOrder,

                [Out "AbsoluteContentSize"] = ContentSize,
            },

            Header(controllers),

            ForPairs(categories, function(index, category)
                return index, CategoryFrame(category, props, SelectedItem)
            end, Fusion.cleanup),
        },
	}
end