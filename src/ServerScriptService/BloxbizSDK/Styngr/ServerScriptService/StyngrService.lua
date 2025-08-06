local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FeatureFlags = require(ReplicatedStorage.Styngr.FeatureFlags)

local CloudService = require(script.Parent.Modules.CloudService)
local ErrorService = require(script.Parent.Modules.ErrorService)
local PurchaseService = require(script.Parent.Modules.PurchaseService)
local RadioService = require(script.Parent.Modules.RadioService)
local Types = require(script.Parent.Types)

local StyngrService = {}

function StyngrService:init(configuration: Types.CloudServiceConfiguration)
	local cloudService = CloudService.New(configuration)

	RadioService:SetConfiguration(cloudService, configuration)
	ErrorService:Init(cloudService)

	if FeatureFlags.radioPayments then
		PurchaseService:SetConfiguration(cloudService, configuration)
	end
end

return StyngrService
