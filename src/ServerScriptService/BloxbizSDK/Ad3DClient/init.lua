local module = {}
module.__index = module

local BLOXBIZ_REMOTES = "BloxbizRemotes"
local AD_ASSETS_FOLDER = "Bloxbiz3DAdAssets"

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterAd = require(script.CharacterAd)
local Update3DAdEvent = ReplicatedStorage:WaitForChild(BLOXBIZ_REMOTES):WaitForChild("Update3DAdEvent")
local characterModelFolder = ReplicatedStorage:WaitForChild(AD_ASSETS_FOLDER)
local Utils = require(script.Parent.Utils)
local ModelScale = require(script.Parent.Utils.ModelScale)

function module:findPartName(partName)
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

function module:updateAd(adData)
	if self.adModels then
		for _, adModel in ipairs(self.adModels) do
			adModel:destroy()
		end

		self.adModelGroup:Destroy()
	end

	local function scaleAdModel(adModel)
		local boxSize = self.adBoxModel.AdBox.Size
		local modelSize = adModel:GetExtentsSize()
		local charSizeX, charSizeY, charSizeZ =
			math.min(boxSize.X, adData.ad_box_width_max),
			math.min(boxSize.Y, adData.ad_box_height_max),
			math.min(boxSize.Z, adData.ad_box_depth_max)
		local scale = math.min(charSizeX / modelSize.X, charSizeY / modelSize.Y, charSizeZ / modelSize.Z)
		ModelScale(adModel, scale)

		return scale
	end

	local adModelGroup = characterModelFolder:FindFirstChild(tostring(adData.bloxbiz_ad_id)):Clone()
	adModelGroup.Name = "AdModel"
	adModelGroup.Parent = self.adBoxModel

	Utils.appendToRaycastFilterList(adModelGroup)

	local AdCenterPart = adModelGroup:FindFirstChild("AdCenterPart")
	local adModelGroupCf, adModelGroupSize = adModelGroup:GetBoundingBox()

	if not AdCenterPart then
		AdCenterPart = Instance.new("Part")
		AdCenterPart.Name = "AdCenterPart"
		AdCenterPart.Anchored = true
		AdCenterPart.CanCollide = false
		AdCenterPart.CanTouch = false
		AdCenterPart.Transparency = 1
		AdCenterPart.Size = Vector3.new(0.05, 0.05, 0.05)
		AdCenterPart.CFrame = adModelGroupCf * CFrame.Angles(0, math.pi, 0)
		AdCenterPart.Parent = adModelGroup
	else
		local adCenterPartRot = AdCenterPart.CFrame - AdCenterPart.Position
		AdCenterPart.CFrame = CFrame.new(adModelGroupCf.Position) * adCenterPartRot
	end

	adModelGroup.PrimaryPart = AdCenterPart

	self.adModelGroup = adModelGroup
	self.adModels = {}

	local adModelGroupScale = scaleAdModel(adModelGroup)
	adModelGroupSize = adModelGroup:GetExtentsSize()
	local adBoxCf = self.adBoxModel.AdBox.CFrame
	local adModelGroupCfToSet = CFrame.new(
		adBoxCf.X,
		adBoxCf.Y - self.adBoxModel.AdBox.Size.Y / 2 + adModelGroupSize.Y / 2,
		adBoxCf.Z
	) * (adBoxCf - adBoxCf.Position)
	adModelGroup:SetPrimaryPartCFrame(adModelGroupCfToSet)

	if adData.bloxbiz_ad_id == -1 and not adData.ad_model_data[1] then
		-- return
	end

	if adData.ad_type == "Character" then
		local MetricsModule = require(script.CharacterAd.MetricsClient)
		MetricsModule.init(self.adBoxModel, false, adData)

		for _, adModelData in ipairs(adData.ad_model_data) do
			local characterModel = adModelGroup:FindFirstChild(adModelData.ad_model_name)
			local adModel =
				CharacterAd.new(self, self.adBoxModel, characterModel, adData, adModelData, adModelGroupScale)

			table.insert(self.adModels, adModel)
		end
	elseif adData.ad_type == "BoxInventorySizing" then
		local MetricsModule = require(script.CharacterAd.MetricsClient)
		MetricsModule.init(self.adBoxModel, false, adData)
	end
end

function module:destroy()
	self.instanceActive = false

	for _, characterModel in pairs(self.adModels) do
		characterModel:destroy()
	end

	if self.adModelGroup then
		self.adModelGroup:Destroy()
	end
end

function module.init(adBoxName, adToLoad)
	local ad3DClientInstance = setmetatable({}, module)
	ad3DClientInstance.adModelBox = nil
	ad3DClientInstance.adModels = nil
	ad3DClientInstance.adModelGroup = nil
	ad3DClientInstance.instanceActive = true
	ad3DClientInstance.adBoxName = adBoxName

	task.spawn(function()
		local adBox

		while ad3DClientInstance.instanceActive and not adBox do
			adBox = ad3DClientInstance:findPartName(adBoxName)
			task.wait(1)
		end

		if adBox then
			ad3DClientInstance.adBoxModel = adBox.Parent
			ad3DClientInstance:updateAd(adToLoad)
		end
	end)

	Update3DAdEvent.OnClientEvent:Connect(function(action, ...)
		if action == "Destruct" then
			local adBoxName = ...

			if adBoxName == ad3DClientInstance.adBoxName then
				ad3DClientInstance:destroy()
			end
		end
	end)

	return ad3DClientInstance
end

return module
