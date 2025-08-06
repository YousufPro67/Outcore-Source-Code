local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))
local Promise = require(UtilsStorage:WaitForChild("Promise"))

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local ForValues = Fusion.ForValues
local Computed = Fusion.Computed
local Spring = Fusion.Spring
local Out = Fusion.Out
local OnEvent = Fusion.OnEvent

local CatalogClient = BloxbizSDK.CatalogClient
local Components = CatalogClient.Components

local ScaledText = require(Components.ScaledText)
local Carousel = require(script.Parent.Carousel)
local ItemFrame = require(script.Parent.ItemFrame)

return function(props)
    props = FusionProps.GetValues(props, {
        Category = "?",
        Name = "",
        Color = "7f7fa5",
        Items = {},
        CornerRadius = 5,
        TopBarHeight = 30,
        OnClick = FusionProps.Nil,
        Pause = false,
        IsShops = false,
    })

    local padding = Computed(function()
        return UDim.new(0, props.TopBarHeight:get() / 2)
    end)

    local color1 = Computed(function()
        local maybeHexColor = props.Color:get()
        if type(maybeHexColor) ~= "string" then
            return Color3.new(0.6, 0.6, 0.65)
        end

        return Color3.fromHex(maybeHexColor)
    end)
    local color2 = Computed(function()
        local h, s, v = color1:get():ToHSV()

        return Color3.fromHSV((h + 0.08) % 1, s, v * 0.9)
    end)
    local textColor = Computed(function()
        return Utils.getTextColor(color1:get())
    end)

    local isHovering = Value(false)

    local isShops = props.IsShops:get()
    local shopBackgroundColor = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(245, 213, 88)),
        ColorSequenceKeypoint.new(0.313, Color3.fromRGB(255, 85, 85)),
        ColorSequenceKeypoint.new(0.668, Color3.fromRGB(224, 74, 190)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(134, 118, 234))
    }

    return New "TextButton" {
        Name = props.Category,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Spring(Computed(function()
            if not isHovering:get() then
                return Color3.new(1, 1, 1)
            else
                return Color3.new(0.9, 0.9, 0.9)
            end
        end), 30),
        Text = "",

        [OnEvent "MouseEnter"] = function()
            isHovering:set(true)
        end,
        [OnEvent "MouseLeave"] = function()
            isHovering:set(false)
        end,

        [OnEvent "Activated"] = function()
            local cb = props.OnClick:get()
            if cb then
                cb()
            end
        end,

        [Children] = {
            New "UIGradient" {
                Color = isShops and shopBackgroundColor or Computed(function()
                    return ColorSequence.new(color1:get(), color2:get())
                end),
                Rotation = 45
            },
            New "UICorner" {
                CornerRadius = Computed(function() return UDim.new(0, props.CornerRadius:get()) end)
            },
            New "UIPadding" {
                PaddingTop = padding,
                PaddingBottom = padding
            },

            isShops and {
                ScaledText {
                    Size = Computed(function()
                        return UDim2.new(1, -props.TopBarHeight:get()/2, 0, props.TopBarHeight:get())
                    end),
                    Position = UDim2.fromScale(0.5, 0.1),
                    AnchorPoint = Vector2.new(0.5, 0),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextColor3 = textColor,
                    Text = "Shops",
                },

                ScaledText {
                    Size = Computed(function()
                        return UDim2.new(1, -props.TopBarHeight:get()/2, 0, props.TopBarHeight:get() / 2.5)
                    end),
                    Position = UDim2.fromScale(0.5, 0.5),
                    AnchorPoint = Vector2.new(0.5, 0),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextColor3 = textColor,
                    Text = "❤️ support creators",
                },

                ScaledText {
                    Size = Computed(function()
                        return UDim2.new(1, -props.TopBarHeight:get()/2, 0, props.TopBarHeight:get() / 2.5)
                    end),
                    Position = UDim2.new(0.5, 0, 0.5, props.TopBarHeight:get() / 2.2),
                    AnchorPoint = Vector2.new(0.5, 0),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextColor3 = textColor,
                    Text = "💸 create your shop",
                },
            } or {
                ScaledText {
                    Size = Computed(function()
                        return UDim2.new(1, -props.TopBarHeight:get()/2, 0, props.TopBarHeight:get()/2)
                    end),
                    Position = Computed(function()
                        return UDim2.new(0, props.TopBarHeight:get()/2, 0, 0)
                    end),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextColor3 = textColor,
                    Text = props.Name
                },

                Carousel {
                    Position = Computed(function()
                        return UDim2.new(0, 0, 0, props.TopBarHeight:get() * 3/4)
                    end),
                    Size = Computed(function()
                        return UDim2.new(1, 0, 1, -props.TopBarHeight:get() * 3/4)
                    end),

                    Items = ForValues(props.Items, function (item)
                        return ItemFrame {
                            ItemId = item.id,
                            IsBundle = item.itemType ~= "Asset"
                        }
                    end, Fusion.cleanup),
                    ItemRatio = 1,
                    Pause = props.Pause
                },
            },
        }
    }
end