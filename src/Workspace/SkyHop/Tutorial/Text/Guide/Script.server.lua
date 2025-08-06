local ts = game.TweenService
local ti = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

local tween1 = ts:Create(script.Parent.Main, ti, {Position = script.Parent.Main.Position + Vector3.new(0, -3, 0)})
tween1:Play()
local tween2 = ts:Create(script.Parent.Part1, ti, {Position = script.Parent.Part1.Position + Vector3.new(0, -3, 0)})
tween2:Play()
local tween3 = ts:Create(script.Parent.Part2, ti, {Position = script.Parent.Part2.Position + Vector3.new(0, -3, 0)})
tween3:Play()
local tween4 = ts:Create(script.Parent.Part3, ti, {Position = script.Parent.Part3.Position + Vector3.new(0, -3, 0)})
tween4:Play()
local tween5 = ts:Create(script.Parent.Part4, ti, {Position = script.Parent.Part4.Position + Vector3.new(0, -3, 0)})
tween5:Play()