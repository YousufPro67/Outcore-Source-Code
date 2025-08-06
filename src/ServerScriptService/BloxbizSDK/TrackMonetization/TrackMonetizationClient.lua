local Tracker = {}

local MarketplaceService = game:GetService( "MarketplaceService" )
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local REMOTES_FOLDER = "BloxbizRemotes"

--[[
    Send to the server that client closed premium prompt
    Server can't detect which client closed prompt, only that a premium prompt was closed
]]
local function PremiumPrompt()
	local bloxbizFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER)
	local premiumPromptEvent = bloxbizFolder:WaitForChild("PremiumPromptEvent")
	premiumPromptEvent:FireServer()
end

MarketplaceService.PromptPremiumPurchaseFinished:Connect(PremiumPrompt)

return Tracker
