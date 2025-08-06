local BloxbizSDK = script.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))
local Promise = require(UtilsStorage:WaitForChild("Promise"))

local New = Fusion.New
local Children = Fusion.Children
local Cleanup = Fusion.Cleanup
local Observer = Fusion.Observer
local Value = Fusion.Value
local Ref = Fusion.Ref
local OnChange = Fusion.OnChange

return function(props)
    props = FusionProps.GetValues(props, {
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        AnchorPoint = Vector2.new(0, 0),

        Text = "",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamMedium,
        MaxSize = 36,
        RichText = false,
        TextTransparency = 0,
        Rotation = 0,
        Visible = true,
        LayoutOrder = 0,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 1,

        Name = "TextLabel",
        Parent = FusionProps.Nil,
        [Children] = FusionProps.Nil
    })

    local textLabel = Value()

    local function updateTextSize()
        if not textLabel:get() then return end
    
        local textLabelInst = textLabel:get()
    
        textLabelInst.TextSize = math.min(textLabelInst.AbsoluteSize.Y, props.MaxSize:get())
    
        local textWidth = textLabelInst.TextBounds.X
        local maxWidth = textLabelInst.AbsoluteSize.X
    
        if textWidth > maxWidth then
            textLabelInst.TextSize *= maxWidth / textWidth
        end
    end

    local font = Fusion.Computed(function()
        local ff = props.Font:get()
        if typeof(ff) == "EnumItem" then
            return Font.fromEnum(ff)
        else
            return ff
        end
    end)

    local sigs = {}
    table.insert(sigs, Observer(props.Text):onChange(updateTextSize))
    table.insert(sigs, Observer(props.MaxSize):onChange(updateTextSize))
    table.insert(sigs, Observer(props.Font):onChange(updateTextSize))

    task.delay(0.5, updateTextSize)

    return New "TextLabel" {
        Size = props.Size,
        Position = props.Position,
        AnchorPoint = props.AnchorPoint,
        BackgroundTransparency = 1,
        Rotation = props.Rotation,
        ZIndex = props.ZIndex:get(),

        Name = props.Name,
        Parent = props.Parent,
        [Children] = props[Children],

        Text = props.Text,
        TextColor3 = props.TextColor3,
        FontFace = font,
        RichText = props.RichText,
        TextTransparency = props.TextTransparency,
        Visible = props.Visible,
        LayoutOrder = props.LayoutOrder,
        TextXAlignment = props.TextXAlignment,

        [Ref] = textLabel,

        [OnChange("AbsoluteSize")] = updateTextSize,

        [Cleanup] = function()
            Fusion.cleanup(sigs)
        end
    }
end