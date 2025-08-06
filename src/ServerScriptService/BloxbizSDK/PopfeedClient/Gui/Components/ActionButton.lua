local Gui = script.Parent.Parent
local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children

return function(props)
	local isButton = not not props.OnActivated
	local hasBackground = not not props.BackgroundColor

	return New(isButton and "TextButton" or "Frame")({
		Name = props.Name,
		Size = props.Size or UDim2.fromScale(0, 1),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = props.BackgroundColor,
		BackgroundTransparency = hasBackground and 0 or 1,
		Visible = props.Visible,
		LayoutOrder = props.LayoutOrder,
		AutomaticSize = Enum.AutomaticSize.X,
		SizeConstraint = props.SizeConstraint,
		ZIndex = props.ZIndex,

		[OnEvent("Activated")] = isButton and props.OnActivated or nil,

		[Children] = {
			props.CornerRadius and New("UICorner")({
				CornerRadius = props.CornerRadius,
			}) or nil,

			New("UIListLayout")({
				Padding = UDim.new(props.Padding, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			props.FrontOffset and New("Frame")({
				Name = "BlankSpace",
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Size = UDim2.fromScale(props.FrontOffset, 0),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}) or nil,

			New("ImageLabel")({
				Name = "Icon",
				Size = props.IconSize or UDim2.fromScale(0.7, 0.7),
				Image = props.Icon,
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				ZIndex = props.ZIndex,
			}),

			props.MiddleOffset and New("Frame")({
				Name = "BlankSpace",
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Size = UDim2.fromScale(props.MiddleOffset, 0),
				BackgroundTransparency = 1,
				LayoutOrder = 3,
			}) or nil,

			New("TextLabel")({
				Text = props.Text,
				Size = props.TextSize or UDim2.fromScale(0, 0.65),
				FontFace = props.Font or Font.fromEnum(Enum.Font.Arial),
				TextColor3 = props.TextColor or Color3.fromRGB(255, 255, 255),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				TextScaled = true,
				LayoutOrder = 4,
				RichText = true,
				ZIndex = props.ZIndex,
			}),

			props.BackOffset and New("Frame")({
				Name = "BlankSpace",
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Size = UDim2.fromScale(props.BackOffset, 0),
				BackgroundTransparency = 1,
				LayoutOrder = 5,
			}) or nil,
		},
	})
end
