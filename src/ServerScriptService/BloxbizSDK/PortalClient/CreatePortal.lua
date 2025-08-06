return function()
	local Portal = Instance.new("Model")
	Portal.Name = "Portal"

	local TeleportPart = Instance.new("Part")
	TeleportPart.Name = "TeleportPart"
	TeleportPart.Anchored = true
	TeleportPart.BottomSurface = Enum.SurfaceType.Smooth
	TeleportPart.CanCollide = false
	TeleportPart.Transparency = 1
	TeleportPart.TopSurface = Enum.SurfaceType.Smooth
	TeleportPart.Color = Color3.fromRGB(27, 42, 53)
	TeleportPart.Size = Vector3.new(7.049999237060547, 11.09999942779541, 1.600000023841858)
	TeleportPart.CFrame = CFrame.new(59.41625213623047, 108.5034408569336, -251.5929412841797, -1, 2.92088246885543e-30, 8.940696716308594e-08, -2.920882845013622e-30, 1, -5.570934424705135e-30, -8.940696716308594e-08, 5.570934800863327e-30, -1)
	TeleportPart.Parent = Portal

	local Billboard = Instance.new("Part")
	Billboard.Name = "Billboard"
	Billboard.Anchored = true
	Billboard.BottomSurface = Enum.SurfaceType.Smooth
	Billboard.TopSurface = Enum.SurfaceType.Smooth
	Billboard.Color = Color3.fromRGB(27, 42, 53)
	Billboard.Size = Vector3.new(15.034883499145508, 7.517441749572754, 0.5249680280685425)
	Billboard.CFrame = CFrame.new(71.32476043701172, 108.22545623779297, -248.5855712890625, -0.9396933317184448, 0.0000015398444475067663, 0.3420187532901764, 6.901035476403194e-07, 1.000004529953003, 7.589757444748102e-08, -0.3420194089412689, 6.5488001155245e-07, -0.939695417881012)
	Billboard.Parent = Portal

	local AdSurfaceGui = Instance.new("SurfaceGui")
	AdSurfaceGui.Name = "AdSurfaceGui"
	AdSurfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	AdSurfaceGui.ClipsDescendants = true
	AdSurfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	AdSurfaceGui.Parent = Billboard

	local ImageLabel = Instance.new("ImageLabel")
	ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	ImageLabel.Size = UDim2.new(1, 0, 1, 0)
	ImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	ImageLabel.BorderSizePixel = 0
	ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ImageLabel.Image = "rbxassetid://9992736001"
	ImageLabel.Parent = AdSurfaceGui

	local HardcodedOverlay = Instance.new("ImageLabel")
	HardcodedOverlay.Name = "HardcodedOverlay"
	HardcodedOverlay.ZIndex = 100
	HardcodedOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
	HardcodedOverlay.Size = UDim2.new(1, 0, 1, 0)
	HardcodedOverlay.Position = UDim2.new(0.5, 0, 0.5, 0)
	HardcodedOverlay.BorderSizePixel = 0
	HardcodedOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	HardcodedOverlay.Image = "http://www.roblox.com/asset/?id=10636513326"
	HardcodedOverlay.Parent = AdSurfaceGui

	local DisclaimerHolder = Instance.new("Frame")
	DisclaimerHolder.Name = "DisclaimerHolder"
	DisclaimerHolder.ZIndex = 2147483647
	DisclaimerHolder.AnchorPoint = Vector2.new(1, 1)
	DisclaimerHolder.SizeConstraint = Enum.SizeConstraint.RelativeYY
	DisclaimerHolder.Size = UDim2.new(2, 0, 1, 0)
	DisclaimerHolder.BackgroundTransparency = 1
	DisclaimerHolder.Position = UDim2.new(1, 0, 1, 0)
	DisclaimerHolder.BorderSizePixel = 0
	DisclaimerHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	DisclaimerHolder.Parent = AdSurfaceGui

	local AdDisclaimerLabel = Instance.new("ImageLabel")
	AdDisclaimerLabel.Name = "AdDisclaimerLabel"
	AdDisclaimerLabel.ZIndex = 2147483647
	AdDisclaimerLabel.AnchorPoint = Vector2.new(1, 1)
	AdDisclaimerLabel.Size = UDim2.new(0.146, 0, 0.1, 0)
	AdDisclaimerLabel.BackgroundTransparency = 1
	AdDisclaimerLabel.Position = UDim2.new(1, 0, 1, 0)
	AdDisclaimerLabel.BorderSizePixel = 0
	AdDisclaimerLabel.ImageTransparency = 0.2
	AdDisclaimerLabel.Image = "rbxassetid://7122215099"
	AdDisclaimerLabel.Parent = DisclaimerHolder

	local Weld = Instance.new("Weld")
	Weld.C1 = CFrame.new(-221.54994201660156, 10, 71.50015258789062, 0, -1, -2.8437621324052686e-34, 5.332054313944397e-34, 2.8437621324052686e-34, -1, 1, 0, 5.332054313944397e-34)
	Weld.C0 = CFrame.new(0, -7.5, 0, 1, 0, 0, 1.0664108627888793e-33, 0, -1, 0, 1, 5.687524264810537e-34)
	Weld.Parent = Billboard

	local Door = Instance.new("Model")
	Door.Name = "Door"
	Door.Parent = Portal

	local TransparentPart = Instance.new("Part")
	TransparentPart.Name = "TransparentPart"
	TransparentPart.Anchored = true
	TransparentPart.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
	TransparentPart.CanCollide = false
	TransparentPart.Transparency = 0.7
	TransparentPart.TopSurface = Enum.SurfaceType.SmoothNoOutlines
	TransparentPart.Color = Color3.fromRGB(18, 238, 212)
	TransparentPart.RightSurface = Enum.SurfaceType.SmoothNoOutlines
	TransparentPart.Material = Enum.Material.Neon
	TransparentPart.Size = Vector3.new(6.193760871887207, 10.929999351501465, 0.929064154624939)
	TransparentPart.BackSurface = Enum.SurfaceType.SmoothNoOutlines
	TransparentPart.LeftSurface = Enum.SurfaceType.SmoothNoOutlines
	TransparentPart.CFrame = CFrame.new(59.538169860839844, 108.41844940185547, -251.6574249267578, 1.000000238418579, -2.756585004703993e-08, -8.940700979565008e-08, 2.7565899785031434e-08, 1.000000238418579, -7.105427357601002e-15, 8.940698847936801e-08, -1.7299483785586378e-13, 1.0000004768371582)
	TransparentPart.FrontSurface = Enum.SurfaceType.SmoothNoOutlines
	TransparentPart.Parent = Door

	local TopPartBottom = Instance.new("WedgePart")
	TopPartBottom.Name = "TopPartBottom"
	TopPartBottom.Anchored = true
	TopPartBottom.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
	TopPartBottom.TopSurface = Enum.SurfaceType.SmoothNoOutlines
	TopPartBottom.Color = Color3.fromRGB(213, 115, 61)
	TopPartBottom.RightSurface = Enum.SurfaceType.SmoothNoOutlines
	TopPartBottom.Size = Vector3.new(1.5484402179718018, 1.5484402179718018, 1.5484402179718018)
	TopPartBottom.BackSurface = Enum.SurfaceType.SmoothNoOutlines
	TopPartBottom.LeftSurface = Enum.SurfaceType.SmoothNoOutlines
	TopPartBottom.CFrame = CFrame.new(55.667137145996094, 114.5667495727539, -251.6573028564453, 8.940700979565008e-08, -2.757909101092082e-08, 1.000000238418579, 0.0001580000389367342, 1.000000238418579, 2.7565899785031434e-08, -1.0000004768371582, 0.00015800011169631034, 8.940698847936801e-08)
	TopPartBottom.FrontSurface = Enum.SurfaceType.SmoothNoOutlines
	TopPartBottom.Parent = Door

	local SidePart = Instance.new("Part")
	SidePart.Name = "SidePart"
	SidePart.Anchored = true
	SidePart.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
	SidePart.TopSurface = Enum.SurfaceType.SmoothNoOutlines
	SidePart.Color = Color3.fromRGB(213, 115, 61)
	SidePart.RightSurface = Enum.SurfaceType.SmoothNoOutlines
	SidePart.Size = Vector3.new(1.5484402179718018, 10.839081764221191, 1.5484402179718018)
	SidePart.BackSurface = Enum.SurfaceType.SmoothNoOutlines
	SidePart.LeftSurface = Enum.SurfaceType.SmoothNoOutlines
	SidePart.CFrame = CFrame.new(55.667137145996094, 108.37296295166016, -251.65736389160156, 1.000000238418579, -2.756585004703993e-08, -8.940700979565008e-08, 2.7565899785031434e-08, 1.000000238418579, -7.105427357601002e-15, 8.940698847936801e-08, -1.7299483785586378e-13, 1.0000004768371582)
	SidePart.FrontSurface = Enum.SurfaceType.SmoothNoOutlines
	SidePart.Parent = Door

	local TopPartBottom1 = Instance.new("WedgePart")
	TopPartBottom1.Name = "TopPartBottom"
	TopPartBottom1.Anchored = true
	TopPartBottom1.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
	TopPartBottom1.TopSurface = Enum.SurfaceType.SmoothNoOutlines
	TopPartBottom1.Color = Color3.fromRGB(213, 115, 61)
	TopPartBottom1.RightSurface = Enum.SurfaceType.SmoothNoOutlines
	TopPartBottom1.Size = Vector3.new(1.5484402179718018, 1.5484402179718018, 1.5484402179718018)
	TopPartBottom1.BackSurface = Enum.SurfaceType.SmoothNoOutlines
	TopPartBottom1.LeftSurface = Enum.SurfaceType.SmoothNoOutlines
	TopPartBottom1.CFrame = CFrame.new(63.409202575683594, 114.5667495727539, -251.65736389160156, -8.940700979565008e-08, -2.757909101092082e-08, -1.000000238418579, -0.0001580000389367342, 1.000000238418579, -2.7565899785031434e-08, 1.0000004768371582, 0.00015800011169631034, -8.940698847936801e-08)
	TopPartBottom1.FrontSurface = Enum.SurfaceType.SmoothNoOutlines
	TopPartBottom1.Parent = Door

	local SidePart1 = Instance.new("Part")
	SidePart1.Name = "SidePart"
	SidePart1.Anchored = true
	SidePart1.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
	SidePart1.TopSurface = Enum.SurfaceType.SmoothNoOutlines
	SidePart1.Color = Color3.fromRGB(213, 115, 61)
	SidePart1.RightSurface = Enum.SurfaceType.SmoothNoOutlines
	SidePart1.Size = Vector3.new(1.5484402179718018, 10.839081764221191, 1.5484402179718018)
	SidePart1.BackSurface = Enum.SurfaceType.SmoothNoOutlines
	SidePart1.LeftSurface = Enum.SurfaceType.SmoothNoOutlines
	SidePart1.CFrame = CFrame.new(63.409202575683594, 108.37296295166016, -251.6574249267578, 1.000000238418579, -2.756585004703993e-08, -8.940700979565008e-08, 2.7565899785031434e-08, 1.000000238418579, -7.105427357601002e-15, 8.940698847936801e-08, -1.7299483785586378e-13, 1.0000004768371582)
	SidePart1.FrontSurface = Enum.SurfaceType.SmoothNoOutlines
	SidePart1.Parent = Door

	local TopPart = Instance.new("Part")
	TopPart.Name = "TopPart"
	TopPart.Anchored = true
	TopPart.BottomSurface = Enum.SurfaceType.Smooth
	TopPart.TopSurface = Enum.SurfaceType.Smooth
	TopPart.Color = Color3.fromRGB(196, 40, 28)
	TopPart.Size = Vector3.new(9.859999656677246, 1.6592092514038086, 1.7960782051086426)
	TopPart.CFrame = CFrame.new(59.563316345214844, 114.66971588134766, -251.67247009277344, -1, 0, 8.940696716308594e-08, 0, 1, 0, -8.940696716308594e-08, 0, -1)
	TopPart.Parent = Door

	local Mesh = Instance.new("SpecialMesh")
	Mesh.Scale = Vector3.new(0.6617456078529358, 0.6814686059951782, 0.7376834154129028)
	Mesh.MeshId = "rbxassetid://6841842647"
	Mesh.MeshType = Enum.MeshType.FileMesh
	Mesh.Parent = TopPart

	local ArrowLabel = Instance.new("Part")
	ArrowLabel.Name = "ArrowLabel"
	ArrowLabel.Anchored = true
	ArrowLabel.BottomSurface = Enum.SurfaceType.Smooth
	ArrowLabel.TopSurface = Enum.SurfaceType.Smooth
	ArrowLabel.Color = Color3.fromRGB(27, 42, 53)
	ArrowLabel.Size = Vector3.new(15.034883499145508, 1.2529069185256958, 0.5249680280685425)
	ArrowLabel.CFrame = CFrame.new(71.32476043701172, 112.60941314697266, -248.5855712890625, -0.9396933317184448, 0.0000015398444475067663, 0.3420187532901764, 6.901035476403194e-07, 1.000004529953003, 7.589757444748102e-08, -0.3420194089412689, 6.5488001155245e-07, -0.939695417881012)
	ArrowLabel.Parent = Portal

	local AdSurfaceGui1 = Instance.new("SurfaceGui")
	AdSurfaceGui1.Name = "AdSurfaceGui"
	AdSurfaceGui1.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	AdSurfaceGui1.ClipsDescendants = true
	AdSurfaceGui1.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	AdSurfaceGui1.Parent = ArrowLabel

	local ImageLabel1 = Instance.new("ImageLabel")
	ImageLabel1.AnchorPoint = Vector2.new(0.5, 0.5)
	ImageLabel1.Size = UDim2.new(1, 0, 1, 0)
	ImageLabel1.Position = UDim2.new(0.5, 0, 0.5, 0)
	ImageLabel1.BorderSizePixel = 0
	ImageLabel1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ImageLabel1.ScaleType = Enum.ScaleType.Fit
	ImageLabel1.Image = "http://www.roblox.com/asset/?id=10569472524"
	ImageLabel1.Parent = AdSurfaceGui1

	local Weld1 = Instance.new("Weld")
	Weld1.C1 = CFrame.new(-221.54994201660156, 10, 71.50015258789062, 0, -1, -2.8437621324052686e-34, 5.332054313944397e-34, 2.8437621324052686e-34, -1, 1, 0, 5.332054313944397e-34)
	Weld1.C0 = CFrame.new(0, -7.5, 0, 1, 0, 0, 1.0664108627888793e-33, 0, -1, 0, 1, 5.687524264810537e-34)
	Weld1.Parent = ArrowLabel

	Weld.Part0 = Billboard

	Weld1.Part0 = ArrowLabel
	
	return Portal
end