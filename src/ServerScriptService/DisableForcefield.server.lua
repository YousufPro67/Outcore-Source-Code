game.Workspace.ChildAdded:connect(function(character)
	if game.Players:GetPlayerFromCharacter(character) ~= nil then
	local f = character:WaitForChild("ForceField",10)
		if not f then return end
		f:Destroy()
	end
end)

