local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer

local PortalClient = {}
PortalClient.__index = PortalClient

local REMOTES_FOLDER = "BloxbizRemotes"

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UpdatePortalEvent = ReplicatedStorage:WaitForChild(REMOTES_FOLDER):WaitForChild("UpdatePortalEvent")
local PortalTeleportRequestEvent = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER):WaitForChild("PortalTeleportRequestEvent")

function PortalClient:findPartName(partName)
	local ancestors = partName:split(".")
	table.remove(ancestors, 1)

	local current = workspace

	for _, name in ipairs(ancestors) do
		current = current:FindFirstChild(name)

		if not current then
			break
		end
	end

	return current
end

function PortalClient:defineOuterPortalModel()
    local adBox

    while self.instanceActive and not adBox do
        adBox = self:findPartName(self.adBoxName)
        task.wait(1)
    end

    if adBox then
        self.outerPortalModel = adBox.Parent
    end
end

function PortalClient:connectPortalTouchedEvent()
    local destinationId = self.adData.destination_place_id

    self.portalModel.TeleportPart.Touched:Connect(function(part)
		local isHumanoid = part.Parent:FindFirstChild('HumanoidRootPart')
		local characterAlive = LocalPlayer.Character and LocalPlayer.Character.Parent ~= nil

		if not isHumanoid or not characterAlive or self.teleportStarted then
			return
		end

		self.teleportStarted = true
	    PortalTeleportRequestEvent:FireServer(destinationId, self.adData.bloxbiz_ad_id)

		task.delay(5, function()
			self.teleportStarted = false
		end)
    end)
end

function PortalClient:activateBillboard()
	local adUnit = self.portalModel.Billboard

	local adData = {}
	adData.bloxbiz_ad_id = self.adData.bloxbiz_ad_id

	local BillboardClientInstance = script.Parent.BillboardClient:Clone()
	BillboardClientInstance.Parent = script.Parent

	local billbaordClient = require(BillboardClientInstance)
	billbaordClient:initAd(adUnit:GetFullName(), adUnit, adData)
end

local function invisiblePart()
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.CanQuery = false
    part.Size = Vector3.new(1, 1, 1)
    part.CanTouch = false

    return part
end

function PortalClient:buildPortal()
	local outerPortalModelCf = self.outerPortalModel:GetBoundingBox()

	local newPortalModel = require(script.CreatePortal)()
	newPortalModel.Name = "Portal"
	newPortalModel.Parent = self.outerPortalModel

    local portalModelBoundingBoxCf = newPortalModel:GetBoundingBox()

    local primaryPart = invisiblePart()
    primaryPart.CFrame = portalModelBoundingBoxCf
    primaryPart.Parent = newPortalModel

    newPortalModel.PrimaryPart = primaryPart
	newPortalModel:SetPrimaryPartCFrame(outerPortalModelCf)

    local gui = newPortalModel.Billboard.AdSurfaceGui

    gui.HardcodedOverlay.Image = self.adData.ad_url[1]
    gui.ImageLabel.Image = self.adData.ad_url[1]

	if self.adData.show_ad_disclaimer then
   		local disclaimerSize = UDim2.new(self.adData.ad_disclaimer_scale_x, 0, self.adData.ad_disclaimer_scale_y, 0)
    	gui.DisclaimerHolder.AdDisclaimerLabel.Image = self.adData.ad_disclaimer_url
    	gui.DisclaimerHolder.AdDisclaimerLabel.Size = disclaimerSize
	end

    self.portalModel = newPortalModel
    self:activateBillboard()
    self:connectPortalTouchedEvent()
end

function PortalClient:updateAd()
	--Utils.appendToRaycastFilterList(self.outerPortalModel.AdBox)

    local invalidBillboardImage = self.adData and self.adData.ad_url and self.adData.ad_url[1] == ""
    local emptyAdSent = self.adData.bloxbiz_ad_id == -1 and invalidBillboardImage
	if emptyAdSent then
		return
	end

	if self.portalModel then
		self.portalModel:Destroy()
	end

    self:buildPortal()
end

function PortalClient:destructActionRequested(adBoxName)
    if adBoxName == self.adBoxName then
        self.instanceActive = false

		if self.portalModel then
			self.portalModel:Destroy()
		end
    end
end

function PortalClient:connectToUpdatePortalEvent()
	UpdatePortalEvent.OnClientEvent:Connect(function(action, ...)
		if action == "Destruct" then
            self:destructActionRequested(...)
		end
	end)
end

function PortalClient.init(adBoxName, adToLoad)
	local adPortalClientInstance = setmetatable({}, PortalClient)
	adPortalClientInstance.instanceActive = true

	adPortalClientInstance.outerPortalModel = nil
	adPortalClientInstance.portalModel = nil
	adPortalClientInstance.adBoxName = adBoxName
    adPortalClientInstance.adData = nil

    adPortalClientInstance.teleportStarted = false

	task.spawn(function()
        adPortalClientInstance:defineOuterPortalModel()

        local portalLoadSuccess = adPortalClientInstance.outerPortalModel ~= nil
        if portalLoadSuccess then
            adPortalClientInstance.adData = adToLoad
            adPortalClientInstance:updateAd()
        end
	end)

    adPortalClientInstance:connectToUpdatePortalEvent()

	return adPortalClientInstance
end

return PortalClient
