local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BloxbizSDK = script.Parent.Parent.Parent

local BodyScaleValues = require(BloxbizSDK.CatalogClient.Libraries.BodyScaleValues)
local Slider = require(script.Parent.Parent.Classes.Slider)

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local Value = Fusion.Value
local New = Fusion.New
local Observer = Fusion.Observer
local Cleanup = Fusion.Cleanup
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Ref = Fusion.Ref
local Spring = Fusion.Spring
local Computed = Fusion.Computed

local SETTINGS = {
	ListOfColors = {
		[1] = Color3.new(1, 0.8, 0.6),
		[2] = Color3.new(0.843137, 0.772549, 0.603922),
		[3] = Color3.new(0.8, 1, 0.8),
		[4] = Color3.new(0.431373, 0.6, 0.792157),
		[5] = Color3.new(0.356863, 0.603922, 0.298039),
		[6] = Color3.new(0.337255, 0.258824, 0.211765),
		[7] = Color3.new(0.0666667, 0.0666667, 0.0666667),
		[8] = Color3.new(0, 1, 1),
		[9] = Color3.new(0.384314, 0.145098, 0.819608),
		[10] = Color3.new(0.0705882, 0.933333, 0.831373),
		[11] = Color3.new(0.639216, 0.635294, 0.647059),
		[12] = Color3.new(1, 0.4, 0.8),
		[13] = Color3.new(0.694118, 0.654902, 1),
		[14] = Color3.new(0.803922, 0.803922, 0.803922),
		[15] = Color3.new(0.854902, 0.521569, 0.254902),
		[16] = Color3.new(0, 0.560784, 0.611765),
		[17] = Color3.new(0.0509804, 0.411765, 0.67451),
		[18] = Color3.new(0.498039, 0.556863, 0.392157),
		[19] = Color3.new(0.666667, 0, 0.666667),
		[20] = Color3.new(0.486275, 0.360784, 0.27451),
		[21] = Color3.new(0.294118, 0.592157, 0.294118),
		[22] = Color3.new(0.886275, 0.607843, 0.25098),
		[23] = Color3.new(0.666667, 0.333333, 0),
		[24] = Color3.new(0.705882, 0.501961, 1),
		[25] = Color3.new(0, 0, 1),
		[26] = Color3.new(0.501961, 0.733333, 0.862745),
		[27] = Color3.new(0.705882, 0.823529, 0.894118),
		[28] = Color3.new(0.8, 0.556863, 0.411765),
		[29] = Color3.new(0.321569, 0.486275, 0.682353),
		[30] = Color3.new(0.470588, 0.564706, 0.509804),
		[31] = Color3.new(0.686275, 0.580392, 0.513726),
		[32] = Color3.new(0.152941, 0.27451, 0.176471),
		[33] = Color3.new(0.0156863, 0.686275, 0.92549),
		[34] = Color3.new(0.411765, 0.25098, 0.156863),
		[35] = Color3.new(0.54902, 0.356863, 0.623529),
		[36] = Color3.new(0.631373, 0.768627, 0.54902),
		[37] = Color3.new(0.643137, 0.741176, 0.278431),
		[38] = Color3.new(0.454902, 0.52549, 0.615686),
		[39] = Color3.new(0.352941, 0.298039, 0.258824),
		[40] = Color3.new(0.654902, 0.368627, 0.607843),
		[41] = Color3.new(0.972549, 0.85098, 0.427451),
		[42] = Color3.new(0.909804, 0.729412, 0.784314),
		[43] = Color3.new(0.129412, 0.329412, 0.72549),
		[44] = Color3.new(0.639216, 0.294118, 0.294118),
		[45] = Color3.new(0.388235, 0.372549, 0.384314),
		[46] = Color3.new(0, 1, 0),
		[47] = Color3.new(0.627451, 0.372549, 0.207843),
		[48] = Color3.new(1, 0.686275, 0),
		[49] = Color3.new(0.835294, 0.45098, 0.239216),
		[50] = Color3.new(0.737255, 0.607843, 0.364706),
		[51] = Color3.new(1, 0, 0),
		[52] = Color3.new(1, 0, 0.74902),
		[53] = Color3.new(0.972549, 0.972549, 0.972549),
		[54] = Color3.new(0.94902, 0.952941, 0.952941),
		[55] = Color3.new(0.623529, 0.952941, 0.913725),
		[56] = Color3.new(0.756863, 0.745098, 0.258824),
		[57] = Color3.new(0.854902, 0.52549, 0.478431),
		[58] = Color3.new(1, 0.596078, 0.862745),
		[59] = Color3.new(0.419608, 0.196078, 0.486275),
		[60] = Color3.new(1, 1, 0),
		[61] = Color3.new(0.780392, 0.67451, 0.470588),
		[62] = Color3.new(0.768627, 0.156863, 0.109804),
		[63] = Color3.new(0.960784, 0.803922, 0.188235),
		[64] = Color3.new(0.486275, 0.611765, 0.419608),
		[65] = Color3.new(0.156863, 0.498039, 0.278431),
		[66] = Color3.new(1, 0.788235, 0.788235),
		[67] = Color3.new(0.584314, 0.47451, 0.466667),
		[68] = Color3.new(1, 1, 0.8),
		[69] = Color3.new(0.992157, 0.917647, 0.552941),
		[70] = Color3.new(0.898039, 0.894118, 0.87451),
		[71] = Color3.new(0.227451, 0.490196, 0.0823529),
		[72] = Color3.new(0.105882, 0.164706, 0.207843),
		[73] = Color3.new(0, 0.12549, 0.376471),
		[74] = Color3.new(0.686275, 0.866667, 1),
		[75] = Color3.new(0.917647, 0.721569, 0.57254),
	},

	ScalesOrder = {
		"HeadScale",
		"HeightScale",
		"WidthScale",
		"BodyTypeScale",
		"ProportionScale",
	},

	Color = {
		Default = Color3.fromRGB(79, 84, 95),
		MouseDown = Color3.fromRGB(15, 15, 15),
		Hover = Color3.fromRGB(128, 128, 128),
	},

	TextColor = {
		Disabled = Color3.fromRGB(128, 128, 128),
		Default = Color3.fromRGB(255, 255, 255),
	},
}

