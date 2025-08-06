-- settings --
local TiltSpeed = 1.5

-- script --
local Signal = script.Parent:WaitForChild("WallrunSignal")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Goal = 0
local CurrentAngle = 0
local cam = workspace.CurrentCamera
local serverscript = script.Parent:WaitForChild("WallrunScript")

local track = game.Players.LocalPlayer.Character.Humanoid:LoadAnimation(serverscript:WaitForChild("Animation"))
local track2 = game.Players.LocalPlayer.Character.Humanoid:LoadAnimation(serverscript:WaitForChild("Animation2"))

UIS.InputBegan:Connect(function(key, p)
	if key.KeyCode == Enum.KeyCode.Space then
		Signal:FireServer(true)
	end
end)

UIS.InputEnded:Connect(function(key, p)
	if key.KeyCode == Enum.KeyCode.Space then
		Signal:FireServer(false)
	end
end)

Signal.OnClientEvent:Connect(function(angle)
	Goal = angle
end)

RS.PreRender:Connect(function()
	local sign = Goal / math.abs(Goal)
	if CurrentAngle * sign < Goal * sign then
		CurrentAngle = CurrentAngle + sign * TiltSpeed
	elseif CurrentAngle ~= 0 then
		sign = CurrentAngle / math.abs(CurrentAngle)
		CurrentAngle = CurrentAngle - sign * TiltSpeed
	end
	if math.abs(CurrentAngle - Goal) <= TiltSpeed then 
		CurrentAngle = Goal 
	end
	cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, math.rad(CurrentAngle))
end)
