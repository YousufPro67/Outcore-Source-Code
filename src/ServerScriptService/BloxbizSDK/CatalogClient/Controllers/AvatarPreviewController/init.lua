local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local BloxbizSDK = script.Parent.Parent.Parent

local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")
local CatalogItemTryOnEvent, CatalogOnSaveOutfit, CatalogOnResetOutfit, OnApplyToRealHumanoid, GetPoses

local ConfigReader = require(script.Parent.Parent.Parent:WaitForChild("ConfigReader"))
local BodyScaleValues = require(BloxbizSDK.CatalogClient.Libraries.BodyScaleValues)

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local _UIScaler = require(UtilsStorage:WaitForChild("UIScaler"))
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local New = Fusion.New
local Computed = Fusion.Computed
local Value = Fusion.Value
local Spring = Fusion.Spring
local Observer = Fusion.Observer
local Children = Fusion.Children

local Classes = script.Parent.Parent.Classes
local AvatarHandler = require(Classes.AvatarHandler)
local DataHandler = require(Classes.DataHandler)
local CatalogChanges = require(Classes.CatalogChanges)

local PreviewFrame = require(script.PreviewFrame)
local PreviewButtons = require(script.PreviewButtons)
local SceneControls = require(script.SceneControls)
local AvatarViewportFrame = require(script.AvatarViewportFrame)
local HumanoidDescriptionProperties = require(script.HumanoidDescriptionProperties)
local Item = require(script.Item)
local WearingButton = require(script.WearingButton)
local LoadingFrame = require(script.LoadingFrame)

local SETTINGS = {
	TopTypes = { 64, 65, 68 },
	BottomTypes = { 66, 69, 72 },

	LimitTryOn = ConfigReader:read("CatalogClothingLimits"),
	PersistentWear = ConfigReader:read("CatalogPersistentWear"),
	SaveOutfitLimit = 100,
}

type OutfitComponent = AvatarHandler.ItemData | { [string]: Color3 }
type Outfit = { [string | number]: OutfitComponent }

local WearingItemsCache: { Item.DataSet } = {}

local function ExceedsWearLimit(
	currentOutfit: { [string | number]: AvatarHandler.ItemData },
	assetWearingLimits: { number },
	assetTypeId: number
): (boolean, AvatarHandler.ItemData)
	local isBottom = table.find(SETTINGS.BottomTypes, assetTypeId)
	local isTop = table.find(SETTINGS.TopTypes, assetTypeId)
	local limit = assetWearingLimits[assetTypeId] or 10

	local count = 0
	local lastAsset

	for _, asset in pairs(currentOutfit) do
		if isTop then
			for _, topId in SETTINGS.TopTypes do
				if asset.AssetType == topId then
					return true, asset
				end
			end
		elseif isBottom then
			for _, bottomId in SETTINGS.BottomTypes do
				if asset.AssetType == bottomId then
					return true, asset
				end
			end
		else
			if asset.AssetType ~= assetTypeId then
				continue
			end
		end

		if not isBottom and not isTop and asset.AssetType == assetTypeId then
			count += 1
			lastAsset = asset
		end
	end

	return count >= limit, lastAsset
end

local function GetTableType(t: { any }): string?
	if next(t) == nil then
		return
	end
	for k, _ in pairs(t) do
		if typeof(k) ~= "number" or (typeof(k) == "number" and (k % 1 ~= 0 or k < 0)) then
			return "Dictionary"
		end
	end

	return "Array"
end

local function GetTableSize(t: any): number
	local tableType = GetTableType(t)
	if tableType == "Array" then
		return #t
	elseif tableType == "Dictionary" then
		local count = 0
		for _ in t do
			count += 1
		end
		return count
	else
		return 0
	end
end

local function GetTableDiff(a: { AvatarHandler.ItemData }, b: { AvatarHandler.ItemData }): ({ number }, { number })
	local added = {}
	local removed = {}

	local sourceIds = {}
	for _, itemData in pairs(a) do
		table.insert(sourceIds, itemData.AssetId)
	end

	local newIds = {}
	for _, itemData in pairs(b) do
		table.insert(newIds, itemData.AssetId)
	end

	for _, id in pairs(newIds) do
		if not table.find(sourceIds, id) then
			table.insert(added, id)
		end
	end

	for _, id in pairs(sourceIds) do
		if not table.find(newIds, id) then
			table.insert(removed, id)
		end
	end

	return added, removed
end

local function FindItemInTable(t: Outfit, item: AvatarHandler.ItemData): number?
	for index, itemData in pairs(t) do
		if index ~= "BodyColors" then
			if tostring(itemData.AssetId) == tostring(item.AssetId) then
				return index
			end
		end
	end

	return nil
