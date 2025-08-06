local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Mouse = Player:GetMouse()
local Camera = workspace.CurrentCamera

local BloxbizSDK = script.Parent.Parent.Parent.Parent
local CatalogClient = BloxbizSDK:WaitForChild("CatalogClient")

local AvatarHandler = require(CatalogClient.Classes.AvatarHandler)

local ConfigReader = require(BloxbizSDK:WaitForChild("ConfigReader"))
local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FP = require(UtilsStorage:WaitForChild("FusionProps"))

local Components = CatalogClient.Components

local Viewport = require(Components.Generic.ViewportFrame)
local Item = require(script.Item)
local PlayerInfo = require(script.PlayerInfo)
local Button = require(script.Button)
local Counter = require(script.Counter)

local TOUCH_ENABLED = UserInputService.TouchEnabled

local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local New = Fusion.New
local Ref = Fusion.Ref
local Computed = Fusion.Computed
local Spring = Fusion.Spring
local Cleanup = Fusion.Cleanup
local Value = Fusion.Value
local ForValues = Fusion.ForValues
local OnChange = Fusion.OnChange
local Out = Fusion.Out

local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")

local CatalogItemPromptEvent = BloxbizRemotes:WaitForChild("catalogItemPromptEvent")
local PromptPurchaseRemote = BloxbizRemotes:WaitForChild("CatalogOnPromptPurchase")

