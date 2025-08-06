local BloxbizSDK = script.Parent.Parent.Parent.Parent
local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")

local _UIScaler = require(UtilsStorage:WaitForChild("UIScaler"))
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))

local New = Fusion.New
local Children = Fusion.Children

return function(props)
	props = FusionProps.GetValues(props, {
		[Children] = FusionProps.Nil,
		Parent = FusionProps.Nil,
		Padding = 7,
	})

	return New("Frame")({
		Parent = props.Parent,
		Name = "TopBarFrame",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.012, 0.017),
		Size = UDim2.fromScale(0.668, 0.07),

		[Children] = {
			New("UIListLayout")({
				Name = "UIListLayout",
				Padding = Fusion.Computed(function()
					return UDim.new(0, props.Padding:get())
				end),
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			New("UISizeConstraint")({
				MaxSize = Vector2.new(math.huge, 50)
			}),
			props[Children]
		},
	})
end
