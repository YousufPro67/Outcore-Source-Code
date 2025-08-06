local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local GuiService = game:GetService("GuiService")

local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")
local BloxbizSDK = script.Parent

local CatalogOpenedEvent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)

local UIScaler = require(UtilsStorage:WaitForChild("UIScaler"))
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))
local IconModule = require(UtilsStorage:WaitForChild("Icon"))

local New = Fusion.New
local Value = Fusion.Value
local Tween = Fusion.Tween
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Computed = Fusion.Computed

local ConfigReader = require(script.Parent:WaitForChild("ConfigReader"))

local LoadingFrame = require(script.Components.LoadingFrame)

local Frame = require(script.Frame)
local Logo = require(script.Logo)
local Close = require(script.Close)
local BuyOutfit = require(script.BuyOutfit)

local LOADED = false

export type Catalog = {
	Enabled: Fusion.Value<boolean>,
	Gui: ScreenGui,
	TopbarButton: ImageButton?,
	Container: Frame,

	Controllers: { [string]: any },

	Init: () -> (),
	ToggleCatalog: () -> (),

	Open: () -> (),
	Close: () -> (),

	CloseCatalog: () -> (),
	OpenCatalog: () -> (),

	getCatalogIcon: () -> ImageButton,
	getCatalogContainer: () -> Frame,
}

local CatalogController = {} :: Catalog

CatalogController.Enabled = Fusion.Value(false)

local function Build(): (Fusion.Value<boolean>, ScreenGui, Frame, Frame, ImageButton)
	local enabled = CatalogController.Enabled
	local screenGui, container: Frame, frameContainer = Frame()

	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = PlayerGui

	local loadingFrame = LoadingFrame()
	loadingFrame.Parent = frameContainer

	return enabled, screenGui, container, loadingFrame, nil, frameContainer
end

local function OpenAnimation(screenGui: ScreenGui, container: Frame, close: ImageButton)
	local logo = screenGui:FindFirstChild("LogoContainer", true)
	local cover = screenGui:FindFirstChild("Cover", true)

	screenGui.Enabled = true

	local tweenInfo = TweenInfo.new(0.1)

	local isNewTopBar = GuiService.TopbarInset.Max.Y > 36

	TweenService:Create(cover, tweenInfo, {
		Transparency = 0,
	}):Play()

	TweenService:Create(logo, tweenInfo, {
		Position = UDim2.new(0, 0, 0, isNewTopBar and 34 or 22),
	}):Play()

	TweenService:Create(container, tweenInfo, {
		Position = UDim2.new(0, 0, 0, isNewTopBar and 57 or 36),
	}):Play()

	TweenService:Create(close, tweenInfo, {
		Position = UDim2.new(0.99, 0, 0, isNewTopBar and 34 or 20),
	}):Play()
end

local function CloseAnimation(screenGui: ScreenGui, container: Frame, close: ImageButton)
	local logo = screenGui:FindFirstChild("LogoContainer", true)
	local cover = screenGui:FindFirstChild("Cover", true)
	local tweenInfo = TweenInfo.new(0.1)

	TweenService:Create(close, tweenInfo, {
		Position = UDim2.new(1, -60, -0.1, 20),
	}):Play()

	TweenService:Create(container, tweenInfo, {
		Position = UDim2.new(0, 0, 1.5, 36),
	}):Play()

	TweenService:Create(logo, tweenInfo, {
		Position = UDim2.new(0, 0, -0.1, 20),
	}):Play()

	TweenService:Create(cover, tweenInfo, {
		BackgroundTransparency = 1,
	}):Play()

	task.wait(0.2)
	screenGui.Enabled = false
end

local DEFAULT_TWEEN = TweenInfo.new(0.1, Enum.EasingStyle.Quint)

