local BloxbizSDK = script.Parent.Parent.Parent
local CatalogClient = BloxbizSDK.CatalogClient

local Classes = CatalogClient.Classes
local InventoryModule = require(Classes:WaitForChild("InventoryHandler"))

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local Value = Fusion.Value

local Navigation = {}
Navigation.__index = Navigation

function Navigation.new()
    local self = setmetatable({}, Navigation)

    self.Enabled = Value({})
    self.Controllers = {}

    return self
end

function Navigation:Init(controllers)
    self.Controllers = controllers

    local enabledMap = {}
    for name, controller in pairs(controllers) do
        if controller.Enable and controller.Disable then
            enabledMap[name] = false
        end
    end

    self.Enabled:set(enabledMap)
end

function Navigation:GetEnabledComputed(name)
    if not Utils.endsWith(name, "Controller") then
        name ..= "Controller"
    end

    return Fusion.Computed(function()
        local enabledMap = self.Enabled:get()
        return not not enabledMap[name]
    end)
end

function Navigation:UpdateEnabled(name, value)
    local enabledMap = Utils.deepCopy(self.Enabled:get())
    enabledMap[name] = value
    self.Enabled:set(enabledMap)
end

function Navigation:SwitchTo(controllerName)
    if (not self.Controllers[controllerName]) and self.Controllers[controllerName .. "Controller"] then
        controllerName ..= "Controller"
    end

    for name, _ in pairs(self.Enabled:get()) do
        if name ~= controllerName then
            self.Controllers[name]:Disable()
        end
    end

    if not table.find({"ShopFeedController", "OutfitFeedController",  "CategoryController"}, controllerName) then
        self.Controllers.TopBarController:Reset()
    end

    self.Controllers[controllerName]:Enable()
end

return Navigation