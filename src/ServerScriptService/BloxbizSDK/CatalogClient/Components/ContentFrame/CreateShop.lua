--!strict
local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local Components = script.Parent.Parent
local Button = require(Components.Generic.Button)

export type Props = {
	Creating: Fusion.Value<boolean>,
	Enabled: boolean,
	Callback: () -> (),
}

return function(props: Props): TextButton
	local buttonProps: Button.Props = {
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromScale(0.12, 1),
		AnchorPoint = Vector2.new(1, 0.5),

		Enabled = props.Enabled,
		Visible = props.Visible,

		Text = props.Text,
		TextSize = UDim2.fromScale(0.85, 0.5),
		TextColor3 = Color3.fromRGB(25, 25, 25),
		BoldTextThickness = 0.3,

		Name = "CreateShop",
		--Image = "rbxassetid://13930689959",

		ImageTransparency = {
			Default = 0,
			Hover = 0.2,
			MouseDown = 0.5,
			Disabled = 0.3,
		},

		BackgroundTransparency = {
			Default = 0,
			Hover = 0.3,
			MouseDown = 0.5,
			Disabled = 0.6,
		},
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),

		TextTransparency = {
			Default = 0,
			Hover = 0.2,
			MouseDown = 0.5,
			Disabled = 0.5,
		},

		Stroke = true,

		Callback = props.Callback,
	}

	return Button(buttonProps)
end
