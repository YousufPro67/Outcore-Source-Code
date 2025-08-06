local BloxbizSDK = script.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local _UIScaler = require(UtilsStorage:WaitForChild("UIScaler"))
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

export type Button = { Instance: GuiButton, EnabledValue: Fusion.Value<boolean> }

export type CatalogChanges = {
	__index: CatalogChanges,
	new: (button: { Instance: GuiButton, EnabledValue: Fusion.Value<boolean> }) -> CatalogChanges,

	Changes: {},
	Button: Button,

	GetLatestChange: (self: CatalogChanges) -> (),
	AddChange: (self: CatalogChanges) -> (),
	RemoveLatestChange: (self: CatalogChanges, change: any) -> (),
	DropChanges: (self: CatalogChanges) -> (),
	BindFunction: (self: CatalogChanges, callback: () -> ()) -> (),
}

local CatalogChanges = {}
CatalogChanges.__index = CatalogChanges

function CatalogChanges.new(): CatalogChanges
	local self = setmetatable({}, CatalogChanges)

	self.Changes = Fusion.Value({})

	return self
end

function CatalogChanges:GetLatestChange()
	local changes = self.Changes:get()

	return changes[#changes]
end

function CatalogChanges:AddChange(change: any)
	local changes = self.Changes:get()
	table.insert(changes, change)
	self.Changes:set(changes)
end

function CatalogChanges:RemoveLatestChange()
	local changes = self.Changes:get()
	changes[#changes] = nil
	self.Changes:set(changes)
end

function CatalogChanges:DropChanges()
	self.Changes:set({})
end

return CatalogChanges
