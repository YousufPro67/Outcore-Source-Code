local BloxbizSDK = script.Parent.Parent.Parent
local Components = script.Parent

local ScaledText = require(Components.ScaledText)

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))
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

export type Option = {
    label: string,
    value: string,
    icon: string?
}

export type Props = {
    Parent: Instance?,
    Size: UDim2?,
    Position: UDim2?,
    AnchorPoint: Vector2?,
    LayoutOrder: number?,
    Value: string?,
    Options: { Option },
    OnChange: (string) -> (),
    LabelPrefix: string?,
    Placeholder: string?,
    Disabled: boolean?
}

return function(props)
    props = FusionProps.GetValues(props, {
        HideStroke = false,
        Parent = FusionProps.Nil,
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        AnchorPoint = Vector2.zero,
        LayoutOrder = 0,
        OnChange = FusionProps.Nil,
        LabelPrefix = FusionProps.Nil,
        Value = FusionProps.Nil,
        SelectedOption = FusionProps.Nil,
        Placeholder = "Pick an option",
        Options = {},
        Disabled = false,
        Visible = true,
        TextTransparency = 0,

        TrayOpen = false,

        Colors = {
            Default = Color3.fromRGB(20, 20, 20),
            MouseDown = Color3.fromRGB(15, 15, 15),
            Hover = Color3.fromRGB(30, 30, 30),
            Disabled = Color3.fromRGB(128, 128, 128),
        },
    
        TextColor = {
            Disabled = Color3.fromRGB(128, 128, 128),
            Default = Color3.fromRGB(255, 255, 255),
        }
    })

    local containerHeight = Value(0)
    local containerRef = Value()

    local containerRefSig = Fusion.Observer(containerRef):onChange(function()
        local inst = containerRef:get()
        if inst then
            containerHeight:set(inst.AbsoluteSize.Y)
        end
    end)

    local currentOption = Computed(function()
        local val = props.Value:get()

        if val then
            return Utils.search(props.Options:get(), function(item)
                return item.value == val
            end)
        end
    end)
    local notSelected = Computed(function()
        local options = props.Options:get()
        local val = props.Value:get()

        return Utils.filter(options, function(opt)
            return opt.value ~= val
        end)
    end)
    local numNotSelected = Computed(function()
        return #(notSelected:get())
    end)

    local absCornerRadius = Computed(function()
        return UDim.new(0, 0.225 * containerHeight:get())
    end)

    local isHovering = Value(false)
    local isMouseDown = Value(false)

    local isTrayOpen = props.TrayOpen

    return New "Frame" {
        Name = "Dropdown",
        Parent = props.Parent,

        Size = props.Size,
        Position = props.Position,
        AnchorPoint = props.AnchorPoint,
        LayoutOrder = props.LayoutOrder,
        BackgroundTransparency = 1,
        Visible = props.Visible,

        [Fusion.Cleanup] = function()
            Fusion.cleanup(containerRefSig)
        end,

        [OnChange("AbsoluteSize")] = function(size)
            containerHeight:set(size.Y)
        end,
        [Children] = {
            New "TextButton" {
                Size = UDim2.fromScale(1, 1),
                Text = "",
                BackgroundColor3 = Fusion.Spring(Fusion.Computed(function()
                    if props.Disabled:get() then
                        return props.Colors:get().Disabled
                    end
                    if isMouseDown:get() then
                        return props.Colors:get().MouseDown
                    elseif isTrayOpen:get() or isHovering:get() then
                        return props.Colors:get().Hover
                    else
                        return props.Colors:get().Default
                    end
                end)),

                -- button events

                [OnEvent("Activated")] = function()
                    if props.Disabled:get() then
                        return
                    end
                    isTrayOpen:set(not isTrayOpen:get())
                end,
        
                [OnEvent("MouseButton1Down")] = function()
                    isMouseDown:set(true)
                end,
        
                [OnEvent("MouseButton1Up")] = function()
                    isMouseDown:set(false)
                end,
        
                [OnEvent("MouseEnter")] = function()
                    isHovering:set(true)
                end,
        
                [OnEvent("MouseLeave")] = function()
                    isHovering:set(false)
                    isMouseDown:set(false)
                end,

                [Children] = {
                    -- UI effects

                    New("UICorner")({
                        Name = "UICorner",
                        CornerRadius = UDim.new(0.225, 0),
                    }),
        
                     New("UIStroke")({
                        Name = "StandardStroke",
                        Color = Color3.fromRGB(79, 84, 95),
                        Thickness = 1.5,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        Enabled = not props.HideStroke:get(),
                    }),

                    -- button text & arrow

                    ScaledText({
                        Name = "Label",
                        AnchorPoint = Vector2.new(0, 0.5),
                        Position = UDim2.fromScale(0.1, 0.5),
                        Size = Computed(function()
                            return UDim2.new(0.9, -(containerHeight:get()), 0.5, 0)
                        end),
                        TextTransparency = props.TextTransparency,
                        RichText = true,

                        TextColor3 = Computed(function()
                            if props.Disabled:get() then
                                return props.TextColor:get().Disabled
                            end

                            return props.TextColor:get().Default
                        end),

                        Text = Computed(function()
                            local current = currentOption:get()

                            if not current then
                                return props.Placeholder:get() or props.LabelPrefix:get()
                            else
                                local text = current.label
                                local prefix = props.LabelPrefix:get()
                                
                                if prefix then
                                    return string.format('<font color="#%s">%s</font> %s', props.TextColor:get().Disabled:ToHex(), prefix, text)
                                else
                                    return text
                                end
                            end

                            return current.label
                        end)
                    }),

                    New("ImageLabel")({
                        Name = "Arrow",
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = Computed(function()
                            local ht = containerHeight:get()

                            return UDim2.new(1, -ht/2, 0.5, 0)
                        end),
                        Size = Computed(function()
                            local ht = containerHeight:get()

                            return UDim2.fromOffset(ht/4, ht/4 * (64/107))
                        end),
                        BackgroundTransparency = 1,
                        Image = "rbxassetid://14908359196",
                        ImageColor3 = props.TextColor:get().Disabled,
                        Rotation = Spring(Computed(function()
                            if isTrayOpen:get() then
                                return 180
                            else
                                return 0
                            end
                        end), 30),
                    }),

                    -- tray

                    New "Frame" {
                        Name = "Tray",
                        Position = UDim2.new(0, 0, 1, 8),
                        Size = Computed(function()
                            return UDim2.new(1, 0, 0, numNotSelected:get() * containerHeight:get())
                        end),
                        Visible = isTrayOpen,
                        ClipsDescendants = true,
                        BackgroundColor3 = props.Colors:get().Default,
                        ZIndex = 100,

                        [Children] = {
                            New("UICorner")({
                                CornerRadius = absCornerRadius,
                            }),
                            New("UIStroke")({
                                Name = "StandardStroke",
                                Color = Color3.fromRGB(79, 84, 95),
                                Thickness = 1.5,
                                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                                Enabled = not props.HideStroke:get(),
                            }),
                            New("UIListLayout")({
                                SortOrder = Enum.SortOrder.LayoutOrder
                            }),

                            Fusion.ForPairs(notSelected, function(idx, option)
                                return idx, New "TextButton" {
                                    Name = option.value,

                                    Size = UDim2.new(1, 0, 0, containerHeight:get()),
                                    BackgroundColor3 = props.Colors:get().Default,
                                    AutoButtonColor = true,
                                    Text = "",
                                    LayoutOrder = idx,

                                    [OnEvent("Activated")] = function()
                                        props.Value:set(option.value)
                                        props.SelectedOption:set(option)

                                        isTrayOpen:set(false)

                                        local cb = props.OnChange:get()
                                        if cb then
                                            cb(option.value)
                                        end
                                    end,

                                    [Children] = {
                                        ScaledText({
                                            AnchorPoint = Vector2.new(0.5, 0.5),
                                            Position = UDim2.fromScale(0.5, 0.5),
                                            Size = UDim2.fromScale(0.8, 0.5),
                                            Text = option.label
                                        }),
                                        New("UICorner")({
                                            CornerRadius = UDim.new(0, absCornerRadius:get().Offset + 1)
                                        }),
                                    }
                                }
                            end, Fusion.cleanup)
                        }
                    }
                }
            }
        }
    }
end