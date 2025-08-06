local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local REMOTES_FOLDER = "BloxbizRemotes"
local RENDER_STEP_NAME = "BLOXBIZ_SCREENSHOT_TOOL"
local DEFAULT_GIF_FPS = 10
local ALLOWED_TOOL_USERS = {
	3436386142, --Kurtis (Mr_Kurtiz)
	1703679745, --Jesse (IGottaTryThis)
	3410520930, --Vincent (vincentdevacc)
	1718501381, --Sam (luckydroz)
	1870858613, --Ben (simplelobster1)
	17047318, --Pat (paricdil)
	401650338, --Zor (Game_ZOR)

	4303693665, --Steven (iwilllaust),
	4312208708, --Generic Account (SuperBizStaff_1),
	4312274403, --Generic Account (SuperBizStaff_2),
	4312278663, --Generic Account (SuperBizStaff_3)
}

local ConfigReader = require(script.Parent.ConfigReader)
local CreateToolGui = require(script.CreateToolGui)
local CreateDebugGui = require(script.Parent.CreateDebugGui)
local Utils = require(script.Parent.Utils)

local LocalPlayer = Players.LocalPlayer
local RemotesFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER)
local newAdEvent = RemotesFolder:WaitForChild("NewAdEvent")
local request3dAdEvent = RemotesFolder:WaitForChild("Request3dAdEvent")
local requestAudioAdEvent = RemotesFolder:WaitForChild("RequestAudioAdEvent")
local requestPortalAdEvent = RemotesFolder:WaitForChild("RequestPortalAdEvent")

local Tool = {}
Tool.TargetedAd = nil
Tool.TargetingUpdated = false
Tool.ValidClients = {}
Tool.LatestAdsForRevert = {}
Tool.MobileIcon = nil
Tool.DebugModeForceEnabled = false
Tool.IsAudioAd = false

local function UserCanScreenshotTool()
	local isAllowed = false

	for _, allowedID in ipairs(ALLOWED_TOOL_USERS) do
		if allowedID == LocalPlayer.UserId then
			isAllowed = true
		end
	end

	return isAllowed
end

local function UserIsMobile()
	local mouseEnabled = UserInputService.MouseEnabled
	local keyboardEnabled = UserInputService.KeyboardEnabled
	local touchEnabled = UserInputService.TouchEnabled

	if not mouseEnabled and not keyboardEnabled and touchEnabled then
		return true
	else
		return false
	end
end

local function WaitForAdPart(partName)
	local adPart
	local updateAdEvent
	local randomBillboardClient = require(script.Parent.BillboardClient)

	while adPart == nil do
		adPart = randomBillboardClient:waitForPart(partName, 5)
		updateAdEvent = RemotesFolder:WaitForChild("updateAdEvent-" .. partName, 5)

		if updateAdEvent == nil then
			return false
		end
	end

	local billboardClient

	while billboardClient == nil do
		for _, module in pairs(script.Parent:GetChildren()) do
			if module.Name ~= "BillboardClient" then
				continue
			end

			local thisClient = require(module)

			if thisClient.adPart == adPart then
				billboardClient = module
			end
		end

		task.wait()
	end

	return adPart, billboardClient
end

local function DisplayAd(billboardClient, ad)
	local ad_format = ad["ad_format"]
	local ad_url = ad["ad_url"]
	local bloxbiz_ad_id = ad["bloxbiz_ad_id"]
	local ad_external_link_references = ad["external_link_references"]

	local gif_fps = ad["gif_fps"]
	local gif_version = ad["gif_version"]
	local audio_url = ad["audio_url"]

	local show_ad_disclaimer = true
	local ad_disclaimer_url = ad["ad_disclaimer_url"]
	local ad_disclaimer_scale_x = ad["ad_disclaimer_scale_x"]
	local ad_disclaimer_scale_y = ad["ad_disclaimer_scale_y"]

	billboardClient:displayAd(
		ad_format,
		ad_url,
		bloxbiz_ad_id,
		ad_external_link_references,
		gif_fps,
		gif_version,
		audio_url,
		show_ad_disclaimer,
		ad_disclaimer_url,
		ad_disclaimer_scale_x,
		ad_disclaimer_scale_y
	)
