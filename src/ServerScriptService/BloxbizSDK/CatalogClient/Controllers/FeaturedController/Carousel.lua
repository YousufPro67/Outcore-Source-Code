local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))
local Promise = require(UtilsStorage:WaitForChild("Promise"))

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local ForPairs = Fusion.ForPairs
local Computed = Fusion.Computed
local Spring = Fusion.Spring
local Out = Fusion.Out
local Ref = Fusion.Ref
local OnEvent = Fusion.OnEvent
local Cleanup = Fusion.Cleanup

local CatalogClient = BloxbizSDK.CatalogClient
local Components = CatalogClient.Components

local ScaledText = require(Components.ScaledText)

return function(props)
    props = FusionProps.GetValues(props, {
        Name = "Carousel",
        Parent = FusionProps.Nil,
        Position = UDim2.fromScale(0, 0),
        Size = UDim2.fromScale(1, 1),
        AnchorPoint = Vector2.new(0, 0),
        Transparency = 0,

        Items = {},
        ItemRatio = 1,
        MinGap = 5,
        Interval = 5,
        Pause = false
    })

    local absoluteSize = Value(Vector2.zero)
    local itemWidth = Computed(function()
        return math.min(absoluteSize:get().Y * props.ItemRatio:get(), absoluteSize:get().X)
    end)
    local itemsPerPage = Computed(function()
        local gap = props.MinGap:get()
        local items = props.Items:get()
        local width = itemWidth:get()

        return math.max(1, math.floor(
            (absoluteSize:get().X - gap) / (width + gap)
        ))
    end)

    local totalWidth = Computed(function()
        return #props.Items:get() * absoluteSize:get().X / itemsPerPage:get()
    end)

    local items = ForPairs(props.Items, function (idx, item)
        item.Position = UDim2.fromScale(0, 0)
        item.Size = UDim2.fromScale(1, 1)
        item.AnchorPoint = Vector2.new(0, 0)
        item.LayoutOrder = idx

        return idx, New "Frame" {
            BackgroundTransparency = 1,
            LayoutOrder = idx,
            Size = Computed(function()
                return UDim2.new(
                    0, absoluteSize:get().X / itemsPerPage:get(),
                    1, 0
                )
            end),

            [Children] = New "Frame" {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = Computed(function()
                    return UDim2.fromOffset(
                        itemWidth:get(),
                        itemWidth:get() / props.ItemRatio:get()
                    )
                end),

                [Children] = item
            }
        }
    end, Fusion.cleanup)
    local itemsContainer = Value()

    local function rotateItems()
        if not itemsContainer:get() then
            return
        end

        local itemsContainer = itemsContainer:get()

        local tween = TweenService:Create(
            itemsContainer,
            TweenInfo.new(0.5),
            {
                Position = UDim2.fromScale(-1 / itemsPerPage:get(), 0)
            }
        )
        tween.Completed:Connect(function()
            -- move first item to end and reset container position
            local itemWrappers = items:get()

            if #itemWrappers > 0 then
                Utils.sortByKey(itemWrappers, "LayoutOrder")
                itemWrappers[1].LayoutOrder += #items:get()
            end

            itemsContainer.Position = UDim2.fromScale(0, 0)
        end)

        tween:Play()
    end

    -- use heartbeat event instead of task.wait() to ensure that all carousels with the same interval are timed together
    local rotateDebounce = 0
    local signal = RunService.Heartbeat:Connect(function()
        local t = math.floor(tick() / props.Interval:get())

        if t ~= rotateDebounce then
            rotateDebounce = t

            if not props.Pause:get() then
                rotateItems()
            end
        end
    end)

    return New "CanvasGroup" {
        Name = props.Name,
        Parent = props.Parent,
        Position = props.Position,
        Size = props.Size,
        AnchorPoint = props.AnchorPoint,
        BackgroundTransparency = 1,

        [Cleanup] = function()
            signal:Disconnect()
        end,

        [Out "AbsoluteSize"] = absoluteSize,

        [Children] = New "Frame" {
            BackgroundTransparency = 1,
            Size = Computed(function()
                return UDim2.new(0, totalWidth:get(), 1, 0)
            end),

            [Ref] = itemsContainer,

            [Children] = {
                New "UIListLayout" {
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                },
                items
            }
        }
    }
end