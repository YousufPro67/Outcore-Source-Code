local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local REMOTES_FOLDER = "BloxbizRemotes"

local CreateBillboard = require(script.CreateBillboard)

local LocalPlayer = game.Players.LocalPlayer
local BloxbizSDK = LocalPlayer.PlayerScripts.BloxbizSDK
local ConfigReader = require(BloxbizSDK.ConfigReader)
local remotesFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER)
--local adChatOpportunityEvent = remotesFolder:WaitForChild("AdChatOpportunityEvent")
local dialogueBranchEntryEvent = remotesFolder:WaitForChild("DialogueBranchEntryEvent")
local DebugAPI

if ConfigReader:read("DebugMode") then
	DebugAPI = require(ConfigReader:read("DebugAPI")())
end

local module = {}
module.BillboardClients = {}

function module.initBillboardClient(adBoxModel, adData)
	local BillboardClientModule = BloxbizSDK.BillboardClient
	local billboardClient = module.BillboardClients[adBoxModel]

	if not billboardClient then
		local newBillboardClientModule = BillboardClientModule:Clone()
		newBillboardClientModule.Parent = BloxbizSDK

		billboardClient = require(newBillboardClientModule)
		module.BillboardClients[adBoxModel] = billboardClient
		billboardClient:initAd(adBoxModel.Billboard.AdUnit:GetFullName(), adBoxModel.Billboard.AdUnit, adData)
	else
		billboardClient.currentBloxbizAdId = adData.bloxbiz_ad_id
	end
end

function module.queueBranchEntry(dialogueObject)
	local billboardClient = module.BillboardClients[dialogueObject.adBoxModel]
	local AdRequestStats = require(script.Parent.Parent.Parent.AdRequestStats)

	local clientPlayerStats = AdRequestStats:getClientPlayerStats(LocalPlayer)
	local partStats = AdRequestStats:getPartStats(billboardClient.adPart)

	dialogueBranchEntryEvent:FireServer(dialogueObject.branchEntered, clientPlayerStats, partStats)
end
--[[
function module.QueueChatOpportunity(adBoxModel, adData)
	local billboardClient = module.BillboardClients[adBoxModel]
	local billboardServer = require(script.Parent.Parent.Parent.BillboardServer)
	
	local client_player_stats = AdRequestStats:getClientPlayerStats(LocalPlayer)
	local part_stats = AdRequestStats:getPartStats(billboardClient.adPart)
	local chatOpportunityData = {
		bloxbiz_ad_id = adData.bloxbiz_ad_id
	}

	adChatOpportunityEvent:FireServer(chatOpportunityData, client_player_stats, part_stats)
end
]]
function module.angleBetweenAdAndCam(adCf, cameraCf)
	local adToCam = cameraCf.Position - adCf.Position
	local unitPos = Vector3.new(adToCam.X, 0, adToCam.Z).Unit
	local leveledCameraPos = adCf.Position + (unitPos * 5)

	local frontNormalPos = adCf.Position + Vector3.new(unitPos.X * 5, 0, unitPos.Z * 5)

	local p1Dir = (frontNormalPos - adCf.Position).Unit
	local p2Dir = (leveledCameraPos - adCf.Position).Unit

	--range: 0 - 180
	return math.atan2(p1Dir:Cross(p2Dir).Magnitude, p1Dir:Dot(p2Dir))
end

function module.getBiggestStatusIcon(adBoxModel)
	local biggest = nil

	for _, adModel in pairs(adBoxModel.AdModel:GetChildren()) do
		if adModel:IsA("Model") and adModel.PrimaryPart and adModel.PrimaryPart:FindFirstChild("StatusIcon") then
			local status = adModel.PrimaryPart:FindFirstChild("StatusIcon")

			if status and biggest == nil or (status and status.Size.Y.Scale > biggest.Size.Y.Scale) then
				biggest = status
			end
		end
	end

	return biggest
end

function module.attachBillboardToAd(adBoxModel, adData)
	local billboard = adBoxModel:FindFirstChild("Billboard")

	if not billboard then
		billboard = CreateBillboard()
		billboard.Parent = adBoxModel
		billboard.PrimaryPart = billboard.AdUnit

		if not DebugAPI then
			billboard.PrimaryPart.Transparency = 0.999
			billboard.PrimaryPart.AdSurfaceGui.Enabled = false
		else
			billboard.PrimaryPart.Transparency = 0
			billboard.PrimaryPart.AdSurfaceGui.Enabled = true
		end
	end

	local currentBillboardClient = module.BillboardClients[adBoxModel]
	local bloxbizAdId = adData.bloxbiz_ad_id

	if currentBillboardClient and bloxbizAdId == currentBillboardClient.currentBloxbizAdId then
		return
	end

	module.initBillboardClient(adBoxModel, adData)
	currentBillboardClient = module.BillboardClients[adBoxModel]

	local statusIcon = module.getBiggestStatusIcon(adBoxModel)
	local statusOffset = (statusIcon and statusIcon.Size.Y.Scale) or 0

	local lastMaxSizeCalculation = tick()
	local _, adMaxSize = adBoxModel.AdModel:GetBoundingBox()
	local mathabs = math.abs
	local mathdeg = math.deg
	local renderSteppedConnection

	local camera = Workspace.CurrentCamera

	if not camera then
		return
	end

	renderSteppedConnection = RunService.RenderStepped:Connect(function()
		local characterDeleted = not adBoxModel:FindFirstChild('AdModel')
		local adChanged = currentBillboardClient.currentBloxbizAdId ~= bloxbizAdId
		if characterDeleted or adChanged then
			renderSteppedConnection:Disconnect()
			return
		end

		local cameraPos = camera.CFrame.Position
		local originPos = adBoxModel.AdModel.AdCenterPart.Position
		local radius = 3

		local newPos = originPos + ((cameraPos - originPos).unit * radius)
		newPos = Vector3.new(newPos.X, originPos.Y + statusOffset / 2, newPos.Z)

		local rX, rY, rZ = CFrame.new(newPos, cameraPos):ToOrientation()
		local newCf = CFrame.new(newPos) * CFrame.fromOrientation(0, rY, rZ)

		billboard.PrimaryPart.CFrame = newCf

		local angle = mathdeg(module.angleBetweenAdAndCam(adBoxModel.AdModel.AdCenterPart.CFrame, camera.CFrame))
		local alpha = 1 - (mathabs(angle - 90) / 90)

		if tick() - lastMaxSizeCalculation > 0.33 then
			lastMaxSizeCalculation = tick()
			_, adMaxSize = adBoxModel.AdModel:GetBoundingBox()
		end

		local diff = (adMaxSize.Z - adMaxSize.X) * alpha

		billboard.PrimaryPart.Size = Vector3.new(adMaxSize.X + diff, adMaxSize.Y + statusOffset, 0.5)
	end)
end

--[[
function module.TrackChatOpportunity(adBoxModel, characterModel, adData)
	local proximityPrompt = characterModel.PrimaryPart.ProximityPrompt
	local lastOpportunity = 0
	
	proximityPrompt.PromptShown:Connect(function()
		if Workspace:GetServerTimeNow() - lastOpportunity < 2 then
			return
		end
		
		lastOpportunity = Workspace:GetServerTimeNow()
		--module.QueueChatOpportunity(adBoxModel, adData)
	end)
end
]]
function module.init(adBoxModel, characterModel, adData)
	module.attachBillboardToAd(adBoxModel, adData)

	if characterModel then
		--module.TrackChatOpportunity(adBoxModel, characterModel, adData)
	end
end

return module
