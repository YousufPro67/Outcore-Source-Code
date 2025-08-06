local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local BloxbizSDK = script.Parent.Parent.Parent.Parent
local CatalogClient = BloxbizSDK.CatalogClient
local Classes = CatalogClient.Classes

local AvatarHandler = require(Classes:WaitForChild("AvatarHandler"))

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local New = Fusion.New
local Value = Fusion.Value
local Cleanup = Fusion.Cleanup
local Computed = Fusion.Computed
local Observer = Fusion.Observer

export type AvatarViewportFrame = {
	Viewport: ViewportFrame,
	Model: Model,
}

local dt

local MIN_ZOOM = 0.4
local MAX_ZOOM = 2

local function GetPreviewFrameViewport(zoom: Fusion.Value?): AvatarViewportFrame
	RunService:UnbindFromRenderStep("AvatarModelRotation")

	local model = AvatarHandler.GetModel()
	local isMouseDown = Value(false)
	local isPinching = Value(false)

	local baseCf = model:GetPivot()
	local pitch = Value(0)
	local yaw = Value(0)
	local pitchAndYaw = Computed(function()
		return {pitch:get(), yaw:get()}
	end)
	local disconnectRotation = Observer(pitchAndYaw):onChange(function()
		local _pitch, _yaw = pitchAndYaw:get()[1], pitchAndYaw:get()[2]

		model:PivotTo(baseCf * CFrame.Angles(
			-math.rad(_pitch),
			math.rad(_yaw),
			0
		))
	end)

	local function ResetRotation()
		pitch:set(0)
		yaw:set(0)
	end

	local prevMouseX, prevMouseY = Mouse.X, Mouse.Y
	RunService:BindToRenderStep("AvatarModelRotation", 2000, function(delta)
		--debug.profilebegin("Avatar Model Rotation")

		dt = delta

		-- use TouchPan event for mobile devices
		if UserInputService.TouchEnabled then
			return
		end

		if isMouseDown:get() then
			local dx, dy = Mouse.X - prevMouseX, Mouse.Y - prevMouseY

			yaw:set(yaw:get() + dx)
			pitch:set(math.clamp(pitch:get() + dy/2, -45, 60))
		end

		prevMouseX, prevMouseY = Mouse.X, Mouse.Y

		--debug.profileend()
	end)

	local screenGuiRef = Value()
	local viewportFrameRef = Value()
	local isViewportVisible = Value(false)

	local prevSig
	local screenGuiRefSig = Fusion.Observer(screenGuiRef):onChange(function()
		if prevSig then
			prevSig:Disconnect()
		end

		local screenGui = screenGuiRef:get()
		if screenGui then
			prevSig = screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
				isViewportVisible:set(screenGui.Enabled)
			end)
		end
	end)

	local baseZoom = 1
	local viewport = New("ViewportFrame")({
		Name = "ViewportFrame",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(79, 84, 95),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Visible = false,

		[Fusion.Ref] = viewportFrameRef,
		[OnEvent "AncestryChanged"] = function()
			local frame = viewportFrameRef:get()

			if frame then
				local screenGuiInstance = Utils.findFirstAncestorOfClass(frame, "ScreenGui")

				if screenGuiInstance then
					screenGuiRef:set(screenGuiInstance)
				end
			end
		end,

		[Cleanup] = function()
			RunService:UnbindFromRenderStep("AvatarModelRotation")
			model:Destroy()
			disconnectRotation()
			screenGuiRefSig:Disconnect()
		end,

		[Children] = {
			New("WorldModel")({
				Name = "WorldModel",
			}),

			New("TextButton")({
				Name = "RotateButton",
				Text = "",
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextSize = 14,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),

				[OnEvent("MouseButton1Down")] = function()
					isMouseDown:set(true)
				end,

				[OnEvent("MouseButton1Up")] = function()
					isMouseDown:set(false)
				end,

				[OnEvent("MouseLeave")] = function()
					isMouseDown:set(false)
				end,

				[OnEvent("MouseWheelForward")] = function()
					if zoom then
						zoom:set(
							math.clamp(zoom:get() * 1.05, MIN_ZOOM, MAX_ZOOM)
						)
					end
				end,

				[OnEvent("MouseWheelBackward")] = function()
					if zoom then
						zoom:set(
							math.clamp(zoom:get() / 1.05, MIN_ZOOM, MAX_ZOOM)
						)
					end
				end,

				[OnEvent("TouchPan")] = function(_, _, vel)
					if isPinching:get() then
						return
					end

					local dx, dy = vel.X*dt, vel.Y*dt

					yaw:set(yaw:get() + dx)
					pitch:set(math.clamp(pitch:get() + dy/2, -45, 60))
				end,

				[OnEvent("TouchPinch")] = function(_, scale, _, state)
					if zoom then
						if state == Enum.UserInputState.Begin then
							isMouseDown:set(false)
							isPinching:set(true)
							baseZoom = zoom:get() or 1
						elseif state == Enum.UserInputState.Change then
							isMouseDown:set(false)
							zoom:set(math.clamp(baseZoom * scale, MIN_ZOOM, MAX_ZOOM))
						elseif state == Enum.UserInputState.End then
							baseZoom = nil
							isPinching:set(false)
						end
					end
				end
			}),
		},
	})

	AvatarHandler.RenderInViewport(model, viewport, false, nil, isViewportVisible)

	return {
		Viewport = viewport,
		Model = model,
		ResetRotation = ResetRotation
	}
end

return GetPreviewFrameViewport
