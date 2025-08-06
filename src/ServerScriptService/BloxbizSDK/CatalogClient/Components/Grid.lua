local BloxbizSDK = script.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))
local Promise = require(UtilsStorage:WaitForChild("Promise"))

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local ForValues = Fusion.ForValues
local Computed = Fusion.Computed
local Out = Fusion.Out

export type GridCell = {
    X: number,
    Y: number,
    Width: number?,
    Height: number?,
    Element: Instance | {Instance} | Fusion.Value<Instance> | Fusion.Value<{Instance}>
}

return function(props)
    props = FusionProps.GetValues(props, {
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        AnchorPoint = Vector2.new(0, 0),

        LayoutOrder = 1,
        CellsX = 1,
        CellsY = 1,
        Padding = UDim.new(0, 0),
        Content = {},
        
        Name = "Grid",
        Parent = FusionProps.Nil,
        [Children] = FusionProps.Nil
    })

    local containerSize = Value(Vector2.zero)
    local paddingPX = Computed(function()
        local padding = props.Padding:get()
        return math.min(containerSize:get().X, containerSize:get().Y) * padding.Scale + padding.Offset
    end)
    local cellWidthPX = Computed(function()
        local containerWidth = containerSize:get().X
        local padding = paddingPX:get()
        local cellCount = props.CellsX:get()
        return (containerWidth - padding * (cellCount - 1)) / cellCount
    end)
    local cellHeightPX = Computed(function()
        local containerHeight = containerSize:get().Y
        local padding = paddingPX:get()
        local cellCount = props.CellsY:get()
        return (containerHeight - padding * (cellCount - 1)) / cellCount
    end)

    return New "CanvasGroup" {
        Parent = props.Parent,
        Name = props.Name,

        Size = props.Size,
        Position = props.Position,
        AnchorPoint = props.AnchorPoint,

        BackgroundTransparency = 1,
        GroupTransparency = props.Transparency,
        Visible = props.Visible,
        LayoutOrder = props.LayoutOrder,

        [Out "AbsoluteSize"] = containerSize,

        [Children] = ForValues(props.Content, function (cell: GridCell)
            cell.Width = cell.Width or 1
            cell.Height = cell.Height or 1

            return New "Frame" {
                BackgroundTransparency = 1,
                Position = Computed(function()
                    return UDim2.fromOffset(
                        cell.X * cellWidthPX:get() + cell.X * paddingPX:get(),
                        cell.Y * cellHeightPX:get() + cell.Y * paddingPX:get()
                    )
                end),
                Size = Computed(function()
                    return UDim2.fromOffset(
                        cell.Width * cellWidthPX:get() + (cell.Width - 1) * paddingPX:get(),
                        cell.Height * cellHeightPX:get() + (cell.Height - 1) * paddingPX:get()
                    )
                end),
                [Children] = cell.Element
            }
        end, Fusion.cleanup)
    }
end