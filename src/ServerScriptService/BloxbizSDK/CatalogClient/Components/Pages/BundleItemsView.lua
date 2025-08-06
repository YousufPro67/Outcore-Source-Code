local AssetService = game:GetService("AssetService")

local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Promise = require(UtilsStorage:WaitForChild("Promise"))
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local Ref = Fusion.Ref
local OnChange = Fusion.OnChange
local Out = Fusion.Out
local OnEvent = Fusion.OnEvent

local CatalogClient = BloxbizSDK.CatalogClient
local Components = CatalogClient.Components

local InventoryHandler = require(CatalogClient.Classes.InventoryHandler)
local AvatarHandler = require(CatalogClient.Classes.AvatarHandler)

local ScrollingFrame = require(Components.Generic.ScrollingFrame)
local LoadingFrame = require(Components.LoadingFrame)
local ScaledText = require(Components.ScaledText)
local CatalogItem = require(Components.CatalogItem)


return function (props)
    props = FusionProps.GetValues(props, {
        Parent = FusionProps.Nil,
        Position = UDim2.fromScale(0, 0),
        AnchorPoint = Vector2.zero,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 100,
        Visible = true,

        HeaderHeight = 40,
        BundleId = -1,
        AvatarPreviewController = FusionProps.Nil,
        CurrentCategory = FusionProps.Nil,
        OnBack = FusionProps.Nil
    })

    local bundleDetails = Value()
    local bundleItems = Value(nil)
    local loadingErr = Value()
    local loading = Computed(function()
        local items = bundleItems:get()
        local err = loadingErr:get()
        return not items and not err
    end)

    local function loadBundle()
        local bundleId = props.BundleId:get()
        bundleDetails:set(nil)
        loadingErr:set(nil)

        if not bundleId or bundleId <= 0 then
            return
        end

        Promise.try(function()
            return AssetService:GetBundleDetailsAsync(bundleId)
        end)
            :andThen(function (details)
                bundleDetails:set(details)

                local itemDetailsMap = InventoryHandler.GetBatchItemDetails(
                    Utils.map(details.Items, function (item) return item.Id end)
                )

                local itemList = {}
                for _, item in ipairs(details.Items) do
                    local itemDetails = itemDetailsMap[item.Id]
                    local itemData = itemDetails and AvatarHandler.BuildItemData(itemDetails) or nil

                    if itemDetails and itemData then
                        table.insert(itemList, itemData)
                    end
                end

                bundleItems:set(itemList)
            end)
            :catch(function (err)
                Utils.debug_warn(err)
                loadingErr:set(err)
            end)
    end

    task.spawn(loadBundle)
    local bundleIdSignal = Fusion.Observer(props.BundleId):onChange(loadBundle)

    local scrollProps = {
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        AnchorPoint = Vector2.new(0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        DragScrollDisabled = true,
    
        Layout = {
            Type = "UIGridLayout",
            FillDirection = Enum.FillDirection.Horizontal,
    
            Size = UDim2.fromScale(0.243, 0.3),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim2.fromScale(0.009, 0.012),
        },
    }
    
    local selectedId = Value()

    return New "Frame" {
        Parent = props.Parent,
        Position = props.Position,
        Size = props.Size,
        AnchorPoint = props.AnchorPoint,
        ZIndex = props.ZIndex,
        Visible = props.Visible,

        BackgroundColor3 = Color3.fromRGB(20, 20, 20),

        [Fusion.Cleanup] = function()
            Fusion.cleanup(bundleIdSignal)
        end,

        [Children] = {
            New "Frame" {
                Name = "Header",
                BackgroundTransparency = 1,
                Size = Computed(function()
                    return UDim2.new(1, 0, 0, props.HeaderHeight:get() * 0.8)
                end),

                [Children] = {
                    -- back button
                    New "TextButton" {
                        Name = "Back",
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2.new(0, 0.5),
                        Position = UDim2.fromScale(0, 0.5),
                        Size = UDim2.fromScale(0.2, 1),
                        Text = "",

                        [OnEvent "Activated"] = function()
                            local cb = props.OnBack:get()
                            if cb then
                                cb()
                            end
                        end,

                        [Children] = {
                            New "UIListLayout" {
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                FillDirection = Enum.FillDirection.Horizontal,
                                Padding = Computed(function()
                                    return UDim.new(0, props.HeaderHeight:get() / 5)
                                end)
                            },
                            New "ImageLabel" {
                                BackgroundTransparency = 1,
                                Image = "rbxassetid://15103716412",
                                ImageColor3 = Color3.fromRGB(95, 166, 255),
                                Size = Computed(function()
                                    return UDim2.fromOffset(
                                        props.HeaderHeight:get() / 3,
                                        props.HeaderHeight:get() / 3
                                    )
                                end)
                            },
                            ScaledText {
                                LayoutOrder = 2,
                                Size = Computed(function()
                                    return UDim2.new(
                                        1, -(props.HeaderHeight:get() * (1/5 + 1/3)),
                                        0.6, 0
                                    )
                                end),
                                TextXAlignment = Enum.TextXAlignment.Left,
                                Text = "Back",
                                TextColor3 = Color3.fromRGB(95, 166, 255)
                            }
                        }
                    },

                    -- bundle name
                    ScaledText {
                        Name = "Title",
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromScale(0.5, 0.6),

                        Text = Computed(function()
                            if bundleDetails:get() then
                                return bundleDetails:get().Name
                            else
                                return ""
                            end
                        end)
                    }
                }
            },

            New "Frame" {
                Name = "Content",
                BackgroundTransparency = 1,
                Position = Computed(function()
                    return UDim2.new(0, 0, 0, props.HeaderHeight:get())
                end),
                Size = Computed(function()
                    return UDim2.new(1, 0, 1, -props.HeaderHeight:get())
                end),

                [Children] = {
                    LoadingFrame {
                        Visible = loading
                    },
                    Computed(function()
                        local isLoading = loading:get()
                        local err = loadingErr:get()
                        local items = bundleItems:get()
                        local AvatarPreviewController = props.AvatarPreviewController:get()

                        if items then
                            return ScrollingFrame(Utils.merge(
                                scrollProps,
                                {[Children] = Fusion.ForValues(items, function (item)
                                    if item.AssetType == 1 then
                                        --return
                                    end

                                    return CatalogItem {
                                        AvatarPreviewController = props.AvatarPreviewController,
                                        ItemData = item,
                                        CategoryName = props.CurrentCategory,
                                        SourceBundleInfo = item.Source,
                                        OnTry = function()
                                            AvatarPreviewController.AddChange(AvatarPreviewController, item, props.CurrentCategory:get())
                                        end,
                                        SelectedId = selectedId
                                    }
                                end, Fusion.cleanup)}
                            ))
                        end
                    end, Fusion.cleanup)
                }
            }
        }
    }
end