local Collection = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character

local SFX = game.ReplicatedStorage.SFX.TunnelSFX
local TAG = "TunnelDetector"

for _, obj in Collection:GetTagged(TAG) do
	for _, v: BasePart in obj.Parent:GetChildren() do
		if not v:IsA("BasePart") then return end
		v.Material = Enum.Material.SmoothPlastic
	end
	obj.Touched:Connect(function(hit: BasePart)
		if not hit:IsDescendantOf(Character) then return end
		for _, v: BasePart in obj.Parent:GetChildren() do
			if not v:IsA("BasePart") then return end
			v.Material = Enum.Material.Neon
			SFX:Play()
		end
	end)
end