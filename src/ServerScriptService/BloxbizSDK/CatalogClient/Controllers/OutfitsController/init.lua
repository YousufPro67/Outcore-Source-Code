local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AvatarEditorService = game:GetService("AvatarEditorService")

local BloxbizSDK = script.Parent.Parent.Parent
local AvatarHandler = require(script.Parent.Parent.Classes.AvatarHandler)
local DataHandler = require(script.Parent.Parent.Classes.DataHandler)
local InventoryHandler = require(script.Parent.Parent.Classes.InventoryHandler)

local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")
local OnDeleteOutfit = BloxbizRemotes:WaitForChild("CatalogOnDeleteOutfit")

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local Promise = require(UtilsStorage:WaitForChild("Promise"))

local Value = Fusion.Value
local Computed = Fusion.Computed
local Hydrate = Fusion.Hydrate
local New = Fusion.New
local Observer = Fusion.Observer
local Children = Fusion.Children
local ForPairs = Fusion.ForPairs
local ForValues = Fusion.ForValues
local OnChange = Fusion.OnChange
local Out = Fusion.Out

local Components = script.Parent.Parent.Components
local ItemGrid = require(Components.ItemGrid)
local OutfitsItemFrame = require(Components.OutfitsItemFrame)
local EmptyState = require(Components.EmptyState)
local Sort = require(Components.ContentFrame.Sort)

local Button = require(script.Button)

local Outfits = {}
Outfits.__index = Outfits

function Outfits.new(coreContainer: Frame)
	local self = setmetatable({}, Outfits)
	self.Enabled = false

	self.Container = coreContainer
	self.Observers = {}
	self.GuiObjects = {}

	self.CurrentSelected = Value()
	self.Debounces = {}

	self.LoadedRobloxOutfits = false
	self.RequestPermFailed = false

	self.Outfits = Value({})
	self.VisibleSet = Value({})

	return self
end

