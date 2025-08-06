local TextService = game:GetService("TextService")

local BloxbizSDK = script.Parent.Parent.Parent
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
        Text = FusionProps.Nil,
        Count = FusionProps.Nil,
        Icon = "",
        Alignment = "Left",
        Disabled = false,
        Padding = 8,
        Selected = false,
        OnClick = FusionProps.Callback,
        TextColor3 = Color3.new(1, 1, 1),
        IconSize = 0.5
    })

    local isHovering = Value(false)
    local isMouseDown = Value(false)

    local buttonColorSpring = Spring(
		Computed(function()
            if props.Selected:get() then
                return Color.Selected
            end

			if not props.Disabled:get() then
				if isMouseDown:get() then
					return Color.MouseDown
				elseif isHovering:get() then
					return Color.Hover
				else
					return Color.Default
				end
			else
				return Color.Default
			end
		end), 20
	)

	local textColorSpring = Spring(
		Computed(function()
			if isMouseDown:get() or props.Disabled:get() then
				return TextColor.Disabled
			else
				return TextColor.Default
			end
		end), 20
	)

    local btnRef = Value()
    local _btnSize = Value(Vector2.zero)
    local btnSize = Computed(function()
        return _btnSize:get() or Vector2.zero  -- workaround to apparent fusion bug
    end)

    local buttonText = Computed(function()
        local count = props.Count:get()
        local text = props.Text:get()

        if text then
            return text
        else
            return count and Utils.toLocaleNumber(count) or nil
        end
    end)

    local textWidth = Computed(function()
        local textSize = TextService:GetTextSize(buttonText:get(), btnSize:get().Y / 2, Enum.Font.GothamMedium, Vector2.new(math.huge, math.huge))

        return textSize.X
    end)

    local padding = Computed(function()
        return btnSize:get().Y * (1 - props.IconSize:get()) / 2
    end)

    local bgTransparency = Spring(Computed(function()
        if props.Disabled:get() then
            return 0.5
        else
            return 0.1
        end
    end), 30)

    return New "TextButton" {
        Parent = props.Parent,
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        Size = Computed(function()
            return UDim2.new(
                0, (btnSize:get() or Vector2.zero).Y * props.IconSize:get() + textWidth:get() + padding:get() * (buttonText:get() and 3.5 or 2) - 1,
                1, 0
            )
        end),
        Visible = props.Visible,

        BackgroundColor3 = buttonColorSpring,
        LayoutOrder = props.LayoutOrder,
        BackgroundTransparency = bgTransparency,

        -- handle button size
        [Ref] = btnRef,
        [Fusion.Out "AbsoluteSize"] = _btnSize,

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

        [OnEvent "Activated"] = function()
            local cb = props.OnClick:get()

            if cb and not props.Disabled:get() then
                cb()
            end
        end,
        
        [Children] = {
            New "UIListLayout" {
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = Computed(function() return UDim.new(0, padding:get()) end)
            },
            New "UIPadding" {
                PaddingLeft = Computed(function() return UDim.new(0, padding:get()) end),
                PaddingRight = Computed(function() return UDim.new(0, padding:get()) end)
            },

            New "ImageLabel" {
                Name = "Icon",
                Image = props.Icon,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = Computed(function()
                    return UDim2.new(0, btnSize:get().Y/2, 0.5, 0)
                end),
                Size = Computed(function()
                    return UDim2.new(0, btnSize:get().Y * props.IconSize:get(), 0, btnSize:get().Y * props.IconSize:get())
                end),
                ImageTransparency = bgTransparency,
            },

            New "TextLabel" {
                Visible = Computed(function() return buttonText:get() ~= nil end),
                BackgroundTransparency = 1,
                LayoutOrder = 2,
                AnchorPoint = Vector2.new(0, 0.5),
                Size = Computed(function()
                    return UDim2.new(0, textWidth:get(), 0.5, 0)
                end),

                Text = buttonText,
                TextSize = Computed(function()
                    return (btnSize:get() or Vector2.zero).Y / 2
                end),
                Font = Enum.Font.GothamMedium,
                TextColor3 = Spring(Computed(function()
                    if props.Selected:get() then
                        return Color3.new(0, 0, 0)
                    else
                        return props.TextColor3:get()
                    end
                end), 30)
            },

            New "UIStroke" {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Color = Color3.fromRGB(79, 84, 95),
                Thickness = 1.5,
            },
            New("UICorner")({
                Name = "UICorner",
                CornerRadius = UDim.new(0.25, 0),
            }),
        }
    }
end