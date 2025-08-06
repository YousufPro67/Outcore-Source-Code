local weld = script.Parent.Weld
local prompt = script.Parent.ProximityPrompt

prompt.Triggered:Connect(function(plr)
	local Blaster = game.ReplicatedStorage.Items.Blaster:Clone()
	Blaster.Parent = plr.Backpack
end)