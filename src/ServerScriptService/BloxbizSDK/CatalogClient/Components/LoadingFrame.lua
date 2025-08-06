local RunService = game:GetService("RunService")
local BloxbizSDK = script.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Ref = Fusion.Ref
local Cleanup = Fusion.Cleanup

return function(props): Frame
	props = FusionProps.GetValues(props, {
		Visible = false,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),
		LayoutOrder = math.huge,
		ZIndex = 10,
		Text = "Loading items...",
		Parent = FusionProps.Nil,
		CornerRadius = UDim.new(0.065, 0)
	})

	local spinnerValue = Value()
	local connection = RunService.RenderStepped:Connect(function()
		local spinner: ImageLabel? = spinnerValue:get()
		if spinner then
			spinner.Rotation += 1
			spinner.Rotation %= 360
		end
	end)

	return New("ImageLabel")({
		Name = "LoadingFrame",
		Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
		ImageTransparency = 1,
		Active = true,
		BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = props.BackgroundColor3 and 0 or 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = props.Position,
		Size = props.Size,
		-- SizeConstraint = Enum.SizeConstraint.RelativeXX,
		ZIndex = props.ZIndex,
		Visible = props.Visible,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,

		[Cleanup] = function()
			connection:Disconnect()
		end,

		[Children] = {
			New("UICorner")({
				CornerRadius = props.CornerRadius
			}),

			New("Frame")({
				Name = "LoadingState",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.5, 0.5),

				[Children] = {
					New("UISizeConstraint")({
						MinSize = Vector2.zero,
						MaxSize = Vector2.new(math.huge, 200)
					}),

					New("ImageLabel")({
						Name = "Spinner",
						Image = "rbxassetid://11304130802",
						ImageColor3 = Color3.fromRGB(225, 225, 225),
						AnchorPoint = Vector2.new(0.5, 0),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Position = UDim2.fromScale(0.5, 0.1),
						Rotation = 60.9,
						Size = UDim2.fromScale(0.4, 0.4),
						SizeConstraint = Enum.SizeConstraint.RelativeYY,

						[Ref] = spinnerValue,
					}),

					New("TextLabel")({
						Name = "Info",
						FontFace = Font.fromEnum(Enum.Font.GothamMedium),
						Text = props.Text,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						TextSize = 28,
						TextWrapped = true,
						AnchorPoint = Vector2.new(0.5, 1),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Position = UDim2.fromScale(0.5, 0.825),
						Size = UDim2.fromScale(0.9, 0.15),
					}),
				},
			}),
		},
	})
end
