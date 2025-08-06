local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local CommandTool = script.Parent.Parent
local BloxbizSDK = CommandTool.Parent

local Config = require(CommandTool.Config)
local Commands = require(CommandTool.Commands)

local UIComponents = BloxbizSDK.UIComponents
local ItemGrid = require(UIComponents.ItemGrid)
local ScaledText = require(UIComponents.ScaledText)

local Fusion = require(BloxbizSDK.Utils.Fusion)

local New = Fusion.New
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Computed = Fusion.Computed
local ForPairs = Fusion.ForPairs
local ForValues = Fusion.ForValues

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local RANKS = Config:Read("Ranks")
local PREIFX = Config:Read("CommandPrefix")

local function getUserAvatarImage(userId)
	return "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=150&h=150&filters=circular"
end

return function(props)
    local screenSize = Camera.ViewportSize

    local playerRanks = props.PlayerRanks
    local selectingUser = props.SelectingUser
    local selectedCommand = props.SelectedCommand

    local PlayerList = Players:GetPlayers()

    local function exitUserSelecting()
        selectingUser:set(false)
        selectedCommand:set(nil)
    end

    return New "Frame" {
        Name = "UserList",
        Size = UDim2.fromScale(0.85, 0.755),
        Position = UDim2.fromScale(0.5, 0.18),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,

        [Children] = {
            New "Frame" {
                Name = "SelectedCommand",
                Size = UDim2.fromScale(1, 0.155),
                Position = UDim2.fromScale(0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Color3.fromRGB(68, 128, 255),

                [Children] = {
                    ScaledText {
                        Size = UDim2.fromScale(0.85, 0.4),
                        Position = UDim2.fromScale(0.5, 0.5),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        RichText = true,

                        Text = Computed(function()
                            local id = selectedCommand:get()
                            if not id then
                                return ""
                            end

                            local command = Commands[id]
                            return string.format("<b>%s%s</b>", PREIFX, command.Name)
                        end),
                    },

                    ScaledText {
                        Text = "Cancel",
                        Size = UDim2.fromScale(0.85, 0.4),
                        Position = UDim2.fromScale(0.5, 0.5),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        TextXAlignment = Enum.TextXAlignment.Right,

                        [Children] = {
                            New "TextButton" {
                                Text = "",
                                Name = "Close",
                                Size = UDim2.fromScale(3, 1),
                                Position = UDim2.fromScale(1, 0.5),
                                AnchorPoint = Vector2.new(1, 0.5),
                                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                                BackgroundTransparency = 1,

                                [OnEvent "Activated"] = exitUserSelecting,
                            },
                        },
                    },

                    New "UICorner" {
                        CornerRadius = UDim.new(0.2, 0),
                    },
                },
            },

            ItemGrid {
                Size = UDim2.fromScale(1, 0.82),
                Position = UDim2.fromScale(0.5, 0.2),
                AnchorPoint = Vector2.new(0.5, 0),

                Gap = 10,
                Columns = 1,
                ItemRatio = 1 / 0.2,

                Visible = Computed(function()
                    local id = selectedCommand:get()
                    if not id then
                        return false
                    end

                    local ranks = playerRanks:get()
                    for _, rank in ranks do
                        if Config:CanUseCommand(rank, id) then
                            return true
                        end
                    end
                    return false
                end),

                [Children] = {
                    ForValues(PlayerList, function(player)
                        local userId = player.UserId
                        local playerName = player.Name
                        local displayName = player.DisplayName

                        return New "TextButton" {
                            Text = "",
                            Name = playerName,
                            BackgroundColor3 = Color3.fromRGB(79, 84, 94),
                            LayoutOrder = player == LocalPlayer and 0 or 1,
                            AutoButtonColor = true,

                            [OnEvent "Activated"] = function()
                                props.RunCommand(player, selectedCommand:get())
                                exitUserSelecting()
                            end,

                            [Children] = {
                                New "Frame" {
                                    Size = UDim2.fromScale(0.875, 1),
                                    Position = UDim2.fromScale(0.5, 0.5),
                                    AnchorPoint = Vector2.new(0.5, 0.5),
                                    BackgroundTransparency = 1,

                                    [Children] = {
                                        New "UIListLayout" {
                                            SortOrder = Enum.SortOrder.LayoutOrder,
                                            FillDirection = Enum.FillDirection.Horizontal,
                                            VerticalAlignment = Enum.VerticalAlignment.Center,
                                        },

                                        New "ImageLabel" {
                                            Name = "AvatarImage",
                                            Size = UDim2.fromScale(0.7, 0.7),
                                            SizeConstraint = Enum.SizeConstraint.RelativeYY,
                                            BackgroundTransparency = 0.3,
                                            Image = getUserAvatarImage(userId),

                                            [Children] = {
                                                New "UICorner" {
                                                    CornerRadius = UDim.new(1, 0),
                                                },
                                            },
                                        },

                                        New "Frame" {
                                            Name = "BlankSpace",
                                            Size = UDim2.fromScale(0.04, 0),
                                            BackgroundTransparency = 1,
                                        },

                                        New "Frame" {
                                            Name = "Names",
                                            Size = UDim2.fromScale(0.5, 0.75),
                                            BackgroundTransparency = 1,

                                            [Children] = {
                                                New "UIListLayout" {
                                                    Padding = UDim.new(0.03, 0),
                                                    SortOrder = Enum.SortOrder.LayoutOrder,
                                                    FillDirection = Enum.FillDirection.Vertical,
                                                    VerticalAlignment = Enum.VerticalAlignment.Center,
                                                },

                                                New "TextLabel" {
                                                    Name = "DisplayName",
                                                    Text = string.format("<b>%s</b>", displayName),
                                                    Font = Enum.Font.GothamMedium,
                                                    Size = UDim2.fromScale(1, 0.45),
                                                    TextColor3 = Color3.fromRGB(255, 255, 255),
                                                    TextXAlignment = Enum.TextXAlignment.Left,
                                                    BackgroundTransparency = 1,
                                                    TextScaled = true,
                                                    RichText = true,
                                                },

                                                New "TextLabel" {
                                                    Name = "Username",
                                                    Text = "@" .. playerName,
                                                    Font = Enum.Font.GothamMedium,
                                                    Size = UDim2.fromScale(1, 0.425),
                                                    TextColor3 = Color3.fromRGB(188, 190, 193),
                                                    TextXAlignment = Enum.TextXAlignment.Left,
                                                    BackgroundTransparency = 1,
                                                    TextScaled = true,
                                                    RichText = true,
                                                },
                                            },
                                        },
                                    },
                                },

                                New "UICorner" {
                                    CornerRadius = UDim.new(0.15, 0),
                                },
                            },
                        }
                    end, Fusion.cleanup),
                },
            },

            ItemGrid {
                Size = UDim2.fromScale(1, 0.882),
                Position = UDim2.fromScale(0.5, 0.2),
                AnchorPoint = Vector2.new(0.5, 0),

                Gap = 14,
                Columns = 1,
                ItemRatio = 1 / 0.425,

                Visible = Computed(function()
                    local id = selectedCommand:get()
                    if not id then
                        return false
                    end

                    local ranks = playerRanks:get()
                    for _, rank in ranks do
                        if Config:CanUseCommand(rank, id) then
                            return false
                        end
                    end
                    return true
                end),

                [Children] = {
                    ForPairs(RANKS, function(rankIndex, rank)
                        local id = selectedCommand:get()
                        if not id then
                            return rankIndex, nil
                        end

                        if not Config:CanUseCommand(rankIndex, id) then
                            return rankIndex, nil
                        end

                        local rankName = rank.Name
                        local obtainCallback = rank.ObtainButtonCallback
                        local obtainGamepassId = rank.ObtainButtonGamepass

                        return rankIndex, New "Frame" {
                            Name = rankName,
                            BackgroundColor3 = Color3.fromRGB(79, 84, 94),

                            [Children] = {
                                New "Frame" {
                                    Name = "Container",
                                    Size = UDim2.fromScale(0.65, 0.9),
                                    Position = UDim2.fromScale(0.5, 0.5),
                                    AnchorPoint = Vector2.new(0.5, 0.5),
                                    BackgroundTransparency = 1,

                                    [Children] = {
                                        New "UIListLayout" {
                                            Padding = UDim.new(0, 0),
                                            SortOrder = Enum.SortOrder.LayoutOrder,
                                            FillDirection = Enum.FillDirection.Vertical,
                                            VerticalAlignment = Enum.VerticalAlignment.Center,
                                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                        },

                                        New "TextLabel" {
                                            Name = "Rank",
                                            Text = string.format("<b>Unlock with %s</b>", rankName),
                                            Font = Enum.Font.GothamMedium,
                                            Size = UDim2.fromScale(1, 0.1),
                                            TextColor3 = Color3.fromRGB(255, 255, 255),
                                            TextSize = screenSize.Y / 40,
                                            BackgroundTransparency = 1,
                                            RichText = true,
                                        },

                                        New "Frame" {
                                            Name = "BlankSpace",
                                            Size = UDim2.fromScale(0, 0.07),
                                            SizeConstraint = Enum.SizeConstraint.RelativeXX,
                                        },

                                        New "TextLabel" {
                                            Name = "RankUpText",
                                            Text = rank.ObtainDescription,
                                            Font = Enum.Font.GothamMedium,
                                            Size = UDim2.fromScale(1, 0.2),
                                            TextColor3 = Color3.fromRGB(188, 190, 193),
                                            TextSize = screenSize.Y / 42,
                                            BackgroundTransparency = 1,
                                            TextWrapped = true,
                                            RichText = true,

                                        },

                                        New "Frame" {
                                            Name = "BlankSpace",
                                            Size = UDim2.fromScale(0, 0.07),
                                            SizeConstraint = Enum.SizeConstraint.RelativeXX,
                                        },

                                        (obtainCallback or obtainGamepassId) and New "TextButton" {
                                            Name = "RankUpButton",
                                            Size = UDim2.fromScale(0.6, 0.15),
                                            SizeConstraint = Enum.SizeConstraint.RelativeXX,
                                            AutoButtonColor = true,

                                            [OnEvent "Activated"] = function()
                                                local gamepassId = obtainGamepassId and tonumber(obtainGamepassId) or nil
                                                if gamepassId then
                                                    MarketplaceService:PromptGamePassPurchase(LocalPlayer,  gamepassId)
                                                end

                                                if obtainCallback then
                                                    obtainCallback(LocalPlayer)
                                                end
                                            end,

                                            [Children] = {
                                                New "TextLabel" {
                                                    Text = string.format("<b>%s</b>", rank.ObtainButtonText or "Buy Rank"),
                                                    Font = Enum.Font.GothamMedium,
                                                    Size = UDim2.fromScale(0.9, 0.55),
                                                    Position = UDim2.fromScale(0.5, 0.5),
                                                    AnchorPoint = Vector2.new(0.5, 0.5),
                                                    TextColor3 = Color3.fromRGB(0, 0, 0),
                                                    BackgroundTransparency = 1,
                                                    TextScaled = true,
                                                    RichText = true,
                                                },

                                                New "UICorner" {
                                                    CornerRadius = UDim.new(0.3, 0),
                                                },
                                            },
                                        } or nil,
                                    },
                                },

                                New "UICorner" {
                                    CornerRadius = UDim.new(0.1, 0),
                                },
                            },
                        }
                    end, Fusion.cleanup),
                },
            },
        },
    }
end