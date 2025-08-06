local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local RemotesFolder = ReplicatedStorage:WaitForChild("BloxbizRemotes")

local OnApplyOutfit = RemotesFolder:WaitForChild("CatalogOnApplyOutfit") :: RemoteEvent
local OnLoadEmoteRequest = RemotesFolder:WaitForChild("CatalogOnLoadEmoteRequest") :: RemoteFunction
local OnApplyToRealHumanoid = RemotesFolder:WaitForChild("CatalogOnApplyToRealHumanoid") :: RemoteEvent

local BloxbizSDK = script.Parent.Parent.Parent
local CatalogClient = BloxbizSDK:WaitForChild("CatalogClient")
local UtilFolder = BloxbizSDK:WaitForChild("Utils")

local BodyScaleValues = require(CatalogClient.Libraries:WaitForChild("BodyScaleValues"))

local ConfigReader = require(BloxbizSDK:WaitForChild("ConfigReader"))
local Utils = require(UtilFolder)
local Fusion = require(UtilFolder:WaitForChild("Fusion"))
local FunctionQueue = require(UtilFolder:WaitForChild("FunctionQueue"))

local Player = Players.LocalPlayer
local PlayerHum: Humanoid, RealHumDesc: HumanoidDescription
local CharLoaded = Instance.new("BindableEvent") :: BindableEvent

local PERSISTENT_WEAR = ConfigReader:read("CatalogPersistentWear")

local DEFAULT_CLOTHES = {
	Pants = 855781078,
	Shirt = 855766176,
}

local TOP_ASSET_TYPES = {
	Enum.AssetType.Shirt,
	Enum.AssetType.ShirtAccessory,
	Enum.AssetType.JacketAccessory,
	Enum.AssetType.TShirtAccessory,
	Enum.AssetType.SweaterAccessory
}
local TOP_ASSET_TYPE_IDs = Utils.map(TOP_ASSET_TYPES, function (enum) return enum.Value end)

local BOTTOM_ASSET_TYPES = {
	Enum.AssetType.Pants,
	Enum.AssetType.PantsAccessory,
	Enum.AssetType.ShortsAccessory,
	Enum.AssetType.DressSkirtAccessory
}
local BOTTOM_ASSET_TYPE_IDs = Utils.map(BOTTOM_ASSET_TYPES, function (enum) return enum.Value end)

local TOP_ACC_TYPES = {
	Enum.AccessoryType.Shirt,
	Enum.AccessoryType.Jacket,
	Enum.AccessoryType.TShirt,
	Enum.AccessoryType.Sweater
}
local BOTTOM_ACC_TYPES = {
	Enum.AccessoryType.Pants,
	Enum.AccessoryType.Shorts,
	Enum.AccessoryType.DressSkirt
}


local HUMANOID_DESC_PROPERTIES = {
	[2] = "GraphicTShirt",
	[11] = "Shirt",
	[12] = "Pants",
	[17] = "Head",
	[18] = "Face",
	[27] = "Torso",
	[28] = "RightArm",
	[29] = "LeftArm",
	[30] = "LeftLeg",
	[31] = "RightLeg",
	[79] = "Head"
}

local ANIMATION_PROPERTIES = {
	[48] = "ClimbAnimation",
	[50] = "FallAnimation",
	[51] = "IdleAnimation",
	[52] = "JumpAnimation",
	--[48] = "MoodAnimation",
	[53] = "RunAnimation",
	[54] = "SwimAnimation",
	[55] = "WalkAnimation",
}

local BODY_COLOR_PROPERTIES = {
	"HeadColor",
	"LeftArmColor",
	"LeftLegColor",
	"RightArmColor",
	"RightLegColor",
	"TorsoColor",
}

local ACCESSORY_TYPE_INDEXES = {
	[1] = Enum.AccessoryType.Unknown,
	[8] = Enum.AccessoryType.Hat,
	[19] = Enum.AccessoryType.Eyebrow,
	[20] = Enum.AccessoryType.Eyelash,
	[41] = Enum.AccessoryType.Hair,
	[42] = Enum.AccessoryType.Face,
	[43] = Enum.AccessoryType.Neck,
	[44] = Enum.AccessoryType.Shoulder,
	[45] = Enum.AccessoryType.Front,
	[46] = Enum.AccessoryType.Back,
	[47] = Enum.AccessoryType.Waist,
	[64] = Enum.AccessoryType.TShirt,
	[65] = Enum.AccessoryType.Shirt,
	[66] = Enum.AccessoryType.Pants,
	[67] = Enum.AccessoryType.Jacket,
	[68] = Enum.AccessoryType.Sweater,
	[69] = Enum.AccessoryType.Shorts,
	[70] = Enum.AccessoryType.LeftShoe,
	[71] = Enum.AccessoryType.RightShoe,
	[72] = Enum.AccessoryType.DressSkirt,
}