return function (props)
    props = FP.GetValues(props, {
        Parent = FP.Nil,
        Id = FP.Required,
        CreatorId = FP.Required,
        ReadOnly = false,
        Outfit = FP.Required,
        Items = FP.Required,
        Likes = 0,
        Boosts = 0,
        TryOns = 0,
        Impressions = 0,
        OwnLike = false,
        HumanoidDescription = FP.Required,
        OnImpression = FP.Callback,
        OnTry = FP.Callback,
        OnLike = FP.Callback,
        OnBoost = FP.Callback,
        Enabled = true,
        SelectedId = FP.Nil,
        AvatarPreviewController = FP.Required,

        AlreadySeen = false,
        AlreadyTriedOn = false,
    })

    local APC = props.AvatarPreviewController

    local containerSize = Value(Vector2.zero)
    local padding = Computed(function()
        containerSize:get()
        return (containerSize:get() or Vector2.zero).Y * 0.02
    end)

    local itemListSize = Value(Vector2.zero)

    local showItems = Computed(function()
        return props.SelectedId:get() == props.Id:get()
    end)

    local previewModel = AvatarHandler.GetModel(props.HumanoidDescription:get())
    local animateScript = previewModel:FindFirstChild("Animate")
	if animateScript then
		animateScript.Disabled = true
	end

    local selectedItem = Value()
    local sig = Fusion.Observer(showItems):onChange(function()
        if not showItems:get() then
            selectedItem:set(nil)
        end
    end)

    local previewSize = Spring(Computed(function()
        if showItems:get() then
            return UDim2.new(0.75, -padding:get() - 1, 1, 0)
        else
            return UDim2.fromScale(1, 1)
        end
    end), 30)

    local frameRef = Value()
    local buttonTraySize = Value(Vector2.zero)

    return New "Frame" {
        Parent = props.Parent,
        Name = props.Id,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,

        [Fusion.Cleanup] = function()
            Fusion.cleanup(sig)
        end,

        [Ref] = frameRef,

        [Out "AbsoluteSize"] = containerSize,

        [Fusion.OnChange("AbsolutePosition")] = function(pos)
			-- detect outfit impressions

			if props.AlreadySeen:get() then
				return
			end

			local frame = frameRef:get()

			if frame then
				local size = frame.AbsoluteSize

				local minY = 0
				local maxY = workspace.Camera.ViewportSize.Y - (size.Y/2)

				if (pos.Y > minY) and (pos.Y < maxY) then
                    if not props.AlreadySeen:get() then
                        props.Impressions:set(props.Impressions:get() + 1)
                    end

					props.AlreadySeen:set(true)
					local cb = props.OnImpression:get()
                    cb()
				end
			end
		end,

        [Children] = {
            -- preview content
            New "Frame" {
                BackgroundTransparency = 1,
                Size = Computed(function()
                    return UDim2.new(1, 0, 0.85, -padding:get() * 1)
                end),

                [Children] = {
                    -- preview viewport container
                    New "TextButton" {
                        Name = "PreviewContainer",
                        Size = previewSize,
                        BackgroundColor3 = Color3.fromHex("373B43"),
                        ZIndex = 10,

                        [Children] = {
                            New "UICorner" {
                                CornerRadius = Computed(function()
                                    return UDim.new(0, padding:get()*2)
                                end)
                            },
                            Viewport {
                                RotateEnabled = true,
                                AutoRotateEnabled = true,
                                Model = previewModel,
                                Size = UDim2.fromScale(1, 1),
                                Position = UDim2.fromScale(0.5, 0.5),
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                OnClick = function()
                                    if props.Id:get() == props.SelectedId:get() then
                                        props.SelectedId:set(nil)
                                    else
                                        props.SelectedId:set(props.Id:get())
                                    end
                                end,
                                AnimTrack = nil,
                            }
                        }
                    },

                    -- item list
                    New "CanvasGroup" {
                        Name = "Items",
                        BackgroundTransparency = 1,
                        GroupTransparency = Spring(Computed(function()
                            if showItems:get() then
                                return 0
                            else
                                return 0.5
                            end
                        end), 30),
                        Visible = Computed(function()
                            return previewSize:get().X.Scale <= 0.999
                        end),

                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.fromScale(1, 0),
                        Size = UDim2.fromScale(0.25, 1),

                        [Children] = {
                            New "UICorner" {
                                CornerRadius = Computed(function()
                                    return UDim.new(0, padding:get()*2)
                                end)
                            },
                            New "ScrollingFrame" {
                                Size = UDim2.fromScale(1, 1),
                                BackgroundTransparency = 1,
                                ScrollBarThickness = 0,
                                CanvasSize = Computed(function()
                                    return UDim2.new(1, 0, 0, (itemListSize:get() or Vector2.zero).Y)
                                end),
                                ScrollingDirection = Enum.ScrollingDirection.Y,

                                [Children] = {
                                    New "UIListLayout" {
                                        Padding = Computed(function() return UDim.new(0, padding:get()) end),
                                        [Out "AbsoluteContentSize"] = itemListSize,
                                    },
                                    ForValues(props.Items, function (itemData)
                                        if not itemData.AssetId then
                                            return
                                        end

                                        return New "Frame" {
                                            Size = UDim2.fromScale(1, 1),
                                            BackgroundTransparency = 1,

                                            [Children] = {
                                                New "UIAspectRatioConstraint" {
                                                    DominantAxis = Enum.DominantAxis.Width,
                                                    AspectRatio = 1,
                                                },
                                                Item {
                                                    AssetId = itemData.AssetId,
                                                    SelectedId = selectedItem,
                                                    CategoryName = "Feed",
                                                    EquippedItems = Computed(function()
                                                        return props.AvatarPreviewController:get().EquippedItems:get()
                                                    end),
                                                    CornerRadius = Computed(function()
                                                        return padding:get() * 2
                                                    end),
                                                    OnBuy = function()
                                                        CatalogItemPromptEvent:FireServer("Feed")

                                                        if itemData.AssetId then
                                                            PromptPurchaseRemote:InvokeServer(itemData.AssetId, false)
                                                        end
                                                    end,
                                                    OnTry = function()
                                                        local AvatarPreviewController = props.AvatarPreviewController:get()
                                                        AvatarPreviewController:AddChange(itemData, "Feed")
                                                    end,
                                                }
                                            }
                                        }
                                    end, Fusion.cleanup)
                                }
                            }
                        }
                    }
                }
            },

            -- footer
            New "Frame" {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.fromScale(0, 0.86),
                Size = Computed(function()
                    return UDim2.new(1, 0, 0.12, 0)
                end),

                [Children] = {
                    PlayerInfo {
                        PlayerId = props.CreatorId,
                        Size = Computed(function()
                            return UDim2.new(
                                1, -(buttonTraySize:get() or Vector2.zero).X - padding:get(),
                                1, 0
                            )
                        end)
                    },

                    New "Frame" {
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.fromScale(1, 0),
                        Size = UDim2.fromScale(0.5, 1),
                        BackgroundTransparency = 1,

                        [Children] = {
                            New "UIListLayout" {
                                FillDirection = Enum.FillDirection.Horizontal,
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                HorizontalAlignment = Enum.HorizontalAlignment.Right,

                                [Out "AbsoluteContentSize"] = buttonTraySize,

                                Padding = Computed(function()
                                    return UDim.new(0, padding:get())
                                end)
                            },
                            New "UIPadding" {
                                PaddingRight = UDim.new(0, 1)
                            },

                            -- impressions count
                            Counter {
                                LayoutOrder = -3,
                                Icon = "rbxassetid://15234940872",
                                Count = props.Impressions,
                                Size = UDim2.fromScale(1, 1)
                            },

                            -- like button
                            Button {
                                LayoutOrder = -2,
                                Icon = Computed(function()
                                    if props.OwnLike:get() then
                                        return "rbxassetid://14110764348"
                                    else
                                        return "rbxassetid://15234302220"
                                    end
                                end),
                                Disabled = props.ReadOnly,
                                Count = props.Likes,
                                
                                OnClick = function()
                                    local isLiked = props.OwnLike:get()
                                    local increment = if isLiked then -1 else 1
                                    
                                    props.OwnLike:set(not isLiked)
                                    props.Likes:set(props.Likes:get() + increment)

                                    local cb = props.OnLike:get()
                                    local success = cb(not isLiked)

                                    if not success then
                                        -- reverse changes if failed
                                        props.OwnLike:set(isLiked)
                                        props.Likes:set(props.Likes:get() - increment)
                                    end
                                end,
                            },
                            -- try on button
                            Button {
                                LayoutOrder = -1,
                                Icon = "rbxassetid://15236081286",
                                Count = props.TryOns,

                                OnClick = function()
                                    local cb = props.OnTry:get()
                                    cb()
                                    props.AlreadyTriedOn:set(true)
                                end
                            }
                        }
                    }
                }
            }
        }
    }
end