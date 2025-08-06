--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")
local OnItemsPageRequest = BloxbizRemotes:WaitForChild("CatalogOnItemsPageRequest") :: RemoteFunction

local Classes = script.Parent.Parent.Parent.Classes
local AvatarHandler = require(Classes.AvatarHandler)

export type ItemData = AvatarHandler.ItemData

export type BundleData = AvatarHandler.BundleData

type Info = {
	name: string,
	query: {
		Category: number?,
		Subcategory: number?,
	},
}

export type Category = {
	__index: Category,

	new: (Info) -> Category,
	RequestPage: (self: Category, pageNum: number, sortType: number?) -> { ItemData & BundleData }?,
	GetSortedPage: (self: Category, pageNum: number, sortType: number) -> { ItemData & BundleData }?,
	GetNormalPage: (self: Category, pageNum: number) -> { ItemData & BundleData }?,
	GetItems: (self: Category, pageNum: number, sortType: number?) -> { ItemData & BundleData }?,

	Name: string,

	Pages: { { ItemData & BundleData }? },
	SortedPages: { [number]: { { ItemData & BundleData }? } },
}

local CategoryLoader = {} :: Category
CategoryLoader.__index = CategoryLoader

function CategoryLoader.new(info: Info): Category
	local self: Category = setmetatable({} :: any, CategoryLoader)

	self.Name = info.name
	self.Pages = {}
	self.SortedPages = {}

	return self
end

function CategoryLoader:RequestPage(pageNum: number, sortType: number?): { ItemData & BundleData }?
	local items = OnItemsPageRequest:InvokeServer({
		Page = pageNum,
		SortType = sortType,
		Category = self.Name,
	})

	return items
end

function CategoryLoader:GetSortedPage(pageNum: number, sortType: number): { ItemData & BundleData }?
	local pages = self.SortedPages[sortType]
	if not pages then
		self.SortedPages[sortType] = {}
		pages = self.SortedPages[sortType]
	end

	if not pages[pageNum] then
		pages[pageNum] = self:RequestPage(pageNum, sortType)
	end

	return pages[pageNum]
end

function CategoryLoader:GetNormalPage(pageNum: number): { ItemData & BundleData }?
	if not self.Pages[pageNum] then
		self.Pages[pageNum] = self:RequestPage(pageNum)
	end

	return self.Pages[pageNum]
end

function CategoryLoader:GetItems(pageNum: number, sortType: number?): { ItemData & BundleData }?
	if sortType then
		return self:GetSortedPage(pageNum, sortType)
	else
		return self:GetNormalPage(pageNum)
	end
end

return CategoryLoader