function Outfits:Init(controllers: { [string]: { any } })
	self.Controllers = controllers
	self.Enabled = controllers.NavigationController:GetEnabledComputed("OutfitsController")

	local container = self.Container:WaitForChild("FrameContainer")

	local SORT_HEIGHT = 0.1

	self.CurrentTab = Value("all")

	local isEmpty = Computed(function()
		local outfits = self.Outfits:get()
		local tab = self.CurrentTab:get()

		return Utils.count(Utils.values(outfits), function (outfit)
			if tab == "game" and outfit.isRoblox:get() then
				return false
			elseif tab == "roblox" and not outfit.isRoblox:get() then
				return false
			end

			return true
		end) == 0
	end)

	local buttonsContainerSize = Value(Vector2.zero)
	local contentSize = Value(Vector2.zero)

	local topBarSize = Value(Vector2.zero)
	local fullSize = Value(Vector2.zero)

	New "Frame" {
		Parent = container,
		Name = "Outfits",

		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = self.Enabled,

		[Out "AbsoluteSize"] = fullSize,

		[Children] = {
			-- sort frame container
			New "Frame" {
				Position = UDim2.fromOffset(0, 1),
				Size = UDim2.fromScale(1, 0.04),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				BackgroundTransparency = 1,

				[Out "AbsoluteSize"] = topBarSize,

				[Children] = {
					Sort {
						Size = UDim2.fromScale(0.5, 0.9),
						Buttons = {
							{
								Text = "Saved Outfits",
								Data = {},
								Id = "all",
							},
							{
								Text = "This Game",
								Data = {},
								Id = "game",
							},
							{
								Text = "Roblox Outfits",
								Data = {},
								Id = "roblox",
							}
						},
						Selected = self.CurrentTab
					},

					New "Frame" {
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(1, 0.5),
						AnchorPoint = Vector2.new(1, 0.5),
						Size = UDim2.fromScale(0.5, 1),

						[Fusion.Out "AbsoluteSize"] = buttonsContainerSize,

						[Children] = {
							New "UIListLayout" {
								FillDirection = Enum.FillDirection.Horizontal,
								HorizontalAlignment = Enum.HorizontalAlignment.Right,
								VerticalAlignment = Enum.VerticalAlignment.Center,
								SortOrder = Enum.SortOrder.LayoutOrder,
								Padding = Computed(function()
									return UDim.new(0, self.Controllers.TopBarController.TopBarHeight:get() / 8 + 3)
								end)
							},
							New "UIPadding" {
								PaddingRight = UDim.new(0, 1.5)
							},

							Button {
								Icon = "rbxassetid://14914253209",
								Text = "Save to Roblox",
								LayoutOrder = 1,
								OnClick = function()
									self:SaveCurrentOutfitToRoblox()
								end,
								MaxWidth = Computed(function()
									return buttonsContainerSize:get().X / 2 - self.Controllers.TopBarController.TopBarHeight:get() / 2 + 3
								end)
							},

							Button {
								Icon = "rbxassetid://14914253209",
								Text = "Update Avatar",
								LayoutOrder = 2,
								OnClick = function()
									local currentOutfit, humanoid = self.Controllers.AvatarPreviewController:GetOutfit()
									local ownedOutfit, removed = self:RemoveUnownedItems(currentOutfit)
						
									local humDesc = AvatarHandler.OutfitToHumDesc(ownedOutfit, humanoid:GetAppliedDescription())
									humDesc.Parent = workspace

									AvatarEditorService:PromptSaveAvatar(humDesc, Enum.HumanoidRigType.R15)
									local result, reason = AvatarEditorService.PromptSaveAvatarCompleted:Wait()
		
									Utils.pprint(result)
									Utils.pprint(reason)
								end,
								MaxWidth = Computed(function()
									return buttonsContainerSize:get().X / 2 - self.Controllers.TopBarController.TopBarHeight:get() / 8 + 3
								end)
							}
						}
					}
				}
			},
			-- content container
			New "Frame" {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = Computed(function()
					return UDim2.new(
						1, 0,
						1, -topBarSize:get().Y * 1.2 - 3
					)
				end),
				BackgroundTransparency = 1,

				[Children] = {
					EmptyState {
						Size = UDim2.fromScale(1, 0.8),
						BackgroundTransparency = 1,
						Visible = isEmpty,
						Text = Computed(function()
							local tab = self.CurrentTab:get()

							if tab == "all" then
								return "You don't have any outfits saved yet."
							elseif tab == "game" then
								return "You don't have any outfits saved to this game."
							elseif tab == "roblox" then
								return "You don't have any outfits in your Roblox inventory."
							end
						end),
						ButtonText = Computed(function()
							local tab = self.CurrentTab:get()

							if tab == "all" then
								return "Save Outfit"
							elseif tab == "game" then
								return "Save Outfit"
							elseif tab == "roblox" then
								return "Save to Roblox"
							end
						end),
				
						Callback = function()
							local tab = self.CurrentTab:get()

							if tab ~= "roblox" then
								self.Controllers.AvatarPreviewController:SaveChange()
							else
								self:SaveCurrentOutfitToRoblox()
							end
						end,
					},

					ItemGrid {
						Gap = Computed(function()
							return self.Controllers.TopBarController.TopBarHeight:get() / 8
						end),
						-- Gap = 4,
						Columns = 4,
						Visible = Computed(function()
							return not isEmpty:get()
						end),

						[Children] = ForValues(self.Outfits, function (outfit)
							local id = outfit.id
					
							local isDeleting
							local function delete()
								isDeleting = true
								
								OnDeleteOutfit:FireServer(id)
								self.CurrentSelected:set(nil)
					
								local outfits = self.Outfits:get()
								outfits[id] = nil
								self.Outfits:set(outfits)
					
								isDeleting = false
							end
					
							local isRoblox = outfit.isRoblox
					
							local frame
							frame = OutfitsItemFrame({
								Outfit = outfit.data,
								IsRoblox = isRoblox,
								Selected = Fusion.Computed(function()
									return self.CurrentSelected:get() == id
								end),
					
								Visible = Computed(function()
									local tab = self.CurrentTab:get()
									if tab == "game" and isRoblox:get() then
										return false
									elseif tab == "roblox" and not isRoblox:get() then
										return false
									end
					
									return true
								end),
					
								OnTry = function(humanoidDesc: HumanoidDescription)
									self.Controllers.AvatarPreviewController:ApplyOutfit(outfit.data, humanoidDesc)
								end,
					
								OnDelete = Fusion.Computed(function()
									if not isRoblox:get() then
										return function()
											if not isDeleting then
												delete()
											end
										end
									end
								end),
					
								OnSaveToRoblox = Fusion.Computed(function()
									if not isRoblox:get() then
										return function(humanoid)
											-- can't create an outfit on Roblox with items you don't own
								
											local ownedOutfit, removed = self:RemoveUnownedItems(outfit.data)
											local isMissingItems = #removed > 0
								
											if InventoryHandler.hasAccess() or InventoryHandler.requestAccess() then
												local humDesc = AvatarHandler.OutfitToHumDesc(ownedOutfit, humanoid:GetAppliedDescription())
												humDesc.Parent = workspace
								
												-- AvatarEditorService:PromptCreateOutfit(humDesc, Enum.HumanoidRigType.R15)
												AvatarEditorService:PromptCreateOutfit(humDesc, Enum.HumanoidRigType.R15)
												local result, reason = AvatarEditorService.PromptCreateOutfitCompleted:Wait()
					
												Utils.pprint(result)
												Utils.pprint(reason)
								
												if result == Enum.AvatarPromptResult.Success then
													if isMissingItems then
														self:LoadOutfit(HttpService:GenerateGUID(), ownedOutfit, true)
													else
														isRoblox:set(true)
														OnDeleteOutfit:FireServer(id)  -- delete datastore copy b/c now roblox copy will be present on reload
													end
												end
											end
										end
									end
								end),
					
								OnActivated = function()
									local currentSelected = self.CurrentSelected:get()
									
									if currentSelected == id then
										self.CurrentSelected:set(nil)
									else
										self.CurrentSelected:set(id)
									end
								end,
							})
					
							return frame.Instance
						end, Fusion.cleanup)
					}
				}
			}
		}
	}

	self:Disable()
