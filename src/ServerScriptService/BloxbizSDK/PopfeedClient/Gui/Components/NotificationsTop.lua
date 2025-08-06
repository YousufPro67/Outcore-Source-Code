local Gui = script.Parent.Parent

local Fusion = require(Gui.Parent.Parent.Utils.Fusion)
local New = Fusion.New

local GuiComponents = Gui.Components
local Line = require(GuiComponents.Line)

local font = Font.fromEnum(Enum.Font.Arial)
font.Bold = true

return function()
	return {
		New("TextLabel")({
			Name = "Title",
			Text = "Notifications",
			Size = UDim2.fromScale(0.7, 0.35),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			TextScaled = true,
			FontFace = font,
			TextColor3 = Color3.fromRGB(255, 255, 255),
		}),

		Line({
			Size = UDim2.fromScale(1, 0.02),
		}),
	}
end
