--!strict
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local BloxbizSDK = script.Parent.Parent.Parent.Parent

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local INITIAL_THETA = 3*math.pi/4

export type Props = {
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,

	Model: Model?,

	RotateEnabled: boolean?,
	AutoRotateEnabled: boolean?
}

type RotateData = {
	AutoRotate: boolean,
	ManualRotate: boolean,

	MouseDown: Fusion.Value<boolean>,
	
	Camera: Camera,
	Source: Vector3,
	Theta: number,
	Rotate: number,
	Orientation: CFrame,
	Frame: Instance,
	IsVisible: boolean?
}

local RotateData = {}
RunService:BindToRenderStep("VIEWPORT_ROTATE", Enum.RenderPriority.Last.Value, function(dt: number)
	debug.profilebegin("Feed Preview Rotate")
	for _, rotateData: RotateData in pairs(RotateData) do
		debug.profilebegin("Feed Item Rotate")
		-- reset rotation as avatar comes into view
		local frame = rotateData.Frame
		local container = Utils.getAncestor(frame, 6)

		if container then
			local isVisible = Utils.isVisible(container, frame)
			local track = rotateData.Track

			if isVisible and not rotateData.IsVisible then
				-- frame has just come into view, reset rotation
				rotateData.Theta = INITIAL_THETA

				if track then
					track:Play()
				end
			elseif rotateData.IsVisible and not isVisible then
				if track then
					track:Stop()
				end
			end

			rotateData.IsVisible = isVisible
		else
			rotateData.IsVisible = false
		end

		-- frame.Visible = rotateData.IsVisible

		-- if not isVisible then
		-- 	return
		-- end

		-- handle mouse/auto rotation
		local x = Mouse.X
		
		if rotateData.MouseDown:get() then
			if rotateData.Rotate then
				local delta = x - rotateData.Rotate
				rotateData.Theta += math.rad(-delta)
			end
			
			rotateData.Rotate = x
		elseif rotateData.AutoRotate and rotateData.IsVisible then
			rotateData.Theta += math.rad(20 * dt)
			rotateData.Rotate = nil
		else
			rotateData.Rotate = nil
		end

		rotateData.Orientation = CFrame.fromEulerAnglesYXZ(math.rad(-20), rotateData.Theta, 0)	

		if rotateData.IsVisible then
			rotateData.Camera.CFrame = CFrame.new(rotateData.Source) * rotateData.Orientation * CFrame.new(0, 0, 6)
		end

		debug.profileend()
	end
	debug.profileend()
end)

local function BindRotateModel(avatarId: string, isMouseDown: Fusion.Value<boolean>, model: Model, camera: Camera, autoRotate: boolean, manualRotate: boolean, frame: Instance, track: Instance)
	if model and camera then
		local root = model.PrimaryPart
		if root then
			local data: RotateData = {
				AutoRotate = autoRotate,
				ManualRotate = manualRotate,

				MouseDown = isMouseDown,

				Source = root.Position,
				Camera = camera,
				Theta = INITIAL_THETA,
				Rotate = 0,
				Orientation = CFrame.new(),
				Frame = frame,
				Track = track
			}

			RotateData[avatarId] = data
		end
	end
end

local function UnbindRotateModel(avatarId: string)
	RotateData[avatarId] = nil
end

return function(props: Props): ViewportFrame
	local avatarId = "AvatarModelRotation" .. HttpService:GenerateGUID()
	
	local isMouseDown = Fusion.Value(false)
	local worldModel = Fusion.Value(nil)
	local model = props.Model
	local camera = Fusion.New("Camera")({})

	local dc

	local lastPos = nil

	local frame = Fusion.New("ViewportFrame")({
		Name = "ViewportFrame",
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(145, 155, 175),
		BackgroundTransparency = 1,
		Position = props.Position or UDim2.fromScale(0.5, 0.5),
		Size = props.Size or UDim2.fromScale(1, 1),
		CurrentCamera = camera,

		[Fusion.Cleanup] = function()
			if dc then dc() end

			UnbindRotateModel(avatarId)
		end,

		[Fusion.Children] = {
			camera,

			Fusion.New("WorldModel")({
				Name = "WorldModel",

				[Fusion.Ref] = worldModel,

				[Fusion.Children] = {
					model
				},

				[Fusion.OnEvent("ChildAdded")] = function(child: Instance)
					local currentModel = model
					if currentModel then
						currentModel:Destroy()
						model = nil
					end

					if child:IsA("Model") or child:IsA("Accessory") then
						model = nil
					end
				end,
			}),

			Fusion.New("TextButton")({
				Name = "RotateButton",
				Text = "",
				TextSize = 14,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),


				[Fusion.OnEvent("InputBegan")] = function(inp)
					if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
						isMouseDown:set(true)

						lastPos = Vector2.new(inp.Position.X, inp.Position.Y)
					end
				end,

				[Fusion.OnEvent("InputEnded")] = function(inp)
					if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
						isMouseDown:set(false)

						local pos = Vector2.new(inp.Position.X, inp.Position.Y)
						if lastPos and ((pos - lastPos).Magnitude <= 5) and props.OnClick then
							props.OnClick()
						end
					end
				end,

				[Fusion.OnEvent("MouseLeave")] = function()
					isMouseDown:set(false)
				end,
			}),
		},
	}) :: ViewportFrame

	if model then
		BindRotateModel(avatarId, isMouseDown, model, camera :: Camera, props.AutoRotateEnabled or false, props.RotateEnabled or false, frame, props.AnimTrack)
	end
	

	return frame
end
