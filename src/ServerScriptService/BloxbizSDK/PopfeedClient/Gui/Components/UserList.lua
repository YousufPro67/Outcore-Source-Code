local Players = game:GetService("Players")

local Gui = script.Parent.Parent
local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Ref = Fusion.Ref
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Computed = Fusion.Computed
local ForValues = Fusion.ForValues

local GuiComponents = Gui.Components
local Line = require(GuiComponents.Line)
local SelectButton = require(GuiComponents.SelectButton)
local ActionButton = require(GuiComponents.ActionButton)

local LocalPlayer = Players.LocalPlayer

local nameFont = Font.fromEnum(Enum.Font.Arial)
local displayNameFont = Font.fromEnum(Enum.Font.Arial)
displayNameFont.Bold = true

return function(props)
    return New "TextButton" {
        Name = "UserList",
        Size = UDim2.fromScale(1, 0.915),
        Position = UDim2.fromScale(0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        ZIndex = 5,

        Visible = Computed(function()
            return props.UserListVisible:get()
        end),

        [Children] = {
            New("Frame")({
                Name = "Top",
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0.1),
                Position = UDim2.fromScale(0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0),


                [Children] = {
                    SelectButton({
						Text = "< Back",
						Name = "BackButton",
						Size = UDim2.fromScale(0, 0.41),
						Color = Color3.fromRGB(255, 255, 255),
						Position = UDim2.fromScale(0.05, 0.5),
						AnchorPoint = Vector2.new(0, 0.5),
						AutomaticSize = Enum.AutomaticSize.X,
						ZIndex = 5,
						Bold = true,

						OnActivated = function()
                            props.UserListVisible:set(false)
						end,
					}),

					Line({
						ZIndex = 5,
						Size = UDim2.fromScale(1, 0.02),
					}),
                },
            }),

            New "ScrollingFrame" {
				Name = "List",
				Size = UDim2.fromScale(0.95, 0.895),
				Position = UDim2.fromScale(0.5, 0.105),
                AnchorPoint = Vector2.new(0.5, 0),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = 0,
				BackgroundTransparency = 1,
                ZIndex = 5,

                [Ref] = props.UserListScrollingFrame,

                [Children] = {
                    New("Frame")({
                        Name = "Container",
                        Size = UDim2.fromScale(1, 1.23),
                        Position = UDim2.fromScale(0.5, 0),
                        AnchorPoint = Vector2.new(0.5, 0),
                        SizeConstraint = Enum.SizeConstraint.RelativeXX,
                        BackgroundTransparency = 1,

                        [Children] = {
                            New("UIListLayout")({
                                Padding = UDim.new(0.04, 0),
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                FillDirection = Enum.FillDirection.Vertical,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            }),

                            ForValues(props.UserListLoaded, function(userData)
                                local isFollowing = Value(userData.is_following)
                                local userId = userData.follower or userData.following
                                local cachedUserInfo = props.cachedUserInfos[userId]

                                return New("TextButton")({
                                    Name = "UserInfo",
                                    Size = UDim2.fromScale(1, 0.12),
                                    SizeConstraint = Enum.SizeConstraint.RelativeXX,
                                    BackgroundTransparency = 1,
                                    ZIndex = 5,

                                    [OnEvent("Activated")] = function()
                                        props.OnSwitchFeedClicked(props.initialProfileFeed, userId)
                                        props.UserListVisible:set(false)
                                    end,

                                    [Children] = {
                                        New("Frame")({
                                            Name = "Container",
                                            Size = UDim2.fromScale(1, 1),
                                            BackgroundTransparency = 1,

                                            [Children] = {
                                                New("UIListLayout")({
                                                    SortOrder = Enum.SortOrder.LayoutOrder,
                                                    FillDirection = Enum.FillDirection.Horizontal,
                                                    VerticalAlignment = Enum.VerticalAlignment.Center,
                                                }),

                                                New("ImageLabel")({
                                                    Name = "ProfilePicture",
                                                    Size = UDim2.fromScale(0.875, 0.875),
                                                    SizeConstraint = Enum.SizeConstraint.RelativeYY,
                                                    Image = props.GetUserProfilePicture(userId),
                                                    BackgroundTransparency = 1,
                                                    ZIndex = 6,
                                                    LayoutOrder = 1,

                                                    [Children] = {
                                                        New("UICorner")({
                                                            CornerRadius = UDim.new(1, 0),
                                                        }),

                                                        New("Frame")({
                                                            Name = "Background",
                                                            Position = UDim2.new(0, 0, 0, -1),
                                                            Size = UDim2.fromScale(1, 1),
                                                            ZIndex = 5,

                                                            [Children] = New("UICorner")({
                                                                CornerRadius = UDim.new(1, 0),
                                                            }),
                                                        }),
                                                    },
                                                }),

                                                New("Frame")({
                                                    Name = "BlankSpace",
                                                    Size = UDim2.fromScale(0.04, 0),
                                                    BackgroundTransparency = 1,
                                                    LayoutOrder = 2,
                                                }),

                                                New("Frame")({
                                                    Name = "Names",
                                                    Size = UDim2.fromScale(0.5, 0.75),
                                                    BackgroundTransparency = 1,
                                                    LayoutOrder = 3,

                                                    [Children] = {
                                                        New("UIListLayout")({
                                                            Padding = UDim.new(0.04, 0),
                                                            SortOrder = Enum.SortOrder.LayoutOrder,
                                                            FillDirection = Enum.FillDirection.Vertical,
                                                            VerticalAlignment = Enum.VerticalAlignment.Center,
                                                        }),

                                                        New("TextLabel")({
                                                            Name = "DisplayName",
                                                            Text = cachedUserInfo.DisplayName,
                                                            Size = UDim2.fromScale(1, 0.5),
                                                            TextColor3 = Color3.fromRGB(255, 255, 255),
                                                            TextXAlignment = Enum.TextXAlignment.Left,
                                                            BackgroundTransparency = 1,
                                                            LayoutOrder = 1,
                                                            TextScaled = true,
                                                            FontFace = displayNameFont,
                                                            ZIndex = 5,
                                                        }),

                                                        New("TextLabel")({
                                                            Name = "Username",
                                                            Text = cachedUserInfo.Username,
                                                            Size = UDim2.fromScale(1, 0.5),
                                                            TextColor3 = Color3.fromRGB(134, 134, 134),
                                                            TextXAlignment = Enum.TextXAlignment.Left,
                                                            BackgroundTransparency = 1,
                                                            LayoutOrder = 2,
                                                            TextScaled = true,
                                                            FontFace = nameFont,
                                                            ZIndex = 5,
                                                        }),
                                                    },
                                                }),
                                            },
                                        }),

                                        ActionButton({
                                            Name = "FollowButton",
                                            Size = UDim2.fromScale(0, 0.56),
                                            AnchorPoint = Vector2.new(1, 0.5),
                                            Position = UDim2.fromScale(1, 0.5),

                                            Padding = 0.015,
                                            BackOffset = 0.4,
                                            FrontOffset = 0.4,
                                            MiddleOffset = 0.1,

                                            CornerRadius = UDim.new(0.5, 0),
                                            BackgroundColor = Color3.fromRGB(0, 170, 255),
                                            ZIndex = 5,

                                            Text = Computed(function()
                                                if isFollowing:get() == true then
                                                    return "Following"
                                                else
                                                    return "Follow"
                                                end
                                            end),

                                            TextSize = UDim2.fromScale(0, 0.6),
                                            Font = displayNameFont,

                                            Icon = Computed(function()
                                                if isFollowing:get() == true then
                                                    return "rbxassetid://13479450009"
                                                else
                                                    return "rbxassetid://13479598082"
                                                end
                                            end),

                                            IconSize = UDim2.fromScale(0.6, 0.6),

                                            Visible = LocalPlayer.UserId ~= userId,

                                            OnActivated = function()
                                                local follows = isFollowing:get() == true
                                                if follows then
                                                    props.OnFollowButtonClicked(userId, false)
                                                    isFollowing:set(false)
                                                else
                                                    props.OnFollowButtonClicked(userId, true)
                                                    isFollowing:set(true)
                                                end
                                            end,
                                        }),
                                    },
                                })
                            end, Fusion.cleanup),
                        },
                    }),
                },
            },

            New("UICorner")({
                CornerRadius = UDim.new(0, 8),
            }),
        },
    }
end
