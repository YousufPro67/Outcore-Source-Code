wait(1)
local knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
knit.Start({ServicePromises = false}):await()
local CameraController = knit.GetController("Camera")
local plrSetting = knit.GetService("SettingService")
local plrData = knit.GetService("PlayerDataManager")
local cam_speed = 10
local plrstates = {
	INGAME = false,
	FOLLOW = true,
	SPS = 0,
	LEVEL_NAME = "Tutorial",
	CAMPART = game.Workspace.CameraParts:WaitForChild("MainCam",20)
}
local LEVELS_LIST = {
		"Tutorial",
		"Practice",
		"Level2",
		"Level3",
		"Level4",
		"Level5",
		"Level6",
		"Level7",
		"Level8"
}
local MainMusic = game.ReplicatedStorage.MUSIC.OutcoreMain
local GameMusic = game.ReplicatedStorage.MUSIC.OutcoreGame

MainMusic.Looped = true
GameMusic.Looped = true
MainMusic.Volume = 0
GameMusic.Volume = 0
MainMusic:Play()
MainMusic.EqualizerSoundEffect.MidGain = 90
MainMusic.EqualizerSoundEffect.LowGain = 90
GameMusic:Play()
GameMusic:Pause()

local player = game:GetService("Players").LocalPlayer
local hum = player.Character:FindFirstChildOfClass("Humanoid")
local plrSettings = {}
local cam = workspace.CurrentCamera
local runService = game:GetService("RunService")
local hotbar = require(game.ReplicatedStorage.YFTools.NeoHotbar)

hotbar:Start()
hotbar:SetEnabled(false)
plrSettings = plrData:Get()

game.Lighting.ColorCorrection.Enabled = false
game.Lighting.MenuDepthOfField.Enabled = true
plrSetting:Set("LEVEL_NAME", LEVELS_LIST[plrstates.SPS + 1])

pcall(function()
	game:GetService("StarterGui"):SetCore("ResetButtonCallback", false)
end)

local function SetValue(_,value,settingname)
	if plrstates[settingname] then
		plrstates[settingname] = value
	elseif plrSettings[settingname] then
		plrSettings[settingname] = value
	end
	if settingname == "INGAME" then
		plrstates.INGAME = value
		game.Lighting.MenuDepthOfField.Enabled = not value
		hotbar:SetEnabled(value)
		if value == false then MainMusic:Resume(); GameMusic:Pause() else MainMusic:Pause(); GameMusic:Resume() end
	end
	if settingname == "FOLLOW" then
		hotbar:SetEnabled(plrstates.INGAME and value or false)
		plrstates.FOLLOW = value
		if value == false then GameMusic:Pause() else GameMusic:Resume() end
	end
	if settingname == "SPS" then
		plrstates.SPS = value
		plrSetting:Set("LEVEL_NAME", LEVELS_LIST[value])
	end
end
plrSetting.OnValueChanged:Connect(function(settingname,value)
	SetValue(game.Players.LocalPlayer,value,settingname)
end)
plrData.OnValueChanged:Connect(function(settingname,value)
	SetValue(game.Players.LocalPlayer,value,settingname)
end)


cam.CFrame = plrstates.CAMPART and plrstates.CAMPART.CFrame or game.Workspace.CameraParts.MainCam.CFrame
cam.CameraSubject = plrstates.CAMPART or game.Workspace.CameraParts.MainCam
hum.Jumping:Connect(function(isJumping)
	if isJumping then
		local sound = game.ReplicatedStorage.SFX.JumpSFX
		sound:Play()
	end
end)

runService.PreRender:Connect(function(dt)
		local s, e = pcall(function()
			CameraController.ControlCamera(
						plrstates,
						plrSettings,
						cam,
						player,
						player:GetMouse(),
						cam_speed
					)
		end)
		if not s then
			warn("Error in Camera Control: ", e)
		end
		for _,obj:Sound in game.ReplicatedStorage.MUSIC:GetChildren() do
			if plrSettings.MUSIC then
				if obj.Name == "OutcoreGame" then continue end
			obj.Volume = plrSettings.MUSIC / 200
			end
		end
		for _,obj:Sound in game.ReplicatedStorage.SFX:GetChildren() do
			if plrSettings.SFX then
			obj.Volume = plrSettings.SFX / 100
			end
		end
		
		game.Lighting.Brightness = plrSettings.BRIGHTNESS or 3
		game.Lighting.GlobalShadows = plrSettings.SHADOWS or true
		game.Lighting.ClockTime = plrSettings.CLOCK_TIME or 0
		game.Lighting.ExposureCompensation = plrSettings.EXPOSURE_COMPENSATION or 0
	--print(player.Character:WaitForChild("HumanoidRootPart").AssemblyLinearVelocity.magnitude/100)
	--print(dt)
	--cameraservice:Shake(player.Character:WaitForChild("HumanoidRootPart").AssemblyLinearVelocity.magnitude/100,dt)
end)

