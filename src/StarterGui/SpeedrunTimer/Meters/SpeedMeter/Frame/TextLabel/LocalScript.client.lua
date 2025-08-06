while true do
	wait(0.25)
	local root:BasePart = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if root then
		local velocity = math.round(10 * root.AssemblyLinearVelocity.Magnitude)/10
		script.Parent.Text = velocity
	end
end
