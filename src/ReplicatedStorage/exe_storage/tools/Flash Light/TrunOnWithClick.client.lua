script.Parent.Activated:Connect(function()
	if script.Parent.Handle.SpotLight.Enabled == true then
		script.Parent.Handle.SpotLight.Enabled = false
		script.Parent.Handle.Sound:Play()
	else
		script.Parent.Handle.SpotLight.Enabled = true
		script.Parent.Handle.Sound:Play()
	end
end)
script.Parent.Equipped:Connect(function()
	script.Parent.Handle.SpotLight.Enabled = false
	script.Parent.Handle.equip:Play()
end)
script.Parent.Unequipped:Connect(function()
	script.Parent.Handle.equip:Play()
end)
--Scriped by fabsili2020_DE :D