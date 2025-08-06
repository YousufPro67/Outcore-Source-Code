local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local BloxbizSDK = script.Parent.Parent.Parent
local CatalogClient = BloxbizSDK:FindFirstChild("CatalogClient")

local AvatarHandler = require(CatalogClient.Classes.AvatarHandler)

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local FusionProps = require(UtilsStorage:WaitForChild("FusionProps"))
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local AvatarHandler = require(CatalogClient.Classes:WaitForChild("AvatarHandler"))
local Button = require(script.InteractionFrame.Button)

local New = Fusion.New
local Value = Fusion.Value
local Computed = Fusion.Computed
local Children = Fusion.Children
local Ref = Fusion.Ref
local OnEvent = Fusion.OnEvent

local InteractionFrame = require(script.InteractionFrame)

local function GetInteractionFrame(
	props,
	humanoid
): Frame
	if type(humanoid) ~= "table" then
		humanoid = Value(humanoid)
	end

	local btnSize = UDim2.new(0.9, 0, 0.18, 0)

	local TryButton = Computed(function()
		if props.OnTry:get() then
			return Button({
				Text = "Try On",
				OnClick = function()
					local cb = props.OnTry:get()
					cb(humanoid:get():GetAppliedDescription())
				end,
				Size = btnSize
			})
		end
	end, Fusion.cleanup)
	local SaveButton = Computed(function()
		if props.OnSaveToRoblox:get() then
			return Button({
				Text = "Save To Roblox",
				OnClick = function()
					props.OnSaveToRoblox:get()(humanoid:get())
				end,
				Size = btnSize
			})
		end
	end, Fusion.cleanup)
	local DeleteButton = Computed(function()
		if props.OnDelete:get() then
			return Button({
				Text = "Delete",
				TextColor = Color3.new(1, 0, 0),
				OnClick = props.OnDelete,
				Size = btnSize
			})
		end
	end, Fusion.cleanup)
	

	local frame = InteractionFrame({
		Selected = props.Selected,
		Items = Computed(function()
			return {
				TryButton:get(),
				SaveButton:get(),
				DeleteButton:get()
			}
		end)
	})

	return frame
end

local SETTINGS = {
	Color = {
		Default = Color3.fromRGB(79, 84, 95),
		Hover = Color3.fromRGB(107, 114, 129),
		MouseDown = Color3.fromRGB(76, 80, 90),
	},
	PreviewFormat = "rbxthumb://type=%s&id=%s&w=150&h=150",
	Font = Font.new("rbxasset://fonts/families/GothamSSm.json"),
}

local function OutfitPrice(props: number): string
	props = FusionProps.GetValues(props, {
		Price = 0
	})

	return New("Frame")({
		Name = "ItemPrice",
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.959),
		Size = UDim2.fromScale(0.9, 0.07),

		[Children] = {
			New("TextLabel")({
				Name = "Amount",
				Text = Computed(function()
					return tostring(props.Price:get())
				end),
				FontFace = SETTINGS.Font,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromScale(0.85, 1),
			}),

			New("ImageLabel")({
				Name = "Icon",
				Image = "rbxassetid://9764949186",
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
			}),
		},
	})
end

local function TotalItems(props)
	local props = FusionProps.GetValues(props, {
		Total = 0
	})

	return New("TextLabel")({
		Name = "ItemCount",
		Text = Computed(function()
			return string.format("%s items", props.Total:get())
		end),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.875),
		Size = UDim2.fromScale(0.9, 0.07),
	})
end

local function GetAvatar(viewportFrame: ViewportFrame): (Model, Humanoid)
	local newModel = AvatarHandler.GetModel(Instance.new("HumanoidDescription"))
	local humanoid = newModel:WaitForChild("Humanoid")

	AvatarHandler.RenderInViewport(newModel, viewportFrame, true, false)
	return newModel, humanoid
end

