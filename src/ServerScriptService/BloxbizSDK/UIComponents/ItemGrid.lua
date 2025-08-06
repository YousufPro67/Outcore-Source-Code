local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local BloxbizSDK = script.Parent.Parent

local Fusion = require(BloxbizSDK.Utils.Fusion)
local FP = require(BloxbizSDK.Utils.FusionProps)

local New = Fusion.New
local OnEvent = Fusion.OnEvent
local Ref = Fusion.Ref
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local Out = Fusion.Out

return function (props)
    props = FP.GetValues(props, {
        Parent = FP.Nil,
        Name = "ItemGrid",

        LayoutOrder = 0,
        AnchorPoint = Vector2.zero,
        Position = UDim2.fromScale(0, 0),
        Size = UDim2.fromScale(1, 1),
        Visible = true,
        Gap = 5,
        MinItemWidth = 200,
        Columns = FP.Nil,
        ItemRatio = 4/5,

        DragScroll = false,

        [Children] = FP.Nil
    })

    local DragScroll = Computed(function()
        return props.DragScroll:get() and not UserInputService.TouchEnabled
    end)

    local absSize = Value(Vector2.zero)

    local cellWidth = Computed(function()
        local size = absSize:get() or Vector2.zero

        local totalWidth = size.X
        local gap = props.Gap:get()
        local cellsX = props.Columns:get() or math.floor((totalWidth + gap) / (props.MinItemWidth:get() + gap))

        return (totalWidth - gap * (cellsX - 1)) / cellsX
    end)
    local cellHeight = Computed(function()
        return cellWidth:get() / props.ItemRatio:get()
    end)

    local contentSize = Value(Vector2.zero)

    local scrollRef = Value()
    local mouse = Players.LocalPlayer:GetMouse()

    local isHovering = Value(false)
    local mouseDown = Value(false)

    local sigs = {}
    table.insert(sigs, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and isHovering:get() and props.Visible:get() then
            mouseDown:set(true)
        end
    end))
    table.insert(sigs, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            mouseDown:set(false)
        end
    end))

    if DragScroll:get() == true then
        local prevY
        local scrollVel = 0
        table.insert(sigs, RunService.RenderStepped:Connect(function (dt)
            local scrollingFrame = scrollRef:get()
            if not scrollingFrame then
                return
            end

            if mouseDown:get() then
                local deltaY = mouse.Y - prevY
                scrollVel = deltaY / dt

                scrollingFrame.CanvasPosition = Vector2.new(
                    scrollingFrame.CanvasPosition.X,
                    scrollingFrame.CanvasPosition.Y - deltaY
                )
            else
                if scrollVel ~= 0 then
                    -- deceleration
                    scrollVel = math.sign(scrollVel) * (math.max(0, math.abs(scrollVel) - 5000 * dt))
                    -- scrollVel = scrollVel * 0.9

                    scrollingFrame.CanvasPosition = Vector2.new(
                        scrollingFrame.CanvasPosition.X,
                        scrollingFrame.CanvasPosition.Y - scrollVel * dt
                    )
                end
            end

            prevY = mouse.Y
        end))
    end

    return New "Frame" {
        Parent = props.Parent,
        LayoutOrder = props.LayoutOrder,
        Name = props.Name,
        Visible = props.Visible,
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        Size = props.Size,

        [Fusion.Cleanup] = function()
            Fusion.cleanup(sigs)
        end,

        [Out "AbsoluteSize"] = absSize,

        BackgroundTransparency = 1,

        [OnEvent "MouseEnter"] = function()
            isHovering:set(true)
        end,
        [OnEvent "MouseLeave"] = function()
            isHovering:set(false)
            mouseDown:set(false)
        end,

        [Children] = New "ScrollingFrame" {
            Size = UDim2.fromScale(1, 1),
            CanvasSize = Computed(function()
                local size = contentSize:get() or Vector2.zero

                return UDim2.new(
                    1, 0,
                    0, size.Y
                )
            end),
            ScrollBarThickness = 0,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            [Ref] = scrollRef,

            [Children] = {
                New "Frame" {
                    Name = "Content",
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Visible = props.ContentVisible,

                    [Children] = {
                        New "UIGridLayout" {
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            CellPadding = Computed(function()
                                return UDim2.fromOffset(props.Gap:get(), props.Gap:get())
                            end),
                            CellSize = Computed(function()
                                local size = absSize:get() or Vector2.zero

                                return UDim2.new(
                                    cellWidth:get() / size.X, 0,
                                    0, cellHeight:get()
                                )
                            end),
                            [Out "AbsoluteContentSize"] = contentSize,
                        },
                        props[Children]
                    }
                },

                props.ScrollingFrameChildren,
            },
        }
    }
end