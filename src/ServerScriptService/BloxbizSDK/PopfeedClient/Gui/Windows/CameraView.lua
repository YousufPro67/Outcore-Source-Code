local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PopfeedClient = script.Parent.Parent.Parent
local RBLXSerialize = require(PopfeedClient.Parent.Utils.RBLXSerialize)

local Gui = PopfeedClient.Gui
local Fusion = require(Gui.Parent.Parent.Utils.Fusion)

local New = Fusion.New
local Ref = Fusion.Ref
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Computed = Fusion.Computed
local ForPairs = Fusion.ForPairs
local ForValues = Fusion.ForValues

local GuiComponents = Gui.Components
local Screen = require(GuiComponents.Screen)

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local rayParams = OverlapParams.new()
rayParams.BruteForceAllSlow = true

local lastPlayedAnimation

local function specialMeshIt(meshPart)
    local part = Instance.new("Part")
    local mesh = Instance.new("SpecialMesh")

    mesh.MeshId = meshPart.MeshId
    mesh.TextureId = meshPart.TextureID
    mesh.Scale = meshPart.Size / meshPart.MeshSize
    mesh.Parent = part

    part.Anchored = true
    part.Name = meshPart.Name
    part.CFrame = meshPart.CFrame
    part.BrickColor = meshPart.BrickColor
    part.Parent = meshPart.Parent

    meshPart:Destroy()

    return part
end

local function getBackground(objects)
    local humanoids = {}

    local cameraClone = Camera:Clone()

    for _, object in objects do
        local humanoid = object.Parent:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            humanoid = object.Parent.Parent:FindFirstChildOfClass("Humanoid")
        end
        if humanoid then
            humanoids[humanoid] = true
            continue
        end

        local objectClone
        if object:IsA("MeshPart") then
            objectClone = specialMeshIt(object:Clone())
        else
            local archivable = object.Archivable;
            object.Archivable = true;
            objectClone = object:Clone();
            object.Archivable = archivable;
        end

        objectClone.Anchored = true
        objectClone.CanCollide = false

        for _, descendant in objectClone:GetDescendants() do
            if not descendant:IsA("BasePart") and not descendant:IsA("Decal") and not descendant:IsA("Texture") and not descendant:IsA("SpecialMesh") then
                descendant:Destroy()
            end
        end

        objectClone.Parent = cameraClone
    end

    return cameraClone, humanoids
end

local function stopAnimation()
    if lastPlayedAnimation then
        lastPlayedAnimation:Stop()
        lastPlayedAnimation = nil
    end
end

local function playAnimation(animationId)
    stopAnimation()

    if animationId == "" then
        return
    end

    local char = Player.Character
    if not char then
        return
    end

    local hum = char:FindFirstChild("Humanoid")
    if not hum then
        return
    end

    local animator = hum:WaitForChild("Animator")

    local animation = Instance.new("Animation")
    animation.AnimationId = animationId

    lastPlayedAnimation = animator:LoadAnimation(animation)
    lastPlayedAnimation.Looped = true
    lastPlayedAnimation:Play()
end

local toEnableGuis = {}

local function hideAllGuis()
    for _, gui in Player.PlayerGui:GetChildren() do
        if gui:IsA("ScreenGui") and gui.Name ~= "CameraView" and gui.Enabled == true then
            gui.Enabled = false
            table.insert(toEnableGuis, gui)
        end
    end
end

local function enableGuis()
    for _, gui in toEnableGuis do
        gui.Enabled = true
    end
    toEnableGuis = {}
end

local function prepareHumanoids(humanoids, worldModel)
    for humanoid in humanoids do
        local model = humanoid:FindFirstAncestorOfClass("Model")
        if model then
            local partCframes = {}

            for _, part in model:GetChildren() do
                if part:IsA("BasePart") then
                    partCframes[part.Name] = {part.CFrame:GetComponents()}
                end
            end

            model.Archivable = true
            local clone = model:Clone()

            local animateScript = clone:FindFirstChild("Animate", true)
            if animateScript then
                animateScript:Destroy()
            end

            local animator = clone:FindFirstChildWhichIsA("Animator", true)
            if animator then
                animator:Destroy()
            end

            local faceControls = clone:FindFirstChildWhichIsA("FaceControls", true)
            if faceControls then
                faceControls:Destroy()
            end

            for partName, partCframe in partCframes do
                local part = clone:FindFirstChild(partName)
                if part then
                    local motor = part:FindFirstChildOfClass("Motor6D")
                    if motor then
                        motor:Destroy()
                    end

                    part.Anchored = true
                    part.CFrame = CFrame.new(table.unpack(partCframe))
                end
            end

            clone.Parent = worldModel
            model.Archivable = false
        end
    end