--@desc: Ref link: https://create.roblox.com/docs/reference/engine/classes/HumanoidDescription#GetAccessories
type AccessoryData = {
	AccessoryType: string,
	AssetId: number,
	IsLayered: boolean,
	Order: number?,
	Puffiness: number?,
}

export type BundleData = {
	BundleId: number,
	BundleType: number,
	Name: string,
	Price: number,
}

export type ItemData = {
	Name: string,
	Price: number,
	AssetId: number,
	BundleId: number?,
	AssetType: number,
	IsForSale: boolean,
	IsLimited: number,

	Available: number,
	Purchased: number,

	--For testing purposes
	DataSource: string?,
}

export type BodyColors = {
	[string]: Color3 | string,
}

export type AvatarModule = {
	IsValidAssetType: (assetTypeId: number) -> boolean,
	UpdateViewportRender: (viewport: ViewportFrame, isOutFit: boolean?, cameraOffset: Vector3?) -> (),
	RenderInViewport: (model: Model, viewport: ViewportFrame, isOutfit: boolean?, cameraOffset: Vector3?) -> (),

	GetItemDataTable: (itemId: string | number, retries: number?, refresh: boolean?) -> ItemData?,
	GetCurrentOutfit: (
		currentOutfit: { [string | number]: ItemData },
		hum: Humanoid?,
		desc: HumanoidDescription?
	) -> ({ ItemData? }, { number | string }, HumanoidDescription),
	GetHumDescFromBundle: (
		desc: HumanoidDescription,
		bundle: BundleData,
		fetchAnimationsInfo: boolean
	) -> (HumanoidDescription, { ItemData? }?),
	GetAssetTypeIdFromString: (assetTypeString: string, getEnum: boolean?) -> number,
	GetRealHumDesc: () -> HumanoidDescription?,
	GetModel: (desc: HumanoidDescription?) -> Model,
	GetCurrentBodyColors: (desc: HumanoidDescription) -> { [string]: Color3 },
	GetCurrentBodyScales: (desc: HumanoidDescription) -> { [string]: { Percent: number, DragBarSize: number } },

	SetBodyScale: (desc: HumanoidDescription, scaleName: string, value: number) -> number,
	SetBodyColor: (desc: HumanoidDescription, color: Color3) -> (),
	SetBodyColors: (desc: HumanoidDescription, colors: { [string]: Color3 }, dontPersistWear: boolean) -> (),

	TryAccessory: (
		desc: HumanoidDescription,
		assetId: number | string,
		accessory: Enum.AccessoryType,
		dontPersistWear: boolean
	) -> (),
	TryItem: (
		desc: HumanoidDescription,
		assetId: number | string,
		property: string,
		dontPersistWear: boolean
	) -> string,
	TryEmote: (avatarHumanoid: Humanoid, assetId: string) -> (),

	TryOutfit: (
		self: AvatarModule,
		avatarHum: Humanoid,
		outfit: { [string | number]: BodyColors | ItemData },
		dontPersistWear: boolean,
		outfitDesc: any
	) -> (),
	TryOn: (
		self: AvatarModule,
		avatarHum: Humanoid,
		assetId: string | number,
		assetType: string | number,
		dontPersistWear: boolean
	) -> string,
	Remove: (self: AvatarModule, avatarHum: Humanoid, assetId: string | number, assetType: string | number) -> (),

	RemoveItem: (desc: HumanoidDescription, property: string) -> (),
	RemoveAccessory: (desc: HumanoidDescription, assetId: string | number) -> (),
	RemoveEmote: () -> (),

	ReplicateBundle: (outfit: { [string]: any }) -> (),
	BuildItemData: (item: { [string]: any }, getEnum: boolean?) -> ItemData?,
	BuildBundleData: (item: { [string]: any }) -> BundleData?,
}

local ItemDataCache = {}

local function GetItemProperty(assetTypeId: number): string
	return HUMANOID_DESC_PROPERTIES[assetTypeId]
end

