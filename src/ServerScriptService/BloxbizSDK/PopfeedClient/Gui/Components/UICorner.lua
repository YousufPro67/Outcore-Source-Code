local Gui = script.Parent.Parent

local Fusion = require(Gui.Parent.Parent.Utils.Fusion)
local New = Fusion.New

return function(props)
	return New("UICorner")({
		CornerRadius = UDim.new(0, props.Radius or 16),
	})
end
