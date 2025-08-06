local TS = game:GetService('TweenService')
local cs = game:GetService("CollectionService")
local TI = TweenInfo.new(
	1,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.InOut,
	-1,
	true
)
local TI2 = TweenInfo.new(
	6,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.InOut,
	-1,
	false
)
--local a = 2


for _,core:BasePart in cs:GetTagged("Core") do

	local tween = TS:Create(core, TI, {
		Position = core.Position + Vector3.new(0,1,0)
	})
	local tween2 = TS:Create(core, TI2, {
		Orientation = core.Orientation + Vector3.new(360,360,0)
	})
	tween:Play()
	tween2:Play()
end


                                                                     
