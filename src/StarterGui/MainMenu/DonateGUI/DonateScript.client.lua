local MarketplaceService = game:GetService("MarketplaceService")
local button = script.Parent.UI.ScrollingFrame.TextButton
local developerProducts = MarketplaceService:GetDeveloperProductsAsync():GetCurrentPage()
local x = script.Parent.UI.Close

for _, developerProduct in pairs(developerProducts) do
	local new = button:Clone()
	new.Name = developerProduct.Name
	new.Text = developerProduct.PriceInRobux
	new.Parent = script.Parent.UI.ScrollingFrame
	new.ZIndex = developerProduct.PriceInRobux
	new.Activated:Connect(function()
		MarketplaceService:PromptProductPurchase(game.Players.LocalPlayer, developerProduct.ProductId)
	end)
end

button:Destroy()

x.MouseButton1Click:Connect(function()
	script.Parent.Enabled = false
	local uiblur = game.Lighting.SecondaryGUIBlur :: BlurEffect
	uiblur.Enabled = false
	x.TextColor3 = Color3.new(1, 1, 1)
end)

