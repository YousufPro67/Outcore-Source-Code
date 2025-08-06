return function()
	local PurchaseService = require(script.Parent.parent.PurchaseService)

	describe("PurchaseService", function()
		describe("getPurchaseItems", function()
			local configPurchaseItems = {
				subscriptions = {
					SUBSCRIPTION = {
						"258764001",
						"270955546",
					},
					TEST = {
						"123443123",
					},
				},
				radioBundles = {
					SUBSCRIPTION_RADIO_TIME_BUNDLE_FREE = {
						"269109337",
					},
					TEST = {
						"123443123",
					},
				},
			}
			local availablePurchaseItems = {
				subscriptions = {
					{ ["name"] = "SUBSCRIPTION" },
				},
				radioBundles = {
					{ ["name"] = "SUBSCRIPTION_RADIO_TIME_BUNDLE_FREE" },
				},
			}
			local expectedPurchesItems = {
				subscriptions = {
					SUBSCRIPTION = {
						"258764001",
						"270955546",
					},
				},
				radioBundles = {
					SUBSCRIPTION_RADIO_TIME_BUNDLE_FREE = {
						"269109337",
					},
				},
			}

			it("should return table with available bundles and subscriptions only compared to purchaseTypes", function()
				local result = PurchaseService._getPurchaseItems(availablePurchaseItems, configPurchaseItems)

				expect(result.radioBundles["TEST"]).never.to.be.ok()
				expect(result.radioBundles["SUBSCRIPTION_RADIO_TIME_BUNDLE_FREE"][1]).to.equal(
					expectedPurchesItems.radioBundles["SUBSCRIPTION_RADIO_TIME_BUNDLE_FREE"][1]
				)
				expect(result.subscriptions["TEST"]).never.to.be.ok()
				expect(result.subscriptions["SUBSCRIPTION"][1]).to.equal(
					expectedPurchesItems.subscriptions["SUBSCRIPTION"][1]
				)
			end)
		end)
	end)
end
