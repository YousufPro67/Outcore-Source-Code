local TextService = game:GetService("TextService")

local BloxbizSDK = script.Parent.Parent.Parent.Parent.Parent
local CatalogClient = BloxbizSDK.CatalogClient

local Components = CatalogClient.Components

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local ScaledText = require(Components.ScaledText)

local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local New = Fusion.New
local Ref = Fusion.Ref
local OnChange = Fusion.OnChange
local Computed = Fusion.Computed
local Observer = Fusion.Observer
local Spring = Fusion.Spring
local Cleanup = Fusion.Cleanup
local Value = Fusion.Value
local ForValues = Fusion.ForValues
local Out = Fusion.Out

local Color = {
	Default = Color3.fromRGB(20, 20, 20),
	MouseDown = Color3.fromRGB(15, 15, 15),
	Hover = Color3.fromRGB(30, 30, 30),
    Selected = Color3.fromRGB(255, 255, 255)
}

local TextColor = {
	Disabled = Color3.fromRGB(155, 155, 155),
	Default = Color3.fromRGB(223, 223, 223)
}


return function (props)
    props = FusionProps.GetValues(props, {
        Parent = FusionProps.Nil,
        AnchorPoint = Vector2.new(0, 0),
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        LayoutOrder = 0,
        Visible = true,
        Text = "",
        Count = FusionProps.Nil,
        Icon = "",
        TextColor3 = Color3.new(0.7, 0.7, 0.7),
        IconSize = 0.5
    })

    local contentSize = Value(Vector2.zero)
    local absSize = Value(Vector2.zero)

    local countText = Computed(function()
        local text = props.Text:get()
        local fullText = props.Count:get() and Utils.toSuffixNumber(props.Count:get()) or ""

        if text ~= "" then
            fullText ..= " " .. text
        end

        return fullText
    end)

    local textSize = Computed(function()
        return (absSize:get() or Vector2.zero).Y / 2
    end)

    local textWidth = Computed(function()
        return TextService:GetTextSize(countText:get(), textSize:get(), Enum.Font.GothamMedium, Vector2.new(math.huge, math.huge)).X
    end)

    return New "Frame" {
        BackgroundTransparency = 1,
        Position = props.Position,
        LayoutOrder = props.LayoutOrder,
        Visible = props.Visible,
        Size = Computed(function()
            return UDim2.new(
                UDim.new(0, (absSize:get() or Vector2.zero).Y * 0.8 + textWidth:get()),
                props.Size:get().Y
            )
        end),

        [Out "AbsoluteSize"] = absSize,
        
        [Children] = {
            New "UIListLayout" {
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = Computed(function()
                    return UDim.new(0, (absSize:get() or Vector2.zero).Y / 5)
                end),
            },

            New "ImageLabel" {
                BackgroundTransparency = 1,
                Size = Computed(function()
                    return UDim2.fromOffset(props.IconSize:get() * (absSize:get() or Vector2.zero).Y, props.IconSize:get() * (absSize:get() or Vector2.zero).Y)
                end),
                Image = props.Icon,
                ImageColor3 = props.TextColor3
            },

            New "TextLabel" {
                LayoutOrder = 2,
                BackgroundTransparency = 1,
                Size = Computed(function()
                    return UDim2.new(0, textWidth:get(), 1, 0)
                end),

                TextColor3 = props.TextColor3,
                TextSize = textSize,
                Font = Enum.Font.GothamMedium,
                Text = countText,
                TextXAlignment = Enum.TextXAlignment.Left
            }
        }
    }
end