local function GetAccessoryType(assetTypeId: number): Enum.AccessoryType
	return ACCESSORY_TYPE_INDEXES[assetTypeId]
end

local function IsValidEmote(assetType: number): boolean | string
	return ANIMATION_PROPERTIES[assetType] or assetType == 61
end

local function GetCamera(viewport: ViewportFrame): Camera
	local camera = viewport.CurrentCamera :: Camera
	if not camera then
		camera = Instance.new("Camera")
		viewport.CurrentCamera = camera
	end

	return camera
end

local function ReplicateAssets(data)
	if not PERSISTENT_WEAR then
		return
	end

	OnApplyToRealHumanoid:FireServer(data)
end

local CurrentlyPlayedTrack: AnimationTrack?
local Queue = FunctionQueue.new(60, 100)

local AvatarModule: AvatarModule = {} :: AvatarModule

AvatarModule.AccessoryTypes = ACCESSORY_TYPE_INDEXES

local function getViewportComponents(viewport: ViewportFrame)
	if not viewport then
		return nil, nil, nil
	end

	local worldModel = viewport:FindFirstChild("WorldModel") :: WorldModel
	local model = worldModel:FindFirstChild("PlayerModel") :: Model
	local pivot = worldModel:FindFirstChild("Pivot")

	return worldModel, model, pivot
end

function AvatarModule.UpdateViewportRender(viewport: ViewportFrame, isOutFit: boolean?, zoom: number?)
	local worldModel, model, pivot = getViewportComponents(viewport)

	if not (worldModel and model) then
		return
	end

	local cf = (pivot and pivot:GetPivot() or model:GetPivot()) - Vector3.new(0, 1/3, 0)
	local size = model:GetExtentsSize()
	local viewportCamera = GetCamera(viewport)

	local biggestSize = math.max(size.X, size.Y)
	local cameraDistance = (biggestSize / 2) / math.tan(math.rad(viewportCamera.FieldOfView) / 2) * (isOutFit and 1 or 1.05)
	cameraDistance = math.clamp(cameraDistance, 7, 11) / (zoom or 1)

	if isOutFit then
		viewportCamera.CFrame = (cf + (cf.LookVector * cameraDistance)) * CFrame.Angles(0, math.pi, 0)
			+ (cameraOffset or Vector3.new())
	else
		TweenService:Create(viewportCamera, TweenInfo.new(0.2), {
			CFrame = (cf + (cf.LookVector * cameraDistance)) * CFrame.Angles(0, math.pi, 0)
				+ (cameraOffset or Vector3.new()),
		}):Play()
	end
end

function AvatarModule.GetIdleAnimationId(model)
	local animateScript = model:FindFirstChild("Animate")
	if animateScript then
		-- animateScript.Disabled = true

		local idle = animateScript:FindFirstChild("idle")
		local anim1 = idle and idle:FindFirstChild("Animation1") or nil
		if anim1 then
			return anim1.AnimationId
		end
	end
end

function AvatarModule.GetAnimationTrack(model, anim)
	local humanoid = model:FindFirstChild("Humanoid")
	local animator = humanoid:FindFirstChild("Animator")

	if animator then
		-- Due to a Roblox engine bug, the animator can't load animations under viewport WorldModels and has to be done in workspace.
		-- The character is immediately removed from workspace after the animation loads

		if type(anim) == "number" then
			local animId = anim
			anim = Instance.new("Animation")
			anim.AnimationId = string.format("rbxassetid://%s", animId)
		end

		local prevParent = model.Parent

		model.Parent = workspace
		local success, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)

		if success then
			model.Parent = prevParent
			track.Looped = true
			track.Priority = Enum.AnimationPriority.Action4

			return track
		end
	end
end

