--!strict
local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local Sort = require(script.Parent.Sort)

export type Props = {
	Padding: number?,
}

return function(props: Props?): Instance
	return Fusion.New("Frame")({
		Name = "UtilitiesHolder",
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = -1,
		Position = UDim2.fromScale(0.5, -3.61e-08),
		Size = UDim2.fromScale(1, 0.05),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,

		ZIndex = props.ZIndex,
		Visible = props.Visible,

		[Fusion.Children] = Fusion.New("Frame")({
			Name = "Holder",
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.05),
			Size = UDim2.fromScale(0.997, 0.75),

			[Fusion.Children] = {
				props and props.Padding and Fusion.New("UIListLayout")({
					Name = "UIListLayout",
					Padding =  props.Padding ,
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),

				(not props.Padding) and Fusion.New("Frame")({
					Name = "Left",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,

					[Fusion.Children] = {
						Fusion.New("UIListLayout")({
							Name = "UIListLayout",
							Padding =  UDim.new(0, 16),
							FillDirection = Enum.FillDirection.Horizontal,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							SortOrder = Enum.SortOrder.LayoutOrder,
						}),

						props.LeftChildren,
					}
				}),

				props.HolderChildren,
			},
		}),
	})
end