end

local function IsSameOutfit(newOutfit: Outfit, outfit: Outfit): boolean
	for itemId, data in pairs(outfit) do
		if not newOutfit[itemId] then
			return false
		end

		if itemId == "BodyColors" then
			for property, color in pairs(outfit.BodyColors) do
				if data[property] ~= color then
					return false
				end
			end
		end
	end

	for itemId, data in pairs(newOutfit) do
		if not outfit[itemId] then
			return false
		end

		if itemId == "BodyColors" then
			for property, color in pairs(newOutfit.BodyColors) do
				if data[property] ~= color then
					return false
				end
			end
		end
	end

	return true
end


export type AvatarPreviewController = {
	__index: AvatarPreviewController,
	new: (coreContainer: Frame) -> AvatarPreviewController,
	Init: (self: AvatarPreviewController, controllers: { [string]: any }) -> (),
	OnClose: (self: AvatarPreviewController) -> (),

	GetHumanoid: (self: AvatarPreviewController) -> Humanoid?,

	Container: Frame,
	Enabled: boolean,
	Debounces: { [string]: boolean },

	GuiObjects: {},
	Observers: { () -> () },

	AvatarObjects: {
		Humanoid: Humanoid?,
		Model: Model?,
	},
}

local VIEWPORT_SIZE = Value(Vector2.new(1280, 720))
RunService.RenderStepped:Connect(function()
	if workspace.Camera.ViewportSize ~= VIEWPORT_SIZE:get() then
		VIEWPORT_SIZE:set(workspace.Camera.ViewportSize)
	end
end)


local AvatarPreview = {} :: AvatarPreviewController
AvatarPreview.__index = AvatarPreview

function AvatarPreview.new(coreContainer: Frame): AvatarPreviewController
	local self: AvatarPreviewController = setmetatable({} :: any, AvatarPreview)

	self.Container = coreContainer
	self.Enabled = false

	self.Observers = {}
	self.GuiObjects = {}
	self.AvatarObjects = {}
	self.Debounces = {}

	self.zoom = Value(0.8)
	self.zoomSpring = Spring(self.zoom, 30)

	self.HideUI = Value(false)

	self.SelectedItem = nil
	self.EquippedItems = Value({})

	self.PlayerDescChanged = Value(false)

	self.Poses = {}
	self.PoseIds = {}

	self.OutfitLoaded = Instance.new("BindableEvent")

	return self
end