local function ScaleSlider(): (Frame, Frame, TextLabel, Frame)
	local background = Value()
	local infoLabel = Value()
	local barFill = Value()

	local slider = New("Frame")({
		Name = "BodyType",
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.95, 0.125),

		[Cleanup] = Fusion.cleanup,

		[Children] = {
			New("TextLabel")({
				Name = "Info",
				Text = "",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0, 0.2),
				Size = UDim2.fromScale(1, 0.25),

				[Ref] = infoLabel,
			}),

			New("Frame")({
				Name = "Bar",
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(102, 102, 102),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.8),
				Size = UDim2.fromScale(1, 0.1),

				[Ref] = background,

				[Children] = {
					New("Frame")({
						Name = "DragBar",
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundColor3 = Color3.fromRGB(82, 172, 255),
						BorderSizePixel = 0,
						Position = UDim2.fromScale(0, 0.5),
						Size = UDim2.fromScale(1, 1),

						[Ref] = barFill,
					}),

					New("ImageButton")({
						Name = "Slider",
						Image = "rbxassetid://10451411298",
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Position = UDim2.fromScale(1, 0.5),
						Size = UDim2.fromScale(3, 3),
						SizeConstraint = Enum.SizeConstraint.RelativeYY,
					}),
				},
			}),
		},
	})

	return slider, background:get(), infoLabel:get(), barFill:get()
end

local function ColorButton(color3: Color3, updateColorCallback: () -> ())
	return New("ImageButton")({
		Name = "ColorButton",
		Image = "rbxassetid://10451411298",
		ImageColor3 = color3,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromScale(0.1, 0.1),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,

		[OnEvent("Activated")] = function()
			updateColorCallback()
		end,

		[Children] = {
			New("UIAspectRatioConstraint")({
				Name = "UIAspectRatioConstraint",
			}),
		},
	})
end

local function GetSkinToneFrame()
	local itemFrame = Value()
	local frame = New("Frame")({
		Name = "SkinTone",
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromScale(0.495, 1),

		[Children] = {
			New("Frame")({
				Name = "Colors",
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.075),
				Size = UDim2.fromScale(1, 0.925),

				[Ref] = itemFrame,

				[Children] = {
					New("UIGridLayout")({
						Name = "UIGridLayout",
						CellPadding = UDim2.fromScale(0.05, 0),
						CellSize = UDim2.fromScale(0.09, 0.085),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
				},
			}),

			New("TextLabel")({
				Name = "TextLabel",
				Text = "Skin Tone",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0, 0.025),
				Size = UDim2.fromScale(0.258, 0.032),
			}),
		},
	})

	return frame, itemFrame:get()
