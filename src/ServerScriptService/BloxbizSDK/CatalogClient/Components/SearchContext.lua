local TextService = game:GetService("TextService")

local BloxbizSDK = script.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))
local Promise = require(UtilsStorage:WaitForChild("Promise"))

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Out = Fusion.Out

return function(props)
    props = FusionProps.GetValues(props, {
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        AnchorPoint = Vector2.new(1, 0),
        Alignment = "Right",

        SearchTerm = "",
        SearchingIn = "",
        Visible = true,
        OnSearchAll = FusionProps.Nil,
        SearchAllText = "Search All Items",
        
        Parent = FusionProps.Nil,
        [Children] = FusionProps.Nil
    })

    local frameSize = Value(Vector2.zero)
    local textSize = Computed(function()
        return frameSize:get().Y
    end)

    local searchAllWidth = Computed(function()
        return TextService:GetTextSize(
            props.SearchAllText:get(),
            textSize:get(),
            Enum.Font.GothamBold,
            Vector2.new(math.huge, math.huge)
        ).X
    end)

    local infoText = Computed(function()
        return string.format("Searching %s in %s.", props.SearchTerm:get() or "", props.SearchingIn:get() or "")
    end)
    local infoRichText = Computed(function()
        return string.format("Searching <b>%s</b> in <b>%s</b>.", props.SearchTerm:get() or "", props.SearchingIn:get() or "")
    end)

    local infoTextWidth = Computed(function()
        return TextService:GetTextSize(
            infoText:get(),
            textSize:get(),
            Enum.Font.GothamBold,
            Vector2.new(math.huge, math.huge)
        ).X
    end)

    local totalWidth = Computed(function()
        return infoTextWidth:get() + searchAllWidth:get() + textSize:get() / 2
    end)
    local scale = Computed(function()
        return math.min(1, frameSize:get().X / totalWidth:get())
    end)

    return New "Frame" {
        Parent = props.Parent,
        Position = props.Position,
        Size = props.Size,
        AnchorPoint = props.AnchorPoint,
        BackgroundTransparency = 1,
        Visible = props.Visible,

        [Out "AbsoluteSize"] = frameSize,

        [Children] = {
            New "Frame" {
                Name = "ScaledContainer",
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                AnchorPoint = props.AnchorPoint,
                Position = Computed(function()
                    return UDim2.fromScale(props.AnchorPoint:get().X, props.AnchorPoint:get().Y)
                end),

                [Children] = {
                    New "UIScale" {
                        Scale = scale
                    },
                    New "UIListLayout" {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Right,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = Computed(function()
                            return UDim.new(0, textSize:get() / 2)
                        end)
                    },
        
                    New "TextLabel" {
                        Name = "Info",
                        LayoutOrder = 1,
                        BackgroundTransparency = 1,
        
                        TextColor3 = Color3.new(1, 1, 1),
                        Text = infoRichText,
                        RichText = true,
                        TextSize = textSize,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        Font = Enum.Font.GothamMedium,
        
                        Size = Computed(function()
                            return UDim2.new(0, infoTextWidth:get(), 1, 0)
                        end)
                    },
                    New "TextButton" {
                        Name = "Button",
                        LayoutOrder = 2,
                        BackgroundTransparency = 1,
        
                        TextColor3 = Color3.fromRGB(95, 166, 255),
                        Text = Computed(function()
                            return "<b>" .. props.SearchAllText:get() .. "</b>"
                        end),
                        RichText = true,
                        TextSize = textSize,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
        
                        Size = Computed(function()
                            return UDim2.new(0, searchAllWidth:get(), 1, 0)
                        end),
        
                        [OnEvent "Activated"] = function()
                            local cb = props.OnSearchAll:get()
                            if cb then
                                cb()
                            end
                        end
                    }
                }
            },
        }
    }
end