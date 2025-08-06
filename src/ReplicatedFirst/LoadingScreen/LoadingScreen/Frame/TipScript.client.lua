local tips = {
	"Change speed in settings.",
	"Make sure to check settings for anything you need.",
	"New dimensions coming soon.",
	"This game was inspired by karlson.",
	"This game was a solo project.",
	"Wallrunning might be the hardest part of this game.",
	"Make sure to not skip anything in tutorials",
	"Support me for later updates, by donating or contacting me.",
	"Join my discord server for updates, bugs and more."
}

local o1 = script.Parent.Tips
local o2 = script.Parent.Tips2

local transparency = 0.4

local ts = game:GetService("TweenService")
local ti = TweenInfo.new(1.5)

local tweeno1 = ts:Create(o1, ti, {TextTransparency = transparency})
local tweeno2 = ts:Create(o2, ti, {TextTransparency = transparency})

local tweeni1 = ts:Create(o1, ti, {TextTransparency = 1})
local tweeni2 = ts:Create(o2, ti, {TextTransparency = 1})

while true do
	tweeni2:Play()
	tweeni2.Completed:Wait()
	o1.Text = tips[math.random(1, #tips)]
	tweeno1:Play()
	tweeno1.Completed:Wait()
	o2.Text = tips[math.random(1, #tips)]
	tweeni1:Play()
	tweeni1.Completed:Wait()
	tweeno2:Play()
	tweeno2.Completed:Wait()
end