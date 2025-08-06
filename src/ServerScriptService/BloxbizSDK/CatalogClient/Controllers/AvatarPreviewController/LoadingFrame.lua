local RunService = game:GetService("RunService")
local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Ref = Fusion.Ref
local Cleanup = Fusion.Cleanup

return function(): Frame
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
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.5,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.514, 0.482),
		Size = UDim2.fromScale(1.03, 1.65),
		ZIndex = 10,

		[Cleanup] = function()
			connection:Disconnect()
		end,

		[Children] = {
			New("Frame")({
				Name = "LoadingState",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.8, 0.45),

				[Children] = {
					New("ImageLabel")({
						Name = "Spinner",
						Image = "rbxassetid://11304130802",
						ImageColor3 = Color3.fromRGB(225, 225, 225),
						AnchorPoint = Vector2.new(0.5, 0),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Position = UDim2.fromScale(0.5, 0.15),
						Rotation = 303,
						Size = UDim2.fromScale(0.3, 0.3),
						SizeConstraint = Enum.SizeConstraint.RelativeYY,

						[Ref] = spinnerValue,
					}),

					New("TextLabel")({
						Name = "Info",
						FontFace = Font.fromEnum(Enum.Font.GothamMedium),
						Text = "Loading avatar...",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						TextSize = 35,
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
