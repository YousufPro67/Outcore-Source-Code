local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local AvatarEditorService = game:GetService("AvatarEditorService")

local BloxbizSDK = script.Parent.Parent.Parent
local ConfigReader = require(BloxbizSDK:WaitForChild("ConfigReader"))
local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Promise = require(UtilsStorage:WaitForChild("Promise"))
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")
local PromptPurchaseRemote, PromptPurchaseOutfit, CatalogItemPromptEvent

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent
local ForValues = Fusion.ForValues

local CatalogClient = BloxbizSDK:WaitForChild("CatalogClient")
local Components = CatalogClient.Components
local ScaledText = require(Components.ScaledText)
local LoadingFrame = require(Components.LoadingFrame)
local ItemGrid = require(Components.ItemGrid)

local Modal = require(script.Modal)
local Item = require(script.Item)

local BODY_PART_IDs = {
	27, 28, 29, 30, 31,  -- body parts
	79  -- dynamic head
}

local BuyOutfit = {}
BuyOutfit.__index = BuyOutfit

function BuyOutfit.new(coreContainer: Frame)
	local self = setmetatable({}, BuyOutfit)

	self.Container = coreContainer

	self.Outfit = Value(nil)
	self.Error = Value(nil)
	self.Loading = Computed(function()
		local outfit = self.Outfit:get()
		local err = self.Error:get()

		return not (outfit or err)
	end)

	PromptPurchaseRemote = BloxbizRemotes:WaitForChild("CatalogOnPromptPurchase")
	CatalogItemPromptEvent = BloxbizRemotes:WaitForChild("catalogItemPromptEvent")
	PromptPurchaseOutfit = BloxbizRemotes:WaitForChild("CatalogOnPromptPurchaseOutfit")

	return self
end

function BuyOutfit:Init(controllers: { [string]: { any } })
	self.Controllers = controllers
	self.Enabled = self.Controllers.NavigationController:GetEnabledComputed("BuyOutfitController")

	local topBarHeight = self.Controllers.TopBarController.TopBarHeight
	local paddingPX = Computed(function()
		return topBarHeight:get() / 1.5
	end)
	local padding = Computed(function()
		return UDim.new(0, paddingPX:get())
	end)

	self.Modal = Modal {
		Parent = self.Container,
		Visible = self.Enabled,
		SizeStandard = topBarHeight,
		OnClose = function ()
			self:Disable()
		end,

		RemainingPrice = Computed(function()
			return Utils.sum(self.Outfit:get(), function (item)
				return item.Purchased and 0 or (item.Price or 0)
			end)
		end),
		TotalPrice = Computed(function()
			return Utils.sum(self.Outfit:get(), function (item)
				return item.Price or 0
			end)
		end),
		RemainingItems = Computed(function()
			return Utils.count(self.Outfit:get(), function (item)
				return item.IsForSale and not item.Purchased
			end)
		end),
		TotalItems = Computed(function()
			return Utils.count(self.Outfit:get(), function () return true end)
		end),

		[Children] = {
			LoadingFrame {
				Visible = self.Loading,
				Size = UDim2.fromScale(1, 1)
			},

			ItemGrid {
				Gap = 5,
				Columns = 3,
				Visible = Computed(function()
					return not self.Loading:get() and not self.Error:get()
				end),
				ItemRatio = 4/5,

				[Children] = ForValues(Computed(function()
					return self.Outfit:get() or {}
				end), function (itemDetails)
					local layoutOrder = itemDetails.Price or 0

					if itemDetails.Purchased then
						layoutOrder += 10^8
					end
					if not itemDetails.IsForSale then
						layoutOrder = math.huge
					end

					local isBundle = itemDetails.BundleId ~= nil

					return Item {
						AssetId = itemDetails.AssetId or itemDetails.BundleId,
						IsBundle = isBundle,
						IsPurchased = itemDetails.Purchased,
						IsForSale = itemDetails.IsForSale,
						Price = itemDetails.Price or 0,
						Name = itemDetails.Name,
						LayoutOrder = layoutOrder,

						OnClick = function()
							CatalogItemPromptEvent:FireServer("Buy Outfit")
							PromptPurchaseRemote:InvokeServer(itemDetails.AssetId or itemDetails.BundleId, isBundle)

							local purchased
							if isBundle then
								_, _, purchased = MarketplaceService.PromptBundlePurchaseFinished:Wait()
							else
								_, _, purchased = MarketplaceService.PromptPurchaseFinished:Wait()
							end

							if purchased then
								local items = Utils.deepCopy(self.Outfit:get())
								items[tostring(itemDetails.AssetId or itemDetails.BundleId)].Purchased = true
								self.Outfit:set(items)
							end
						end
					}
				end, Fusion.cleanup)
			}
		}
	}
