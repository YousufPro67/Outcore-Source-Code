local BloxbizSDK = script.Parent.Parent.Parent.Parent
local CatalogClient = BloxbizSDK.CatalogClient
local Classes = CatalogClient.Classes

local AvatarHandler = require(Classes:WaitForChild("AvatarHandler"))

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local New = Fusion.New
local Ref = Fusion.Ref
local Computed = Fusion.Computed
local Observer = Fusion.Observer
local Spring = Fusion.Spring
local Cleanup = Fusion.Cleanup
local Value = Fusion.Value

local function GetTableType(t: { any }): string?
	if next(t) == nil then
		return
	end
	for k, _ in pairs(t) do
		if typeof(k) ~= "number" or (typeof(k) == "number" and (k % 1 ~= 0 or k < 0)) then
			return "Dictionary"
		end
	end

	return "Array"
end

local function GetTableSize(t: { any }): number
	local tableType = GetTableType(t)
	if tableType == "Array" then
		return #t
	elseif tableType == "Dictionary" then
		local count = 0
		for _ in t do
			count += 1
		end
		return count
	else
		return 0
	end
end

local SETTINGS = {
	Buttons = {
		Save = {
			Position = UDim2.fromScale(0.285, 1),
			AnchorPoint = Vector2.new(0, 1),
		},
		Reset = {
			Position = UDim2.fromScale(0.06, 1),
			AnchorPoint = Vector2.new(0, 1),
		},
		Redo = {
			Position = UDim2.fromScale(0.94, 1),
			AnchorPoint = Vector2.new(1, 1),
		},
		Undo = {
			Position = UDim2.fromScale(0.715, 1),
			AnchorPoint = Vector2.new(1, 1),
		},
	},

	Color = {
		Selected = Color3.new(1, 1, 1),
		Default = Color3.fromRGB(20, 20, 20),
		MouseDown = Color3.fromRGB(15, 15, 15),
		Hover = Color3.fromRGB(30, 30, 30),
	},

	TextColor = {
		Selected = Color3.new(0, 0, 0),
		Disabled = Color3.fromRGB(128, 128, 128),
		Default = Color3.fromRGB(255, 255, 255),
	},
}

local function WearingItems(
	wearingListFrame: ScrollingFrame,
	wearingItems: Fusion.Value<{ AvatarHandler.ItemData }>
): TextButton
	local isHovering = Value(false)
	local isHeldDown = Value(false)
	local isSelected = Value(false)

	local wearingTextLabel = Value()
	local itemListObs = Observer(wearingItems)
	local disconnect = itemListObs:onChange(function()
		local label = wearingTextLabel:get()
		local list = wearingItems:get()
		local value = GetTableSize(list) - (list.BodyColors and 1 or 0)

		label.Text = string.format("Wearing %d items", value)
	end)

	local buttonColorSpring = Spring(
		Computed(function()
			if isSelected:get() then
				return SETTINGS.Color.Selected
			elseif isHeldDown:get() then
				return SETTINGS.Color.MouseDown
			elseif isHovering:get() then
				return SETTINGS.Color.Hover
			else
				return SETTINGS.Color.Default
			end
		end),
		20,
		1
	)

	local textColorSpring = Spring(
		Computed(function()
			if isSelected:get() then
				return SETTINGS.TextColor.Selected
			elseif isHeldDown:get() then
				return SETTINGS.TextColor.Disabled
			else
				return SETTINGS.TextColor.Default
			end
		end),
		20,
		1
	)

	local iconColorSpring = Spring(
		Computed(function()
			if isHeldDown:get() then
				return SETTINGS.TextColor.Disabled
			else
				return SETTINGS.TextColor.Default
			end
		end),
		20,
		1
	)

	local strokeColorSpring = Spring(
		Computed(function()
			if isSelected:get() then
				return Color3.new(0, 0, 0)
			else
				return Color3.fromRGB(79, 84, 95)
			end
		end),
		20,
		1
	)

	return New("TextButton")({
		Name = "WearingItems",
		Text = "",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextScaled = true,
		TextSize = 14,
		TextWrapped = true,
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = buttonColorSpring,
		LayoutOrder = 1,
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromScale(0.5, 0.07),
		ZIndex = 3,

		[Cleanup] = function()
			disconnect()
		end,

		[Children] = {
			New("TextLabel")({
				Name = "TextLabel",
				Text = "Loading Wearing Items",
				TextColor3 = textColorSpring,
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.9, 0.5),
				Size = UDim2.fromScale(0.6, 0.6),

				[Ref] = wearingTextLabel,
			}),

			New("ImageLabel")({
				Name = "Icon",
				Image = "rbxassetid://13733130817",
				ImageColor3 = iconColorSpring,
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.1, 0.5),
				Size = UDim2.fromScale(0.6, 0.6),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
			}),

			New("UICorner")({
				Name = "UICorner",
				CornerRadius = UDim.new(0.225, 0),
			}),

			New("UIStroke")({
				Name = "StandardStroke",
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = strokeColorSpring,
				Thickness = 1.5,
			}),
		},

		[OnEvent("Activated")] = function()
			isSelected:set(not isSelected:get())
			wearingListFrame.Visible = not wearingListFrame.Visible
		end,

		[OnEvent("MouseButton1Down")] = function()
			isHeldDown:set(true)
		end,

		[OnEvent("MouseButton1Up")] = function()
			isHeldDown:set(false)
		end,

		[OnEvent("MouseEnter")] = function()
			isHovering:set(true)
		end,

		[OnEvent("MouseLeave")] = function()
			isHovering:set(false)
			isHeldDown:set(false)
		end,
	})
end

return WearingItems