end

return function(props)
    hideAllGuis()

    local viewportFrame = Value()

    local enabledCameraView = Value(true)

    local outfitsVisible = Value(false)
    local animationsVisible = Value(false)

    local outfits = Value(ReplicatedStorage.Outfits:GetChildren())
    local animations = Value({
        Wave = "http://www.roblox.com/asset/?id=507770239",
        Point = "http://www.roblox.com/asset/?id=507770453",
        Cheer = "http://www.roblox.com/asset/?id=507770677",
        Laugh = "http://www.roblox.com/asset/?id=507770818",
        Dance1 = "http://www.roblox.com/asset/?id=507771019",
        Dance2 = "http://www.roblox.com/asset/?id=507776043",
        Dance3 = "http://www.roblox.com/asset/?id=507777268",
        Stop = "",
    })

    local function changeOutfit(outfitId)
        props.ChangeOutfit:FireServer(outfitId)
    end

    local function takeScreenshot()
        enabledCameraView:set(false)

        local worldModel = Instance.new("WorldModel")
        local viewport = viewportFrame:get()

        local renderRadius = 50
        local cameraPosition = Camera.CFrame.Position
        local cameraDirection = Camera.CFrame.LookVector

        local viewCircle = cameraPosition + cameraDirection * renderRadius

        local objects = workspace:GetPartBoundsInRadius(viewCircle, renderRadius, rayParams)
        local renderObjects, humanoids = getBackground(objects)

        local serializedCharacters = props.GetSerializedCharacters(humanoids)
        --print("Characters size:", #HttpService:JSONEncode(serializedCharacters))
        local _, serializedBackground = pcall(RBLXSerialize.Encode, renderObjects)
		--print("Background size:", #serializedBackground)

        --local _, unserializedBackground = pcall(RBLXSerialize.Decode, serializedBackground)
        --local unserializedCharacters = props.GetDeserializedCharacters(serializedCharacters)

        prepareHumanoids(humanoids, worldModel)

        --unserializedCharacters.Parent = worldModel
        --unserializedBackground.Parent = worldModel
        renderObjects.Parent = worldModel

        worldModel.Parent = viewport

        --viewport.CurrentCamera = unserializedBackground
        viewport.CurrentCamera = renderObjects
        --viewport.Visible = true

        props.OnScreenshotTaken({
            Viewport = viewport:Clone(),
            Characters = serializedCharacters,
            Background = serializedBackground,
        })

        props.ToggleCamera(false)
        props.IsOpened:set(true)

        changeOutfit()
        stopAnimation()
    end

    return Screen {
        Name = "CameraView",

        Enabled = Computed(function()
            return enabledCameraView:get()
        end),

        Cleanup = function()
            enableGuis()
        end,

        Children = {
            New "ViewportFrame" {
                Size = UDim2.fromScale(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Visible = false,

                [Ref] = viewportFrame,

                [Children] = {
                    New "UICorner" {
                        CornerRadius = UDim.new(0, 8),
                    },
                },
            },

            New "Frame" {
                Name = "Outfits",
                Size = UDim2.fromScale(0.25, 0.6),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                BackgroundTransparency = 1,

                Visible = Computed(function()
                    return outfitsVisible:get()
                end),

                [Children] = {
                    New("UIListLayout")({
                        Padding = UDim.new(0, 0),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        FillDirection = Enum.FillDirection.Vertical,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    }),

                    ForValues(outfits, function(outfit)
                        local outfitId = outfit.Name

                        return New "TextButton" {
                            Text = outfitId,
                            Name = outfitId,
                            Size = UDim2.fromScale(1, 1 / 7),
                            LayoutOrder = tonumber(outfitId:match("%d+")),
                            AutoButtonColor = true,
                            BackgroundTransparency = 0.5,

                            [OnEvent "Activated"] = function()
                                changeOutfit(outfitId)
                            end,
                        }
                    end, Fusion.cleanup)
                },
            },

            New "Frame" {
                Name = "Animations",
                Size = UDim2.fromScale(0.25, 0.6),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                BackgroundTransparency = 1,

                Visible = Computed(function()
                    return animationsVisible:get()
                end),

                [Children] = {
                    New("UIListLayout")({
                        Padding = UDim.new(0, 0),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        FillDirection = Enum.FillDirection.Vertical,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    }),

                    ForPairs(animations, function(animationName, animationId)
                        local stop = animationName == "Stop"

                        return animationName, New "TextButton" {
                            Text = animationName,
                            Name = animationName,
                            Size = UDim2.fromScale(1, 1 / 8),
                            AutoButtonColor = true,
                            BackgroundTransparency = 0.5,
                            LayoutOrder = stop and 2 or 1,
                            BackgroundColor3 = stop and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255),

                            [OnEvent "Activated"] = function()
                                playAnimation(animationId)
                            end,
                        }
                    end, Fusion.cleanup)
                },
            },

            New "TextButton" {
                Name = "Screenshot",
                Size = UDim2.fromScale(0.125, 0.125),
                Position = UDim2.fromScale(0.5, 0.95),
                AnchorPoint = Vector2.new(0.5, 1),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                AutoButtonColor = true,

                [OnEvent "Activated"] = takeScreenshot,

                [Children] = {
                    New "UICorner" {
                        CornerRadius = UDim.new(1, 0),
                    },

                    New "UIStroke" {
                        Thickness = 2,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    },

                    New "TextButton" {
                        Text = "X",
                        Name = "Close",
                        Size = UDim2.fromScale(0.4, 0.4),
                        Position = UDim2.fromScale(-0.5, 0.5),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        TextScaled = true,

                        [OnEvent "Activated"] = function()
                            stopAnimation()
                            changeOutfit()

                            props.ToggleCamera(false)
                            props.IsOpened:set(true)
                        end,

                        [Children] = {
                            New "UICorner" {
                                CornerRadius = UDim.new(1, 0),
                            },

                            New "UIStroke" {
                                Thickness = 2,
                                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                            },
                        },
                    },

                    New "TextButton" {
                        Text = "",
                        Name = "Outfits",
                        Size = UDim2.fromScale(0.4, 0.4),
                        Position = UDim2.fromScale(1.5, 0.5),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        TextScaled = true,

                        [OnEvent "Activated"] = function()
                            outfitsVisible:set(not outfitsVisible:get())
                            animationsVisible:set(false)
                        end,

                        [Children] = {
                            New "UICorner" {
                                CornerRadius = UDim.new(1, 0),
                            },

                            New "UIStroke" {
                                Thickness = 2,
                                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                            },

                            New "ImageLabel" {
                                Size = UDim2.fromScale(0.5, 0.5),
                                Position = UDim2.fromScale(0.5, 0.5),
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                BackgroundTransparency = 1,
                                Image = "rbxassetid://16568591138",
                            }
                        },
                    },

                    New "TextButton" {
                        Text = "",
                        Name = "Animations",
                        Size = UDim2.fromScale(0.4, 0.4),
                        Position = UDim2.fromScale(2.2, 0.5),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        TextScaled = true,

                        [OnEvent "Activated"] = function()
                            animationsVisible:set(not animationsVisible:get())
                            outfitsVisible:set(false)
                        end,

                        [Children] = {
                            New "UICorner" {
                                CornerRadius = UDim.new(1, 0),
                            },

                            New "UIStroke" {
                                Thickness = 2,
                                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                            },

                            New "ImageLabel" {
                                Size = UDim2.fromScale(0.8, 0.8),
                                Position = UDim2.fromScale(0.5, 0.5),
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                BackgroundTransparency = 1,
                                Image = "rbxassetid://16568591411",
                            }
                        },
                    },
                },
            },
        },
    }
end