end

function Tool.UpdateClients()
	Tool.ValidClients = {}

	for _, module in pairs(script.Parent:GetChildren()) do
		if module.Name ~= "BillboardClient" then
			continue
		end

		local billboardClient = require(module)

		if billboardClient.adPart ~= nil and not billboardClient.isClientPart then
			table.insert(Tool.ValidClients, module)
		end
	end
end

function Tool.RevertToLatestAds()
	for module, ad in pairs(Tool.LatestAdsForRevert) do
		local billboardClient = require(module)
		DisplayAd(billboardClient, ad)
	end
end

function Tool.TurnOnDebugMode()
	local PlayerGui = LocalPlayer.PlayerGui
	local debugGUI = CreateDebugGui()
	debugGUI.Parent = PlayerGui

	for _, billboardClient in pairs(script.Parent:GetChildren()) do
		if billboardClient.Name == "BillboardClient" and billboardClient.ClassName == "ModuleScript" then
			billboardClient = require(billboardClient)
			billboardClient.debugAPI = require(ConfigReader:read("DebugAPI")())
		end
	end
end

function Tool.TurnOffDebugMode()
	for _, billboardClient in pairs(script.Parent:GetChildren()) do
		if billboardClient.Name == "BillboardClient" and billboardClient.ClassName == "ModuleScript" then
			billboardClient = require(billboardClient)
			billboardClient.debugAPI = nil

			local adPartGui = billboardClient.adPart and billboardClient.adPart:FindFirstChild("AdSurfaceGui")
			if adPartGui and adPartGui:FindFirstChild("Colorize") then
				adPartGui.Colorize:Destroy()
			end
		end
	end

	local PlayerGui = LocalPlayer.PlayerGui
	if PlayerGui:FindFirstChild("DebugGui") then
		PlayerGui.DebugGui:Destroy()
	end
end

function Tool.Target3dAd(targetedAd)
	request3dAdEvent:FireServer(targetedAd)
end

function Tool.TargetPortalAd(targetedAd)
	requestPortalAdEvent:FireServer(targetedAd)
end

function Tool.TargetAudioAd(targetedAd)
	requestAudioAdEvent:FireServer(targetedAd)
end

function Tool.TurnOnTargeting(targetedAd)
	Tool.TargetedAd = targetedAd
	Tool.TargetingUpdated = true
	Tool.UpdateClients()

	local currentId = Tool.TargetedAd["bloxbiz_ad_id"]
	RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Last.Value, function()
		for _, module in ipairs(Tool.ValidClients) do
			local billboardClient = require(module)
			local idChanged = tonumber(billboardClient.currentBloxbizAdId) ~= tonumber(currentId)

			if idChanged or Tool.TargetingUpdated then
				local ad = Tool.TargetedAd
				DisplayAd(billboardClient, ad)
			end
		end

		if Tool.TargetingUpdated then
			Tool.TargetingUpdated = false
		end
	end)
end

function Tool.TurnOffTargeting()
	RunService:UnbindFromRenderStep(RENDER_STEP_NAME)
	Tool.TargetedAd = nil
	Tool.RevertToLatestAds()
end

