local BloxbizSDK = script.Parent.Parent.Parent.Parent.Parent
local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local Computed = Fusion.Computed
local Observer = Fusion.Observer
local Spring = Fusion.Spring
local Value = Fusion.Value

local Button = require(script.Parent.Parent.ItemButton)

local SETTINGS = {
	DefaultFont = Font.new("rbxasset://fonts/families/GothamSSm.json"),
	ItemColor = {
		Default = Color3.fromRGB(79, 84, 95),
		Hover = Color3.fromRGB(107, 114, 129),
		MouseDown = Color3.fromRGB(76, 80, 90),
	},

	ButtonColor = {
		Default = Color3.fromRGB(255, 255, 255),
		MouseDown = Color3.fromRGB(153, 153, 153),
	},

	TextColor = {
		Enabled = Color3.fromRGB(255, 255, 255),
		Disabled = Color3.fromRGB(120, 125, 136),
	},

	Size = {
		Default = UDim2.fromScale(0.9, 0.2),
		Hover = UDim2.fromScale(0.925, 0.205),
	},
}

return function(
	callback: () -> (),
	textTransparency: Fusion.Spring<any>
): (Fusion.Value<boolean>, TextButton)
	local isHovering = Value(false)
	local isHeldDown = Value(false)

	local button, textLabel

	local buttonSize = Spring(
		Computed(function()
			return isHovering:get() and SETTINGS.Size.Hover or SETTINGS.Size.Default
		end),
		40,
		1
	)

	local buttonBackground = Spring(
		Computed(function()
			return isHeldDown:get() and SETTINGS.ButtonColor.MouseDown or SETTINGS.ButtonColor.Default
		end),
		40,
		1
	)

	local springs = {
		TextTransparency = textTransparency,
		ButtonBackgroundColor = buttonBackground,
		ButtonSize = buttonSize,
	}

	local values = {
		Held = isHeldDown,
		Hovering = isHovering,
	}

	button, textLabel = Button(
		"See Items",
		Color3.new(),
		springs,
		values,
		function() end,
		callback
	)

	return button
end