function AvatarModule.RenderInViewport(
	model: Model,
	viewport: ViewportFrame,
	isOutfit: boolean?,
	animate: boolean?,
	isVisibleValue
)
	if animate == nil then
		animate = not isOutfit
	end

	local worldModel = viewport:FindFirstChild("WorldModel") :: WorldModel
	if not worldModel then
		return
	end

	if worldModel:FindFirstChild("PlayerModel") then
		worldModel.PlayerModel:Destroy()
	end

	local animateScript = model:FindFirstChild("Animate")
	local animateSignal
	if animateScript then
		animateScript.Disabled = true

		if animate then
			local idle = animateScript:FindFirstChild("idle")
			local anim1 = idle and idle:FindFirstChild("Animation1") or nil
			if anim1 then
				local humanoid = model:FindFirstChild("Humanoid")
				local animator = humanoid:FindFirstChild("Animator")

				if animator then
					-- Due to a Roblox engine bug, the animator can't load animations under viewport WorldModels and has to be done in workspace.
					-- The character is immediately removed from workspace after the animation loads

					local track
					
					-- if the animation is playing while it isn't visible on the screen, a Roblox bug causes updateInvalidatedFastClusters
					-- to be triggered every frame, causing significant lag for some users
					if isVisibleValue then
						animateSignal = Fusion.Observer(isVisibleValue):onChange(function()
							local isVisible = isVisibleValue:get()

							if isVisible then
								if not track then
									model.Parent = workspace
									track = animator:LoadAnimation(anim1)
									model.Parent = worldModel
									track.Looped = true
								end

								track:Play()
							else
								track:Stop()
							end
						end)
					end
				end
			end
		end
	end

	model.Parent = worldModel

	model.Destroying:Connect(function()
		if animateSignal then
			animateSignal:Disconnect()
		end
	end)

	-- create pivot

	if worldModel:FindFirstChild("Pivot") then
		worldModel:FindFirstChild("Pivot"):Destroy()
	end

	local pivot = model.PrimaryPart:Clone()
	pivot.Parent = worldModel
	pivot.Name = "Pivot"
	pivot.Anchored = true
	pivot.Transparency = 1
	pivot:ClearAllChildren()

	local viewportCamera = GetCamera(viewport)
	viewportCamera.Parent = viewport

	AvatarModule.UpdateViewportRender(viewport, isOutfit)
end

function AvatarModule.GetItemDataTable(
	itemId: string | number,
	retries: number?,
	refresh: boolean?
): (ItemData & BundleData)?
	if not refresh and ItemDataCache[itemId] then
		return ItemDataCache[itemId]
	end

	local itemInfo = Utils.callWithRetry(function()
		return MarketplaceService:GetProductInfo(tonumber(itemId) :: number)
	end, retries or 3)

	if not itemInfo then
		return
	end

	local limitedType = 0
	if itemInfo.IsLimitedUnique then
		limitedType = 1
	elseif itemInfo.IsLimited then
		limitedType = 2
	end

	local itemData = {
		Name = itemInfo.Name,
		Price = itemInfo.PriceInRobux,
		AssetId = tonumber(itemId) :: number,
		BundleId = itemInfo.BundleId,
		AssetType = itemInfo.AssetTypeId,
		IsForSale = itemInfo.IsForSale,
		IsLimited = limitedType,

		Available = itemInfo.Remaining,
		Purchased = itemInfo.Sales,
	}

	ItemDataCache[itemId] = itemData

	return itemData :: ItemData & BundleData
end

function AvatarModule.BuildItemData(item: { [string]: any }, getEnum: boolean?): ItemData?
	if not item.AssetType then
		return
	end

	local limitedType = 0
	if item.ItemRestrictions then
		if table.find(item.ItemRestrictions, "LimitedUnique") or table.find(item.ItemRestrictions, "Collectible") then
			limitedType = 1
		elseif table.find(item.ItemRestrictions, "Limited") then
			limitedType = 2
		end
	end

	local assetType = item.AssetType
	if type(assetType) == "string" then
		assetType = AvatarModule.GetAssetTypeIdFromString(assetType, getEnum)
	-- elseif typeof(item.AssetType) == "EnumItem" then
	-- 	assetType = item.AssetType.Value
	end

	return {
		Name = item.Name,
		Price = item.LowestPrice or item.Price,
		AssetId = item.Id or item.AssetId,
		AssetType = assetType,
		IsForSale = item.PriceStatus ~= "Off sale",
		IsLimited = limitedType,

		Available = item.UnitsAvailableForConsumption,
		Purchased = item.PurchaseCount,
	}
end

function AvatarModule.BuildBundleData(item: { [string]: any }): BundleData?
	if not item.BundleType then
		return
	end

	return {
		Name = item.Name,
		Price = item.LowestPrice or item.Price,
		BundleId = item.Id,
		BundleType = item.BundleType,
	}
end

