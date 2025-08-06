local TextService = game:GetService("TextService")

local BloxbizSDK = script.Parent.Parent.Parent.Parent.Parent
local CatalogClient = BloxbizSDK:WaitForChild("CatalogClient")

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FP = require(UtilsStorage:WaitForChild("FusionProps"))

local Components = CatalogClient.Components

local ScaledText = require(Components.ScaledText)

local Children = Fusion.Children
local New = Fusion.New
local Computed = Fusion.Computed
local Cleanup = Fusion.Cleanup
local Value = Fusion.Value
local Out = Fusion.Out

return function (props)
    props = FP.GetValues(props, {
        Parent = FP.Nil,
        AnchorPoint = Vector2.zero,
        Position = UDim2.fromScale(0, 0),
        Size = UDim2.fromScale(1, 1),

        Data = FP.Required
    })

    local data = props.Data:get()

    local secondaryText
    if data.Creator or data.ItemCount then
        secondaryText = data.Creator and "By @" .. data.Creator or data.ItemCount .. " items"
    end

    local _containerSize = Value(Vector2.zero)
    local containerSize = Computed(function()
        return _containerSize:get() or Vector2.zero
    end)

    local shopName = data.Name
    local truncateAt = data.Truncate
    if truncateAt then
        if #shopName > truncateAt then
            shopName = shopName:sub(0, truncateAt) .. "..."
        end
    end

    return New "Frame" {
        Name = "ShopInfo",

        Parent = props.Parent,
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        Size = props.Size,
        BackgroundTransparency = 1,

        [Out "AbsoluteSize"] = _containerSize,

        [Cleanup] = function()
            --Fusion.cleanup(sig)
        end,

        [Children] = {
            New "UIListLayout" {
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,

                Padding = Computed(function()
                    return UDim.new(0, containerSize:get().Y / 4)
                end)
            },

            -- pfp
            New "Frame" {
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(54, 59, 68),

                [Children] = {
                    New "UICorner" {
                        CornerRadius = UDim.new(0.2, 0),
                    },
                    New "UIAspectRatioConstraint" {
                        AspectRatio = 1,
                        DominantAxis = Enum.DominantAxis.Height
                    },

                    ScaledText {
                        Position = UDim2.fromScale(0.5, 0.5),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Size = props.IconSize or UDim2.fromScale(0.8, 0.8),
                        Text = data.Icon,
                    },
                }
            },

            -- names
            New "Frame" {
                BackgroundTransparency = 1,
                LayoutOrder = 2,
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.fromScale(0.5, 0.85),

                [Children] = {
                    -- shop name
                    New "TextLabel" {
                        Text = shopName,
                        Font = Enum.Font.GothamMedium,
                        Size = props.TopLabelSize or UDim2.fromScale(1, 0.5),
                        TextColor3 = Color3.new(1, 1, 1),
                        BackgroundTransparency = 1,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextSize = data.NameTextSize,
                    },

                    -- item count
                    secondaryText and ScaledText {
                        AnchorPoint = Vector2.new(0, 1),
                        Position = UDim2.fromScale(0, 1),
                        Size = props.BottomLabelSize or UDim2.fromScale(1, 0.4),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Text = secondaryText,
                        TextColor3 = Color3.new(0.7, 0.7, 0.7)
                    } or nil,
                }
            }
        }
    }
end