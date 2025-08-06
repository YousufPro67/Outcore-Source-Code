local BloxbizSDK = script.Parent.Parent.Parent.Parent

local Components = BloxbizSDK:WaitForChild("CatalogClient"):WaitForChild("Components")
local ScaledText = require(Components.ScaledText)

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FP = require(UtilsStorage:WaitForChild("FusionProps"))

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local Value = Fusion.Value
local Ref = Fusion.Ref
local OnChange = Fusion.OnChange
local OnEvent = Fusion.OnEvent

return function (props)
    props = FP.GetValues(props, {
        Name = "Banner",
        Parent = FP.Nil,
        BackgroundColorHex = "#bdc1ca",
        BackgroundImageId = FP.Nil,
        TextColorHex = FP.Nil,
        HeaderText = FP.Nil,
        SubheaderText = FP.Nil,

        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        LayoutOrder = 0
    })

    local textColor = Computed(function()
        local propsTextColor, propsBgColor = props.TextColorHex:get(), props.BackgroundColorHex:get()

        if propsTextColor then
            return Color3.fromHex(propsTextColor)
        end

        return Utils.getTextColor(propsBgColor)
    end)

    return New "ImageLabel" {
        Name = props.Name,
        Parent = props.Parent,
        Size = props.Size,
        Position = props.Position,
        LayoutOrder = props.LayoutOrder,

        Image = Computed(function()
            if props.BackgroundImageId:get() then
                return ("rbxassetid://%s"):format(props.BackgroundImageId:get())
            else
                return ""
            end
        end),
        ScaleType = Enum.ScaleType.Crop,

        BackgroundColor3 = Computed(function()
            return Color3.fromHex(props.BackgroundColorHex:get())
        end),

        [Children] = {
            New "UIAspectRatioConstraint" {
                AspectRatio = 7,
                DominantAxis = Enum.DominantAxis.Width,
                AspectType = Enum.AspectType.FitWithinMaxSize
            },
            New "UICorner" {
                CornerRadius = UDim.new(0.08, 0)
            },

            ScaledText {
                Name = "Header",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.fromScale(0.9, 1 / 4),
                Position = Computed(function()
                    if props.SubheaderText:get() then
                        return UDim2.fromScale(0.5, 0.4)
                    else
                        return UDim2.fromScale(0.5, 0.5)
                    end
                end),

                Font = Enum.Font.GothamBlack,
                Text = props.HeaderText,
                TextColor3 = textColor,
            },

            Computed(function()
                if props.SubheaderText:get() then
                    return ScaledText {
                        Name = "Subheader",
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Size = UDim2.fromScale(0.9, 1 / 6),
                        Position = UDim2.fromScale(0.5, 0.64),
        
                        Font = Enum.Font.GothamBold,
                        Text = props.SubheaderText,
                        TextColor3 = textColor,
                    }
                end
            end, Fusion.cleanup),
        }
    }
end