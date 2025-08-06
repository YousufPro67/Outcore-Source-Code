local BloxbizSDK = script.Parent.Parent.Parent.Parent.Parent
local CatalogClient = BloxbizSDK.CatalogClient
local Components = CatalogClient.Components

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))

local ScaledText = require(Components.ScaledText)

local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local New = Fusion.New
local Ref = Fusion.Ref
local Computed = Fusion.Computed
local Observer = Fusion.Observer
local Spring = Fusion.Spring
local Cleanup = Fusion.Cleanup
local Value = Fusion.Value
local ForValues = Fusion.ForValues

local SETTINGS = {
	Buttons = {
		{
			Name = "Save",
			Image = "rbxassetid://13729958499",
			Position = UDim2.fromScale(0.285, 1),
			AnchorPoint = Vector2.new(0, 1),
		},
		{
			Name = "Reset",
			Image = "rbxassetid://13729954132",

			Position = UDim2.fromScale(0.06, 1),
			AnchorPoint = Vector2.new(0, 1),
		},
		{
			Name = "Undo",
			Image = "rbxassetid://13729949413",
			Position = UDim2.fromScale(0.715, 1),
			AnchorPoint = Vector2.new(1, 1),
		},
		{
			Name = "Redo",
			Image = "rbxassetid://13729823355",
			Position = UDim2.fromScale(0.94, 1),
			AnchorPoint = Vector2.new(1, 1),
		},
	},

	Color = {
		Default = Color3.fromRGB(255, 255, 255),
		Hover = Color3.fromRGB(240, 240, 240),
		MouseDown = Color3.fromRGB(225, 225, 225),
	},

	TextColor = {
		Disabled = Color3.fromRGB(100, 100, 100),
		Default = Color3.fromRGB(0, 0, 0),
	},
}

export type Props = {
    Image: Fusion.CanBeState<string>,
    Position: Fusion.CanBeState<UDim2>,
    Size: Fusion.CanBeState<UDim2>,
    AnchorPoint: Fusion.CanBeState<Vector2>,
    Text: Fusion.CanBeState<string>,
    LayoutOrder: Fusion.CanBeState<number>?,
    Disabled: Fusion.CanBeState<boolean>?,
    Visible: Fusion.CanBeState<boolean>?,
    Stroke: Fusion.CanBeState<boolean>?,
    OnClick: () -> any,
}

local function ActionButton(_props: Props): { Instance: Frame, EnabledValue: Fusion.Value<boolean> }
    local props = FusionProps.GetValues(_props, {
        Disabled = false,
        LayoutOrder = 0,
        Stroke = false,
        Visible = true,
        Parent = FusionProps.Nil,
        Text = "",
        TextColor = FusionProps.Nil,
        OnClick = FusionProps.Nil
    })

    local TextColor = Computed(function()
        if props.TextColor:get() then
            return {
                Default = props.TextColor:get(),
                Disabled = SETTINGS.TextColor.Disabled
            }
        else
            return SETTINGS.TextColor
        end
    end)

	local isHovering = Value(false)
	local isHeldDown = Value(false)
	local isEnabled = Computed(function()
        return not props.Disabled:get()
    end)

	local buttonColorSpring = Spring(
		Computed(function()
			if isEnabled:get() then
				if isHeldDown:get() then
					return SETTINGS.Color.MouseDown
				elseif isHovering:get() then
					return SETTINGS.Color.Hover
				else
					return SETTINGS.Color.Default
				end
			else
				return SETTINGS.Color.Default
			end
		end),
		20,
		1
	)

	local textColorSpring = Spring(
		Computed(function()
			if isHeldDown:get() or not isEnabled:get() then
				return TextColor:get().Disabled
			else
				return TextColor:get().Default
			end
		end),
		20,
		1
	)

	return New("TextButton")({
        Name = props.Text,
        FontFace = Font.fromEnum(Enum.Font.GothamMedium),
        Text = "",
        TextColor3 = Color3.fromRGB(0, 0, 0),
        TextScaled = true,
        TextSize = 20,
        TextWrapped = true,
        AutoButtonColor = false,
        AnchorPoint = props.AnchorPoint,
        BackgroundColor3 = buttonColorSpring,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        LayoutOrder = props.LayoutOrder,
        Position = UDim2.fromScale(0.94, 1),
        Visible = props.Visible,
        Parent = props.Parent,
        Size = props.Size,

        [Children] = {
            New("UICorner")({
                Name = "UICorner",
                CornerRadius = UDim.new(0.25, 0),
            }),

            ScaledText({
                Name = "Label",
                Text = props.Text,
                TextColor3 = textColorSpring,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(0.9, 0.4),
                Visible = Fusion.Computed(function()
                    local text = props.Text:get()
                    return text and #text > 0
                end)
            })

            -- New("UIStroke")({
            --     Name = "StandardStroke",
            --     Color = Color3.fromRGB(79, 84, 95),
            --     Thickness = 1.5,
            --     ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            -- }),
        },

        [OnEvent("MouseButton1Down")] = function()
            isHeldDown:set(true)
        end,

        [OnEvent("MouseButton1Up")] = function()
            isHeldDown:set(false)
        end,

        [OnEvent("MouseEnter")] = function()
            isHovering:set(true)
        end,

        [OnEvent("MouseLeave")] = function()
            isHovering:set(false)
            isHeldDown:set(false)
        end,

        [OnEvent("Activated")] = function()
            local cb = props.OnClick:get()
            if cb then
                cb()
            end
        end
    })
end

return ActionButton