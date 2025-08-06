local ts = game:GetService("TweenService")
local ti = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

local tween = ts:Create(script.Parent, ti, {TextTransparency = 1})
tween:Play()

