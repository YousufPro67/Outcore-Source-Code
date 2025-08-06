local UserService = game:GetService("UserService")

local PopfeedClient = script.Parent.Parent.Parent

local Gui = PopfeedClient.Gui
local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children

local nameFont = Font.fromEnum(Enum.Font.Arial)
local displayNameFont = Font.fromEnum(Enum.Font.Arial)
displayNameFont.Bold = true

return function(props)
    local player = props.Player
    local userId = player.UserId

    local userName, displayName = "@Unknown", "Unknown"

	local profileInfo = UserService:GetUserInfosByUserIdsAsync({userId})[1]
    if profileInfo then
        userName = "@" .. profileInfo.Username
        displayName = profileInfo.DisplayName or profileInfo.Username
    end

    local feedProps = props.FeedProps

    return New "BillboardGui" {
        Name = "FloatingProfile",
        Size = UDim2.fromScale(5, 1.5),
        StudsOffset = Vector3.new(0, 4, 0),
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        LightInfluence = 0,
        Active = true,
        Adornee = props.RootPart,

        [Children] = {
            New "TextButton" {
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                BackgroundTransparency = 0.2,

                [Children] = {
                    New("UIListLayout")({
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        FillDirection = Enum.FillDirection.Horizontal,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    }),

                    New("Frame")({
                        Name = "BlankSpace",
                        Size = UDim2.fromScale(0.05, 0),
                        BackgroundTransparency = 1,
                    }),

                    New("ImageLabel")({
                        Name = "ProfilePicture",
                        Size = UDim2.fromScale(0.65, 0.65),
                        SizeConstraint = Enum.SizeConstraint.RelativeYY,
                        Image = feedProps.GetUserProfilePicture(userId),
                        BackgroundTransparency = 1,
                        ZIndex = 2,

                        [Children] = {
                            New("UICorner")({
                                CornerRadius = UDim.new(1, 0),
                            }),

                            New("Frame")({
                                Name = "Background",
                                Position = UDim2.new(0, 0, 0, -1),
                                Size = UDim2.fromScale(1, 1),
                                ZIndex = 1,

                                [Children] = New("UICorner")({
                                    CornerRadius = UDim.new(1, 0),
                                }),
                            }),
                        },
                    }),

                    New("Frame")({
                        Name = "BlankSpace",
                        Size = UDim2.fromScale(0.08, 0),
                        BackgroundTransparency = 1,
                    }),

                    New("Frame")({
                        Name = "Names",
                        Size = UDim2.fromScale(0.59, 0.65),
                        BackgroundTransparency = 1,

                        [Children] = {
                            New("UIListLayout")({
                                Padding = UDim.new(0.04, 0),
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                FillDirection = Enum.FillDirection.Vertical,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                            }),

                            New("TextLabel")({
                                Name = "DisplayName",
                                Text = displayName,
                                Size = UDim2.fromScale(1, 0.5),
                                TextColor3 = Color3.fromRGB(255, 255, 255),
                                TextXAlignment = Enum.TextXAlignment.Left,
                                BackgroundTransparency = 1,
                                LayoutOrder = 1,
                                TextScaled = true,
                                FontFace = displayNameFont,
                            }),

                            New("TextLabel")({
                                Name = "Username",
                                Text = userName,
                                Size = UDim2.fromScale(1, 0.4),
                                TextColor3 = Color3.fromRGB(134, 134, 134),
                                TextXAlignment = Enum.TextXAlignment.Left,
                                BackgroundTransparency = 1,
                                LayoutOrder = 2,
                                TextScaled = true,
                                FontFace = nameFont,
                            }),
                        },
                    }),

                    New "UICorner" {
                        CornerRadius = UDim.new(1, 0),
                    },
                },

                [OnEvent "Activated"] = function()
                    feedProps.LoadProfileFromFloatingBanner(player)
                end,
            },
        },
    }
end