function Tool.GetAdFromInput(adInput, gifFPS)
	local adToShowPlayer = {
		["ad_format"] = nil,
		["ad_url"] = nil,
		["bloxbiz_ad_id"] = -2,
		["external_link_references"] = {},
		["gif_fps"] = gifFPS,
		["gif_version"] = nil,
		["audio_url"] = nil,
		["show_ad_disclaimer"] = true,
		["ad_disclaimer_url"] = "rbxassetid://7122215099",
		["ad_disclaimer_scale_x"] = 0.117,
		["ad_disclaimer_scale_y"] = 0.08,
	}

	if string.match(adInput, ",") then
		local urls = {}

		for url in string.gmatch(adInput, "([^,]+)") do
			table.insert(urls, {ad_url = url, frames_per_sheet = 8})
		end

		adToShowPlayer["ad_format"] = "gif"
		adToShowPlayer["ad_url"] = urls
		adToShowPlayer["gif_version"] = 2
	elseif Utils.getAdUsingBloxbizAdId(adInput) then
		local ad = Utils.getAdUsingBloxbizAdId(adInput)

		adToShowPlayer["ad_format"] = ad["ad_format"]
		adToShowPlayer["ad_url"] = ad["ad_url"]
		adToShowPlayer["bloxbiz_ad_id"] = ad["bloxbiz_ad_id"]
		adToShowPlayer["gif_version"] = ad["gif_version"] or 2
		adToShowPlayer["gif_fps"] = ad["gif_fps"] or gifFPS
		adToShowPlayer["audio_url"] = ad["audio_url"]

		local isStaticAd = ad["ad_format"] == "static"
		local isPortalAd = ad["ad_format"] == "portal"
		if isPortalAd then
			adToShowPlayer["destination_place_id"] = ad["destination_place_id"]
		end
		if isStaticAd or isPortalAd then
			adToShowPlayer["ad_url"] = { ad["ad_url"] }
		end
	elseif string.match(adInput, "id") then
		if Tool.IsAudioAd then
			adToShowPlayer["ad_format"] = "audio"
			adToShowPlayer["audio_url"] = tostring(adInput)
			adToShowPlayer["gif_version"] = nil
		else
			adToShowPlayer["ad_format"] = "static"
			adToShowPlayer["ad_url"] = { tostring(adInput) }
			adToShowPlayer["gif_version"] = nil
		end
	end

	local isBillboardOrPortalAd = adToShowPlayer["ad_url"]
	local is3dAd = adToShowPlayer["ad_format"] == '3d'
	local isAudioAd = adToShowPlayer["ad_format"] == 'audio'

	if isBillboardOrPortalAd or isAudioAd then
		return adToShowPlayer
	elseif is3dAd then
		return Utils.getAdUsingBloxbizAdId(adInput)
	end
end

function Tool.ProcessInput()
	local gifFPS = DEFAULT_GIF_FPS

	local PlayerGui = LocalPlayer.PlayerGui
	local GUI = PlayerGui.ScreenshotTool.Main

	local adInput = GUI.Ad.TextBox.Text
	local fpsInput = tonumber(GUI.FPS.TextBox.Text)

	if fpsInput ~= nil and fpsInput > 0 then
		gifFPS = fpsInput
	end

	local targetedAd = Tool.GetAdFromInput(adInput, gifFPS)

	local is3dAd = targetedAd and targetedAd['ad_format'] == '3d'
	local isPortalAd = targetedAd and targetedAd['ad_format'] == 'portal'
	local isAudioAd = targetedAd and targetedAd['ad_format'] == 'audio'

	if isPortalAd then
		Tool.TargetPortalAd(targetedAd)
	elseif is3dAd then
		Tool.Target3dAd(targetedAd)
	elseif isAudioAd then
		Tool.TargetAudioAd(targetedAd)
	elseif targetedAd then
		Tool.TurnOffTargeting()
		Tool.TurnOnTargeting(targetedAd)
	else
		Tool.TurnOffTargeting()
	end

	if Tool.DebugModeForceEnabled then
		Tool.TurnOffDebugMode()
	else
		Tool.TurnOnDebugMode()
	end
end

function Tool.OnUpdateAdURL(partName)
	local updateAdEvent = RemotesFolder:WaitForChild("updateAdEvent-" .. partName)

	updateAdEvent.OnClientEvent:Connect(function(ad)
		local adPart, billboardClient = WaitForAdPart(partName)

		if not adPart then
			return
		end

		Tool.LatestAdsForRevert[billboardClient] = ad
	end)
end

function Tool.OnNewAdEvent(partName)
	local adPart = WaitForAdPart(partName)

	if not adPart then
		return
	end

	Tool.UpdateClients()
	Tool.OnUpdateAdURL(partName)
end

function Tool.UpdateDebugModeBtn()
	local PlayerGui = LocalPlayer.PlayerGui
	local Main = PlayerGui.ScreenshotTool.Main

	if Tool.DebugModeForceEnabled then
		Main.DebugModeBtn.TextLabel.Text = "DebugMode: Off"
	else
		Main.DebugModeBtn.TextLabel.Text = "DebugMode: On"
	end
