game["Run Service"].Heartbeat:Connect(function(dt)
	script.Parent.Rotation = script.Parent.Rotation + (dt * 60)
end)
