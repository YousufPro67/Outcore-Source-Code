local Collection = game:GetService("CollectionService")

local Enemies = game.ReplicatedStorage.OutcoreStorage.Enemies
local TAG = "EPlatform"
local EnemyTemplate: Model = game.ReplicatedStorage.OutcoreStorage.Enemies:GetChildren()[2]

for _, p: BasePart in Collection:GetTagged(TAG) do
	local Enemy = EnemyTemplate:Clone()
	Enemy:PivotTo(CFrame.new(p.Position + Vector3.new(0, 10, 0)))
	Enemy.Parent = game.ReplicatedStorage.OutcoreStorage.Enemies
end EnemyTemplate:Destroy()