local Slider = script.Parent.Input.Slider
local Switch = script.Parent.Input.Switch
local TextFrame = script.Parent.Text
local InputFrame = script.Parent.Input
local TemplateText = TextFrame.TEXT
local Separator = TextFrame.Separator
local SeparatorGhost = InputFrame.Separator

local function MakeSetting(Name: string, SettingName: string, Type: string, Min: number, Max: number, DecimalPoints: number): ()
	if Type ~= "Separator" then
		local SettingText = TemplateText:Clone()
		SettingText.Text = Name
		SettingText.Parent = TextFrame -- Add text label to the TextFrame
	end
	
	if Type == "Slider" then
		local NewSlider = Slider:Clone()
		NewSlider.Name = Name
		NewSlider.Slider:SetAttribute("Min", Min)
		NewSlider.Slider:SetAttribute("Max", Max)
		NewSlider.Slider:SetAttribute("Setting", SettingName)
		NewSlider.Slider:SetAttribute("DecimalPoints", DecimalPoints)
		NewSlider.Parent = InputFrame -- Add slider to the InputFrame
	elseif Type == "Switch" then
		local NewSwitch = Switch:Clone()
		NewSwitch.Name = Name
		NewSwitch.Switch:SetAttribute("Setting", SettingName)
		NewSwitch.Parent = InputFrame -- Add switch to the InputFrame
	elseif Type == "Separator" then
		local newSeparator = Separator:Clone()
		local newSeparatorGhost = SeparatorGhost:Clone()
		newSeparator.Name = Name
		newSeparator.Parent = TextFrame
		newSeparatorGhost.Name = Name
		newSeparatorGhost.Parent = InputFrame
		newSeparator.TextLabel.Text = Name
	end
end

MakeSetting("GRAPHICS", nil, "Separator")
MakeSetting("CLOCK TIME", "CLOCK_TIME", "Slider", 0, 23.9, 1)
MakeSetting("EXPOSURE", "EXPOSURE_COMPENSATION", "Slider", -3, 3, 2)
MakeSetting("BRIGHTNESS", "BRIGHTNESS", "Slider", 0, 50, 1)
MakeSetting("CAMERA SHAKE", "CAMERA_SHAKE", "Switch")
MakeSetting("SHADOWS", "SHADOWS", "Switch")

MakeSetting("MISC", nil, "Separator")
MakeSetting("SPEED", "SPEED", "Slider", 100, 200, 0)
MakeSetting("SPEEDLINES", "SHOW_SPEEDLINES", "Switch")
MakeSetting("SHOW BODY", "SHOW_BODY", "Switch")
MakeSetting("MAX FOV", "FOV", "Slider", 1, 120, 0)
MakeSetting("MUSIC", "MUSIC", "Slider", 0, 100, 0)
MakeSetting("SFX", "SFX", "Slider", 0, 100, 0)

local userid = game.Players.LocalPlayer.UserId

if userid == 4142124115 or userid == 1863746978 or userid == 4020495744 or userid == 5043465441 or userid == 5217760304 or userid == 2956507573 then
	MakeSetting("ADMIN ONLY", nil, "Separator")
	MakeSetting("LEVELS", "LEVELS", "Slider", 1, 9, 0)
	MakeSetting("STUDS", "STUDS", "Slider", 0, 999999999, 0)
	MakeSetting("JUMPS", "JUMPS", "Slider", 0, 999999999, 0)
	MakeSetting("FINISHES", "FINISHES", "Slider", 0, 999999999, 0)
	MakeSetting("KILLS", "KILLS", "Slider", 0, 999999999, 0)
end

Slider:Destroy()
Switch:Destroy()
TemplateText:Destroy()
Separator:Destroy()
SeparatorGhost:Destroy()