local knit = require(game:GetService('ReplicatedStorage').Packages.Knit)
module = knit.CreateService({
	Name = "PlayerState",
	Client = {},
})

local datamanager
local timermanager 
local settingsmanager


function module.initvals(dm,tm,sm)
	datamanager = dm
	timermanager = tm
	settingsmanager = sm
end

function teleportPlayer(player, spawnPoint)
	if player and player.Character and player.Character.PrimaryPart then
		player.Character:SetPrimaryPartCFrame(spawnPoint.CFrame + Vector3.new(0,5,0))
	else

		player.CharacterAdded:Wait()
		wait(1)
		player.Character:SetPrimaryPartCFrame(spawnPoint.CFrame + Vector3.new(0,5,0))

	end
end
function module:SpawnPlayer(plr : Player)
		local Objects = workspace:FindFirstChild("OutcoreStorage")
		local vfxfolder = workspace.VFX
		for _,v in vfxfolder:GetChildren() do
			if string.find(v.Name, tostring(plr.UserId)) then
				v:Destroy()
			end
		end
		if Objects then
			Objects:Destroy()
		end
			local newObjects = game.ReplicatedStorage.OutcoreStorage:Clone()
			newObjects.Parent = workspace
		
		plr:LoadCharacter()
end
module.Client["SpawnPlayer"] = module.SpawnPlayer

function module:onPlayerRespawn(plr: Player,IN_GAME,SPSetter,SPoints)
	if IN_GAME then
		teleportPlayer(plr, SPoints[SPSetter])
	else
		teleportPlayer(plr, SPoints[1])
	end
	plr.Character.CharacterController.CharacterControllers.Enabled = true
	return SPSetter
end



function module:IsDied(PLR:Player,IN_GAME,FOLLOW)
	if IN_GAME == true then
		if FOLLOW == true then	
			local gui = game.StarterGui.MainMenu.RetryGUI:Clone()
			gui.Parent = PLR.PlayerGui.MainMenu
			gui.Enabled = true
			timermanager:PauseTimer(PLR.UserId)
		else
			if PLR.PlayerGui.MainMenu.PauseGUI.Enabled == true then
			else
				module:SpawnPlayer(PLR)
			end
		end
	else
		module:SpawnPlayer(PLR)
	end
end

function module:IsFinished(PLR: Player, INGAME: boolean, FOLLOW: boolean, SPS: number)
	if INGAME then
		if FOLLOW then
			local gui = PLR.PlayerGui.MainMenu.FinishGUI:Clone()
			gui.Parent = PLR.PlayerGui.MainMenu
			if SPS == 9 then
				gui.A.FinishText.Visible = true
			end
			gui.Enabled = true
			PLR.Character.Humanoid.WalkSpeed = 0
			PLR.Character.Humanoid.JumpPower = 0
		end
	end
end
return module