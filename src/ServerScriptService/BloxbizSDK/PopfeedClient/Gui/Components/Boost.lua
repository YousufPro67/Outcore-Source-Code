local Gui = script.Parent.Parent
local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed

local GuiComponents = Gui.Components
local UICorner = require(GuiComponents.UICorner)
local TextButton = require(GuiComponents.TextButton)

return function(props)
	local font = Font.fromEnum(Enum.Font.Arial)
	local boldFont = Font.fromEnum(Enum.Font.Arial)
	boldFont.Bold = true

	return New("Frame")({
		Name = "Boost",
		Size = UDim2.fromScale(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		ZIndex = 3,

		Visible = false,--[[Computed(function()
            return props.IsBoosting:get()
        end),]]

		[Children] = {
			TextButton({
				Text = "Buy \u{E002}100",
				Name = "BoostButton",
				Color = Color3.fromRGB(78, 175, 83),
				TextSize = UDim2.fromScale(0.9, 0.45),
				TextColor = Color3.fromRGB(255, 255, 255),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 0.73),
				Size = UDim2.fromScale(0.9, 0.16),
				ZIndex = 5,

				OnActivated = props.OnBoostButtonClicked,
			}),

			TextButton({
				Text = "Cancel",
				Name = "CancelButton",
				Color = Color3.fromRGB(255, 255, 255),
				TextSize = UDim2.fromScale(0.9, 0.45),
				TextColor = Color3.fromRGB(0, 0, 0),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 0.945),
				Size = UDim2.fromScale(0.9, 0.16),
				ZIndex = 5,

				OnActivated = function()
					props.IsBoosting:set(false)
				end,
			}),

			New("ImageLabel")({
				Size = UDim2.fromScale(0.175, 0.175),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.07),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Image = "rbxassetid://12934370316",
				BackgroundTransparency = 1,
				ZIndex = 5,
			}),

			New("TextLabel")({
				Size = UDim2.fromScale(0.83, 0.075),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.42),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Text = "Get this post more visibility.",
				TextScaled = true,
				FontFace = font,
				ZIndex = 5,
			}),

			New("TextLabel")({
				Size = UDim2.fromScale(0.8, 0.075),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.3),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Text = "Boost Post",
				TextScaled = true,
				FontFace = boldFont,
				ZIndex = 5,
			}),

			New("TextButton")({
				Name = "Background",
				Size = UDim2.fromScale(10, 10),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.3,
				AutoButtonColor = false,
				ZIndex = 2,
			}),

			UICorner({}),
		},
	})
end
