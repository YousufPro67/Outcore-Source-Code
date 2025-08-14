script.Parent.MouseButton1Click:Connect(function()
	script.Parent.Parent.Parent.Enabled = false
	local uiblur = game.Lighting.SecondaryGUIBlur :: BlurEffect
	uiblur.Enabled = false
end)