function AvatarPreview:Init(controllers: { [string]: { any } })
	self.Controllers = controllers

	CatalogItemTryOnEvent = BloxbizRemotes:WaitForChild("CatalogItemTryOnEvent") :: RemoteEvent
	CatalogOnSaveOutfit = BloxbizRemotes:WaitForChild("CatalogOnSaveOutfit") :: RemoteFunction
	CatalogOnResetOutfit = BloxbizRemotes:WaitForChild("CatalogOnResetOutfit")
	OnApplyToRealHumanoid = BloxbizRemotes:WaitForChild("CatalogOnApplyToRealHumanoid") :: RemoteEvent
	GetPoses = BloxbizRemotes:WaitForChild("CatalogOnGetPoses") :: RemoteEvent

	-- Getting avatar rules
	local rules = AvatarEditorService:GetAvatarRules()
	if not rules then
		return
	end

	self.AssetWearingLimits = {}
	for _, assetType in pairs(rules.WearableAssetTypes) do
		local limit = assetType.MaxNumber
		self.AssetWearingLimits[assetType.Id] = limit <= 0 and 1 or limit
	end

	-- Getting loading frame
	local loadingFrame = LoadingFrame()
	self.GuiObjects.LoadingFrame = loadingFrame
	loadingFrame.Visible = false

	local list = self.EquippedItems

	self.UndoChanges = CatalogChanges.new()
	self.RedoChanges = CatalogChanges.new()
	self.SaveDisabled = Fusion.Value(false)

	self.WearingVisible = Fusion.Value(false)

	self.SelectedItem = nil
	self.EquippedCount = Fusion.Computed(function()
		return Utils.getArraySize(self.EquippedItems:get())
	end)

	-- get screen orientation
	
	self.ScreenOrientation = Value(Players.LocalPlayer.PlayerGui.ScreenOrientation)
	Fusion.Hydrate(Players.LocalPlayer.PlayerGui)({
		[Fusion.Out "CurrentScreenOrientation"] = self.ScreenOrientation
	})

	-- use top bar height to scale buttons

	local BTN_HT = Fusion.Computed(function()
		local topBarHeight = self.Controllers.TopBarController.TopBarHeight

		-- make buttons bigger for touch enabled devices
		local isTouch = UserInputService.TouchEnabled
		local isPortrait = self.ScreenOrientation:get() == Enum.ScreenOrientation.Portrait
		local ratio = (isTouch and not isPortrait) and 1.4 or 1
	
		return topBarHeight:get() * ratio
	end)

	-- animation

	local AnimsFolder = BloxbizRemotes:WaitForChild("PoseAnimations")

	-- preload animations
	task.spawn(function()
		ContentProvider:PreloadAsync(AnimsFolder:GetChildren())
	end)

	self.Poses = GetPoses:InvokeServer()
	self.PoseAnimIds = Utils.values(self.Poses)

	if not Players.LocalPlayer.Character then
		Players.LocalPlayer.CharacterAdded:Wait()
	end

	-- local idleAnimUrl = AvatarHandler.GetIdleAnimationId(Players.LocalPlayer.Character)
	-- if idleAnimUrl then
	-- 	local idleAnimId  = tonumber(string.gsub(idleAnimUrl, "%D", ""))
	-- 	table.insert(self.PoseAnimIds, 1, idleAnimId)
	-- end

	table.insert(self.PoseAnimIds, 1, "")
	

	self.PoseIdx = Value(1)

	self._animTrack = nil
	local function onPose(poseIdx)
		if self._animTrack then
			self._animTrack:Stop()
			self._animTrack:Destroy()
		end

		if not poseIdx then
			poseIdx = self.PoseIdx:get() + 1
			if poseIdx > #self.PoseAnimIds then
				poseIdx = 1
			end
		end

		local animId = self.PoseAnimIds[poseIdx]
		if animId ~= "" then
			local anim = AnimsFolder:FindFirstChild(tostring(animId)) or animId

			self._animTrack = AvatarHandler.GetAnimationTrack(self.AvatarObjects.Model, anim)
			if self._animTrack then
				self._animTrack:Play()
			end
		else
			-- print("empty anim")
		end

		self.PoseIdx:set(poseIdx)
	end

	-- scenes/backgrounds set up

	self.FullScreen = Value(false)

	local COLOR_SCENES = {
		{
			Image = "",
			Color = Color3.new(0, 1, 0)
		},
		{
			Image = "",
			Color = Color3.new(0, 0, 1)
		},
		{
			Image = "",
			Color = Color3.new(1, 1, 1)
		},
		{
			Image = "",
			Color = Color3.new(0, 0, 0)
		},
	}

	self.Scene = Value({
		Image = "http://www.roblox.com/asset/?id=10393363412",
		Color = Color3.new(1, 1, 1)
	})
	self.Scenes = Value(Utils.concat(
		{self.Scene:get()},
		COLOR_SCENES
	))

	-- load dynamic backgrounds
	task.spawn(function()
		local success, myConfig = BloxbizRemotes:WaitForChild("GetCatalogConfigForPlayer"):InvokeServer()
		
		if success and #myConfig.try_on_backgrounds > 0 then
			Utils.pprint(myConfig.try_on_backgrounds)
			local scenes = Utils.concat(
				Utils.map(myConfig.try_on_backgrounds, function (assetId)
					return {
						Image = ("http://www.roblox.com/asset/?id=%s"):format(assetId),
						Color = Color3.new(1, 1, 1)
					}
				end),
				COLOR_SCENES
			)
			self.Scenes:set(scenes)
			self.Scene:set(scenes[1])
		end
	end)

	-- get frame

	self.ViewportFrameRef = Value()

	PreviewFrame {
		Parent = self.Container,
		
		Scene = self.Scene,

		Position = Spring(Computed(function()
			if self.FullScreen:get() then
				return UDim2.fromScale(0, 0)
			else
				return UDim2.new(0.688, 0, 0.017, 0)
			end
		end), 30),
		Size = Spring(Computed(function()
			if self.FullScreen:get() then
				return UDim2.fromScale(1, 1)
			else
				return UDim2.new(0.302, 0, 1 - 0.017, 0)
			end
		end), 30),

		ButtonHeight = BTN_HT,
		EquippedItems = self.EquippedItems,
		ShowItems = self.WearingVisible,
		CategoryName = "",
		AvatarPreviewController = self,
		[Children] = {
			self.ViewportFrameRef,

			self.GuiObjects.LoadingFrame,

			SceneControls {
				Visible = Computed(function()
					local fs = self.FullScreen:get()
					local hideUI = self.HideUI:get()

					return fs and not hideUI
				end),
				ButtonHeight = BTN_HT,
				OnFullScreen = function(isFull)
					self.WearingVisible:set(false)
					self.FullScreen:set(isFull)

					if not isFull then
						self.Scene:set(self.Scenes:get()[1])
						self:StopPosing()
					end
				end,
				FullScreen = self.FullScreen,
				HideUI = self.HideUI,

				Scene = self.Scene,
				Scenes = self.Scenes,
				OnPoseChange = onPose
			},

			PreviewButtons {
				Visible = Computed(function()
					return not self.FullScreen:get()
				end),
				ButtonHeight = BTN_HT,

				FullScreen = self.FullScreen,
				OnFullScreen = function(isFull)
					self.WearingVisible:set(false)
					self.FullScreen:set(isFull)
				end,
		
				UndoDisabled = Fusion.Computed(function()
					return #self.UndoChanges.Changes:get() == 0
				end),
				RedoDisabled = Fusion.Computed(function()
					return #self.RedoChanges.Changes:get() == 0
				end),
				SaveDisabled = Fusion.Computed(function()
					local currentEquipped = self.EquippedItems:get()
					local outfits = self.Controllers.OutfitsController.Outfits:get()

					local humanoid = self.AvatarObjects.Humanoid
					if not humanoid then
						return false
					end

					currentEquipped.BodyColors = AvatarHandler.GetCurrentBodyColors(humanoid:GetAppliedDescription())

					for _, outfit in pairs(outfits) do
						local exist = (not outfit.isRoblox:get()) and IsSameOutfit(currentEquipped, outfit.data)

						if exist then
							return true
						end
					end

					return false
				end),
				WearingItems = list,
		
				OnUndo = function()
					self:ReverseChange(true)
				end,
				OnRedo = function()
					self:ReverseChange(false)
				end,
				OnReset = function()
					self:ResetChanges()
				end,
				OnSave = function()
					self:SaveChange()
				end,
		
				OnOpenWearing = function()
					self.WearingVisible:set(not self.WearingVisible:get())
				end,
				WearingSelected = self.WearingVisible,
		
				OnOpenBody = function()
					self.Controllers.NavigationController:SwitchTo("BodyEditor")
				end,
				BodySelected = self.Controllers.NavigationController:GetEnabledComputed("BodyEditor"),
		
				OnOpenInventory = function()
					self.Controllers.NavigationController:SwitchTo("Inventory")
				end,
				InventorySelected = self.Controllers.NavigationController:GetEnabledComputed("Inventory"),
		
				OnOpenOutfits = function()
					self.Controllers.NavigationController:SwitchTo("Outfits")
				end,
				OutfitsSelected = self.Controllers.NavigationController:GetEnabledComputed("Outfits"),
			}
		}
	}

	self:RefreshViewportFrame()

	local zoomObs = Observer(self.zoomSpring)
	zoomObs:onChange(function()
		local zoom = self.zoomSpring:get()
		
		AvatarHandler.UpdateViewportRender(self.GuiObjects.ViewportFrame, true, zoom)
	end)

	-- detect player's humanoid description changing

	local sig = nil

	local function onCharacterAdded(char)
		if sig then
			sig:Disconnect()
		end

		local humanoid = char:WaitForChild("Humanoid")
		if humanoid then
			local desc = humanoid:FindFirstChild("HumanoidDescription")

			if desc then
				sig = desc.Changed:Connect(function()
					-- mark the player's outfit changed, which will cause it to be reloaded next time
					-- the catalog opens
	
					self.PlayerDescChanged:set(true)
					Utils.pprint("Player's HumanoidDescription changed")
				end)
			end
		end
	end

	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(onCharacterAdded)

	if player.Character then
		onCharacterAdded(player.Character)
	end
