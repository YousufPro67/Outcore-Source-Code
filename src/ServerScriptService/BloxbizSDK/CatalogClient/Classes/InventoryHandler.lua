local Utils = require(script.Parent.Parent.Parent.Utils)
local Fusion = require(script.Parent.Parent.Parent.Utils.Fusion)

local Value = Fusion.Value

local InventoryModule = {}

local AvatarEditorService = game:GetService("AvatarEditorService")

local Classes = script.Parent

local AvatarModule = require(Classes.AvatarHandler)

local playerInventory = Value({})
local inventoryLoaded = Instance.new("BindableEvent")

local realWornAssets = {}
local requestToWearDebounce

local hasAccess = false
local hasRequested = false

local ASSET_TYPES = {
	"TShirt",
	"Hat",
	"HairAccessory",
	"FaceAccessory",
	"NeckAccessory",
	"ShoulderAccessory",
	"FrontAccessory",
	"BackAccessory",
	"WaistAccessory",
	"Shirt",
	"Pants",
	"Head",
	"Face",
	"Torso",
	"RightArm",
	"LeftArm",
	"LeftLeg",
	"RightLeg",
	"EmoteAnimation",
	"TShirtAccessory",
	"ShirtAccessory",
	"PantsAccessory",
	"JacketAccessory",
	"SweaterAccessory",
	"ShortsAccessory",
	"DressSkirtAccessory",
}

InventoryModule.ItemDetailsCache = {}
InventoryModule.Inventory = playerInventory

function InventoryModule.GetBatchItemDetails(assetIds, itemType)
	local missing = {}

	for _, assetId in ipairs(assetIds) do
		if not InventoryModule.ItemDetailsCache[assetId] then
			table.insert(missing, assetId)
		end
	end

	for _, chunkedIds in ipairs(Utils.chunk(missing, 100)) do
		local batchItemData, success = Utils.callWithRetry(function()
			if #missing > 0 then
				return AvatarEditorService:GetBatchItemDetails(chunkedIds, itemType and itemType or 1)
			else
				return {}
			end
		end, 2)

		if success then
			for _, rawData in pairs(batchItemData) do
				InventoryModule.ItemDetailsCache[rawData.Id] = rawData
			end
		end
	end

	local final = {}
	for _, assetId in ipairs(assetIds) do
		final[assetId] = InventoryModule.ItemDetailsCache[assetId]
	end

	return final
end

function InventoryModule.get()
	if not hasAccess then
		return
	end

	if inventoryLoaded ~= true then
		inventoryLoaded.Event:Wait()
	end

	return playerInventory:get()
end

function InventoryModule.ownsAsset(assetId)
	if not hasAccess then
		return
	end

	if inventoryLoaded ~= true then
		inventoryLoaded.Event:Wait()
	end

	return not not playerInventory:get()[assetId]
end

function InventoryModule.ownsAssetComputed(assetId)
	if type(assetId) == "number" then
		assetId = Value(assetId)
	end

	return Fusion.Computed(function()
		return playerInventory:get()[assetId:get()]
	end)
end

function InventoryModule.addAsset(assetId)
	-- if not hasAccess then
	-- 	return
	-- end

	-- if inventoryLoaded ~= true then
	-- 	inventoryLoaded.Event:Wait()
	-- end

	local inv = playerInventory:get()
	inv[assetId] = true
	playerInventory:set(inv)
end

function InventoryModule.requestToWear(item)
	if realWornAssets[item.AssetId] then
		-- return
	end

	if requestToWearDebounce then
		return
	end
	requestToWearDebounce = true

	local model = AvatarModule.GetModel()
	model.Parent = workspace

	local hum = model.Humanoid
	AvatarModule:TryOn(hum, item.AssetId, item.AssetType, true)

	local Desc = hum:GetAppliedDescription()
	model:Destroy()

	AvatarEditorService:PromptSaveAvatar(Desc, hum.RigType)

	local result = AvatarEditorService.PromptSaveAvatarCompleted:Wait()
	if result == Enum.AvatarPromptResult.Success then
		realWornAssets[item.AssetId] = true
	end

	requestToWearDebounce = nil
end

local function fetchPlayerInventory()
	local inventory = {}

	for _, assetName in ASSET_TYPES do
		local pages = AvatarEditorService:GetInventory({ Enum.AvatarAssetType[assetName] })
		local page = pages:GetCurrentPage()

		for _, asset in page do
			local assetId = asset.AssetId

			local item = AvatarModule.BuildItemData(asset)
			inventory[assetId] = item
		end
	end

	playerInventory:set(inventory)

	local _evt = inventoryLoaded
	inventoryLoaded = true
	_evt:Fire()
	_evt:Destroy()
end

function InventoryModule.hasAccess()
	return hasAccess
end

function InventoryModule.requestAccess()
	if hasAccess then
		return true
	end

	if hasRequested then
		return hasAccess
	end
	hasRequested = true

	AvatarEditorService:PromptAllowInventoryReadAccess()

	local result = AvatarEditorService.PromptAllowInventoryReadAccessCompleted:Wait()
	hasAccess = result == Enum.AvatarPromptResult.Success
	if hasAccess then
		task.spawn(fetchPlayerInventory)
	else
		print("[Bloxbiz] Player denied inventory access to catalog")
	end

	hasRequested = nil

	return hasAccess
end

return InventoryModule
