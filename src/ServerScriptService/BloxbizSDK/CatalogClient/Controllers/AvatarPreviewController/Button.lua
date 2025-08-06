local TextService = game:GetService("TextService")

local BloxbizSDK = script.Parent.Parent.Parent.Parent
local CatalogClient = BloxbizSDK.CatalogClient

local Components = CatalogClient.Components

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
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
        Visible = true,
        Text = "",
        Count = FusionProps.Nil,
        Icon = "",
        Alignment = "Left",
        Disabled = false,
        Padding = 8,
        Selected = false,
        OnClick = FusionProps.Nil,
        IconSize = 0.6
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
    local btnWidth = Value(0)
    local btnHeight = Value(0)

    local sig = Observer(btnRef):onChange(function()
        local btn = btnRef:get()

        if btn then
            btnWidth:set(btn.AbsoluteSize.X)
            btnHeight:set(btn.AbsoluteSize.Y)
        end
    end)

    local ratio = Computed(function()
        if props.Count:get() then
            return 1.8
        else
            return 1
        end
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
        Size = props.Size,
        Visible = props.Visible,

        BackgroundColor3 = buttonColorSpring,
        LayoutOrder = Computed(function ()
            if props.Alignment:get() == "Left" then
                return 1
            else
                return 2
            end
        end),
        BackgroundTransparency = bgTransparency,

        -- handle button size
        [Ref] = btnRef,
        [OnChange "AbsoluteSize"] = function (size)
            btnWidth:set(size.X)
            btnHeight:set(size.Y)
        end,
        [Fusion.Cleanup] = function()
            Fusion.cleanup(sig)
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

        [OnEvent "Activated"] = function()
            local cb = props.OnClick:get()

            if cb and not props.Disabled:get() then
                cb()
            end
        end,
        
        [Children] = {
            Computed(function()
                if type(props.Icon:get()) == "string" then
                    return New "ImageLabel" {
                        Name = "Icon",
                        Image = props.Icon,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Position = Computed(function()
                            return UDim2.new(0, btnHeight:get()/2, 0.5, 0)
                        end),
                        Size = Computed(function()
                            return UDim2.new(0, btnHeight:get() * props.IconSize:get(), 0, btnHeight:get() * props.IconSize:get())
                        end),
                        ImageTransparency = bgTransparency,
                    }
                else
                    return New "Frame" {
                        Name = "Icon",
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = Computed(function()
                            return UDim2.new(0, btnHeight:get()/2, 0.5, 0)
                        end),
                        Size = Computed(function()
                            return UDim2.new(0, btnHeight:get() * props.IconSize:get(), 0, btnHeight:get() * props.IconSize:get())
                        end),
                        [Children] = props.Icon:get()()
                    }
                end
            end, Fusion.cleanup),

            ScaledText({
                Visible = Computed(function() return props.Count:get() ~= nil end),
                AnchorPoint = Vector2.new(0, 0.5),
                Position = Computed(function()
                    return UDim2.new(0, btnHeight:get() - 3, 0.5, 0)
                end),
                Size = Computed(function()
                    return UDim2.new(0, btnWidth:get() - btnHeight:get() - 5, 0.5, 0)
                end),
                Text = Computed(function()
                    return tostring(props.Count:get())
                end),
                TextColor3 = Spring(Computed(function()
                    if props.Selected:get() then
                        return Color3.new(0, 0, 0)
                    else
                        return Color3.new(1, 1, 1)
                    end
                end), 30)
            }),

            New "UIAspectRatioConstraint" {
                AspectRatio = ratio,
                DominantAxis = Enum.DominantAxis.Height
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