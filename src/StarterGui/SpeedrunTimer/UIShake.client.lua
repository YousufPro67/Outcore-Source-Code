local ts = game.TweenService
local ti = TweenInfo.new(0.1, Enum.EasingStyle.Sine)
local human:BasePart = game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart", 60)

game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
	human = char:WaitForChild("HumanoidRootPart", 60)
end)

local function Update()
	local velocity;
	local success, err = pcall(function()
		velocity = human.AssemblyLinearVelocity.Magnitude
	end)
	if success then
		if velocity >= 80 then
			ts:Create(script.Parent.TextLabel, ti, {Position = UDim2.new(0.5, math.random(-velocity * 0.01, velocity * 0.01), 0, 15 + math.random(-velocity * 0.01, velocity * 0.01))}):Play()
			ts:Create(script.Parent.Meters, ti, {Position = UDim2.new(0, 15 + math.random(-velocity * 0.01, velocity * 0.01), 1, -15 + math.random(-velocity * 0.01, velocity * 0.01))}):Play()
			--print("yes")
		else
			script.Parent.TextLabel.Position = UDim2.new(0.5, 0, 0, 15)
			script.Parent.Meters.Position = UDim2.new(0, 15, 1, -15)
			--print("no")
		end
	end
end

game["Run Service"].PreRender:Connect(Update)