local TweenService = game:GetService("TweenService")
local part = script.Parent
part.Anchored = true
local left = script.Parent.Left
local right  = script.Parent.Right

local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut, 0, false, 0)
local originalPosition = part.Position
local leftPosition = originalPosition - Vector3.new(0, 0, 20)
local rightPosition = originalPosition + Vector3.new(0, 0, 20)
local tweenToLeft = TweenService:Create(part, tweenInfo, {Position = leftPosition})
local tweenToRight = TweenService:Create(part, tweenInfo, {Position = rightPosition})

while true do
	left.Enabled = true
	tweenToRight:Play()
	tweenToRight.Completed:Wait()
	left.Enabled = false
	right.Enabled = true
	tweenToLeft:Play()
	tweenToLeft.Completed:Wait()
	right.Enabled = false
end
