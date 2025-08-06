local Gui = script.Parent.Parent

local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Computed = Fusion.Computed

local GuiComponents = Gui.Components
local Line = require(GuiComponents.Line)
local SelectButton = require(GuiComponents.SelectButton)

local font = Font.fromEnum(Enum.Font.Arial)
font.Bold = true

return function(props)
	return {
		New("TextLabel")({
			Name = "Title",
			Text = "Profile",
			Size = UDim2.fromScale(0.7, 0.41),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			TextScaled = true,
			FontFace = font,
			TextColor3 = Color3.fromRGB(255, 255, 255),
		}),

		SelectButton({
			Name = "Back",
			Text = "< Back",
			Size = UDim2.fromScale(0, 0.41),
			Color = Color3.fromRGB(255, 255, 255),
			Position = UDim2.fromScale(0.05, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
			AutomaticSize = Enum.AutomaticSize.X,
			Bold = true,

			OnActivated = function()
				props.OnBackButtonClicked()
			end,
			Visible = Computed(function()
				if #props.undoTable == 0 then
					return false
				end

				local bottomProfileBtnPressed = props.LastBottomBtnPress:get() == props.initialProfileFeed
					and #props.undoTable == 0
				if bottomProfileBtnPressed then
					return false
				else
					return true
				end
			end),
		}),

		Line({
			Size = UDim2.fromScale(1, 0.02),
		}),
	}
end