end

function BuyOutfit:GetBundleName(itemDetails)
	local bundleName = itemDetails.Name
	bundleName = bundleName:split(" - ")[1]

	for _, suffix in ipairs({"Dynamic Head", "Head", "Torso", "Left Leg", "Left Arm", "Right Leg", "Right Arm"}) do
		bundleName = Utils.strip(bundleName, " " .. suffix)
	end

	return bundleName
end

function BuyOutfit:FindBundle(bundleName, targetItems)
	-- attempt to find a parent bundle based on a name and the target items
	-- many bundles share names so this could end up being multiple bundles!

	local bundleResults = {}

	local searchParams = CatalogSearchParams.new()
	searchParams.BundleTypes = {Enum.BundleType.DynamicHead, Enum.BundleType.DynamicHeadAvatar, Enum.BundleType.BodyParts}
	searchParams.SearchKeyword = bundleName

	local pages = AvatarEditorService:SearchCatalog(searchParams)

	local page = pages:GetCurrentPage()

	for _, bundle in ipairs(page) do
		local success, bundleDetails = pcall(function()
			return AvatarEditorService:GetItemDetails(bundle.Id, Enum.AvatarItemType.Bundle)
		end)

		if success then
			local bundleItems = bundleDetails.BundledItems

			local targetedItems = Utils.filter(bundleItems or {}, function (item)
				return targetItems[tostring(item.Id)] ~= nil
			end)

			if #targetedItems > 0 then
				bundleResults[tostring(bundle.Id)] = {
					BundleId = bundle.Id,
					IsForSale = bundleDetails.IsPurchasable,
					Price = bundleDetails.Price,
					Name = bundleDetails.Name,
					Purchased = bundleDetails.Owned
				}

				for _, item in ipairs(bundleItems) do
					targetItems[tostring(item.Id)] = nil
				end

				if Utils.getArraySize(targetItems) == 0 then
					break
				end
			end
		else
			Utils.debug_warn(bundleDetails)
		end
	end

	return bundleResults
end

function BuyOutfit:Enable()
end

function BuyOutfit:Disable()
	self.Outfit:set(nil)
	self.Error:set(nil)
end

function BuyOutfit:OnClose()
	self:Disable()
end

function BuyOutfit:GetCurrentOufit()
	local currentOutfit = Utils.deepCopy(self.Controllers.AvatarPreviewController.EquippedItems:get())
	currentOutfit.BodyColors = nil

	-- check item ownership and filter out body parts
	local bundleItems = {}
	local ownershipPromises = {}
	for id, itemInfo in pairs(currentOutfit) do
		if table.find(BODY_PART_IDs, itemInfo.AssetType) then
			local bundleName = self:GetBundleName(itemInfo)
			bundleItems[bundleName] = bundleItems[bundleName] or {}
			bundleItems[bundleName][id] = itemInfo

			currentOutfit[id] = nil
			continue
		end

		itemInfo.Purchased = itemInfo.Purchased > 0
		if itemInfo.Price == nil or itemInfo.Quantity == 0 then
			-- price is 0 for free items, if price is nil then the item is a member of a bundle and cant be purchased individually, for ex body parts
			itemInfo.IsForSale = false
		end
		
		if not itemInfo.Purchased then
			table.insert(ownershipPromises, Promise.new(function (resolve)
				local success, isOwned = pcall(function()
					return MarketplaceService:PlayerOwnsAsset(Players.LocalPlayer, itemInfo.AssetId)
				end)

				if success and isOwned then
					currentOutfit[id].Purchased = true
				end

				resolve()
			end))
		end
	end

	-- Promise.all(ownershipPromises):await()

	for k, v in pairs(bundleItems) do
		local result = self:FindBundle(k, v)
		currentOutfit = Utils.merge(currentOutfit, result)
	end

	return currentOutfit
end

function BuyOutfit:PromptBulkPurchase()
	PromptPurchaseOutfit:InvokeServer(self:GetCurrentOufit())
end

function BuyOutfit:ShowModal()
	if self.Enabled:get() then
		self:Disable()
		return
	end

	self.Outfit:set(nil)
	self:Enable()

	self.Outfit:set(self:GetCurrentOufit())
end

return BuyOutfit