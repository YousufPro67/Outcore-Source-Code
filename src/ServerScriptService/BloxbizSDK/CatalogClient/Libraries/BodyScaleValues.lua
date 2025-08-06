export type Value = {
	Min: number,
	Max: number,
	Default: number,
}

local BodyScaleValues = {
	HeadScale = { Min = 0.1, Max = 1, Default = 1 },
	WidthScale = { Min = 0.1, Max = 1, Default = 1 },
	HeightScale = { Min = 0.1, Max = 1.2, Default = 1 },
	BodyTypeScale = { Min = 0, Max = 1, Default = 0 },
	ProportionScale = { Min = 0, Max = 1, Default = 0 },
}

return BodyScaleValues