local function createPrimaryButton()
	local sizeStates = {
		HeldDown = UDim2.fromScale(0.15 * 0.925, 0.118 * 0.925),
		Hovered = UDim2.fromScale(0.15 * 1.1, 0.118 * 1.1),
		Default = UDim2.fromScale(0.15, 0.118),
	}

	local sizeValue = Value(sizeStates.Default)
    local sizeTween = Tween(sizeValue, DEFAULT_TWEEN)

	New "ScreenGui" {
		Parent = Players.LocalPlayer.PlayerGui,
		Name = "Catalog Buttons",
		[Children] = {
			New "TextButton" {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 0.935),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),

				Size = Computed(function()
					return sizeTween:get()
				end),

				[OnEvent "Activated"] = function()
					CatalogController.Open()
				end,

				[OnEvent "MouseButton1Down"] = function()
					sizeValue:set(sizeStates.HeldDown)
				end,

				[OnEvent "MouseButton1Up"] = function()
					sizeValue:set(sizeStates.Default)
				end,

				[OnEvent "MouseEnter"] = function()
					sizeValue:set(sizeStates.Hovered)
				end,

				[OnEvent "MouseLeave"] = function()
					sizeValue:set(sizeStates.Default)
				end,

				[Children] = {
					New "ImageLabel" {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(0.7, 0.4),
						BackgroundTransparency = 1,
						Image = "rbxassetid://14555107778",
						ScaleType = Enum.ScaleType.Fit,
					},

					New "UICorner" {
						CornerRadius = UDim.new(0.5, 0)
					}
				},
			}
		}
	}
end

function CatalogController.Init()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, ConfigReader:read("DisplayPlayerList"))

	CatalogOpenedEvent = BloxbizRemotes:WaitForChild("CatalogOpenedEvent")

	local enabled, screenGui, container, loadingFrame, closeContainer, frameContainer = Build()

	local controllers = {}
	for _, controllerModule in pairs(script.Controllers:GetChildren()) do
		local controller = require(controllerModule)
		local name = controllerModule.Name

		if controller.Enable then
			local wrappedEnable = controller.Enable
			controller.Enable = function(self, ...)
				controllers.NavigationController:UpdateEnabled(name, true)
				wrappedEnable(self, ...)
				-- Utils.pprint(string.format("[Super Biz] %s enabled!", name))
			end
		end
		if controller.Disable then
			local wrappedDisable = controller.Disable
			controller.Disable = function(self, ...)
				controllers.NavigationController:UpdateEnabled(name, false)
				wrappedDisable(self, ...)
				-- Utils.pprint(string.format("[Super Biz] %s disabled!", name))
			end
		end

		if name == "ShopFeedController" then
			controllers[name] = controller:Init(container)
		else
			controllers[name] = controller.new(container, loadingFrame)
		end
	end

	for name, controllerObject in pairs(controllers) do
		if name == "ShopFeedController" then
			controllerObject:Init(nil, controllers)
			continue
		end

		controllerObject:Init(controllers)
	end

	local logo = Logo({
		FullScreen = controllers.AvatarPreviewController.FullScreen,
		Visible = Fusion.Computed(function()
			return not controllers.AvatarPreviewController.HideUI:get()
		end)
	})
	logo.Parent = screenGui

	local isNewTopBar = GuiService.TopbarInset.Max.Y > 36

	closeContainer = New "Frame" {
		Name = "Close",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		LayoutOrder = 1,
		Position = UDim2.new(1, -60, 0, isNewTopBar and 34 or 20),
		Size = UDim2.new(0, 200, 0, 30),
		Parent = screenGui,
		Visible = Fusion.Computed(function()
			return not controllers.AvatarPreviewController.HideUI:get()
		end),

		[Children] = {
			New "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 5)
			},

			BuyOutfit {
				OnBuy = function()
					controllers.BuyOutfitController:PromptBulkPurchase()
				end,
			},

			Close {
				OnClose = function()
					if enabled:get() then
						CatalogController.Close()
					end
				end,
			}
		}
	}

	for controllerName, controllerObject in pairs(controllers) do
		if controllerObject.Start then
			controllerObject:Start(controllers)
		end
	end

	if ConfigReader:read("CatalogShowToolbarButton") then
		if ConfigReader:read("CatalogPrimaryButton") == true then
			createPrimaryButton()
		else
			local topbarButton = IconModule.new()
			topbarButton:setImage(ConfigReader:read("CatalogToolbarIcon"))
			--topbarButton:setProperty("deselectWhenOtherIconSelected", false)
			local buttonLocation = ConfigReader:read("CatalogToolbarButtonLocation")
			topbarButton:align(buttonLocation == "left" and "Left" or "Right")
	
			if ConfigReader:read("CatalogToolbarButtonLabel") then
				topbarButton:setLabel(ConfigReader:read("CatalogToolbarButtonLabel"))
			end
	
			topbarButton:bindEvent("selected", function()
				if not enabled:get() and LOADED then
					CatalogController.Open()
				end
			end)
	
			topbarButton:bindEvent("deselected", function()
				if enabled:get() and LOADED then
					CatalogController.Close()
				end
			end)
	
			CatalogController.TopbarButton = topbarButton
		end
	end

	local obs = Fusion.Observer(enabled)
	obs:onChange(function()
		if enabled:get() then
			OpenAnimation(screenGui, container, closeContainer)
		else
			CloseAnimation(screenGui, container, closeContainer)
		end
	end)

	CatalogController.Gui = screenGui
	CatalogController.Controllers = controllers
	CatalogController.Container = container

	-- hydrate main content container to adjust to top bar size

	local topBarHeight = CatalogController.Controllers.TopBarController.TopBarHeight
	local topBarY = CatalogController.Controllers.TopBarController.TopBarY
	local containerPosY = Fusion.Computed(function()
		local baseY = topBarY:get() - container.AbsolutePosition.Y
		return baseY + topBarHeight:get() + 7
	end)
	Fusion.Hydrate(frameContainer)({
		Position = Fusion.Computed(function()
			return UDim2.new(0.012, 0, 0, containerPosY:get())
		end),
		Size = Fusion.Computed(function()
			return UDim2.new(0.668, 0, 1, -containerPosY:get())
		end)
	})

	-- UIScaler auto-sets font
	UIScaler:TagScreenGui(screenGui)
	LOADED = true

	-- set screen orientation
	local defaultOrientation = Players.LocalPlayer.PlayerGui.ScreenOrientation

	Fusion.Hydrate(Players.LocalPlayer.PlayerGui)({
		ScreenOrientation = Fusion.Computed(function()
			local enabled = CatalogController.Enabled:get()
			local fullScreen = controllers.AvatarPreviewController.FullScreen:get()

			if enabled then
				if fullScreen then
					return Enum.ScreenOrientation.LandscapeSensor
				else
					return Enum.ScreenOrientation.LandscapeSensor
				end
			else
				return defaultOrientation
			end
		end)
	})
