local fps = 0

game["Run Service"].PreRender:Connect(function(dt)
	local root:BasePart = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if root then
		fps = math.round(10 * (1/dt))/10
	end
end)

while true do
	wait(.1)
	script.Parent.Text = fps
end