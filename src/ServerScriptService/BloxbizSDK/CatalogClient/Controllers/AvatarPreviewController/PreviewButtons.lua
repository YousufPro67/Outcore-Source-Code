local RunService = game:GetService("RunService")

local BloxbizSDK = script.Parent.Parent.Parent.Parent
local CatalogClient = BloxbizSDK.CatalogClient
local Classes = CatalogClient.Classes

local AvatarHandler = require(Classes:WaitForChild("AvatarHandler"))

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))
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

local BUTTONS = {
	Save = {
		Image = "rbxassetid://13729958499",
	},
	Reset = {
		Text = "Reset",
		Image = "rbxassetid://13729954132",
	},
	Undo = {
		Text = "Undo",
		Image = "rbxassetid://13729949413",
	},
	Redo = {
		Text = "Redo",
		Image = "rbxassetid://13729823355",
	},
	Wearing = {
		Image = "rbxassetid://13733130817",
	},
	Outfits = {
		Image = "rbxassetid://13930689959"
	},
	Inventory = {
		Image = "rbxassetid://13730244296"
	},
	Body = {
		Image = "rbxassetid://14975667673"
	},
	Buy = {

	},
	Expand = {
		Image = "rbxassetid://131070415886065"
	},
	Shrink = {
		Image = "rbxassetid://15177307285"
	}
}

local VIEWPORT_SIZE = Value(Vector2.new(1280, 720))
RunService.RenderStepped:Connect(function()
	if workspace.Camera.ViewportSize ~= VIEWPORT_SIZE:get() then
		VIEWPORT_SIZE:set(workspace.Camera.ViewportSize)
	end
end)


local DEFAULT_BTN_HT = Computed(function()
	return 0
end)

return function(props)
	props = FusionProps.GetValues(props, {
		Parent = FusionProps.Nil,
		Visible = true,

		FullScreen = false,
		OnFullScreen = FusionProps.Callback,

		OnSave = FusionProps.Nil,
		OnReset = FusionProps.Nil,
		OnUndo = FusionProps.Nil,
		OnRedo = FusionProps.Nil,
		OnOpenWearing = FusionProps.Nil,
		OnOpenOutfits = FusionProps.Nil,
		OnOpenInventory = FusionProps.Nil,
		OnOpenBody = FusionProps.Nil,

		OutfitsSelected = false,
		InventorySelected = false,
		BodySelected = false,

		UndoDisabled = false,
		RedoDisabled = false,
		SaveDisabled = false,
		WearingItems = FusionProps.Nil,
		WearingSelected = false,

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

	local notFullScreen = Computed(function()
		return not props.FullScreen:get()
	end)

	return New "Frame" {
		Name = "PreviewButtons",
		Parent = props.Parent,
		Position = props.Position,
		Size = props.Size,
		BackgroundTransparency = 1,
		ZIndex = 10,
		Visible = props.Visible,

		[Children] = {
			New "UIPadding" {
				PaddingBottom = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 8),
			},

			-- top left
			New "Frame" {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 0),
				Position = UDim2.fromScale(0, 0),
				Size = Computed(function()
					return UDim2.new(0.5, 0, 0, BTN_HT:get())
				end),
				Visible = notFullScreen,
				[Children] = {
					New "UIListLayout" {
						Padding = PADDING,
						SortOrder = Enum.SortOrder.LayoutOrder,
						FillDirection = Enum.FillDirection.Horizontal
					},

					-- Outfits
					Button({
						Size = BTN_SIZE,
						Icon = BUTTONS.Outfits.Image,
						Text = "Outfits",
						OnClick = props.OnOpenOutfits,
						Selected = props.OutfitsSelected
					}),

					-- inventory
					Button({
						Size = BTN_SIZE,
						Icon = BUTTONS.Inventory.Image,
						Text = "Inventory",
						OnClick = props.OnOpenInventory,
						Selected = props.InventorySelected
					}),

					-- Body
					Button({
						Size = BTN_SIZE,
						Icon = BUTTONS.Body.Image,
						Text = "Body",
						OnClick = props.OnOpenBody,
						Selected = props.BodySelected
					}),
				}
			},

			-- top right
			New "Frame" {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.fromScale(0.4, 0.5),
				Visible = notFullScreen,
				[Children] = {
					New "UIListLayout" {
						Padding = UDim.new(0, 8),
						SortOrder = Enum.SortOrder.LayoutOrder,
						HorizontalAlignment = Enum.HorizontalAlignment.Right,
					},

					-- Wearing items
					Button({
						Size = BTN_SIZE,
						Icon = BUTTONS.Wearing.Image,
						Count = Computed(function()
							return Utils.getArraySize(props.WearingItems:get() or {})
						end),
						OnClick = props.OnOpenWearing,
						Alignment = "Right",
						Selected = props.WearingSelected
					}),
				}
			},

			-- bottom
			New "Frame" {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				Size = Computed(function()
					return UDim2.fromOffset(
						BTN_HT:get() * 5 + 8 * 3,
						BTN_HT:get()
					)
				end),
				AutomaticSize = Enum.AutomaticSize.X,

				[Children] = {
					New "UIListLayout" {
						Padding = PADDING,
						SortOrder = Enum.SortOrder.LayoutOrder,
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center
					},

					-- undo
					Button({
						Size = BTN_SIZE,
						Icon = BUTTONS.Undo.Image,
						Text = BUTTONS.Undo.Text,
						OnClick = props.OnUndo,
						Disabled = props.UndoDisabled,
						Visible = notFullScreen
					}),
					-- redo
					Button({
						Size = BTN_SIZE,
						Icon = BUTTONS.Redo.Image,
						Text = BUTTONS.Redo.Text,
						OnClick = props.OnRedo,
						Disabled = props.RedoDisabled,
						Visible = notFullScreen
					}),
					-- reset
					Button({
						Size = BTN_SIZE,
						Icon = BUTTONS.Reset.Image,
						Text = BUTTONS.Reset.Text,
						OnClick = props.OnReset,
						Visible = notFullScreen
					}),
					-- save
					Button({
						Size = BTN_SIZE,
						Icon = BUTTONS.Save.Image,
						Text = Computed(function()
							if props.SaveDisabled:get() then
								return "Saved"
							else
								return "Save"
							end
						end),
						Disabled = props.SaveDisabled,
						OnClick = props.OnSave,
						Visible = notFullScreen
					}),
					-- full screen
					Button({
						Size = BTN_SIZE,
						Icon = Computed(function()
							if props.FullScreen:get() then
								return BUTTONS.Shrink.Image
							else
								return BUTTONS.Expand.Image
							end
						end),
						IconSize = 0.8,
						OnClick = function()
							local cb = props.OnFullScreen:get()
							cb(not props.FullScreen:get())
						end
					}),
				}
			},
		}
	}
end