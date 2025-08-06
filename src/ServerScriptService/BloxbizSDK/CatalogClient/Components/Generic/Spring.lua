--!strict
local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

export type States = {
	Enabled: Fusion.Value<boolean>,
	Hovering: Fusion.Value<boolean>,
	HeldDown: Fusion.Value<boolean>,
	Selected: Fusion.Value<boolean>,
}

export type Values<T> = {
	MouseDown: T?,
	Selected: T?,
	Hover: T?,
	Disabled: T?,
	Default: T,
}

return function(states: States, values: Values<any>, speed: number?, damping: number?): Fusion.Spring<any>
	return Fusion.Spring(
		Fusion.Computed(function()
			if states.Enabled:get() then
				if states.Selected:get() then
					return values.Selected or values.Default
				elseif states.HeldDown:get() then
					return values.MouseDown or values.Default
				elseif states.Hovering:get() then
					return values.Hover or values.Default
				else
					return values.Default
				end
			else
				return values.Disabled or values.Default
			end
		end),
		speed or 20,
		damping or 1
	)
end