end

function AvatarPreview:StopPosing()
	if self._animTrack then
		self._animTrack:Stop()
		self._animTrack:Destroy()
	end
	self.PoseIdx:set(1)
end

function AvatarPreview:LoadCurrentOutfit(presetHumanoid: Humanoid?, apply: boolean?): boolean
	local humanoid = presetHumanoid or self.AvatarObjects.Humanoid

	local wearing, notWearing, humDesc: HumanoidDescription =
		AvatarHandler.GetCurrentOutfit(self.EquippedItems:get(), humanoid)

	wearing.BodyColors = AvatarHandler.GetCurrentBodyColors(humanoid:GetAppliedDescription())

	local array = {}
	for id, itemData in pairs(wearing) do
		if id == "BodyColors" then
			continue
		end
		array[tostring(itemData.AssetId)] = itemData
	end

	self.EquippedItems:set(array)

	local wearChanged = #wearing > 0
	local notWearChanged = #notWearing > 0

	local found = table.find(notWearing, "BodyColors")
	if found then
		notWearChanged = #notWearing - 1 > 0
	end

	if self.Controllers then
		if self.Controllers.BodyEditorController then
			self.Controllers.BodyEditorController:UpdateSliders(humDesc)
		end
	end

	if SETTINGS.PersistentWear then
		task.spawn(function()
			if apply then
				self:ApplyOutfit(self.EquippedItems:get(), humDesc)
			end

			self.AvatarObjects.Humanoid:ApplyDescription(humDesc)
			local char = self.AvatarObjects.Humanoid.Parent
			if not (char:FindFirstChild("Head") or char:FindFirstChild("DynamicHead")) then
				Utils.pprint("Dynamic head was unable to load due to Roblox bug, reverting to default head")
				
				humDesc.Head = 2432102561
				self.AvatarObjects.Humanoid:ApplyDescription(humDesc)
			end

			self.OutfitLoaded:Fire()
		end)
	else
		self.OutfitLoaded:Fire()
	end

	return (wearChanged or notWearChanged)
