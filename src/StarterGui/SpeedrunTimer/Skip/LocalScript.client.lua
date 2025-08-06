local MS = game:GetService("MarketplaceService")
local Player = game.Players.LocalPlayer
local RE = game.ReplicatedStorage.RemoteEvents:WaitForChild("SkipStage")

-- Connect the purchase finished event once
MS.PromptProductPurchaseFinished:Connect(function(userId, productId, isPurchased)
	if userId == Player.UserId and productId == 3060460096 and isPurchased then
		RE:FireServer()
		print("done purchase") 
	end
end)

script.Parent.MouseButton1Click:Connect(function()
	print("prompting")
	MS:PromptProductPurchase(Player, 3060460096, false)
end)
