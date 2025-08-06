local GuiService = game:GetService("GuiService")

local BloxbizSDK = script.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Ref = Fusion.Ref

return function()
	local container = Value()
	local frameContainer = Value()
	local cover = Value()

	local isNewTopBar = GuiService.TopbarInset.Max.Y > 36

	return New("ScreenGui")({
		Name = "IngameCatalog",
		DisplayOrder = 11,
		IgnoreGuiInset = true,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

		[Children] = {
			New("Frame")({
				Name = "Container",
				BackgroundColor3 = Color3.fromRGB(20, 20, 20),
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(0, isNewTopBar and 57 or 36),
				Size = UDim2.new(1, 0, 1, isNewTopBar and -57 or -36),

				[Ref] = container,

				[Children] = {
					New("Frame")({
						Name = "FrameContainer",
						Active = true,
						BackgroundColor3 = Color3.fromRGB(20, 20, 20),
						BorderSizePixel = 0,
						ClipsDescendants = true,
						Position = UDim2.new(0.012, -2, 0.105, 0),
						Size = UDim2.new(0.668, 2, 0.893, 0),

						[Ref] = frameContainer,
					}),

					New("Frame")({
						Name = "Gradient",
						AnchorPoint = Vector2.new(0.5, 1),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						Position = UDim2.fromScale(0.343, 1),
						Size = UDim2.fromScale(0.688, 0.04),

						[Children] = {
							New("UIGradient")({
								Name = "UIGradient",
								Color = ColorSequence.new({
									ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 20)),
									ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20)),
								}),
								Rotation = -90,
								Transparency = NumberSequence.new({
									NumberSequenceKeypoint.new(0, 0),
									NumberSequenceKeypoint.new(0.152, 0.3),
									NumberSequenceKeypoint.new(0.303, 0.55),
									NumberSequenceKeypoint.new(0.489, 0.781),
									NumberSequenceKeypoint.new(0.631, 0.887),
									NumberSequenceKeypoint.new(0.745, 0.962),
									NumberSequenceKeypoint.new(1, 1),
								}),
							}),
						},
					}),
				},
			}),

			New("Frame")({
				Name = "Cover",
				BackgroundColor3 = Color3.fromRGB(20, 20, 20),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(4, 4),
				ZIndex = 0,

				[Ref] = cover,
			}),
		},
	}),
		container:get(),
		frameContainer:get(),
		cover:get()
end
