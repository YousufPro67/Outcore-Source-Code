local Gui = script.Parent.Parent

local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Cleanup = Fusion.Cleanup
local Children = Fusion.Children

return function(props)
	return New("ScreenGui")({
		Name = props.Name,
		Enabled = props.Enabled,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
		DisplayOrder = props.DisplayOrder,

		[Cleanup] = props.Cleanup,
		[Children] = props.Children,
	})
end
