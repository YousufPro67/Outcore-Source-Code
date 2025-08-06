local BloxbizSDK = script.Parent.Parent.Parent.Parent

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
		Enabled = Color3.fromRGB(248, 51, 51),
		Disabled = Color3.fromRGB(120, 125, 136),
	},

	Size = {
		Default = UDim2.fromScale(0.9, 0.2),
		Hover = UDim2.fromScale(0.925, 0.205),
	},
}

return function(
	deleteOutfitCallback: (...any) -> (),
	textTransparency: Fusion.Spring<any>
): (Fusion.Value<boolean>, TextButton)
	local isHovering = Value(false)
	local isHeldDown = Value(false)
	local isDeleting = Value(false)

	local button, textLabel

	local equippedObserver = Observer(isDeleting)
	local disconnectingObserver = equippedObserver:onChange(function()
		if textLabel then
			textLabel.Text = isDeleting:get() and "Confirm?" or "Delete"
		end
	end)

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

	local function cleanUpCallback()
		disconnectingObserver()
	end

	local function onDelete()
		deleteOutfitCallback(isDeleting)
	end

	button, textLabel = Button("Delete", Color3.fromRGB(248, 51, 51), springs, values, cleanUpCallback, onDelete)

	return isDeleting, button
end
