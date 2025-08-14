local CP = game:GetService('ContentProvider')
local TS = game:GetService('TweenService')
local StarterGui = game:GetService("StarterGui")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local LocalPlayer = game.Players.LocalPlayer

local debounce = false
local gui = script.Parent.LoadingScreen:Clone()
local PText = gui.Frame.Loadinfo
local PBar = gui.Frame.Frame.CanvasGroup.LoadingBar
gui.Frame.CanvasGroup.Visible = false

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

if LocalPlayer.UserId == 1863746978 then
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
end

ReplicatedFirst:RemoveDefaultLoadingScreen()

repeat wait() until game:IsLoaded()

local blur = Instance.new("BlurEffect")
blur.Enabled = true
blur.Parent = game.Lighting
blur.Name = "LoadingBlur"
blur.Size = 56

local assets = game:GetDescendants()
local maxassets = #assets

gui.Parent = LocalPlayer.PlayerGui
local sstartime = tick()
gui.Frame.CanvasGroup.Skip.Activated:Once(function()
	local uit = TS:Create(gui.Frame, TweenInfo.new(2, Enum.EasingStyle.Sine), {GroupTransparency = 1})
	uit:Play()
	gui.Frame.TextButton:Destroy()
	task.wait(1)
	local blurt = TS:Create(blur,TweenInfo.new(2, Enum.EasingStyle.Sine),{Size = 0})
	blurt:Play()
	blurt.Completed:Wait()
	gui:Destroy()
	blur:Destroy()
	script:Destroy()
end)

-- Show skip button after 15 seconds using task.delay
task.delay(10, function()
	if not debounce then
		debounce = true
		gui.Frame.CanvasGroup.Visible = true
		TS:Create(gui.Frame.CanvasGroup,TweenInfo.new(0.5,Enum.EasingStyle.Sine),{GroupTransparency = 0}):Play()
	end
end)

for i, asset in ipairs(assets) do
	if asset.Name == "exe_storage" or asset:IsDescendantOf(game.ReplicatedStorage.exe_storage) then continue end
	local starttime = tick()
	local percent = i / maxassets

	PText.Text = math.floor(percent * 100) .. "%"
	TS:Create(PBar, TweenInfo.new(1), {Size = UDim2.new(percent, 0, 1, 0)}):Play()

	local success, err = pcall(function()
		local loaded = false

		-- Use task.delay for timeout warning
		local timeoutWarned = false
		local timeoutConn = task.delay(5, function()
			if not loaded then
				timeoutWarned = true
				warn("Asset loading timeout: ", asset)
			end
		end)

		CP:PreloadAsync({asset})
		loaded = true

		-- No need to cancel task.delay, just set loaded = true before timeout triggers
	end)

	if not success then
		warn("Failed to preload asset: ", asset, err)
	end

	-- Pause every 500 assets to avoid blocking
	if i % 500 == 0 then
		wait(0.1)
	end
end

wait(1)
local uit = TS:Create(gui.Frame, TweenInfo.new(2, Enum.EasingStyle.Sine), {GroupTransparency = 1})
uit:Play()
wait(1)
local blurt = TS:Create(blur,TweenInfo.new(2, Enum.EasingStyle.Sine),{Size = 0})
blurt:Play()
blurt.Completed:Wait()
gui:Destroy()
blur:Destroy()
script:Destroy()
