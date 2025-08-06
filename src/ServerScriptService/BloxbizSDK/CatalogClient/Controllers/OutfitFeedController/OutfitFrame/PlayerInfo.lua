local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserService = game:GetService("UserService")
local BloxbizSDK = script.Parent.Parent.Parent.Parent.Parent
local CatalogClient = BloxbizSDK:WaitForChild("CatalogClient")

local AvatarHandler = require(CatalogClient.Classes.AvatarHandler)

local ConfigReader = require(BloxbizSDK:WaitForChild("ConfigReader"))
local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local Promise = require(UtilsStorage:WaitForChild("Promise"))
local FP = require(UtilsStorage:WaitForChild("FusionProps"))

local Components = CatalogClient.Components

local InteractionFrame = require(script.Parent.InteractionFrame)
local Button = require(Components.Button)
local ScaledText = require(Components.ScaledText)

local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local New = Fusion.New
local Ref = Fusion.Ref
local Computed = Fusion.Computed
local Spring = Fusion.Spring
local Cleanup = Fusion.Cleanup
local Value = Fusion.Value
local ForPairs = Fusion.ForPairs
local OnChange = Fusion.OnChange
local Out = Fusion.Out

local cachedPlayers = {}
local cachedThumbnails = {}

return function (props)
    props = FP.GetValues(props, {
        Parent = FP.Nil,
        AnchorPoint = Vector2.zero,
        Position = UDim2.fromScale(0, 0),
        Size = UDim2.fromScale(1, 1),

        PlayerId = FP.Required
    })

    local userInfo = Value()
    local thumbnail = Value("")

    local function getPlayerInfo(playerId)
        local infoPromise = Promise.new(function (resolve)
            if cachedPlayers[playerId] then
                userInfo:set(cachedPlayers[playerId])
                return resolve(cachedPlayers[playerId])
            end
    
            local result = Utils.callWithRetry(function()
                return UserService:GetUserInfosByUserIdsAsync({playerId})
            end, 5)[1]

            userInfo:set(result)
            cachedPlayers[playerId] = result
            resolve(result)
        end)

        local thumbnailPromise = Promise.new(function (resolve)
            if cachedThumbnails[playerId] then
                thumbnail:set(cachedThumbnails[playerId])
                return resolve(cachedThumbnails[playerId])
            end

            local result = Players:GetUserThumbnailAsync(playerId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
            thumbnail:set(result)

            cachedThumbnails[playerId] = result
            resolve(result)
        end)

        Promise.all({infoPromise, thumbnailPromise}):await()
    end

    task.spawn(getPlayerInfo, props.PlayerId:get())

    local sig = Fusion.Observer(props.PlayerId):onChange(function()
        task.spawn(getPlayerInfo, props.PlayerId:get())
    end)

    local _containerSize = Value(Vector2.zero)
    local containerSize = Computed(function()
        return _containerSize:get() or Vector2.zero
    end)

    return New "Frame" {
        Name = "PlayerInfo",

        Parent = props.Parent,
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        Size = props.Size,
        BackgroundTransparency = 1,

        [Out "AbsoluteSize"] = _containerSize,

        [Cleanup] = function()
            Fusion.cleanup(sig)
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
            New "CanvasGroup" {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),

                [Children] = {
                    New "UICorner" {
                        CornerRadius = UDim.new(0.5, 0),
                    },
                    New "UIAspectRatioConstraint" {
                        AspectRatio = 1,
                        DominantAxis = Enum.DominantAxis.Height
                    },

                    New "ImageLabel" {
                        Size = UDim2.fromScale(1, 1),
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        Image = thumbnail
                    }
                }
            },

            -- names
            New "Frame" {
                BackgroundTransparency = 1,
                LayoutOrder = 2,
                Size = Computed(function()
                    return UDim2.new(1, -containerSize:get().Y * 5/4, 1, 0)
                end),

                [Children] = {
                    -- display name
                    ScaledText {
                        Size = UDim2.fromScale(1, 0.5),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Text = Computed(function()
                            local info = userInfo:get()

                            if not info then
                                return "..."
                            else
                                return info.DisplayName or info.Username
                            end
                        end)
                    },
                    -- username
                    ScaledText {
                        AnchorPoint = Vector2.new(0, 1),
                        Position = UDim2.fromScale(0, 1),
                        Size = UDim2.fromScale(1, 0.4),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Text = Computed(function()
                            local info = userInfo:get()

                            if not info then
                                return "..."
                            else
                                return "@" .. info.Username
                            end
                        end),
                        TextColor3 = Color3.new(0.7, 0.7, 0.7)
                    }
                }
            }
        }
    }
end