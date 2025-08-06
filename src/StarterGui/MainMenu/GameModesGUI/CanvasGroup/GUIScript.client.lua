local buttons = nil
local ts = game:GetService("TweenService")
local CurrentButton = nil
local Modes = {
	["STORY MODE"] = {Name = "STORY MODE", ImageID = "rbxassetid://132072861772725", Link = ""},
	["RACE"] =       {Name = "RACE", ImageID = "rbxassetid://19006051974", Link = ""},
	["CITY MODE"] =  {Name = "CITY MODE", ImageID = "rbxassetid://19006052513", Link = ""}
}

function ButtonStyles(button:TextButton)
	if button:IsA("TextButton") then
		local paddingr = UDim.new(0.4,0)
		local paddingl = UDim.new(0.15,0)
		local newpaddingr = UDim.new(0.3,0)
		local newpaddingl = UDim.new(0.25,0)
		local THover = Color3.fromRGB(255,132,10)
		
		local buttonhover = game.ReplicatedStorage.SFX.ButtonHover
		local buttonactive = game.ReplicatedStorage.SFX.ButtonActive
		
		local tinfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine)
		local ti = ts:Create(button.UIPadding, tinfo, {PaddingLeft = newpaddingl, PaddingRight = newpaddingr})
		local to = ts:Create(button.UIPadding, tinfo, {PaddingLeft = paddingl, PaddingRight = paddingr})
		local ti2 = ts:Create(button.TextLabel, tinfo, {TextColor3 = THover})
		local to2 = ts:Create(button.TextLabel, tinfo, {TextColor3 = Color3.new(1,1,1)})
		
		button.MouseEnter:Connect(function()
			ti:Play()
			ti2:Play()
			buttonhover:Play()
		end)
		button.MouseLeave:Connect(function()
			to:Play()
			to2:Play()
		end)
		button.MouseButton1Click:Connect(function()
			buttonactive:Play()
			button.Parent.Parent.Frame.ImageLabel.Image = button:GetAttribute("ImageID")
			button.BackgroundTransparency = 0.7
			CurrentButton = button
			button.Parent.Parent.Frame.ImageLabel.TextLabel.Visible = true
			for _,b in buttons do
				if b:IsA("TextButton") and b ~= button then
					b.BackgroundTransparency = 1
				end
			end
		end)
	end
end

function CreateButton(Name, ImageID, Link)
	local button = script.Parent.Frame.j.CanvasGroup.ScrollingFrame.TextButton
	local bclone = button:Clone()
	bclone.TextLabel.Text = Name
	bclone.Name = Name
	bclone.Parent = button.Parent
	bclone:SetAttribute("ImageID", ImageID)
	bclone:SetAttribute("Link", Link)
end

for _,mode in Modes do
	CreateButton(mode.Name, mode.ImageID)	
end
script.Parent.Frame.j.CanvasGroup.ScrollingFrame.TextButton:Destroy()
buttons = script.Parent.Frame.j.CanvasGroup.ScrollingFrame:GetChildren()

for _,button in buttons do
	if button:IsA("TextButton") then
		ButtonStyles(button)
	end
end