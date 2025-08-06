game["Run Service"].PreRender:Connect(function()
	local root:BasePart = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if root then
		local ping = math.round((game.Players.LocalPlayer:GetNetworkPing() * 2) * 10000) / 10
		script.Parent.Text = ping
	end
end)
