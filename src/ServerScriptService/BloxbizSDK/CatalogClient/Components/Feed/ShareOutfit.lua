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
		Size = UDim2.fromScale(0.15, 1),
		AnchorPoint = Vector2.new(1, 0.5),

		Enabled = props.Enabled,
		Visible = props.Visible,

		Text = "Share Outfit",
		TextPosition = UDim2.fromScale(0.9, 0.5),
		TextSize = UDim2.fromScale(0.6, 0.8),

		Name = "Share",
		Image = "rbxassetid://13930689959",

		ImageTransparency = {
			Default = 0,
			Hover = 0.2,
			MouseDown = 0.5,
			Disabled = 0.3,
		},

		BackgroundTransparency = {
			Default = 1,
			Hover = 0.8,
			MouseDown = 0.5,
			Disabled = 0.6,
		},
		BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),

		TextTransparency = {
			Default = 0,
			Hover = 0.2,
			MouseDown = 0.5,
			Disabled = 0.5,
		},

		Stroke = true,

		Callback = function(enabled: Fusion.Value<boolean>, selected: Fusion.Value<boolean>)
			if not props.Creating:get() then
				props.Callback()
			end
		end,
	}

	return Button(buttonProps)
end