end

function AvatarPreview:UpdateEquippedItems(id: string | number, itemData: AvatarHandler.ItemData?)
	local equippedItems = self.EquippedItems:get()

	if itemData then
		itemData = Utils.merge(itemData, {
			equippedAt = tick()
		})
	end

	equippedItems[tostring(id)] = itemData
	self.EquippedItems:set(equippedItems)

	--Update on the category side
	local categoryItem = self.Controllers.CategoryController:GetAvatarItemCache(id)
	if not itemData then
		if categoryItem then
			categoryItem.Equipped:set(false)
		end
	else
		if categoryItem then
			categoryItem.Equipped:set(true)
		end
	end

	--Update on the inventory side
	local inventoryItem = self.Controllers.InventoryController:GetAvatarItemCache(id)
	if not itemData then
		if inventoryItem then
			inventoryItem.Equipped:set(false)
		end
	else
		if inventoryItem then
			inventoryItem.Equipped:set(true)
		end
	end

	-- self.Controllers.OutfitFeedController:UpdateTryButton(id, itemData ~= nil)
end

function AvatarPreview:IsSavedOutfit(
	currentEquipped: { [string | number]: AvatarHandler.ItemData | { [string]: Color3 } },
	bodyColors: { [string]: Color3 }
): boolean
	currentEquipped.BodyColors = bodyColors

	local outfits = self.Controllers.OutfitsController.Outfits:get()

	for _, outfit in pairs(outfits) do
		local exist = (not outfit.isRoblox:get()) and IsSameOutfit(currentEquipped, outfit.data)

		if exist then
			return true
		end
	end

	return false
end

function AvatarPreview:UpdateSaveButton(forcedResult: { CanSaveOutfit: boolean, Reason: string })
	local humanoid = self.AvatarObjects.Humanoid
	local equippedItems = self.EquippedItems:get()

	local bodyColors = AvatarHandler.GetCurrentBodyColors(humanoid:GetAppliedDescription())

	local cannotSaveOutfit, reason = self:IsSavedOutfit(equippedItems, bodyColors)
	if forcedResult then
		cannotSaveOutfit, reason = not forcedResult.CanSaveOutfit, forcedResult.Reason
	end

	if cannotSaveOutfit then
		self.SaveDisabled:set(true)
	else
		self.SaveDisabled:set(false)
	end
end

function AvatarPreview:RefreshViewportFrame()
	self.GuiObjects.LoadingFrame.Visible = true

	task.spawn(function()
		if self.GuiObjects.ViewportFrame then
			self.AvatarObjects.Model:Destroy()
			self.GuiObjects.ViewportFrame:Destroy()
		end

		local avatarPreviewFrameComponents = AvatarViewportFrame(self.zoom)
		local viewportFrame, model = avatarPreviewFrameComponents.Viewport, avatarPreviewFrameComponents.Model
		self.ViewportFrameRef:set(viewportFrame)

		local humanoid = model:WaitForChild("Humanoid")

		self.AvatarObjects.Model = model
		self.AvatarObjects.Humanoid = humanoid

		viewportFrame.Visible = true
		self.GuiObjects.ViewportFrame = viewportFrame
		self.ResetRotation = avatarPreviewFrameComponents.ResetRotation

		AvatarHandler.UpdateViewportRender(viewportFrame, true, self.zoom:get())
	end)

	self.GuiObjects.LoadingFrame.Visible = false
end

function AvatarPreview:GetOutfit()
	local humanoid = self.AvatarObjects.Humanoid
	local bodyColors = AvatarHandler.GetCurrentBodyColors(humanoid:GetAppliedDescription())

	local outfit = self.EquippedItems:get()
	outfit.BodyColors = bodyColors

	return outfit, humanoid
end