function AvatarModule.GetCurrentOutfit(
	currentOutfit: { [string | number]: ItemData },
	hum: Humanoid?,
	desc: HumanoidDescription?
): ({ ItemData? }, { number | string }, HumanoidDescription)
	if not desc then
		hum = hum or PlayerHum

		if not hum then
			CharLoaded.Event:Wait()
			hum = PlayerHum
		end
	end

	local humanoidDesc = (hum and hum:GetAppliedDescription() or desc) :: HumanoidDescription
	local accessories = humanoidDesc:GetAccessories(true) :: { AccessoryData }

	local wearing: { ItemData? } = {}
	local notWearing: { number | string } = {}

	local wearingIds = {}

	local accessoryLoaded, animationLoaded, humDescLoaded = false, false, false

	task.spawn(function()
		for _, accessory: AccessoryData in pairs(accessories) do
			local itemId = accessory.AssetId
			if itemId == 0 then
				continue
			end

			table.insert(wearingIds, itemId)

			if currentOutfit[itemId] then
				continue
			end

			table.insert(wearing, AvatarModule.GetItemDataTable(itemId))
		end

		accessoryLoaded = true
	end)

	task.spawn(function()
		for _, itemType in pairs(HUMANOID_DESC_PROPERTIES) do
			local itemId = humanoidDesc[itemType]
			if itemId == 0 then
				continue
			end

			table.insert(wearingIds, itemId)

			if currentOutfit[itemId] then
				continue
			end

			table.insert(wearing, AvatarModule.GetItemDataTable(itemId))
		end

		humDescLoaded = true
	end)

	task.spawn(function()
		for _, animationType in pairs(ANIMATION_PROPERTIES) do
			local itemId = humanoidDesc[animationType]
			if itemId == 0 then
				continue
			end

			table.insert(wearingIds, itemId)

			if currentOutfit[itemId] then
				continue
			end

			table.insert(wearing, AvatarModule.GetItemDataTable(itemId))
		end

		animationLoaded = true
	end)

	repeat
		task.wait()
	until accessoryLoaded and animationLoaded and humDescLoaded

	for itemId, _ in pairs(currentOutfit) do
		local found
		for _, _itemId in wearingIds do
			if _itemId == itemId then
				found = true
				break
			end
		end

		if not found then
			table.insert(notWearing, itemId)
		end
	end

	return wearing, notWearing, humanoidDesc
end

function AvatarModule.GetHumDescFromBundle(
	desc: HumanoidDescription,
	bundle: BundleData,
	fetchAnimationsInfo: boolean
): (HumanoidDescription, { ItemData? }?)
	local details = AssetService:GetBundleDetailsAsync(bundle.BundleId)

	if bundle.BundleType == 2 then
		local animationsInfo = {}

		for _, info in details.Items do
			if info.Type == "UserOutfit" then
				continue
			end

			local assetType = (info.Name:match("%s(.+)") .. "Animation"):gsub(" ", "")
			desc[assetType] = info.Id

			if fetchAnimationsInfo then
				Queue:Add(function()
					table.insert(animationsInfo, AvatarModule.GetItemDataTable(info.Id))
				end):Wait()
			end
		end

		return desc, animationsInfo
	else
		local hasDynamicHead = false
		local id
		for _, info in details.Items do
			if not id then
				id = info.Id
			end

			if string.find(info.Name, "Dynamic Head") then
				hasDynamicHead = true
			end

			if info.Type == "UserOutfit" then
				id = info.Id
				break
			end
		end

		local humDesc = Players:GetHumanoidDescriptionFromOutfitId(id)

		if hasDynamicHead then
			-- humDesc.Head = 0
		end

		if details.BundleType == "Shoes" then
			local itemsIds = {}
			for _, info in details.Items do
				table.insert(itemsIds, info.Id)
			end

			local items = {}
			for _, itemId in pairs(itemsIds) do
				table.insert(items, AvatarModule.GetItemDataTable(itemId))
			end

			return humDesc, items, hasDynamicHead
		else
			return humDesc, nil, hasDynamicHead
		end
	end
end

function AvatarModule.IsValidAssetType(assetTypeId: number): boolean
	if HUMANOID_DESC_PROPERTIES[assetTypeId] then
		return true
	end

	if ACCESSORY_TYPE_INDEXES[assetTypeId] then
		return true
	end

	return false
end