end

local function GetBodyScalesFrame(): (Frame, Frame)
	local itemFrame = Value()

	local mainFrame = New("Frame")({
		Name = "BodyScale",
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromScale(0.495, 1),

		[Children] = {
			New("Frame")({
				Name = "Scales",
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.075),
				Size = UDim2.fromScale(1, 0.925),

				[Ref] = itemFrame,

				[Children] = {
					New("UIListLayout")({
						Name = "UIListLayout",
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
				},
			}),

			New("TextLabel")({
				Name = "TextLabel",
				Text = "Body Scale",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0, 0.025),
				Size = UDim2.fromScale(0.27, 0.04),
			}),
		},
	})

	return mainFrame, itemFrame:get()
end

local function ParentFrame(): Frame
	return New("Frame")({
		Name = "BodyFrame",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
	})
end

local BodyEditor = {}
BodyEditor.__index = BodyEditor

function BodyEditor.new(coreContainer: Frame)
	local self = setmetatable({}, BodyEditor)
	self.Enabled = false

	self.Container = coreContainer
	self.Observers = {}
	self.GuiObjects = {}

	return self
end

function BodyEditor:Init(controllers: { [string]: { any } })
	self.Controllers = controllers

	local frameContainer = self.Container:WaitForChild("FrameContainer")
	local frame = ParentFrame()
	frame.Visible = false
	frame.Parent = frameContainer

	local skinFrame, colorHolder = GetSkinToneFrame()
	for _, color in pairs(SETTINGS.ListOfColors) do
		local button = ColorButton(color, function()
			if self.Enabled then
				self.Controllers.AvatarPreviewController:UpdateColor(color)
			end
		end)
		button.Parent = colorHolder
	end

	local sliders = {}
	local bodyScaleFrame, scalesHolder = GetBodyScalesFrame()
	for i = 1, #SETTINGS.ScalesOrder do
		local category = SETTINGS.ScalesOrder[i]
		local data = BodyScaleValues[category]

		local name = string.gsub(category, "Scale", "")
		local value = math.max(data.Min, data.Default)

		local sliderFrame, background, infoLabel, barFill = ScaleSlider()
		sliderFrame.Name = name

		local slider = Slider.new(background, {
			SliderData = {
				Start = data.Min,
				End = data.Max,
				Increment = 0.01,
				DefaultValue = value,
			},

			MoveType = "Instant",
			MoveInfo = TweenInfo.new(0.1),

			Padding = 0,
			Axis = "X",
			AllowBackgroundClick = true,
		})

		slider:Track()
		slider.Changed:Connect(function(newValue: number)
			infoLabel.Text = string.format("%s (%d%%)", name, newValue * 100)
			barFill.Size = UDim2.fromScale(slider._data._percent, 1)

			self.Controllers.AvatarPreviewController:UpdateScale(name, newValue)
		end)

		sliders[category] = {
			Slider = slider,
			Instance = sliderFrame,
		}
	end

	skinFrame.Parent = frame
	bodyScaleFrame.Parent = frame

	self.GuiObjects.Frame = frame
	self.GuiObjects.ScalesHolder = scalesHolder
	self.GuiObjects.BodyScaleFrame = bodyScaleFrame
	self.GuiObjects.SkinFrame = skinFrame
	self.GuiObjects.Sliders = sliders
end

function BodyEditor:Start()
	

	for _, slider in pairs(self.GuiObjects.Sliders) do
		slider.Instance.Parent = self.GuiObjects.ScalesHolder
	end
end

function BodyEditor:UpdateSliders(humanoidDescription: any)
	self.SettingDefault = true

	for scaleCategory: string, data in pairs(BodyScaleValues) do
		local current = humanoidDescription[scaleCategory]
		current = math.clamp(current, data.Min, data.Max)

		local slider = self.GuiObjects.Sliders[scaleCategory]
		if not slider then
			continue
		end

		local object = slider.Slider
		if object then
			object:OverrideValue(current)
		end
	end

	self.SettingDefault = false
end

function BodyEditor:Enable()
	self.Enabled = true
	self.GuiObjects.Frame.Visible = true

	self.Controllers.TopBarController:ResetSearchBar()
	self.Controllers.OutfitFeedController:Disable()
end

function BodyEditor:Disable()
	self.Enabled = false
	self.GuiObjects.Frame.Visible = false
end

return BodyEditor
