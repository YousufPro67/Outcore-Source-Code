return function()
	local VideoFrame = Instance.new("Frame")
	VideoFrame.Name = "VideoFrame"
	VideoFrame.ZIndex = 2147483647
	VideoFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	VideoFrame.Size = UDim2.new(1, 0, 1, 0)
	VideoFrame.BackgroundTransparency = 1
	VideoFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	VideoFrame.BorderSizePixel = 0
	VideoFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

	local AudioBtn = Instance.new("ImageButton")
	AudioBtn.Name = "AudioBtn"
	AudioBtn.ZIndex = 2147483647
	AudioBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	AudioBtn.Size = UDim2.new(1, 0, 1, 0)
	AudioBtn.BackgroundTransparency = 1
	AudioBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
	AudioBtn.BorderSizePixel = 0
	AudioBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	AudioBtn.Parent = VideoFrame

	local AudioLabel = Instance.new("ImageLabel")
	AudioLabel.Name = "AudioLabel"
	AudioLabel.ZIndex = 2147483647
	AudioLabel.AnchorPoint = Vector2.new(1, 0)
	AudioLabel.SizeConstraint = Enum.SizeConstraint.RelativeYY
	AudioLabel.Size = UDim2.new(40 / 380, 0, 40 / 380, 0)
	AudioLabel.BackgroundTransparency = 1
	AudioLabel.Position = UDim2.new(755 / 775, 0, 20 / 380, 0)
	AudioLabel.BorderSizePixel = 0
	AudioLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	AudioLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
	AudioLabel.Image = "http://www.roblox.com/asset/?id=10647669422"
	AudioLabel.Parent = VideoFrame

	return VideoFrame
end
