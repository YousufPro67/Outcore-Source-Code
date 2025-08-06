local knit = require(game.ReplicatedStorage.Packages.Knit)
knit.Start():await()
local plrsetting = knit.GetService("SettingService")

script.Parent.ChildAdded:Connect(function(child: Instance)
local set = plrsetting:Get()
	if child.Name == "FinishGUI" then
		if set.FINISHED then
			child:Destroy()
		end
	elseif child.Name == "RetryGUI" then
		if set.RETRY then
			child:Destroy()
		end
	elseif child.Name == "PauseGUI" then
		if set.PAUSED then
			child:Destroy()
		end
	else
		error("Unknown Instance Made In MainMenu! Instance:"..child.Name)
	end
	if set.FINISHED and set.RETRY then
		for _, obj:ScreenGui in script.Parent:GetChildren() do
			if obj.Enabled == true and obj.Name == "RetryGUI" then
				obj:Destroy()
			end
		end
	end
end)