function AvatarPreview:SaveChange()
	if self.Debounces.SaveOutfitDebounce then
		return
	end
	self.Debounces.SaveOutfitDebounce = true

	local humanoid = self.AvatarObjects.Humanoid
	local bodyColors = AvatarHandler.GetCurrentBodyColors(humanoid:GetAppliedDescription())

	local equippedItems = self.EquippedItems:get()

	if self:IsSavedOutfit(equippedItems, bodyColors) then
		self.Debounces.SaveOutfitDebounce = false
		return
	end

	local success = CatalogOnSaveOutfit:InvokeServer(equippedItems, bodyColors)
	if success then
		self.SaveDisabled:set(true)
	else
		self:UpdateSaveButton()
	end

	self.Debounces.SaveOutfitDebounce = false
end

function AvatarPreview:GetMaxOrder()
	local humanoid = self.AvatarObjects.Humanoid
	local wearingAccessories = humanoid:GetAppliedDescription():GetAccessories(false)

	local maxOrder = 0
	for _, accessory in ipairs(wearingAccessories) do
		maxOrder = math.max(maxOrder, accessory.Order or 0)
	end

	return maxOrder
end

function AvatarPreview:GetLastEquippedAsset(assetTypeIds, offset)
	if type(assetTypeIds) ~= "table" then
		assetTypeIds = {assetTypeIds or -1}
	end
	if offset == nil then
		offset = 1
	end

	local equippedItems = Utils.values(self.EquippedItems:get(), function (_, assetId) return assetId ~= "BodyColors" end)
	local sortValues = equippedItems
	local sameType = Utils.filter(equippedItems, function (item)
		return table.find(assetTypeIds, item.AssetType)
	end)

	if Utils.getArraySize(sameType) >= offset then
		sortValues = sameType
	end

	Utils.sortByKey(sortValues, function (item) return -(item.equippedAt or 0) end)
	return sortValues[offset]
end

function AvatarPreview:AddChange(itemData: AvatarHandler.ItemData & AvatarHandler.BundleData, currentCategory: string)
	self.GuiObjects.LoadingFrame.Visible = true

	local assetId = itemData.AssetId
	local assetType = itemData.AssetType
	local isBundle = itemData.BundleId ~= nil

	local humanoid = self.AvatarObjects.Humanoid

	local currentDesc = humanoid:GetAppliedDescription()
	local change = {
		Old = {
			Outfit = Utils.deepCopy(self.EquippedItems:get()),
			Desc = currentDesc,
		},
	}

	if isBundle then
		local prevHead = 2432102561  -- default roblox head
		-- local prevDesc = humanoid:FindFirstChild("HumanoidDescription")
		-- if prevDesc then
		-- 	prevHead = prevDesc.Head
		-- end

		local desc, _, hasDynamicHead = AvatarHandler.GetHumDescFromBundle(currentDesc, itemData, false)
		humanoid:ApplyDescription(desc)

		local char = humanoid.Parent
		if not (char:FindFirstChild("Head") or char:FindFirstChild("DynamicHead")) then
			Utils.pprint("Dynamic head was unable to load due to Roblox bug, reverting to default head")
			
			desc.Head = prevHead
			humanoid:ApplyDescription(desc)
		end

		self:LoadCurrentOutfit(humanoid)
		AvatarHandler.ReplicateBundle(HumanoidDescriptionProperties.FetchDescriptionToTable(desc))
	else
		local equipped = self:IsItemEquipped(itemData)
		
		if equipped then
			local shouldReload = AvatarHandler:Remove(humanoid, assetId, assetType)

			if shouldReload then
				Utils.pprint("reloading outfit with default clothes")
				task.wait()
				self:LoadCurrentOutfit(humanoid, false)
			else
				self:UpdateEquippedItems(assetId, nil)
			end
		else
			local equippedItems = self.EquippedItems:get()
			local exceeds, _ = ExceedsWearLimit(equippedItems, self.AssetWearingLimits, assetType)
			
			local isBottom = table.find(SETTINGS.BottomTypes, assetType)
			local isTop = table.find(SETTINGS.TopTypes, assetType)
			local types = (isBottom and SETTINGS.BottomTypes) or (isTop and SETTINGS.TopTypes) or {assetType}
			local lastAsset = self:GetLastEquippedAsset(types, 1)

			if not SETTINGS.LimitTryOn then
				exceeds = Utils.getArraySize(equippedItems) >= 50
			end

			if exceeds then
				local id = lastAsset.AssetId
				local Type = lastAsset.AssetType

				AvatarHandler:Remove(humanoid, id, Type)
				self:UpdateEquippedItems(id, nil)
			end

			CatalogItemTryOnEvent:FireServer(assetId, itemData.Name, currentCategory)
			Utils.pprint("try on fired in", currentCategory)

			itemData.Order = self:GetMaxOrder() + 1
			local removeOldAsset = AvatarHandler:TryOn(humanoid, assetId, assetType, not SETTINGS.PersistentWear, itemData.Order)
			self:UpdateEquippedItems(assetId, itemData)

			if removeOldAsset then
				local oldId = removeOldAsset
				self:UpdateEquippedItems(oldId, nil)
			end
		end
	end

	change.New = {
		Outfit = Utils.deepCopy(self.EquippedItems:get()),
		Desc = humanoid:GetAppliedDescription(),
	}

	self.UndoChanges:AddChange(change)
	self.RedoChanges:DropChanges()

	AvatarHandler.UpdateViewportRender(self.GuiObjects.ViewportFrame, false, self.zoom:get())

	self.GuiObjects.LoadingFrame.Visible = false

	-- don't log changes made by the catalog persisting items
	task.spawn(function()
		task.wait(0.1)  -- wait until after OnChange event for player's HumDesc has fired
		self.PlayerDescChanged:set(false)
	end)
