local BloxbizSDK = script.Parent.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local Spring = Fusion.Spring
local OnEvent = Fusion.OnEvent

return function(props)
    props = FusionProps.GetValues(props, {
        Category = "shops",
        Name = "",
        Color = "7f7fa5",
        Items = {},
        OnClick = FusionProps.Nil,
        Pause = false,

        Size = UDim2.fromScale(0, 0),
        Position = UDim2.fromScale(0, 0),
        AnchorPoint = Vector2.new(0, 0),
    })

    local isHovering = Value(false)

    local backgroundColor = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(243, 73, 57)),
        ColorSequenceKeypoint.new(0.384, Color3.fromRGB(253, 84, 250)),
        ColorSequenceKeypoint.new(0.671, Color3.fromRGB(163, 105, 230)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(102, 171, 228))
    }

    return New "TextButton" {
        Name = props.Category,
        Size = props.Size,
        Position = props.Position,
        AnchorPoint = props.AnchorPoint,

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
            props.Controllers:get().TopBarController:SwitchToCategoryOrSearch("shops")
        end,

        [Children] = {
            New "UIGradient" {
                Color = backgroundColor,
                Rotation = 20
            },
            New "UICorner" {
                CornerRadius = UDim.new(0.1, 0)
            },

            New "Frame" {
                Size = UDim2.fromScale(0.9, 0.35),
                Position = UDim2.fromScale(0.5, 0.15),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,

                [Children] = {
                    New "TextLabel" {
                        FontFace = Font.new(
                            "rbxasset://fonts/families/GothamSSm.json",
                            Enum.FontWeight.Medium,
                            Enum.FontStyle.Normal
                        ),
                        Text = "<b>Try Shops</b>",
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

                    New "ImageLabel" {
                        Image = "rbxassetid://134114719141022",
                        Size = UDim2.fromScale(0.9, 0.9),
                        Position = UDim2.fromScale(1, 0.5),
                        AnchorPoint = Vector2.new(1, 0.5),
                        SizeConstraint = Enum.SizeConstraint.RelativeYY,
                        BackgroundTransparency = 1,
                    },
                },
            },

            New "TextLabel" {
                FontFace = Font.new(
                    "rbxasset://fonts/families/GothamSSm.json",
                    Enum.FontWeight.Medium,
                    Enum.FontStyle.Normal
                ),
                Text = "<b>Try Shops</b>",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                RichText = true,
                TextScaled = true,
                TextWrapped = false,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(0.9, 0.35),
                Position = UDim2.fromScale(0.5, 0.15),
                AnchorPoint = Vector2.new(0.5, 0),
            },

            New "TextLabel" {
                FontFace = Font.new(
                    "rbxasset://fonts/families/GothamSSm.json",
                    Enum.FontWeight.Medium,
                    Enum.FontStyle.Normal
                ),
                Text = "<b>Get popular on Popmall</b>",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                RichText = true,
                TextScaled = true,
                TextWrapped = false,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(0.9, 0.18),
                Position = UDim2.fromScale(0.5, 0.6),
                AnchorPoint = Vector2.new(0.5, 0),
            },
        }
    }
end