end

function Outfits:Start()
	self:GetSavedOutfits()

	DataHandler.DataChanged.Event:Connect(function(key: string, value)
		if key ~= "Outfits" then
			return
		end

		self:LoadOutfit(value.InnerKey, value.InnerValue)
	end)
end

function Outfits:RemoveUnownedItems(outfitData)
	local assetIds = {}

	for k, _ in pairs(outfitData) do
		if k ~= "BodyColors" then
			table.insert(assetIds, tonumber(k))
		end
	end

	local ownershipPromises = Utils.map(assetIds, function(assetId)
		return Promise.new(function (resolve)
			resolve(MarketplaceService:PlayerOwnsAsset(Players.LocalPlayer, assetId))
		end)
	end)

	local _, ownerships = Promise.all(ownershipPromises):await()

	local newOutfit = Utils.deepCopy(outfitData)
	local removedAssets = {}
	for i, assetId in ipairs(assetIds) do
		if not ownerships[i] then
			newOutfit[tostring(assetId)] = nil
			table.insert(removedAssets, assetId)
		end
	end

	return newOutfit, removedAssets
end

function Outfits:SaveCurrentOutfitToRoblox()
	local currentOutfit, humanoid = self.Controllers.AvatarPreviewController:GetOutfit()
	local ownedOutfit, removed = self:RemoveUnownedItems(currentOutfit)

	if InventoryHandler.hasAccess() or InventoryHandler.requestAccess() then
		local humDesc = AvatarHandler.OutfitToHumDesc(ownedOutfit, humanoid:GetAppliedDescription())
		humDesc.Parent = workspace

		-- AvatarEditorService:PromptCreateOutfit(humDesc, Enum.HumanoidRigType.R15)
		AvatarEditorService:PromptCreateOutfit(humDesc, Enum.HumanoidRigType.R15)
		local result, reason = AvatarEditorService.PromptCreateOutfitCompleted:Wait()

		Utils.pprint(result)
		Utils.pprint(reason)

		if result == Enum.AvatarPromptResult.Success then
			-- if this matches a saved outfit in this game, replace it
			local replacedSavedOutfit = false
			for outfitId, savedOutfit in pairs(self.Outfits:get()) do
				if savedOutfit.isRoblox:get() then
					continue
				end

				if Utils.hasSameKeys(savedOutfit.data, ownedOutfit) then
					-- overwrite datastore outfit and replace with Roblox outfit
					savedOutfit.isRoblox:set(true)
					OnDeleteOutfit:FireServer(outfitId)

					replacedSavedOutfit = true
					break
				end
			end

			if not replacedSavedOutfit then
				self:LoadOutfit(HttpService:GenerateGUID(), ownedOutfit, true)
			end
		end
	end
