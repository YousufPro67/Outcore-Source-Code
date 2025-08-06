local weld = script.Parent.Weld
local prompt = script.Parent.ProximityPrompt

prompt.Triggered:Connect(function(plr)
	plr.Character:FindFirstChildOfClass("Humanoid"):UnequipTools()
	local s, ab = pcall(function()
		return plr.Backpack.AutoBlaster
	end)
	if not s then
		local Blaster = game.ReplicatedStorage.Items.AutoBlaster:Clone()
		Blaster.Parent = plr.Backpack
	end
end)