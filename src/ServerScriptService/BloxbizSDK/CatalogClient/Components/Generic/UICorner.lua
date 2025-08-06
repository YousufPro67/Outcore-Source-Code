--!strict
local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

return function(radius: number?): Instance
	return Fusion.New("UICorner")({
		CornerRadius = UDim.new(0, radius or 16),
	})
end
