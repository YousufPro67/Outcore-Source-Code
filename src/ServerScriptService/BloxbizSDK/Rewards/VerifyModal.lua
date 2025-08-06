local Players = game:GetService("Players")

local BloxbizSDK = script.Parent.Parent
local UtilsFolder = BloxbizSDK:WaitForChild("Utils")
local Utils = require(UtilsFolder)
local Net = require(UtilsFolder:WaitForChild("Net"))
local FP = require(UtilsFolder:WaitForChild("FusionProps"))

local Components = require(BloxbizSDK.CatalogClient.Components)

local Fusion = require(UtilsFolder:WaitForChild("Fusion"))
local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local Ref = Fusion.Ref
local OnEvent = Fusion.OnEvent
local Out = Fusion.Out

return function ()
    local modalRef = Value()
    
    local function onClose()
        Fusion.cleanup(modalRef:get())
    end

    local absSize = Value(Vector2.new())
    local paddingX = Computed(function()
        return UDim.new(0, absSize:get() and absSize:get().Y * 0.08)
    end)
    local paddingY = Computed(function()
        return UDim.new(0, absSize:get() and absSize:get().Y * 0.05)
    end)

    return New "ScreenGui" {
        [Ref] = modalRef,

        Name = "UnlockablesVerifyModal",
        Parent = Players.LocalPlayer.PlayerGui,

        [Children] = New "Frame" {
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromScale(0.7, 0.7),
            BackgroundColor3 = Color3.fromRGB(20, 16, 15),

            [Out "AbsoluteSize"] = absSize,

            [Children] = {
                New "UIAspectRatioConstraint" {
                    AspectRatio = 1.3,
                    AspectType = Enum.AspectType.FitWithinMaxSize,
                },
                New "UICorner" {
                    CornerRadius = UDim.new(0.1, 0)
                },
                New "TextButton" {
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.fromScale(1, 0),
                    Size = UDim2.fromScale(0.2, 0.2),
                    BackgroundTransparency = 1,
                    [OnEvent "MouseButton1Click"] = onClose,
                    [Children] = {
                        New "UIAspectRatioConstraint" {
                            AspectRatio = 1,
                            AspectType = Enum.AspectType.FitWithinMaxSize,
                        },
                        Components.ScaledText {
                            Text = "X",
                            Position = UDim2.fromScale(0.5, 0.5),
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Size = UDim2.fromScale(0.5, 0.5),
                        }
                    }
                },

                New "Frame" {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    [Children] = {
                        New "UIPadding" {
                            PaddingTop = paddingY,
                            PaddingBottom = paddingY,
                            PaddingLeft = paddingX,
                            PaddingRight = paddingX,
                        },
                        New "UIListLayout" {
                            VerticalFlex = Enum.UIFlexAlignment.SpaceEvenly,
                            ItemLineAlignment = Enum.ItemLineAlignment.Center,
                            SortOrder = Enum.SortOrder.LayoutOrder,
                        },

                        Components.ScaledText {
                            LayoutOrder = 1,
                            Name = "Heading",
                            Size = UDim2.fromScale(1, 0.1),
                            Text = "Verify it's you",
                            Font = Enum.Font.GothamBold,
                        },

                        New "ImageLabel" {
                            LayoutOrder = 2,
                            Name = "Logo",
                            Image = "rbxassetid://92462163495378",
                            Size = UDim2.fromScale(0.3, 0.3),
                            BackgroundTransparency = 1,
                            [Children] = New "UIAspectRatioConstraint" {
                                AspectRatio = 1,
                                AspectType = Enum.AspectType.FitWithinMaxSize,
                            },
                        },

                        Components.ScaledText {
                            LayoutOrder = 3,
                            Name = "Statement",
                            Size = UDim2.fromScale(1, 0.07),
                            Text = "Unlockables wants to verify your account.",
                        },

                        New "TextButton" {
                            LayoutOrder = 4,
                            Name = "Confirm",
                            BackgroundColor3 = Color3.fromRGB(245, 213, 85),
                            Text = "",
                            Size = UDim2.fromScale(1, 0.15),

                            [OnEvent "MouseButton1Click"] = function()
                                Net:RemoteEvent("UnlockablesVerifyComplete"):FireServer()
                                onClose()
                            end,

                            [Children] = {
                                New "UICorner" {
                                    CornerRadius = UDim.new(0.5, 0)
                                },
                                Components.ScaledText {
                                    Position = UDim2.fromScale(0.5, 0.5),
                                    AnchorPoint = Vector2.new(0.5, 0.5),
                                    Size = UDim2.fromScale(0.9, 0.4),
                                    TextColor3 = Color3.new(),
                                    Text = "Yes, it's me",
                                }
                            }
                        },

                        New "TextButton" {
                            LayoutOrder = 5,
                            Name = "Ignore",
                            BackgroundColor3 = Color3.fromRGB(46, 50, 57),
                            Text = "",
                            Size = UDim2.fromScale(1, 0.15),

                            [OnEvent "MouseButton1Click"] = onClose,

                            [Children] = {
                                New "UICorner" {
                                    CornerRadius = UDim.new(0.5, 0)
                                },
                                Components.ScaledText {
                                    Position = UDim2.fromScale(0.5, 0.5),
                                    AnchorPoint = Vector2.new(0.5, 0.5),
                                    Size = UDim2.fromScale(0.9, 0.4),
                                    Text = "Ignore",
                                }
                            }
                        },
                    }
                }
            }
        }
    }
end