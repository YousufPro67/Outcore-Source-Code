--!strict
local HttpService = game:GetService("HttpService")

local URL_ENDPOINT = "&Limit=30&Category=%s&Subcategory=%s&SortType=%s"

local Utils = require(script.Parent.Parent.Utils)
local merge = Utils.merge

type Info = {
	name: string,
	query: {
		Category: number?,
		Subcategory: number?,
		AssetTypeId: number?,
	},
}

type ItemData = {
	Name: string,
	Price: number,
	AssetId: number,
	AssetType: number,
	IsForSale: boolean,
	IsLimited: number,

	Available: number,
	Purchased: number,

	--For testing purposes
	DataSource: string?,
}

type BundleData = {
	Name: string,
	Price: number,
	BundleId: number,
	BundleType: string,
}

type Items = {
	[number]: { BundleData | ItemData },
}

export type Page = {
	Items: Items,
	NextPageCursor: string,
}

export type Category = {
	__index: Category,

	new: (Info) -> Category,
	RequestPage: (
		self: Category,
		player: Player,
		pages: { [number]: any },
		pageNum: number,
		sortType: string?
	) -> Page?,
	GetSortedPage: (self: Category, player: Player, pageNum: number, sortType: string) -> Page?,
	GetNormalPage: (self: Category, player: Player, pageNum: number) -> Page?,
	GetItems: (self: Category, player: Player, pageNum: number, sortType: string?) -> Items?,

	Name: string,
	CategoryId: number?,
	SubcategoryId: number?,

	Pages: { Page? },
	SortedPages: { [string]: { Page? } },
}

---------------------------
---[[PRIVATE INTERFACE]]---
---------------------------

local function BuildAssetData(item): ItemData?
	if not item.assetType then
		return
	end

	local limitedType = 0

	if table.find(item.itemRestrictions, "LimitedUnique") or table.find(item.itemRestrictions, "Collectible") then
		limitedType = 1
	elseif table.find(item.itemRestrictions, "Limited") then
		limitedType = 2
	end

	return {
		Name = item.name,
		Price = item.lowestPrice or item.price,
		AssetId = item.id,
		AssetType = item.assetType,
		IsForSale = item.priceStatus ~= "Offsale",
		IsLimited = limitedType,

		Available = item.unitsAvailableForConsumption,
		Purchased = item.purchaseCount,
	}
end

local function BuildBundleData(item): BundleData?
	if not item.bundleType then
		return
	end

	return {
		Name = item.name,
		Price = item.lowestPrice or item.price,
		BundleId = item.id,
		BundleType = item.bundleType,
	}
end

--@desc: Data reference: https://create.roblox.com/docs/studio/catalog-api#query-parameters
local function DownloadPage(player: Player, url: string): (Items, string)
	local AdRequestStats = require(script.Parent.Parent.AdRequestStats)

	local gameStats = AdRequestStats:getGameStats()
	local playerStats = AdRequestStats:getPlayerStats(player)
	local clientPlayerStats = AdRequestStats:getClientPlayerStats(player)

	local data = merge(merge(gameStats, playerStats), clientPlayerStats)
	data = HttpService:JSONEncode(data)

	local Response = HttpService:PostAsync(url, data, Enum.HttpContentType.ApplicationJson)
	local Data = HttpService:JSONDecode(Response)

	local items: Items = {}
	local nextPageCursor = Data.nextPageCursor

	for _, itemData: { [string]: any } in Data.data do
		local data: BundleData | ItemData | nil
		if itemData.itemType == "Asset" then
			data = BuildAssetData(itemData)
		else
			data = BuildBundleData(itemData)
		end

		if data then
			table.insert(items, data)
		end
	end

	return items, nextPageCursor
end

---------------------------
---[[PUBLIC  INTERFACE]]---
---------------------------

local CategoryClass = {} :: Category
CategoryClass.__index = CategoryClass

function CategoryClass.new(info: Info): Category
	local self: Category = setmetatable({} :: any, CategoryClass)

	self.Name = info.name
	self.CategoryId = info.query.Category
	self.SubcategoryId = info.query.Subcategory

	self.Pages = {}
	self.SortedPages = {}

	return self
end

function CategoryClass:RequestPage(player: Player, pages: { [number]: any }, pageNum: number, sortType: string?): Page?
	if self.CategoryId == "ShopsFeed" then
		return
	end

	local BatchHTTP = require(script.Parent.Parent.BatchHTTP)

	local baseUrl = BatchHTTP.getNewUrl("catalog/proxy")
	baseUrl = baseUrl .. URL_ENDPOINT

	local newUrl = baseUrl:format(self.CategoryId, self.SubcategoryId or "", sortType or "")

	local items, nextPageCursor

	local previousPage = pages[pageNum - 1]
	if previousPage then
		if not previousPage.NextPageCursor then
			return
		end

		items, nextPageCursor = DownloadPage(player, newUrl .. "&Cursor=" .. previousPage.NextPageCursor)
	else
		if pageNum > 1 then
			return
		end
		items, nextPageCursor = DownloadPage(player, newUrl)
	end

	local page = {
		Items = items,
		NextPageCursor = nextPageCursor,
	}

	return page
end

function CategoryClass:GetSortedPage(player: Player, pageNum: number, sortType: string): Page?
	local pages = self.SortedPages[sortType]
	if not pages then
		self.SortedPages[sortType] = {}
		pages = self.SortedPages[sortType]
	end

	local page = pages[pageNum]
	if not page then
		page = self:RequestPage(player, pages, pageNum, sortType)
		pages[pageNum] = page
	end

	return page
end

function CategoryClass:GetNormalPage(player: Player, pageNum: number): Page?
	local page = self.Pages[pageNum]
	if not page then
		page = self:RequestPage(player, self.Pages, pageNum)
		self.Pages[pageNum] = page
	end

	return page
end

function CategoryClass:GetItems(player: Player, pageNum: number, sortType: string?): Items?
	local page
	if sortType then
		page = self:GetSortedPage(player, pageNum, sortType)
	else
		page = self:GetNormalPage(player, pageNum)
	end

	return page and page.Items or nil
end

return CategoryClass
