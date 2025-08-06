local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Fusion = require(ReplicatedStorage.BloxbizSDK.Utils.Fusion)

local FeatureFlags = require(ReplicatedStorage.Styngr.FeatureFlags)

local showErrorToPlayer = require(script.Parent.Message)

local New = Fusion.New
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

local Passes = Fusion.Value({})

local function Item(props)
	local function _setTransactionId()
		local transactionId = ReplicatedStorage.Styngr.Purchase:InvokeServer(props.Id)

		if not transactionId then
			showErrorToPlayer("There was an issue in communication to the server. Please, try again later.")
			return
		end

		MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, props.Id)
	end

	return New("TextButton")({
		Size = UDim2.fromOffset(60, 60),
		Position = UDim2.fromOffset(0, 0),
		TextWrapped = true,

		Text = props.Name,

		[OnEvent("Activated")] = _setTransactionId,

		[Children] = {
			New("UICorner")({
				CornerRadius = UDim.new(0.167, 0),
			}),
		},
	})
end

local function getPass(passes)
	local userId = Players.LocalPlayer.UserId
	for _, id in passes do
		local asset = MarketplaceService:GetProductInfo(id, Enum.InfoType.GamePass)
		local hasPass = false
		local success, _ = pcall(function()
			hasPass = MarketplaceService:UserOwnsGamePassAsync(userId, id)
		end)

		if not success then
			continue
		end

		if not hasPass then
			return id, asset.Name
		end
	end

	return nil, nil
end

local function setPasses()
	local updatePasses = {}

	local purchaseItems = ReplicatedStorage.Styngr.GetPurchaseItems:InvokeServer()

	for _, purchaseItem in purchaseItems do
		for _, productIds in purchaseItem do
			local id, name = getPass(productIds)

			if id then
				table.insert(updatePasses, { id = id, name = name })
				break
			end
		end
	end

	Passes:set(updatePasses)
end

local function Purchase()
	local Items = Fusion.Computed(function()
		local items = {}

		for _, pass in Passes:get() do
			table.insert(
				items,
				Item({
					["Id"] = pass.id,
					["Name"] = pass.name,
				})
			)
		end

		return items
	end, Fusion.cleanup)

	return New("Frame")({
		Name = "Purchase",
		BackgroundColor3 = Color3.fromRGB(34, 34, 34),
		Size = UDim2.fromOffset(200, 200),
		Position = UDim2.fromOffset(0, 0),

		[Children] = {
			New("UIListLayout")({
				Name = "UIListLayout",
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Items,
		},
	})
end

if FeatureFlags.radioPayments then
	setPasses()

	ReplicatedStorage.Styngr.PurchaseEvent.OnClientEvent:Connect(function()
		setPasses()
	end)
end

return Purchase
