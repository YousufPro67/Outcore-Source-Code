local Gui = script.Parent.Parent

local Fusion = require(Gui.Parent.Parent.Utils.Fusion)
local New = Fusion.New
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Computed = Fusion.Computed

return function(props)
	props = {
		Name = props.Name,
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		Visible = props.Visible == nil and true or props.Visible,
		AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.None,
		Text = props.Text,
		Color = props.Color,
		Bold = props.Bold,
		OnActivated = props.OnActivated,
		NoticeValue = props.NoticeValue,
		isSelected = props.isSelected or false,
		ZIndex = props.ZIndex,
		TextXAlignment = props.TextXAlignment,
	}

	local font = Font.fromEnum(Enum.Font.Arial)
	font.Bold = not not props.Bold

	return New("TextButton")({
		Name = props.Name,
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		Visible = props.Visible,
		BackgroundTransparency = 1,
		AutomaticSize = props.AutomaticSize,
		TextXAlignment = props.TextXAlignment,
		ZIndex = props.ZIndex,

		Text = props.Text,
		TextScaled = true,
		FontFace = font,
		TextColor3 = props.Color,

		[OnEvent("Activated")] = props.OnActivated,

		[Children] = {
			props.NoticeValue and New("ImageLabel")({
				Name = "Notice",
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromScale(1, -0.3),
				AnchorPoint = Vector2.new(0.5, 0.5),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				BackgroundTransparency = 1,
				Image = "rbxassetid://12776995467",
				ImageColor3 = Color3.fromRGB(224, 83, 83),
				Visible = Computed(function()
					return props.NoticeValue:get() > 0
				end),

				[Children] = {
					New("TextLabel")({
						Name = "Count",
						Text = Computed(function()
							return props.NoticeValue:get()
						end),
						Size = UDim2.fromScale(0.9, 0.9),
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						TextScaled = true,
						FontFace = font,
						TextColor3 = Color3.fromRGB(255, 255, 255),
					}),
				},
			}) or {},

			New("Frame")({
				Name = "ActiveLine",
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.fromScale(0.5, 1),
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = props.Color,
				Visible = props.isSelected,
			}),
		},
	})
end
