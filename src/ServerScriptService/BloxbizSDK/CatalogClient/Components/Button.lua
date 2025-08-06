local BloxbizSDK = script.Parent.Parent.Parent
local Components = script.Parent

local ScaledText = require(Components.ScaledText)

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FP = require(UtilsStorage:WaitForChild("FusionProps"))
local Promise = require(UtilsStorage:WaitForChild("Promise"))

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local Spring = Fusion.Spring
local ForValues = Fusion.ForValues
local Value = Fusion.Value
local Ref = Fusion.Ref
local OnChange = Fusion.OnChange
local OnEvent = Fusion.OnEvent

return function (props)
    props = FP.GetValues(props, {
        Parent = FP.Nil,
        LayoutOrder = 0,
        AnchorPoint = Vector2.zero,
        Position = UDim2.fromScale(0, 0),
        Size = UDim2.fromScale(1, 1),

        BackgroundColor3 = Color3.new(1, 1, 1),
        TextColor3 = Color3.new(0, 0, 0),

        Text = "",
        Disabled = false,
        OnClick = FP.Callback
    })

    return New "TextButton" {
        Parent = props.Parent,
        LayoutOrder = props.LayoutOrder,
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        Size = props.Size,

        BackgroundColor3 = props.BackgroundColor3,
        AutoButtonColor = Computed(function()
            return not props.Disabled:get()
        end),
        Text = "",

        [OnEvent "Activated"] = function()
            if not props.Disabled:get() then
                props.OnClick:get()()
            end
        end,

        [Children] = {
            New "UICorner" {
                CornerRadius = UDim.new(0.2, 0)
            },
            ScaledText {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(0.8, 0.5),
                TextColor3 = props.TextColor3,
                Text = props.Text
            }
        }
    }
end