local MenuDetector = game:GetService("GuiService")
local TS = game:GetService("TweenService")

local blur = Instance.new("BlurEffect")
blur.Name = "CoreMenuBlur"
blur.Enabled = true
blur.Size = 0
blur.Parent = game.Lighting

local blurt:Tween = nil

MenuDetector.MenuOpened:Connect(function()
	blurt = TS:Create(blur, TweenInfo.new(1, Enum.EasingStyle.Sine), {Size = 56})
	blurt:Play()
end)

MenuDetector.MenuClosed:Connect(function()
	if blurt.PlaybackState == Enum.PlaybackState.Playing then
		blurt:Cancel()
		blurt = TS:Create(blur, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {Size = 0})
		blurt:Play()
	end
	blurt = TS:Create(blur, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {Size = 0})
	blurt:Play()
end)