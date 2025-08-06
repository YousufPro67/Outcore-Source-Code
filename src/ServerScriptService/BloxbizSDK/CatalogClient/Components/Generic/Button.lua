--!strict
local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local Components = script.Parent.Parent
local Generic = Components.Generic

local Spring = require(Generic.Spring)

export type Option<T> = T | Spring.Values<T> | Fusion.Computed<T>

type StateValues = {
	Enabled: Fusion.Value<boolean>,
	Hovering: Fusion.Value<boolean>,
	HeldDown: Fusion.Value<boolean>,
	Selected: Fusion.Value<boolean>,
}

export type Props = {
	States: StateValues?,
	Name: string?,

	Enabled: boolean?,

	AnchorPoint: Option<Vector2>?,
	Size: Option<UDim2>?,
	Position: Option<UDim2>?,

	Image: Option<string>?,
	Text: Option<string>?,
	TextSize: UDim2?,
	TextPosition: UDim2?,

	BackgroundTransparency: Option<number>?,
	BackgroundColor3: Option<Color3>?,

	TextTransparency: Option<number>?,
	TextColor3: Option<Color3>?,

	ImageTransparency: Option<number>?,
	ImageColor3: Option<Color3>?,

	CornerRadius: Option<UDim>?,
	Callback: (enabled: Fusion.Value<boolean>, selected: Fusion.Value<boolean>, ...any) -> (),
}


local function GetValue(states: Spring.States, value: Option<any>?, default: any): Fusion.Spring<any> | any
	if value then
		if typeof(value) == "table" and value.Default then
			return Spring(states, value ::  Spring.Values<any>)
		else
			return value
		end
	end

	return default
end

local DEFAULT_TEXT_SIZE = 20

return function(props: Props): TextButton
	local states = (props.States or {
		Enabled = Fusion.Value(if props.Enabled ~= nil then props.Enabled else true),
		Hovering = Fusion.Value(false),
		HeldDown = Fusion.Value(false),
		Selected = Fusion.Value(false),
	}) :: StateValues

	if type(props.Enabled) == "table" and props.Enabled.type == "State" then
		states.Enabled = props.Enabled
	end

	local backgroundColor3 = GetValue(states, props.BackgroundColor3, Color3.fromRGB(20, 20, 20))
	local backgroundTransparency = GetValue(states, props.BackgroundTransparency, 0)

	local textColor3 = GetValue(states, props.TextColor3, Color3.fromRGB(255, 255, 255))
	local textTransparency = GetValue(states, props.TextTransparency, 0)

	local imageColor3 = GetValue(states, props.ImageColor3, Color3.fromRGB(255, 255, 255))
	local imageTransparency = GetValue(states, props.ImageTransparency, 0)

	local anchorPoint = GetValue(states, props.AnchorPoint, Vector2.new(0.5, 0.5))
	local size = GetValue(states, props.Size, UDim2.fromScale(0.5, 0.5))
	local position = GetValue(states, props.Position, UDim2.fromScale(0.5, 0.5))

	local textScaled = props.TextScaled
	if textScaled == nil then textScaled = true end
	local textWrapped = props.TextWrapped
	if textWrapped == nil then textWrapped = true end

	local textLabel = Fusion.Value()
	local container = Fusion.Value()

	local function updateTextSize()
		if props.TextSize then return end
		if not textLabel:get() then return end
		if not container:get() then return end

		local containerInst = container:get()
		local textLabelInst = textLabel:get()

		textLabelInst.TextSize = containerInst.AbsoluteSize.Y / 2

		local textWidth = textLabelInst.TextBounds.X
		local maxWidth = textLabelInst.AbsoluteSize.X

		if textWidth > maxWidth then
			textLabelInst.TextSize *= maxWidth / textWidth
		end
	end

	local visible = props.Visible
	if visible == nil then
		visible = true
	end

	return Fusion.New("TextButton")({
		Name = props.Name or "GenericButton" .. tostring(tick()),
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = anchorPoint,
		BackgroundColor3 = backgroundColor3,
		BackgroundTransparency = backgroundTransparency,
		Position = position,
		Size = size,
		BorderSizePixel = 0,
		Visible = visible,

		[Fusion.Ref] = container,

		[Fusion.Children] = {
			Fusion.New("UICorner")({
				Name = "UICorner",
				CornerRadius = props.CornerRadius or UDim.new(0.2),
			}),

			Fusion.Computed(function()
				if props.Stroke then
					return Fusion.New "UIStroke" {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Color3.fromRGB(79, 84, 95),
						Thickness = 1.5,
					}
				end
			end, Fusion.cleanup),

			Fusion.New("ImageLabel")({
				Name = "Icon",
				Image = props.Image,
				Visible = props.Image ~= nil,
				ImageTransparency = imageTransparency,
				AnchorPoint = Vector2.new(0, 0.5),
				ImageColor3 = imageColor3,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.1, 0.5),
				Size = UDim2.fromScale(1, 0.5),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,

				[Fusion.Children] = {
					Fusion.New("UIAspectRatioConstraint")({
						Name = "UIAspectRatioConstraint",
					}),
				},
			}) :: ImageLabel,

			Fusion.New("TextLabel")({
				Name = "Label",
				Text = props.Text,
				TextColor3 = textColor3,
				TextTransparency = textTransparency,
				TextScaled = textScaled,
				TextSize = type(props.TextSize) == "number" and props.TextSize or DEFAULT_TEXT_SIZE,
				TextWrapped = textWrapped,
				AnchorPoint = props.Image and Vector2.new(1, 0.5) or Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = props.TextPosition or (props.Image and UDim2.fromScale(0.9, 0.5) or UDim2.fromScale(0.5, 0.5)),
				Size = props.TextSize or UDim2.fromScale(0.6, 0.8),

				[Fusion.Ref] = textLabel,

				[Fusion.Children] = {
					Fusion.Computed(function()
						if props.BoldTextThickness then
							return Fusion.New "UIStroke" {
								ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
								Color = textColor3,
								Thickness = props.BoldTextThickness,
							}
						end
					end, Fusion.cleanup),
				},
			}),
		},

		[Fusion.OnChange("AbsoluteSize")] = updateTextSize,

		[Fusion.OnEvent("Activated")] = function()
			if not states.Enabled:get() then
				return
			end

			props.Callback(states.Enabled, states.Selected)
		end,

		[Fusion.OnEvent("MouseButton1Down")] = function()
			states.HeldDown :set(true)
		end,

		[Fusion.OnEvent("MouseButton1Up")] = function()
			states.HeldDown:set(false)
		end,

		[Fusion.OnEvent("MouseEnter")] = function()
			states.Hovering:set(true)
		end,

		[Fusion.OnEvent("MouseLeave")] = function()
			states.Hovering:set(false)
			states.HeldDown:set(false)
		end,
	}) :: TextButton
end