function AvatarModule.GetAssetTypeIdFromString(assetTypeString: string, getEnum: boolean?): number | any
	if assetTypeString == "TShirt" then
		return getEnum and Enum.AccessoryType.TShirt or 2
	elseif assetTypeString == "Hat" then
		return getEnum and Enum.AccessoryType.Hat or 8
	elseif assetTypeString == "EmoteAnimation" then
		return 61
	elseif assetTypeString == "DynamicHead" then
		return 79
	end

	if assetTypeString:find("Accessory") then
		for assetTypeId, assetTypeEnum in ACCESSORY_TYPE_INDEXES do
			if assetTypeEnum.Name .. "Accessory" == assetTypeString then
				return getEnum and assetTypeEnum or assetTypeId
			end
		end
	else
		for assetTypeId, humDescProperty in HUMANOID_DESC_PROPERTIES do
			if humDescProperty == assetTypeString then
				return getEnum and humDescProperty or assetTypeId
			end
		end
	end

	Utils.pprint("[Superbiz] Could not find AssetTypeId for AssetTypeString", assetTypeString)

	return 1
end

function AvatarModule.GetRealHumDesc(): HumanoidDescription?
	RealHumDesc = Utils.callWithRetry(function()
		return Players:GetHumanoidDescriptionFromUserId(math.max(Player.UserId, 1)) :: HumanoidDescription
	end, 5)

	return RealHumDesc
end

function AvatarModule.OutfitToHumDesc(outfit, baseHumDesc): HumanoidDescription
	local humDesc = baseHumDesc and baseHumDesc:Clone() or Instance.new("HumanoidDescription")	humDesc.Shirt = nil
	humDesc.Pants = nil
	humDesc.Head = nil
	humDesc.LeftArm = nil
	humDesc.RightArm = nil
	humDesc.LeftLeg = nil
	humDesc.RightLeg = nil
	humDesc.Torso = nil

	for k, v in pairs(outfit.BodyColors) do
		humDesc[k] = v
	end

	local baseAccessories = baseHumDesc and baseHumDesc:GetAccessories(true) or {}
	local accessories = {}

	for k, assetInfo in pairs(outfit) do
		if k == "BodyColors" then
			continue
		end

		local assetId, assetType = assetInfo.AssetId, assetInfo.AssetType
		local emote = IsValidEmote(tonumber(assetType))
		local property = GetItemProperty(tonumber(assetType))
		local accessory = GetAccessoryType(tonumber(assetType))

		if property then
			humDesc[property] = assetId
		elseif accessory then
		
			local accessoryData = Utils.search(baseAccessories, function (acc) return acc.AssetId == assetId end)

			if not accessoryData then
				accessoryData = {
					AccessoryType = accessory,
					AssetId = assetId,
				}
			end

			table.insert(accessories, accessoryData)
		elseif emote then
			-- pass
		else
			Utils.pprint("[SuperBiz] Asset is not an accessory, emote or a valid HumDesc property")
			Utils.pprint(assetType)
		end
	end

	humDesc:SetAccessories(accessories, true)

	return humDesc
end

function AvatarModule.GetModel(desc: HumanoidDescription?): Model
	desc = desc or AvatarModule.GetRealHumDesc() :: HumanoidDescription

	local baseHumModel = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	local humanoid = baseHumModel:FindFirstChild("Humanoid") :: Humanoid
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	baseHumModel.Name = "PlayerModel"

	return baseHumModel
end

function AvatarModule.GetCurrentBodyScales(
	desc: HumanoidDescription
): { [string]: { Percent: number, DragBarSize: number } }
	local scales = {}

	type ScaleLimit = {
		Min: number,
		Max: number,
	}

	for property, scaleLimit: ScaleLimit in pairs(BodyScaleValues) do
		local scale = desc[property]
		local dragBarSize = (scale - scaleLimit.Min) / (scaleLimit.Max - scaleLimit.Min)

		scales[property] = {
			Percent = math.ceil(scale * 100),
			DragBarSize = dragBarSize,
		}
	end

	return scales
end

function AvatarModule.SetBodyScale(humanoidDescription: HumanoidDescription, scaleName: string, value: number): number
	local property = scaleName .. "Scale"
	humanoidDescription[property] = value

	return value
end

function AvatarModule.GetCurrentBodyColors(humanoidDescription: HumanoidDescription): { [string]: Color3 }
	local colors = {}
	for _, property in BODY_COLOR_PROPERTIES do
		colors[property] = humanoidDescription[property]
	end

	return colors
end

function AvatarModule.SetBodyColor(humanoidDescription: HumanoidDescription, color: Color3)
	for _, property in BODY_COLOR_PROPERTIES do
		humanoidDescription[property] = color
	end

	ReplicateAssets({ BodyColor = color })
end