end

function AvatarPreview:ReverseChange(isUndo: boolean)
	self.GuiObjects.LoadingFrame.Visible = true

	local humanoid = self.AvatarObjects.Humanoid

	local change
	if isUndo then
		change = self.UndoChanges:GetLatestChange()
	else
		change = self.RedoChanges:GetLatestChange()
	end
	if not change then
		return
	end

	if self.Debounces.TryItemDebounce then
		return
	end
	self.Debounces.TryItemDebounce = true

	local oldOutfit, oldDesc
	if isUndo then
		oldDesc = change.Old.Desc
		oldOutfit = change.Old.Outfit
	else
		-- Reverse changes if it's redo
		oldDesc = change.New.Desc
		oldOutfit = change.New.Outfit
	end

	local items = Utils.deepCopy(oldOutfit)
	local added, removed = GetTableDiff(self.EquippedItems:get(), items)

	for _, itemId in pairs(removed) do
		self:UpdateEquippedItems(itemId, nil)
	end

	for _, itemData in pairs(items) do
		if table.find(added, itemData.AssetId) then
			self:UpdateEquippedItems(itemData.AssetId, itemData)
		end
	end

	humanoid:ApplyDescription(oldDesc)
	AvatarHandler.ReplicateBundle(HumanoidDescriptionProperties.FetchDescriptionToTable(oldDesc))
	AvatarHandler.UpdateViewportRender(self.GuiObjects.ViewportFrame, false, self.zoom:get())

	if isUndo then
		self.RedoChanges:AddChange(change)
		self.UndoChanges:RemoveLatestChange()
	else
		self.UndoChanges:AddChange(change)
		self.RedoChanges:RemoveLatestChange()
	end

	self.Debounces.TryItemDebounce = false

	self.GuiObjects.LoadingFrame.Visible = false
end

function AvatarPreview:ApplyOutfit(outfitData: Outfit, outfitDesc: HumanoidDescription): ()
	self.GuiObjects.LoadingFrame.Visible = true

	if self.Debounces.TryItemDebounce then
		return
	end
	self.Debounces.TryItemDebounce = true
	local humanoid = self.AvatarObjects.Humanoid

	repeat
		task.wait()
		humanoid = self.AvatarObjects.Humanoid
	until humanoid

	local change = {
		Old = {
			Outfit = Utils.deepCopy(self.EquippedItems:get()),
			Desc = humanoid:GetAppliedDescription(),
		},
	}

	local currentOutfit = {}
	currentOutfit.BodyColors = outfitData.BodyColors

	local descriptionClone = humanoid:GetAppliedDescription()
	descriptionClone.Shirt = 0
	descriptionClone.GraphicTShirt = 0
	descriptionClone.Pants = 0
	descriptionClone.Head = 0
	descriptionClone.LeftArm = 0
	descriptionClone.RightArm = 0
	descriptionClone.LeftLeg = 0
	descriptionClone.RightLeg = 0
	descriptionClone.Torso = 0
	humanoid:ApplyDescription(descriptionClone)

	AvatarHandler:TryOutfit(humanoid, outfitData, false, HumanoidDescriptionProperties.FetchDescriptionToTable(outfitDesc))

	for assetId, itemData in pairs(outfitData) do
		if assetId == "BodyColors" then
			continue
		end

		currentOutfit[tostring(assetId)] = itemData
	end
	self.EquippedItems:set(currentOutfit)

	change.New = {
		Outfit = Utils.deepCopy(self.EquippedItems:get()),
		Desc = humanoid:GetAppliedDescription(),
	}

	self.UndoChanges:AddChange(change)
	self.RedoChanges:DropChanges()

	self.Debounces.TryItemDebounce = false
	self.GuiObjects.LoadingFrame.Visible = false