local function GetViewport(): (ViewportFrame, WorldModel)
	local worldModel = Value()

	local viewport = New("ViewportFrame")({
		Name = "ViewportFrame",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(79, 84, 95),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromScale(0.9, 0.9),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,

		[Children] = {
			New("WorldModel")({
				Name = "WorldModel",
				[Ref] = worldModel,
			}),
		},
	})

	return viewport, worldModel:get()
end

return function (props)
	props = FusionProps.GetValues(props, {
		Outfit = FusionProps.Required,
		IsRoblox = false,
		Visible = true,

		OnTry = FusionProps.Nil,
		OnDelete = FusionProps.Nil,
		OnActivated = FusionProps.Nil,
		OnSaveToRoblox = FusionProps.Nil,
		Selected = false,

		Size = UDim2.fromOffset(100, 100),
		Position = UDim2.fromScale(0, 0)
	})

	local sigs = {}

	local isHovering = Value(false)
	local isHeldDown = Value(false)
	local isSelected = Value(false)

	local humanoidRef = Value()
	local viewport, worldModel = GetViewport()

	local loadAvatarTask = task.spawn(function()
		local model, humanoid = GetAvatar(viewport)
		model.Parent = worldModel

		humanoidRef:set(humanoid)

		local function applyOutfit()
			AvatarHandler:TryOutfit(humanoid, props.Outfit:get(), true)
		end

		if not viewport.Parent then
			viewport.Parent = Players.LocalPlayer.PlayerGui
		end
		applyOutfit()

		table.insert(sigs, Fusion.Observer(props.Outfit):onChange(applyOutfit))
	end)

	local totals = Computed(function()
		local totalPrice = 0
		local totalItem = 0

		for assetId, itemData: AvatarHandler.ItemData in props.Outfit:get() do
			if assetId == "BodyColors" then
				continue
			end

			totalPrice += itemData.Price or 0
			totalItem += 1
		end

		return {totalItem, totalPrice}
	end)
	local totalItems = Computed(function()
		return totals:get()[1]
	end)
	local totalPrice = Computed(function()
		return totals:get()[2]
	end)

	local frame = New("Frame")({
		Name = "Outfit",
		BackgroundColor3 = Color3.fromRGB(79, 84, 95),
		Size = props.Size,
		Position = props.Position,
		Visible = props.Visible,

		[Fusion.Cleanup] = function()
			task.cancel(loadAvatarTask)
		end,

		[Children] = {
			viewport,
			GetInteractionFrame(props, humanoidRef),

			New("UICorner")({
				Name = "UICorner",
				CornerRadius = UDim.new(0.05, 0),
			}),

			OutfitPrice({Price = totalPrice}),
			TotalItems({Total = totalItems}),

			Computed(function()
				if props.IsRoblox:get() then
					return New "ImageLabel" {
						Position = UDim2.fromScale(0.05, 0.05),
						Size = UDim2.fromScale(0.12, 1),
						Image = "rbxassetid://14914253209",
						BackgroundTransparency = 1,
						[Children] = {
							New "UIAspectRatioConstraint" {
								AspectRatio = 1,
								DominantAxis = Enum.DominantAxis.Width,
							}
						}
					}
				end
			end, Fusion.cleanup),

			--Main button
			New("TextButton")({
				Name = "Button",
				Text = "",
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextSize = 14,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),

				[OnEvent("MouseButton1Down")] = function()
					isHeldDown:set(true)
				end,

				[OnEvent("MouseButton1Up")] = function()
					isHeldDown:set(false)
				end,

				[OnEvent("MouseEnter")] = function()
					isHovering:set(true)
				end,

				[OnEvent("MouseLeave")] = function()
					isHovering:set(false)
					isHeldDown:set(false)
				end,

				[OnEvent("Activated")] = function()
					local cb = props.OnActivated:get()

					if cb then
						cb()
					end
				end,
			}),
		},
	})

	return {
		Instance = frame,
		Humanoid = humanoidRef
	}
end