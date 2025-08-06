return function()
	local Billboard = Instance.new("Model")
	Billboard.Name = "Billboard"
	Billboard.WorldPivot = CFrame.new(
		-89.21399688720703,
		106.60600280761719,
		-253.22500610351562,
		-0.29351359605789185,
		-4.2523757315393595e-07,
		-0.9559594392776489,
		-1.850575017670053e-07,
		1,
		-3.8800882862233266e-07,
		0.955958366394043,
		6.303451982603292e-08,
		-0.29351329803466797
	)

	local AdUnit = Instance.new("Part")
	AdUnit.Name = "AdUnit"
	AdUnit.Anchored = true
	AdUnit.BottomSurface = Enum.SurfaceType.Smooth
	AdUnit.CanCollide = false
	AdUnit.Transparency = 0.4
	AdUnit.TopSurface = Enum.SurfaceType.Smooth
	AdUnit.Color = Color3.fromRGB(255, 255, 255)
	AdUnit.Size = Vector3.new(0.0010000000474974513, 0.0010000000474974513, 0.0010000000474974513)
	AdUnit.Locked = true
	AdUnit.CFrame = CFrame.new(
		-89.21399688720703,
		106.60600280761719,
		-253.22500610351562,
		-0.29351359605789185,
		-4.2523757315393595e-07,
		-0.9559594392776489,
		-1.850575017670053e-07,
		1,
		-3.8800882862233266e-07,
		0.955958366394043,
		6.303451982603292e-08,
		-0.29351329803466797
	)
	AdUnit.Parent = Billboard

	local AdSurfaceGui = Instance.new("SurfaceGui")
	AdSurfaceGui.Name = "AdSurfaceGui"
	AdSurfaceGui.Enabled = false
	AdSurfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	AdSurfaceGui.ClipsDescendants = true
	AdSurfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	AdSurfaceGui.Parent = AdUnit

	local ImageLabel = Instance.new("ImageLabel")
	ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	ImageLabel.Size = UDim2.new(1, 0, 1, 0)
	ImageLabel.BackgroundTransparency = 1
	ImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	ImageLabel.BorderSizePixel = 0
	ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ImageLabel.ScaleType = Enum.ScaleType.Fit
	ImageLabel.Parent = AdSurfaceGui

	local Weld = Instance.new("Weld")
	Weld.C1 = CFrame.new(
		-221.54994201660156,
		10,
		71.50015258789062,
		0,
		-1,
		-2.8437621324052686e-34,
		5.332054313944397e-34,
		2.8437621324052686e-34,
		-1,
		1,
		0,
		5.332054313944397e-34
	)
	Weld.C0 = CFrame.new(0, -7.5, 0, 1, 0, 0, 1.0664108627888793e-33, 0, -1, 0, 1, 5.687524264810537e-34)
	Weld.Parent = AdUnit

	Weld.Part0 = AdUnit

    return Billboard
end
