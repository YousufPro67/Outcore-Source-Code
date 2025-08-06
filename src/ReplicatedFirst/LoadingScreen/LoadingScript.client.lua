local CP = game:GetService('ContentProvider')
local TS = game:GetService('TweenService')
local StarterGui = game:GetService("StarterGui")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local LocalPlayer = game.Players.LocalPlayer

local debounce = false
local gui = script.Parent.LoadingScreen:Clone()
local PText = gui.Frame.Loadinfo
local PBar = gui.Frame.Frame.CanvasGroup.LoadingBar

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
	wait(1)
	local blurt = TS:Create(blur,TweenInfo.new(2, Enum.EasingStyle.Sine),{Size = 0})
	blurt:Play()
	blurt.Completed:Wait()
	gui:Destroy()
	blur:Destroy()
	script:Destroy()
end)



for i, asset in ipairs(assets) do
	if asset.Name == "exe_storage" or asset:IsDescendantOf(game.ReplicatedStorage.exe_storage) then continue end
	local starttime = tick()
	local percent = i / maxassets

	PText.Text = math.floor(percent * 100) .. "%"
	TS:Create(PBar, TweenInfo.new(1), {Size = UDim2.new(percent, 0, 1, 0)}):Play()
	if tick() - sstartime > 15 and not debounce then
		debounce = true
		gui.Frame.CanvasGroup.Visible = true
		TS:Create(gui.Frame.CanvasGroup,TweenInfo.new(0.5,Enum.EasingStyle.Sine),{GroupTransparency = 0}):Play()
	end

	local success, err = pcall(function()
		local loaded = false

		-- Start a separate thread to handle the timeout
		local timeoutThread = coroutine.create(function()
			while not loaded do
				if tick() - starttime >= 5 then
					warn("Asset loading timeout: ", asset)
					break
				end
				wait(0.1)
			end
		end)

		-- Start preloading
		CP:PreloadAsync({asset})
		loaded = true

		-- Resume the timeout thread to exit if done within time
		coroutine.resume(timeoutThread)
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