end

function AvatarPreview:UpdateColor(color3: Color3)
	local humanoid = self.AvatarObjects.Humanoid

	local currentDesc = humanoid:GetAppliedDescription()
	local change = {
		Old = {
			Outfit = Utils.deepCopy(self.EquippedItems:get()),
			Desc = currentDesc,
		},
	}

	local desc = humanoid:GetAppliedDescription()

	AvatarHandler.SetBodyColor(desc, color3)
	humanoid:ApplyDescription(desc)

	change.New = {
		Outfit = Utils.deepCopy(self.EquippedItems:get()),
		Desc = humanoid:GetAppliedDescription(),
	}

	self.UndoChanges:AddChange(change)
	self.RedoChanges:DropChanges()

	self:UpdateSaveButton()
end

function AvatarPreview:UpdateScale(scaleCategory: string, value: number)
	local humanoid = self.AvatarObjects.Humanoid
	if humanoid then
		local currentDesc = humanoid:GetAppliedDescription()

		AvatarHandler.SetBodyScale(currentDesc, scaleCategory, value)
		humanoid:ApplyDescription(currentDesc)
	end
end

function AvatarPreview:ApplyScalesToPlayerHumanoid()
	local humanoid = self.AvatarObjects.Humanoid
	if humanoid then
		local currentDesc = humanoid:GetAppliedDescription()

		if SETTINGS.PersistentWear then
			local scales = {}
			for scaleName, _ in pairs(BodyScaleValues) do
				scales[scaleName] = currentDesc[scaleName]
			end

			OnApplyToRealHumanoid:FireServer({
				BodyScale = scales,
			})
		end
	end
end

function AvatarPreview:ResetChanges()
	self.GuiObjects.LoadingFrame.Visible = true

	if self.Debounces.TryItemDebounce then
		return
	end
	self.Debounces.TryItemDebounce = true

	local humanoid = self.AvatarObjects.Humanoid

	local change = {
		Old = {
			Outfit = Utils.deepCopy(self.EquippedItems:get()),
			Desc = humanoid:GetAppliedDescription(),
		},
	}

	local items = self.EquippedItems:get()

	local realDesc = AvatarHandler.GetRealHumDesc()
	humanoid:ApplyDescription(realDesc)
	local char = humanoid.Parent
	if not (char:FindFirstChild("Head") or char:FindFirstChild("DynamicHead")) then
		Utils.pprint("Dynamic head was unable to load due to Roblox bug, reverting to default head")
		
		realDesc.Head = 2432102561
		humanoid:ApplyDescription(realDesc)
	end

	local changed = self:LoadCurrentOutfit(humanoid, true)
	
	if not changed then
		self.Debounces.TryItemDebounce = false
		return
	end

	local _, removed = GetTableDiff(items, self.EquippedItems:get())
	for _, itemId in pairs(removed) do
		self:UpdateEquippedItems(itemId, nil)
	end

	change.New = {
		Outfit = Utils.deepCopy(self.EquippedItems:get()),
		Desc = humanoid:GetAppliedDescription(),
	}

	self.UndoChanges:AddChange(change)
	self.RedoChanges:DropChanges()

	if SETTINGS.PersistentWear then
		CatalogOnResetOutfit:FireServer()
	end

	self.Debounces.TryItemDebounce = false
	self.GuiObjects.LoadingFrame.Visible = false

	self.ResetRotation()
	self.zoom:set(0.8)
end

function AvatarPreview:GetCurrentOutfit()
	return self.EquippedItems:get()
end

function AvatarPreview:IsItemEquipped(itemData: AvatarHandler.ItemData): boolean
	local equippedItems = self.EquippedItems:get()
	local equipped = FindItemInTable(equippedItems, itemData)
	return equipped ~= nil
end

function AvatarPreview:GetHumanoid(): Humanoid?
	return self.AvatarObjects.Humanoid
end

function AvatarPreview:OnClose()
	if SETTINGS.PersistentWear then
		self:ApplyScalesToPlayerHumanoid()
	end

	self.FullScreen:set(false)
	self.Scene:set(self.Scenes:get()[1])
	self:StopPosing()
end

function AvatarPreview:OnOpen()
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChild("Humanoid")

	task.spawn(function()
		self.GuiObjects.LoadingFrame.Visible = true

		if SETTINGS.PersistentWear then
			self:LoadCurrentOutfit(humanoid, false)
		else
			self:LoadCurrentOutfit()
		end

		AvatarHandler.UpdateViewportRender(self.GuiObjects.ViewportFrame, false, self.zoom:get())
		self.GuiObjects.LoadingFrame.Visible = false
	end)
end

return AvatarPreview
