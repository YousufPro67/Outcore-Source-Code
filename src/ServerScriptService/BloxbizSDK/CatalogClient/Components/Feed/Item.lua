--!strict
local BloxbizSDK = script.Parent.Parent.Parent.Parent
local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local Components = BloxbizSDK.CatalogClient.Components
local GenericComponents = Components.Generic

local Button = require(GenericComponents.Button)
local Spring = require(GenericComponents.Spring)

export type ButtonData = {
	Selected: Fusion.Value<boolean>,
	Button: Fusion.Value<TextButton?>,
	Text: Fusion.Value<TextLabel?>,
	Data: any?,
}

export type HolderProps = {
	EquippedItems: Fusion.Value,
	AssetId: number,
	CurrentButton: Fusion.Value<ButtonData?>,
	TryCallback: () -> (),
	BuyCallback: () -> (),
}

local function GetButton(
	text: any,
	backgroundColor3: { [string]: Color3 },
	textColor3: { [string]: Color3 },
	callback: (boolean) -> ()
): TextButton
	local props: Button.Props = {
		Name = text,
		Text = text,
		Size = {
			Default = UDim2.fromScale(0.8, 0.3),
			Hover = UDim2.fromScale(0.8, 0.3),
		},

		BackgroundColor3 = backgroundColor3,
		TextColor3 = textColor3,

		Callback = function(enabled: Fusion.Value<boolean>, selected: Fusion.Value<boolean>)
			callback(enabled:get())
		end,
	}

	return Button(props)
end

return function(props: HolderProps): TextButton
	local states = {
		Hovering = Fusion.Value(false),
		HeldDown = Fusion.Value(false),
		Selected = Fusion.Value(false),
		Enabled = Fusion.Value(true),
	}

	local buttonData = {
		Selected = states.Selected,
	}

	local buttonProps: Button.Props = {
		Name = tostring(props.AssetId),
		States = states,

		Size = UDim2.fromScale(1, 1),
		CornerRadius = UDim.new(0.065, 0),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,

		BackgroundColor3 = {
			Default = Color3.fromRGB(79, 84, 95),
			Selected = Color3.fromRGB(48, 51, 58),
		},
		BackgroundTransparency = {
			Default = 0,
			Hover = 0.2,
			Selected = 0.3,
			MouseDown = 0.4,
			Disabled = 0,
		},

		Callback = function(enabled: Fusion.Value<boolean>, selected: Fusion.Value<boolean>)
			if states.Enabled:get() then
				local currentSelected = props.CurrentButton:get()
				if currentSelected then
					currentSelected.Selected:set(false)
					props.CurrentButton:set(nil)

					if currentSelected.Selected == states.Selected then
						return
					end
				end

				props.CurrentButton:set(buttonData)
				buttonData.Selected:set(true)
			end
		end,
	}
	local button = Button(buttonProps)

	local imageTransparencySpring = Spring(
		states, {
			Default = 0,
			Hover = 0.3,
			Selected = 0.6,
			MouseDown = 0.5,
			Disabled = 0,
		}, 20, 1
	)

	local preview = Fusion.New("ImageLabel")({
		Name = "Preview",
		Image = string.format("rbxthumb://type=Asset&id=%d&w=150&h=150", props.AssetId),
		ImageTransparency = imageTransparencySpring,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(79, 84, 95),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
	})

	local equipped = Fusion.Computed(function()
		local equipped = props.EquippedItems:get()
		
		for matchId, _ in pairs(equipped) do
			if tostring(props.AssetId) == tostring(matchId) then
				return true
			end
		end

		return false
	end)

	local tryText = Fusion.Computed(function()
		return equipped:get() and "Remove" or "Try"
	end)

	local interactionLayer = Fusion.New("Frame")({
		Name = "InteractableLayer",
		Size = UDim2.fromScale(1, 1),
		Transparency = 1,
		BackgroundColor3 = Color3.fromRGB(),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Visible = Fusion.Computed(function()
			return states.Selected:get()
		end),

		[Fusion.Children] = {
			Fusion.New("UIListLayout")({
				Name = "UIListLayout",
				Padding = UDim.new(0.05, 0),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			GetButton("Buy", {
				Default = Color3.fromRGB(79, 173, 116),
				MouseDown = Color3.fromRGB(57, 95, 73),
				Disabled = Color3.fromRGB(77, 121, 95),
			}, {
				Default = Color3.fromRGB(255, 255, 255),
				Disabled = Color3.fromRGB(120, 125, 136),
			}, function(enabled: boolean)
				if states.Selected:get() and states.Enabled:get() then
					props.BuyCallback()
				end
			end),
			GetButton(tryText, {
				Default = Color3.fromRGB(255, 255, 255),
				MouseDown = Color3.fromRGB(153, 153, 153),
			}, {
				Default = Color3.fromRGB(0, 0, 0),
				Disabled = Color3.fromRGB(120, 125, 136),
			}, function(enabled: boolean)
				if states.Selected:get() and states.Enabled:get() then
					props.TryCallback()
				end
			end),
		},
	})
	
	preview.Parent = button
	interactionLayer.Parent = button

	return button
end
