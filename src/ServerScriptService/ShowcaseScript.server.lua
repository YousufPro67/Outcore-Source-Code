local cs = game.CollectionService

game["Run Service"].Heartbeat:Connect(function()
	for _,v in cs:GetTagged("Showcase") do
		local weld = v.Weld
		weld.C1 = weld.C1:Lerp(weld.C1 * CFrame.Angles(math.rad(0), math.rad(5), math.rad(0)), 0.5)
	end
end)
