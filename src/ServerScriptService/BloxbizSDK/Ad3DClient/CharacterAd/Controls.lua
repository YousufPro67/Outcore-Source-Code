local LocalPlayer = game:GetService("Players").LocalPlayer

local module = {}
module.previousWalkSpeed = nil

function module.gameIsR6R15()
	local character = LocalPlayer.Character

	if not character then
		return false
	end

	local humanoid = character:FindFirstChild("Humanoid")

	if not humanoid or (humanoid and not humanoid.RigType) then
		return false
	end

	return true
end

function module.enablePlayerMovement()
	local Controls = require(LocalPlayer.PlayerScripts.PlayerModule):GetControls()
	Controls:Enable()
end

function module.disablePlayerMovement()
	local Controls = require(LocalPlayer.PlayerScripts.PlayerModule):GetControls()
	Controls:Disable()
end

function module.enablePlayerMovementControlGuiVisible()
	if not module.gameIsR6R15() then
		return
	end

	local character = LocalPlayer.Character

	if not character then
		return
	end

	local humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = module.previousWalkSpeed or 16
end

function module.disablePlayerMovementControlGuiVisible(walkSpeedOverride)
	if not module.gameIsR6R15() then
		return
	end

	local character = LocalPlayer.Character

	if not character then
		return
	end

	local humanoid = character:WaitForChild("Humanoid")
	module.previousWalkSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = walkSpeedOverride or 0
end

function module.watchForMovement(secondsThreshold)
	local watching = true
	local moving = false
	local moveStart = nil

	local movementFinishedEvent = Instance.new("BindableEvent")

	local PlayerModule = require(game.Players.LocalPlayer.PlayerScripts.PlayerModule)
	local Controls = PlayerModule:GetControls()

	local function watch()
		while watching do
			local moveVector = Controls:GetMoveVector()
			moving = moveVector.Magnitude ~= 0

			if moving and not moveStart then
				moveStart = tick()
			elseif secondsThreshold and moving and moveStart then
				local dt = tick() - moveStart

				if dt > secondsThreshold then
					movementFinishedEvent:Fire("TimeElapsed", dt)
					break
				end
			elseif not moving and moveStart then
				local dt = tick() - moveStart
				moveStart = nil
				movementFinishedEvent:Fire("InputEnd", dt)
			end

			task.wait()
		end
	end

	task.spawn(watch)

	movementFinishedEvent.Event:Connect(function(what, dt)
		if what == "StopWatching" then
			watching = false
		end
	end)

	return movementFinishedEvent
end

return module