end

function Outfits:LoadOutfit(id, outfitData: { AvatarHandler.ItemData }, isRoblox)
	if not id or not outfitData then
		return
	end

	local outfits = self.Outfits:get()

	outfits[tostring(id)] = {
		isRoblox = Value(isRoblox or false),
		data = outfitData,
		id = tostring(id)
	}
	self.Outfits:set(outfits)
end

function Outfits:ShowFrame(show: boolean)
	self.GuiObjects.ScrollingFrame.Visible = show
end

function Outfits:GetSavedOutfits()
	local outfits = DataHandler.GetData("Outfits")

	local stateOutfits = self.Outfits:get()

	for id, outfitData in pairs(outfits) do
		stateOutfits[tostring(id)] = {
			isRoblox = Value(false),
			data = outfitData,
			id = tostring(id)
		}
	end

	self.Outfits:set(stateOutfits)
end

function Outfits:LoadRobloxOutfits()
	if self.LoadedRobloxOutfits then
		return
	end

	local stateOutfits = self.Outfits:get()

	local robloxOutfits = AvatarEditorService:GetOutfits(Enum.OutfitSource.Created)
	local isFinished = false
	while not isFinished do
		local page = robloxOutfits:GetCurrentPage()
		local outfitPromises = {}

		for _, outfit in page do
			if not outfit.IsEditable then
				continue
			end

			table.insert(outfitPromises, Promise.new(function (resolve)
				local details = AvatarEditorService:GetOutfitDetails(outfit.Id)

				local popmallOutfit = {
					BodyColors = details.BodyColors
				}

				for _, asset in ipairs(details.Assets) do
					popmallOutfit[tostring(asset.Id)] = Utils.deepCopy(AvatarHandler.GetItemDataTable(asset.Id))

					if asset.Meta then
						popmallOutfit[tostring(asset.Id)].Order = asset.Meta.Order
					end
				end

				stateOutfits[tostring(outfit.Id)] = {
					isRoblox = Value(true),
					data = popmallOutfit,
					id = tostring(outfit.Id)
				}
				self.Outfits:set(stateOutfits)

				resolve()
			end))
		end

		Promise.all(outfitPromises)
			:andThen(function()
				self.Controllers.AvatarPreviewController:UpdateSaveButton()
				-- self.Outfits:set(stateOutfits)
			end)
			:catch(warn)
		
		isFinished = robloxOutfits.IsFinished
		if not isFinished then
			robloxOutfits:AdvanceToNextPageAsync()
		end
	end

	self.LoadedRobloxOutfits = true
end

function Outfits:Enable()
	self.Controllers.TopBarController:ResetSearchBar()
	self.Controllers.OutfitFeedController:Disable()

	task.spawn(function()
		if (InventoryHandler.hasAccess() or not self.RequestPermFailed) and not self.LoadedRobloxOutfits then
			self.RequestPermFailed = not InventoryHandler.requestAccess()
	
			if not self.RequestPermFailed then
				self:LoadRobloxOutfits()
			end
		end
	end)
end

function Outfits:Disable()
end

return Outfits
