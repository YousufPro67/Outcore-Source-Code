local RunService = game:GetService("RunService")
local BloxbizSDK = script.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local Generic = script.Parent.Generic
local Button = require(Generic.Button)

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Ref = Fusion.Ref
local Cleanup = Fusion.Cleanup

return function(props): Frame
	props = FusionProps.GetValues(props, {
		Visible = false,
		BackgroundTransparency = 0.5,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),
		MaxSize = Vector2.new(math.huge, math.huge),
		LayoutOrder = math.huge,
		ZIndex = 10,
		Text = "There was an issue loading more items.",
		ButtonText = "Retry",
		ButtonEnabled = true,
		Callback = FusionProps.Nil,
		Parent = FusionProps.Nil,
		CornerRadius = UDim.new(0.065, 0)
	})

	return New("ImageLabel")({
		Name = "ErrorFrame",
		Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
		ImageTransparency = 1,
		Active = true,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = props.BackgroundTransparency,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = props.Position,
		Size = props.Size,
		-- SizeConstraint = Enum.SizeConstraint.RelativeXX,
		ZIndex = props.ZIndex,
		Visible = props.Visible,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent,

		[Children] = {
			New("UICorner")({
				CornerRadius = props.CornerRadius
			}),
			New("UISizeConstraint")({
				MaxSize = props.MaxSize
			}),

			New("TextLabel")({
				Name = "Info",
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Text = props.Text,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 28,
				TextWrapped = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.4),
				Size = UDim2.fromScale(0.8, 0.2),
				[Children] = New("UITextSizeConstraint")({
					MaxTextSize = 32,
				})
			}),

			Button({
				Position = UDim2.fromScale(0.5, 0.7),
				Size = UDim2.fromScale(0.3, 0.2),
				AnchorPoint = Vector2.new(0.5, 0.5),
				CornerRadius = UDim.new(0.2, 0),
		
				Text = props.ButtonText,
				Name = "Button",
		
				ImageTransparency = {
					Default = 0,
					Hover = 0.2,
					MouseDown = 0.5,
					Disabled = 0.8,
				},
		
				BackgroundColor3 = Color3.fromHex("4F545F"),
				BackgroundTransparency = {
					Default = 0,
					Hover = 0.2,
					MouseDown = 0.5,
					Disabled = 0.8,
				},
				
				TextTransparency = {
					Default = 0,
					Hover = 0.2,
					MouseDown = 0.5,
					Disabled = 0.8,
				},
		
				Callback = function(enabled, selected)
					local cb = props.Callback:get()

					if cb then
						cb()
					end
				end,
			})
		},
	})
end
