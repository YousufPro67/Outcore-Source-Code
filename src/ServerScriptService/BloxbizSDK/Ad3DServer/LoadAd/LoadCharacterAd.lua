local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(script.Parent.Parent.Parent.Utils)
local RBLXSerialize = require(script.Parent.Parent.Parent.Utils.RBLXSerialize)

local AD_ASSETS_FOLDER = "Bloxbiz3DAdAssets"

local characterModelFolder = ReplicatedStorage:WaitForChild(AD_ASSETS_FOLDER)

return function(adToLoad)
	local character = characterModelFolder:FindFirstChild(adToLoad.bloxbiz_ad_id)

	if not character then
		local success, result = pcall(RBLXSerialize.Decode, adToLoad.ad_serialized_model)

		if success then
			result.Name = adToLoad.bloxbiz_ad_id

			for _, child in pairs(result:GetChildren()) do
				local customPositionPart = child:FindFirstChild("CustomCameraPositionPart")
				if customPositionPart then
					local CustomCameraCf = Instance.new("CFrameValue")
					CustomCameraCf.Name = "CustomCameraCf"
					CustomCameraCf.Value = result.PrimaryPart.CFrame:ToObjectSpace(customPositionPart.CFrame)
					CustomCameraCf.Parent = child
					customPositionPart:Destroy()
				end
			end

			for _, descendant in pairs(result:GetDescendants()) do
				if descendant:IsA("BasePart") and string.find(descendant.Name, "CanCollide") then
					local start, finish = string.find(descendant.Name, "CanCollide")
					descendant.CanCollide = true
					descendant.Name = string.sub(descendant.Name, 1, start - 1)
						.. string.sub(descendant.Name, finish + 1, #descendant.Name)
				elseif descendant:IsA("BasePart") then
					descendant.CanCollide = false
				elseif descendant.Name == "Adornee" then
					descendant.Parent.Adornee = result:FindFirstChild(descendant.Value, true)
				end
			end

			result.Parent = characterModelFolder
		else
			Utils.pprint("[SuperBiz] Error: " .. result)
		end
	end

	return character
end