function AvatarModule.SetBodyColors(
	humanoidDescription: HumanoidDescription,
	colors: { [string]: Color3 },
	dontPersistWear: boolean
)
	if not colors then
		return
	end

	for property, color in colors do
		humanoidDescription[property] = color
	end

	if not dontPersistWear then
		ReplicateAssets({ BodyColor = colors })
	end
end

function AvatarModule.TryItem(
	humanoidDescription: HumanoidDescription,
	assetId: number | string,
	property: string,
	dontPersistWear: boolean
): string
	assetId = tonumber(assetId) :: number

	local oldId = humanoidDescription[property]
	humanoidDescription[property] = assetId

	if not dontPersistWear then
		ReplicateAssets({ Property = property, AssetId = assetId })
	end

	return oldId
end

function AvatarModule.RemoveItem(humanoidDescription: HumanoidDescription, property: string)
	local shouldReload = false
	humanoidDescription[property] = 0

	local accessories = humanoidDescription:GetAccessories(true)

	if property == "Pants" then
		local hasPants = Utils.search(accessories, function (acc)
			return table.find(BOTTOM_ACC_TYPES, acc.AccessoryType)
		end)

		if not hasPants then
			shouldReload = true
			humanoidDescription.Pants = DEFAULT_CLOTHES.Pants
			ReplicateAssets({ Property = "Pants", AssetId = DEFAULT_CLOTHES.Pants })
		end
	elseif property == "Shirt" then
		local hasShirt = (humanoidDescription.Shirt > 0) or Utils.search(accessories, function (acc)
			return table.find(TOP_ACC_TYPES, acc.AccessoryType)
		end)

		if not hasShirt then
			shouldReload = true
			humanoidDescription.Shirt = DEFAULT_CLOTHES.Shirt
			ReplicateAssets({ Property = "Shirt", AssetId = DEFAULT_CLOTHES.Shirt })
		end
	end

	ReplicateAssets({ Property = property, AssetId = humanoidDescription[property] })
	return shouldReload
end

function AvatarModule.TryAccessory(
	desc: HumanoidDescription,
	assetId: number | string,
	accessory: Enum.AccessoryType,
	dontPersistWear: boolean,
	order: number?
)
	if order == nil then
		order = 1
	end

	assetId = tonumber(assetId) :: number
	local accessories = desc:GetAccessories(true)

	local AccessoryData = {
		AccessoryType = accessory,
		AssetId = assetId,
		Order = order,
	}
	table.insert(accessories, AccessoryData)

	desc:SetAccessories(accessories, true)

	if not dontPersistWear then
		ReplicateAssets({ AccessoryData = AccessoryData })
	end
end

function AvatarModule.RemoveAccessory(desc: HumanoidDescription, assetId: string | number)
	local shouldReload = false
	local accessories = desc:GetAccessories(true)

	for i, accessory in pairs(accessories) do
		if accessory.AssetId == assetId then
			table.remove(accessories, i)

			if table.find(BOTTOM_ACC_TYPES, accessory.AccessoryType) and desc.Pants == 0 then
				desc.Pants = DEFAULT_CLOTHES.Pants
				-- ReplicateAssets({ Property = "Pants", AssetId = DEFAULT_CLOTHES.Pants })
				shouldReload = true
			end

			if table.find(TOP_ACC_TYPES, accessory.AccessoryType) and desc.Shirt == 0 then
				desc.Shirt = DEFAULT_CLOTHES.Shirt
				shouldReload = true
			end

			break
		end
	end

	desc:SetAccessories(accessories, true)
	ReplicateAssets({ AssetId = assetId })
	if shouldReload then
		ReplicateAssets({ Property = "Pants", AssetId = DEFAULT_CLOTHES.Pants })
		ReplicateAssets({ Property = "Shirt", AssetId = DEFAULT_CLOTHES.Shirt })
	end
	return shouldReload
end

function AvatarModule.TryEmote(avatarHumanoid: Humanoid, assetId: string)
	if CurrentlyPlayedTrack then
		CurrentlyPlayedTrack:Stop()
		CurrentlyPlayedTrack = nil
	end

	local emote: Animation
	local folder = ReplicatedStorage:FindFirstChild("BloxbizCatalogEmotes")
	if folder then
		emote = folder:FindFirstChild(assetId)
	end

	if not emote then
		emote = OnLoadEmoteRequest:InvokeServer(assetId)
		if not emote then
			return
		end
	end

	local track: AnimationTrack

	local animator = avatarHumanoid:FindFirstChild("Animator") :: Animator
	if animator then
		track = animator:LoadAnimation(emote)
	end

	if track then
		track.Looped = false
		track:Play()
		CurrentlyPlayedTrack = track
	end
