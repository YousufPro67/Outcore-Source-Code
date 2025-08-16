local ts = game.TweenService
local ti = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local collectionService = game:GetService("CollectionService")

task.wait(0.5)
for _, v: Model in collectionService:GetTagged("GuideWall") do 
    if not v:IsA("Model") then continue end
    if not v:FindFirstChild("Main") or not v:FindFirstChild("Part1") or not v:FindFirstChild("Part2") or not v:FindFirstChild("Part3") or not v:FindFirstChild("Part4") then continue end
    local tween1 = ts:Create(v.Main, ti, {Position = v.Main.Position + Vector3.new(0, -3, 0)})
    tween1:Play()
    local tween2 = ts:Create(v.Part1, ti, {Position = v.Part1.Position + Vector3.new(0, -3, 0)})
    tween2:Play()
    local tween3 = ts:Create(v.Part2, ti, {Position = v.Part2.Position + Vector3.new(0, -3, 0)})
    tween3:Play()
    local tween4 = ts:Create(v.Part3, ti, {Position = v.Part3.Position + Vector3.new(0, -3, 0)})
    tween4:Play()
    local tween5 = ts:Create(v.Part4, ti, {Position = v.Part4.Position + Vector3.new(0, -3, 0)})
    tween5:Play()
end