end

function Tool.OnUpdatePressed()
	Tool.ProcessInput()
	Tool.DestroyGUI()
end

function Tool.SwitchAdType(isAudioAd, anyButton, audioButton)
	Tool.IsAudioAd = isAudioAd

	if isAudioAd then
		anyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		audioButton.TextColor3 = Color3.fromRGB(22, 144, 255)
	else
		anyButton.TextColor3 = Color3.fromRGB(22, 144, 255)
		audioButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

function Tool.OpenGUI()
	local PlayerGui = LocalPlayer.PlayerGui

	if PlayerGui:FindFirstChild("ScreenshotTool") then
		return
	end

	local GUI = CreateToolGui()
	GUI.Parent = PlayerGui

	local Main = GUI.Main

	Main.AnyButton.MouseButton1Click:Connect(function()
		Tool.SwitchAdType(false, Main.AnyButton, Main.AudioButton)
		Main.FPS.Visible = true
	end)
	Main.AudioButton.MouseButton1Click:Connect(function()
		Tool.SwitchAdType(true, Main.AnyButton, Main.AudioButton)
		Main.FPS.Visible = false
	end)

	Main.UpdateBtn.MouseButton1Click:Connect(Tool.OnUpdatePressed)
	Main.DebugModeBtn.MouseButton1Click:Connect(function()
		Tool.DebugModeForceEnabled = not Tool.DebugModeForceEnabled
		Tool.UpdateDebugModeBtn()
	end)

	if Tool.MobileIcon and not Tool.MobileIcon.isSelected then
		Tool.MobileIcon:select()
	end

	Tool.UpdateDebugModeBtn()
end

function Tool.DestroyGUI()
	local PlayerGui = LocalPlayer.PlayerGui

	if PlayerGui:FindFirstChild("ScreenshotTool") then
		PlayerGui.ScreenshotTool:Destroy()
	end

	if Tool.MobileIcon and Tool.MobileIcon.isSelected then
		Tool.MobileIcon:deselect()
	end
end

function Tool.SetupMobileEntry()
	local IconModule = require(script.Parent.Utils.Icon)

	Tool.MobileIcon = IconModule.new()

	local mobileIcon = Tool.MobileIcon
	mobileIcon:setImage(9792053373)
	mobileIcon:align("Center")

	mobileIcon:bindEvent("selected", function()
		Tool.OpenGUI()
	end)

	mobileIcon:bindEvent("deselected", function()
		Tool.DestroyGUI()
	end)
end

function Tool.SetupDesktopEntry()
	local ctrlActive = false
	local shiftActive = false

	local isOpen = false

	local function processState()
		local shortcutActivated = ctrlActive and shiftActive

		if shortcutActivated then
			if not isOpen then
				Tool.OpenGUI()
			else
				Tool.DestroyGUI()
			end

			isOpen = not isOpen

			ctrlActive = false
			shiftActive = false
		end
	end

	UserInputService.InputBegan:Connect(function(inputObj)
		if inputObj.KeyCode == Enum.KeyCode.LeftControl then
			ctrlActive = true
		elseif inputObj.KeyCode == Enum.KeyCode.U then
			shiftActive = true
		end

		processState()
	end)

	UserInputService.InputEnded:Connect(function(inputObj)
		if inputObj.KeyCode == Enum.KeyCode.LeftControl then
			ctrlActive = false
		elseif inputObj.KeyCode == Enum.KeyCode.U then
			shiftActive = false
		end

		processState()
	end)
end

function Tool.init()
	newAdEvent.OnClientEvent:Connect(Tool.OnNewAdEvent)

	for _, ad in ipairs(ConfigReader:read("Ads")) do
		if type(ad) == "table" then
			ad = ad["partInstance"]
		end

		Tool.OnUpdateAdURL(ad:GetFullName())
	end

	if not UserCanScreenshotTool() then
		return
	end

	Tool.SetupMobileEntry()

	if not UserIsMobile() then
		Tool.SetupDesktopEntry()
	end
end

return Tool
