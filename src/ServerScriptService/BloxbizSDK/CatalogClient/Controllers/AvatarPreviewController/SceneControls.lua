local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local BloxbizSDK = script.Parent.Parent.Parent.Parent
local CatalogClient = BloxbizSDK.CatalogClient
local Classes = CatalogClient.Classes

local AvatarHandler = require(Classes:WaitForChild("AvatarHandler"))

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local FP = require(UtilsStorage:WaitForChild("FusionProps"))
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local New = Fusion.New
local Ref = Fusion.Ref
local Computed = Fusion.Computed
local Observer = Fusion.Observer
local Spring = Fusion.Spring
local Cleanup = Fusion.Cleanup
local Value = Fusion.Value
local ForValues = Fusion.ForValues

local Button = require(script.Parent.Button)

local ICONS = {
	Pose = "rbxassetid://15184432252",
	Eye = "rbxassetid://15184317987",
	Shrink = "rbxassetid://15177307285",
}

local VIEWPORT_SIZE = Value(Vector2.new(1280, 720))
RunService.RenderStepped:Connect(function()
	if workspace.Camera.ViewportSize ~= VIEWPORT_SIZE:get() then
		VIEWPORT_SIZE:set(workspace.Camera.ViewportSize)
	end
end)

local DEFAULT_BTN_HT = 0

local clickTypes = {Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch}

return function(props)
	props = FP.GetValues(props, {
		Parent = FP.Nil,
		Visible = true,

		FullScreen = true,
		OnFullScreen = FP.Callback,

		Scene = {
			Image = "http://www.roblox.com/asset/?id=10393363412",
			Color = Color3.new(1, 1, 1)
		},
		Scenes = {{
			Image = "http://www.roblox.com/asset/?id=10393363412",
			Color = Color3.new(1, 1, 1)
		}},
		OnSceneChange = FP.Callback,
		OnPoseChange = FP.Callback,

		HideUI = false,

		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),

		ButtonHeight = DEFAULT_BTN_HT
	})

	local BTN_HT = props.ButtonHeight
	local BTN_SIZE = Computed(function()
		return UDim2.new(1, 0, 0, props.ButtonHeight:get())
	end)
	local PADDING = Computed(function()
		return UDim.new(0, BTN_HT:get() / 5)
	end)

	local signals = {}

	local sceneId = Value(1)
	table.insert(signals, Fusion.Observer(props.Scenes):onChange(function()
		local scenes = props.Scenes:get()
		if sceneId:get() > #scenes then
			sceneId:set(1)
			props.Scene:set(props.Scenes:get()[1])
		end
	end))

	table.insert(signals, Fusion.Observer(props.FullScreen):onChange(function()
		if not props.FullScreen:get() then
			sceneId:set(1)
			props.Scene:set(props.Scenes:get()[1])
		end
	end))

	-- detect clicks while still allowing avatar panning in hide UI mode
	local dragStart = nil
	local mouse = Players.LocalPlayer:GetMouse()
	table.insert(signals, UserInputService.InputBegan:Connect(function(input)
		if table.find(clickTypes, input.UserInputType) then
			dragStart = Vector2.new(mouse.X, mouse.Y)
		end
	end))
	table.insert(signals, UserInputService.InputEnded:Connect(function(input)
		if dragStart and table.find(clickTypes, input.UserInputType) and props.HideUI:get() then
			local pos = Vector2.new(mouse.X, mouse.Y)

			if (pos - dragStart).Magnitude < 3 then
				props.HideUI:set(false)
			end
		end
	end))

	return New "Frame" {
		Name = "SceneControls",
		Parent = props.Parent,
		Position = props.Position,
		Size = props.Size,
		BackgroundTransparency = 1,
		ZIndex = 10,
		Visible = props.Visible,

		[Cleanup] = function()
			Fusion.cleanup(signals)
		end,

		[Children] = {
			New "UIPadding" {
				PaddingBottom = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				PaddingTop = UDim.new(0, 8)
			},

			-- bottom right
			New "Frame" {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.fromScale(1, 1),
				Size = UDim2.fromScale(0.4, 0.5),
				[Children] = {
					New "UIListLayout" {
						Padding = UDim.new(0, 8),
						SortOrder = Enum.SortOrder.LayoutOrder,
						HorizontalAlignment = Enum.HorizontalAlignment.Right,
						VerticalAlignment = Enum.VerticalAlignment.Bottom
					},

					-- scene
					Button {
						LayoutOrder = -4,
						Size = BTN_SIZE,
						OnClick = function()
							local scenes = props.Scenes:get()
							local _sceneId = sceneId:get() + 1
							if _sceneId > #scenes then
								_sceneId = 1
							end
							sceneId:set(_sceneId)

							props.Scene:set(props.Scenes:get()[_sceneId])
						end,

						IconSize = 0.6,
						Icon = function () return New "CanvasGroup" {
							Size = UDim2.fromScale(1, 1),

							[Children] = {
								New "UICorner" {
									CornerRadius = UDim.new(0.5, 0)
								},
								New "UIStroke" {
									Color = Color3.fromRGB(0, 0, 0),
									Thickness = 1.5,
									-- ApplyStrokeMode = Enum.ApplyStrokeMode.Border
								},

								New "ImageLabel" {
									Size = UDim2.fromScale(1, 1),
									BackgroundColor3 = Computed(function()
										return props.Scene:get().Color
									end),
									ScaleType = Enum.ScaleType.Crop,
									Image = Computed(function()
										return props.Scene:get().Image
									end),
									ImageColor3 = Computed(function()
										return props.Scene:get().Color
									end)
								}
							}
						} end,
					},

					-- pose
					Button {
						LayoutOrder = -3,
						Size = BTN_SIZE,
						OnClick = props.OnPoseChange,
						Icon = ICONS.Pose,
						IconSize = 0.7
					},

					-- hide UI
					Button {
						LayoutOrder = -2,
						Size = BTN_SIZE,
						OnClick = function()
							task.defer(function()
								task.wait(1/30)
								props.HideUI:set(true)
							end)
						end,
						Icon = ICONS.Eye
					},

					-- full screen
					Button {
						LayoutOrder = -1,
						Size = BTN_SIZE,
						OnClick = function()
							local cb = props.OnFullScreen:get()
							cb(not props.OnFullScreen:get())
						end,
						Icon = ICONS.Shrink,
						IconSize = 0.8
					}
				}
			},
		}
	}
end