local Gui = script.Parent.Parent

local Fusion = require(Gui.Parent.Parent.Utils.Fusion)
local New = Fusion.New

return function(props)
	return New("Frame")({
		Name = "Line",
		Size = props.Size,
		ZIndex = props.ZIndex,
		Position = props.Position or UDim2.fromScale(0.5, 1),
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 1),
		LayoutOrder = props.LayoutOrder,
		BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(50, 50, 50),
		SizeConstraint = props.SizeConstraint or Enum.SizeConstraint.RelativeXY,
	})
end
