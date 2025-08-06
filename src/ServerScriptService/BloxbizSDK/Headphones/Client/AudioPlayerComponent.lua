local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Fusion = require(script.Parent.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Ref = Fusion.Ref
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Computed = Fusion.Computed

local Player = Players.LocalPlayer

local TouchEnabled = UserInputService.TouchEnabled
local KeyboardEnabled = UserInputService.KeyboardEnabled

local IsOnMobile = TouchEnabled == true and KeyboardEnabled == false

return function(props)
    local ICONS = props.ICONS

	local font = Font.fromEnum(Enum.Font.SourceSans)
	local fontBold = Font.fromEnum(Enum.Font.SourceSans)
	fontBold.Bold = true

    local cornerRadius = IsOnMobile and 4 or 9

    local audio = props.AudioInstance

    local container = Value()
    local barSize = Value(UDim2.new(0, 0, 1, 0))
    local timePosition = Value(0)
    local isPaused = Value(false)

    audio.Paused:Connect(function()
        isPaused:set(true)
    end)

    audio.Resumed:Connect(function()
        isPaused:set(false)
    end)

    audio.Played:Connect(function()
        isPaused:set(false)
    end)

    RunService.RenderStepped:Connect(function()
        timePosition:set(audio.TimePosition)
    end)

    task.defer(function()
        local x = container:get().AbsoluteSize.X

        barSize:set(UDim2.new(0, x, 1, 0))
    end)

    return New "ScreenGui"{
        Name = "HeadphonesAudioPlayer",
        Enabled = true,
        DisplayOrder = 0,
        ResetOnSpawn = false,
        Parent = Player:WaitForChild("PlayerGui"),

        [Children] = {
            New "Frame" {
                Name = "Container",
                Size = UDim2.fromScale(0.375, 0.08),
                Position = UDim2.new(1, -12, 0, 12),
                AnchorPoint = Vector2.new(1, 0),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.5,
                Active = false,

                [Ref] = container,

                [Children] = {
                    New "Frame" {
                        Name = "ProgressBar",
                        Position = UDim2.fromScale(0, 1),
                        AnchorPoint = Vector2.new(0, 1),
                        BackgroundTransparency = 1,
                        ClipsDescendants = true,

                        Size = Computed(function()
                            return UDim2.fromScale(timePosition:get() / audio.TimeLength, 1)
                        end),

                        [Children] = {
                            New "Frame" {
                                Name = "Bar",
                                Position = UDim2.fromScale(0, 1),
                                AnchorPoint = Vector2.new(0, 1),

                                Size = Computed(function()
                                    return barSize:get()
                                end),

                                [Children] = {
                                    New "UIGradient" {
                                        Rotation = 90,
                                        Transparency = NumberSequence.new{
                                            NumberSequenceKeypoint.new(0, 1),
                                            NumberSequenceKeypoint.new(0.92, 1),
                                            NumberSequenceKeypoint.new(0.921, 0),
                                            NumberSequenceKeypoint.new(1, 0),
                                        },
                                    },

                                    New "UICorner" {
                                        CornerRadius = UDim.new(0, cornerRadius),
                                    },
                                },
                            },
                        },
                    },

                    New "Frame" {
                        Name = "Content",
                        Size = UDim2.fromScale(1, 0.6),
                        Position = UDim2.fromScale(0.5, 0.45),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,

                        [Children] = {
                            New "UIListLayout" {
                                Padding = UDim.new(0, 0),
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                FillDirection = Enum.FillDirection.Horizontal,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                            },

                            --[[New "Frame" {
                                Name = "BlankSpace",
                                Size = UDim2.fromScale(0.2, 0),
                                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                                LayoutOrder = 0,
                            },

                            New "ImageLabel" {
                                Name = "Icon",
                                Size = UDim2.fromScale(1.1, 1.1),
                                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                                BackgroundTransparency = 1,
                                LayoutOrder = 1,
                                Image = "rbxassetid://17732184286",
                            },]]

                            New "Frame" {
                                Name = "BlankSpace",
                                Size = UDim2.fromScale(0.6, 0),
                                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                                LayoutOrder = 2,
                            },

                            New "Frame" {
                                Name = "Labels",
                                Size = UDim2.fromScale(3.646, 1),
                                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                                BackgroundTransparency = 1,
                                LayoutOrder = 3,

                                [Children] = {
                                    New "UIListLayout" {
                                        Padding = UDim.new(0, 0),
                                        SortOrder = Enum.SortOrder.LayoutOrder,
                                        FillDirection = Enum.FillDirection.Vertical,
                                        VerticalAlignment = Enum.VerticalAlignment.Top,
                                        HorizontalAlignment = Enum.HorizontalAlignment.Left,
                                    },

                                    New "TextLabel" {
                                        Name = "SongName",
                                        Size = UDim2.fromScale(1, 0.55),
                                        TextColor3 = Color3.fromRGB(255, 255, 255),
                                        TextXAlignment = Enum.TextXAlignment.Left,
                                        BackgroundTransparency = 1,
                                        TextScaled = true,
                                        FontFace = fontBold,

                                        Text = Computed(function()
                                            local audioData = props.PlayedAudioData:get()
                                            if not audioData then
                                                return "Loading..."
                                            end

                                            return audioData.SongName
                                        end),
                                    },

                                    New "TextLabel" {
                                        Name = "ArtistName",
                                        Size = UDim2.fromScale(1, 0.45),
                                        TextColor3 = Color3.fromRGB(255, 255, 255),
                                        TextXAlignment = Enum.TextXAlignment.Left,
                                        BackgroundTransparency = 1,
                                        TextScaled = true,
                                        FontFace = font,

                                        Text = Computed(function()
                                            local audioData = props.PlayedAudioData:get()
                                            if not audioData then
                                                return "Loading..."
                                            end

                                            return audioData.Artist
                                        end),
                                    },
                                },
                            },

                            New "Frame" {
                                Name = "BlankSpace",
                                Size = UDim2.fromScale(1.1, 0),
                                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                                LayoutOrder = 4,
                            },

                            New "ImageButton" {
                                Name = "PlayButton",
                                Size = UDim2.fromScale(0.8, 0.8),
                                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                                BackgroundTransparency = 1,
                                LayoutOrder = 5,

                                Image = Computed(function()
                                    return isPaused:get() and ICONS.Play or ICONS.Pause
                                end),

                                [OnEvent "Activated"] = props.TogglePauseAudio,
                            },

                            New "Frame" {
                                Name = "BlankSpace",
                                Size = UDim2.fromScale(0.4, 0),
                                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                                LayoutOrder = 6,
                            },

                            New "ImageButton" {
                                Name = "NextButton",
                                Size = UDim2.fromScale(0.8, 0.8),
                                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                                BackgroundTransparency = 1,
                                Image = ICONS.Next,
                                LayoutOrder = 7,

                                [OnEvent "Activated"] = props.NextAudio,
                            },
                        },
                    },

                    New "UICorner" {
                        CornerRadius = UDim.new(0, cornerRadius),
                    },

                    New "UIScale" {
                        Scale = IsOnMobile and 1.75 or 1,
                    },
                },
            }
        },
    }
end