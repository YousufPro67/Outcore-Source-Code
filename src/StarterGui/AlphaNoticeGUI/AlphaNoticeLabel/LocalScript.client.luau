local TweenService = game:GetService("TweenService")
local blur = Instance.new("BlurEffect")
blur.Size = 50
blur.Parent = game.Lighting
blur.Name = "AlphaBlur"

local noticeLabel = script.Parent
noticeLabel.Text =
	"<font size='26' color='#FF8C00'><b>ALPHA NOTICE</b></font><br>" ..
	"<font size='20' color='#CCCCCC'>" ..
	"This game is currently in its alpha stage and is subject to change. You may encounter bugs — if you do, please report them in my Discord server before rejoining the game. " ..
	"As a solo developer, I am committed to improving the experience, fixing issues, and adding new content. " ..
	"The full release will include additional <font color='#FFB347'>dimensions</font>, new <font color='#FFB347'>game modes</font> (such as City Mode and multiplayer), and more. " ..
	"Please note that all player data will be <font color='#FF4444'>reset</font> once the game enters live production." ..
	"</font></br>"

-- Fade-in animation
task.wait(3)

local ct = TweenService:Create(
	script.Parent.Parent.CText,
	TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
	{ TextTransparency = 0 }
)
ct:Play()
ct.Completed:Wait()

script.Parent.Parent.Continue.Active = true


script.Parent.Parent.Continue.Activated:Connect(function()
	script.Parent.Parent.Continue:Destroy()
	TweenService:Create(
		noticeLabel,
		TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ TextTransparency = 1 }
	):Play()
	TweenService:Create(
		script.Parent.Parent.Frame,
		TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	):Play()
	TweenService:Create(
		script.Parent.Parent.CText,
		TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ TextTransparency = 1 }
	):Play()
	TweenService:Create(
		blur,
		TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ Size = 0 }
	):Play()
	task.wait(1)
	blur:Destroy()
	script.Parent.Parent:Destroy()
end)
-- Client script for Alpha Notice GUI

