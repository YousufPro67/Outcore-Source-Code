local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BloxbizSDK = script.Parent.Parent.Parent

local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")
local OnGetFeatured = BloxbizRemotes:WaitForChild("CatalogOnGetFeatured")

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local New = Fusion.New
local Hydrate = Fusion.Hydrate
local Value = Fusion.Value
local Computed = Fusion.Computed

local Components = script.Parent.Parent.Components
local LoadingFrame = require(Components.LoadingFrame)

local BuildHomepage = require(script.BuildHomepage)

local Featured = {}
Featured.__index = Featured

function Featured.new(coreContainer)
    local self = setmetatable({}, Featured)

    self.CoreContainer = coreContainer
    self.Container = New "Frame" {
        Name = "FeaturedCategories",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Parent = self.CoreContainer.FrameContainer,
        Visible = false
    }

    self.Categories = Value({})
    self.Loading = Computed(function()
        return #(self.Categories:get() or {}) == 0
    end)

    Fusion.Observer(self.Categories):onChange(function()
        local categories = self.Categories:get()

        local thumbs = {}
        for _, category in ipairs(categories) do
            for _, item in ipairs(category.items) do
                local thumbType = item.itemType == "Asset" and "Asset" or "BundleThumbnail"
                local thumb = string.format("rbxthumb://type=%s&id=%s&w=420&h=420", thumbType, item.id)
                table.insert(thumbs, thumb)
            end
        end

        task.spawn(function()
            ContentProvider:PreloadAsync(thumbs)
        end)
    end)

    return self
end

function Featured:Init(controllers)
    self.Controllers = controllers
    self.Enabled = self.Controllers.NavigationController:GetEnabledComputed("FeaturedController")

    -- start loading categories

    task.spawn(function()
        local featured = OnGetFeatured:InvokeServer()
        self.Categories:set(featured)
    end)

    -- render componenets

    Hydrate(self.Container) {
        Visible = self.Enabled
    }

    LoadingFrame {
        Parent = self.Container,
        Visible = self.Loading
    }

    BuildHomepage(self)
end

function Featured:Enable()
    -- pass
end

function Featured:Disable()
    -- pass
end

return Featured