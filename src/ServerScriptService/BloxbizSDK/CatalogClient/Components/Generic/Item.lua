--!strict
local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local Components = script.Parent.Parent
local Generic = Components.Generic

local UICorner = require(Generic.UICorner)
local Spring = require(Generic.Spring)

export type Colors = Spring.Values<Color3>

export type Props = {
	AssetId: number,

	AnchorPoint: Vector2?,
	Position: UDim2?,
	Size: UDim2?,
	BackgroundColor3: Colors?,
	Toggle: boolean?,

	SizeConstrait: Enum.SizeConstraint?,
	Callback: (enabled: boolean, selected: boolean?) -> (),
}

return function(props: Props): Frame
	local states: Spring.States = {
		HeldDown = Fusion.Value(false),
		Hovering = Fusion.Value(false),
		Selected = Fusion.Value(false),
		Enabled = Fusion.Value(true),
	}

	return Fusion.New("Frame")({
		Name = tostring(props.AssetId),
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		BackgroundColor3 = props.BackgroundColor3 and Spring(states, props.BackgroundColor3)
			or Color3.fromRGB(79, 84, 95),

		Position = props.Position or UDim2.fromScale(0, 0),
		Size = props.Size or UDim2.fromScale(1, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Visible = true,

		[Fusion.Children] = {
			UICorner(0.065),

			Fusion.New("ImageLabel")({
				Name = "Preview",
				Image = string.format("rbxthumb://type=Asset&id=%d&w=150&h=150", props.AssetId),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(79, 84, 95),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,

				[Fusion.OnEvent("MouseButton1Down")] = function()
					states.HeldDown:set(true)
				end,

				[Fusion.OnEvent("MouseButton1Up")] = function()
					states.HeldDown:set(false)
				end,

				[Fusion.OnEvent("MouseEnter")] = function()
					states.Hovering:set(true)
				end,

				[Fusion.OnEvent("MouseLeave")] = function()
					states.Hovering:set(false)
					states.HeldDown:set(false)
				end,

				[Fusion.OnEvent("Activated")] = function()
					if props.Toggle then
						if states.Enabled:get() then
							states.Selected:set(states.Selected:get())
						end
					end

					if props.Callback then
						props.Callback(states.Enabled:get(), props.Toggle and states.Selected:get() or nil)
					end
				end,
			}),
		},
	}) :: Frame
end
