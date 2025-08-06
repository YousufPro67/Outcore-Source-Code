local Gui = script.Parent.Parent
local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children

return function(props)
	local textFont = Font.fromEnum(Enum.Font.Arial)
	textFont.Bold = props.Bold or false

	return New("TextButton")({
		Name = props.Name,
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = props.Color,
		LayoutOrder = props.LayoutOrder,
		SizeConstraint = props.SizeConstraint,
		ZIndex = props.ZIndex,

		[OnEvent("Activated")] = props.OnActivated,

		[Children] = {
			New("TextLabel")({
				Text = props.Text,
				AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.None,
				BackgroundTransparency = 1,
				TextScaled = true,
				FontFace = textFont,
				TextColor3 = props.TextColor,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = props.TextSize or UDim2.fromScale(0.9, 0.5),
				ZIndex = props.ZIndex + 1,
			}),

			New("UICorner")({
				CornerRadius = props.CornerRadius or UDim.new(0, 8),
			}),

			props[Children],
		},
	})
end
