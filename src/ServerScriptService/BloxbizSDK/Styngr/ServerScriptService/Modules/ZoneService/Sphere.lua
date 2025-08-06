local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.BloxbizSDK.Utils.Fusion)

local New = Fusion.New

local SphereSize = 50

local Sphere = New("Part")({
	Name = "SphereZone",
	Shape = Enum.PartType.Ball,
	Transparency = 1,
	Size = Vector3.new(SphereSize, SphereSize, SphereSize),
	CanCollide = false,
})

return Sphere