end

function CatalogController.Open(categoryName: string?)
	if CatalogController.Enabled:get() then
		return
	end

	CatalogController.LastChatActiveState = StarterGui:GetCore("ChatActive")
	CatalogController.LastPlayerListState = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
	CatalogOpenedEvent:FireServer()

	CatalogController.Controllers.TopBarController.OpenCategory = categoryName

	if CatalogController.TopbarButton then
		--CatalogController.TopbarButton:select()
	end

	for _, controller in pairs(CatalogController.Controllers) do
		if controller.OnOpen then
			controller:OnOpen()
		end
	end

	CatalogController.Enabled:set(true)

	task.defer(function()
		StarterGui:SetCore("ChatActive", false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	end)
end

function CatalogController.Close()
	CatalogController.Enabled:set(false)
	StarterGui:SetCore("ChatActive", CatalogController.LastChatActiveState)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, CatalogController.LastPlayerListState)

	if CatalogController.TopbarButton then
		CatalogController.TopbarButton:deselect()
	end

	for _, controller in pairs(CatalogController.Controllers) do
		if controller.OnClose then
			controller:OnClose()
		end
	end
end

function CatalogController.OpenCatalog(categoryName: string?)
	CatalogController.Open(categoryName)
end

function CatalogController.CloseCatalog()
	CatalogController.Close()
end

function CatalogController.PromptBuyOutfit()
	CatalogController.Open()

	-- wait for outfit to refresh in case player's HumanoidDescription changed
	CatalogController.Controllers.AvatarPreviewController.OutfitLoaded.Event:Wait()

	CatalogController.Controllers.BuyOutfitController:ShowModal()
end

function CatalogController.ToggleCatalog(categoryName: string?)
	if CatalogController.Enabled:get() then
		CatalogController.Close()
	else
		CatalogController.Open(categoryName)
	end
end

function CatalogController.getCatalogIcon(): ImageButton
	return CatalogController.TopbarButton
end

function CatalogController.getCatalogContainer(): Frame
	return CatalogController.Container
end

return CatalogController
