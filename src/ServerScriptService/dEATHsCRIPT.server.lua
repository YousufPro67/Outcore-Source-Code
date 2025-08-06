game.ReplicatedStorage.DeathEvent.OnServerEvent:Connect(function(plr)
	local char = plr.Character
	local hum = char:FindFirstChildOfClass("Humanoid")
	hum:TakeDamage(hum.Health)
	hum:ChangeState(Enum.HumanoidStateType.Dead)
end)
