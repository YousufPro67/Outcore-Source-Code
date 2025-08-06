local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local New = Fusion.New
local Ref = Fusion.Ref

local Cleanup = Fusion.Cleanup
local Value = Fusion.Value

local SETTINGS = {
	DefaultFont = Font.new("rbxasset://fonts/families/GothamSSm.json"),
}

return function(
	displayText: string,
	textColor: Color3,
	springs: { [string]: Fusion.Spring<any> },
	values: { [string]: Fusion.Value<boolean> },
	cleanUpCallback: () -> (),
	triggerCallback: (...any) -> ()
): (Frame, Frame)
	local textLabel = Value()

	local button = New("TextButton")({
		Name = displayText,
		Text = "",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextScaled = true,
		TextSize = 14,
		TextWrapped = true,
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = springs.ButtonBackgroundColor,
		BackgroundTransparency = springs.TextTransparency,
		Position = UDim2.fromScale(0.5, 0.275),
		Size = springs.ButtonSize,
		ZIndex = 2,

		[Cleanup] = function()
			cleanUpCallback()
		end,

		[OnEvent("Activated")] = function(...)
			triggerCallback(...)
		end,

		[OnEvent("MouseButton1Down")] = function()
			values.Held:set(true)
		end,

		[OnEvent("MouseButton1Up")] = function()
			values.Held:set(false)
		end,

		[OnEvent("MouseEnter")] = function()
			values.Hovering:set(true)
		end,

		[OnEvent("MouseLeave")] = function()
			values.Hovering:set(false)
			values.Held:set(false)
		end,

		[Children] = {
			New("UICorner")({
				Name = "UICorner",
				CornerRadius = UDim.new(0.15, 0),
			}),

			New("TextLabel")({
				Name = "TextLabel",
				Text = displayText,
				TextColor3 = textColor,
				FontFace = SETTINGS.DefaultFont,
				TextScaled = true,
				TextSize = 14,
				TextTransparency = springs.TextTransparency,
				TextWrapped = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.8, 0.4),

				[Ref] = textLabel,
			}),
		},
	})

	return button, textLabel:get()
end