end

function AvatarModule.RemoveEmote()
	if CurrentlyPlayedTrack then
		CurrentlyPlayedTrack:Stop()
		CurrentlyPlayedTrack = nil
	end
end

function AvatarModule.ReplicateBundle(outfit: { [string]: any })
	if not PERSISTENT_WEAR then
		return
	end

	OnApplyOutfit:FireServer(outfit)
end

function AvatarModule:TryOutfit(
	avatarHum: Humanoid,
	outfit: { [string | number]: BodyColors | ItemData },
	dontPersistWear: boolean,
	outfitDesc: any
)
	local desc: HumanoidDescription = avatarHum:GetAppliedDescription()
	desc:SetAccessories({}, true)

	self.SetBodyColors(desc, outfit.BodyColors, dontPersistWear)
	avatarHum:ApplyDescription(desc)

	local noPants = true
	local noShirt = true

	for id, data in outfit do
		if id == "BodyColors" then
			continue
		end

		local assetId = data.AssetId
		local assetType = data.AssetType

		self:TryOn(avatarHum, assetId, assetType, dontPersistWear, data.Order)
		
		if table.find(BOTTOM_ASSET_TYPE_IDs, assetType) then
			noPants = false
		elseif table.find(TOP_ASSET_TYPE_IDs, assetType)  then
			noShirt = false
		end
	end

	if noPants then
		self:TryOn(avatarHum, DEFAULT_CLOTHES.Pants, Enum.AssetType.Pants.Value, dontPersistWear)
	end

	if noShirt then
		self:TryOn(avatarHum, DEFAULT_CLOTHES.Shirt, Enum.AssetType.Shirt.Value, dontPersistWear)
	end

	if PERSISTENT_WEAR then
		if not dontPersistWear then
			OnApplyOutfit:FireServer(outfitDesc)
		end
	end
end

function AvatarModule:TryOn(
	avatarHum: Humanoid,
	assetId: string | number,
	assetType: string | number,
	dontPersistWear: boolean,
	order: number?
): string
	local desc = avatarHum:GetAppliedDescription()

	local emote = IsValidEmote(tonumber(assetType) :: number)
	local property = GetItemProperty(tonumber(assetType) :: number)
	local accessory = GetAccessoryType(tonumber(assetType) :: number)

	local removeOldAsset

	if property then
		removeOldAsset = self.TryItem(desc, assetId, property, dontPersistWear)
		avatarHum:ApplyDescription(desc)
	elseif accessory then
		self.TryAccessory(desc, assetId, accessory, dontPersistWear, order)
		local suc = pcall(function()
			avatarHum:ApplyDescription(desc)
		end)
		if not suc then
			Utils.pprint("[Bloxbiz] Accessory is already being worn")
		end
	elseif emote then
		self.TryEmote(avatarHum, assetId)
	else
		Utils.pprint("[SuperBiz] Asset is not an accessory, emote or a valid HumDesc property")
		Utils.pprint(assetType)
	end

	return removeOldAsset
end

function AvatarModule:Remove(avatarHum: Humanoid, assetId: string | number, assetType: string | number)
	local desc: HumanoidDescription = avatarHum:GetAppliedDescription()

	local emote = IsValidEmote(tonumber(assetType) :: number)
	local property = GetItemProperty(tonumber(assetType) :: number)
	local accessory = GetAccessoryType(tonumber(assetType) :: number)

	local shouldReload = false

	if property then
		shouldReload = self.RemoveItem(desc, property)
		avatarHum:ApplyDescription(desc)
	elseif accessory then
		shouldReload = self.RemoveAccessory(desc, assetId)
		avatarHum:ApplyDescription(desc)
	elseif emote then
		self.RemoveEmote()
	else
		Utils.pprint("[SuperBiz] Asset is not an accessory, emote or a valid HumDesc property")
		Utils.pprint(assetId)
	end

	return shouldReload
end

Player.CharacterAdded:Connect(function(character: Model)
	PlayerHum = character:WaitForChild("Humanoid") :: Humanoid
	CharLoaded:Fire()
end)
if Player.Character then
	PlayerHum = Player.Character:WaitForChild("Humanoid") :: Humanoid
	CharLoaded:Fire()
end

return AvatarModule
