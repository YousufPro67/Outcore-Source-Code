local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local New = Fusion.New
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Computed = Fusion.Computed
local ForValues = Fusion.ForValues

local Components = script.Parent.Parent
local ItemGrid = require(Components.ItemGrid)
local ScaledText = require(Components.ScaledText)
local Button = require(script.Parent.Button)

local Camera = workspace.CurrentCamera

return function(props)
	local parent = props.Parent
	local displayProps = props.DisplayProps

	return New "TextButton" {
		Name = "ShopsPopUp",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(2, 2),
		BackgroundTransparency = 0.4,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		Active = true,
		Selectable = false,
		Text = "",
		Parent = parent,

		Visible = Computed(function()
			return displayProps:get().Visible
		end),

		[Children] = {
			New "Frame" {
				Name = "Container",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(20, 20, 20),
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.175, 0.13),

				[Children] = {
					New "TextLabel" {
						Name = "Title",
						FontFace = Font.fromEnum(Enum.Font.GothamMedium),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						TextWrapped = true,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.04),
						AnchorPoint = Vector2.new(0.5, 0),
						Size = UDim2.fromScale(0.45, 0.175),

						Text = Computed(function()
							return displayProps:get().Title or ""
						end),
					},

					New "Frame" {
						Name = "Line",
						Size = UDim2.new(0.95, 0, 0, 2),
						Position = UDim2.fromScale(0.5, 0.245),
						AnchorPoint = Vector2.new(0.5, 0),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						BackgroundColor3 = Color3.fromRGB(55, 55, 55),
					},

					New "TextLabel" {
						Name = "Description",
						FontFace = Font.fromEnum(Enum.Font.GothamMedium),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						TextWrapped = true,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.285),
						AnchorPoint = Vector2.new(0.5, 0),
						Size = UDim2.fromScale(0.9, 0.4),

						Text = Computed(function()
							return displayProps:get().Text or ""
						end),

						[Children] = {
							New "UITextSizeConstraint" {
								MaxTextSize = Camera.ViewportSize.Y / 32,
							},
						},
					},

					Button {
						Size = UDim2.fromScale(0.3, 0.175),
						Position = UDim2.fromScale(0.5, 0.76),
						AnchorPoint = Vector2.new(0.5, 0),
						IgnoreAspecetRatio = true,

						Color = {
							Default = Color3.fromRGB(255, 255, 255),
							MouseDown = Color3.fromRGB(100, 100, 100),
							Hover = Color3.fromRGB(155, 155, 155),
							Selected = Color3.fromRGB(255, 255, 255)
						},

						Text = Computed(function()
							return displayProps:get().ButtonText or "Continue"
						end),
						TextSize = UDim2.fromScale(0.8, 0.6),
						TextColor3 = Color3.fromRGB(0, 0, 0),

						OnClick = function()
							displayProps:set({})
						end,
					},

					New "UICorner" {
						Name = "UICorner",
						CornerRadius = UDim.new(0.065, 0),
					},

					New("UIStroke")({
                        Name = "UIStroke",
                        Color = Color3.fromRGB(255, 255, 255),
                        Thickness = 2,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        Transparency = 0.5,
					}),
				},
			},
		},
	}
end
