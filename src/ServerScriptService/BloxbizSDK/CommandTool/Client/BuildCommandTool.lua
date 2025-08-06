local Players = game:GetService("Players")

local CommandTool = script.Parent.Parent
local BloxbizSDK = CommandTool.Parent

local UIComponents = BloxbizSDK.UIComponents
local ScaledText = require(UIComponents.ScaledText)

local UserList = require(script.Parent.UserList)
local CommandList = require(script.Parent.CommandList)

local Fusion = require(BloxbizSDK.Utils.Fusion)

local New = Fusion.New
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Computed = Fusion.Computed

local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

return function(props)
    local isMobile = props.IsMobile
    local selectingUser = props.SelectingUser

    local size = isMobile and UDim2.fromScale(0.55, 0.7) or UDim2.fromScale(0.52, 0.6)
    local position = isMobile and UDim2.fromScale(1, 0.4) or UDim2.fromScale(1, 0.5)

    return New "ScreenGui" {
        Name = "CommandTool",
        Enabled = props.Opened,
        Parent = PlayerGui,
        ResetOnSpawn = false,
        ScreenInsets = Enum.ScreenInsets.None,

        [Children] = {
            New "Frame" {
                Name = "Container",
                Size = size,
                Position = position,
                AnchorPoint = Vector2.new(1, 0.5),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                BackgroundColor3 = Color3.fromRGB(25, 25, 25),

                [Children] = {
                    CommandList(props),

                    Computed(function()
                        return selectingUser:get() and UserList(props) or nil
                    end, Fusion.cleanup),

                    ScaledText {
                        Size = UDim2.fromScale(0.85, 0.07),
                        Position = UDim2.fromScale(0.5, 0.07),
                        AnchorPoint = Vector2.new(0.5, 0),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        RichText = true,

                        Text = Computed(function()
                            return selectingUser:get() and "<b>Select player</b>" or "<b>Commands</b>"
                        end),
                    },

                    New "Frame" {
                        Size = UDim2.fromScale(0.85, 0.07),
                        Position = UDim2.fromScale(0.5, 0.07),
                        AnchorPoint = Vector2.new(0.5, 0),
                        BackgroundTransparency = 1,

                        [Children] = {
                            New "TextButton" {
                                Text = "",
                                Name = "Close",
                                Size = UDim2.fromScale(0.8, 0.8),
                                Position = UDim2.fromScale(1, 0.5),
                                AnchorPoint = Vector2.new(1, 0.5),
                                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                                BackgroundTransparency = 1,

                                [OnEvent "Activated"] = props.Close,

                                [Children] = {
                                    New "ImageLabel" {
                                        Image = "rbxassetid://121362700253178",
                                        Size = UDim2.fromScale(1, 1),
                                        Position = UDim2.fromScale(0.5, 0.5),
                                        AnchorPoint = Vector2.new(0.5, 0.5),
                                        BackgroundTransparency = 1,
                                    },
                                },
                            },
                        },
                    },

                    New "UICorner" {
                        CornerRadius = UDim.new(0.08, 0),
                    },
                },
            },
        },
    }
end