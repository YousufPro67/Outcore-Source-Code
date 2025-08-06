local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

local GuiTrackingClient = {}

local batchedButtons = {}

local playerGui = Player:WaitForChild("PlayerGui")

local remotesFolder = ReplicatedStorage:WaitForChild("BloxbizRemotes")
local onSendGuiImpressions = remotesFolder:WaitForChild("OnSendGuiImpressions")

local TRACKED_INPUT_TYPES = {
    [Enum.UserInputType.Touch] = true,
    [Enum.UserInputType.MouseButton1] = true,
}

local function lookForButton(elements)
    for _, element in elements do
        if element:IsA("GuiButton") then
            return element
        end
    end
end

local function onInputBegan(input, gameProcessedEvent)
    if not gameProcessedEvent then
        return
    end

    local inputPosition = input.Position
    local inputType = input.UserInputType

    if not TRACKED_INPUT_TYPES[inputType] then
        return
    end

    local elements = playerGui:GetGuiObjectsAtPosition(inputPosition.X, inputPosition.Y)
    local button = lookForButton(elements)
    if not button then
        return
    end

    local path = button:GetFullName():split("PlayerGui.")[2]
    table.insert(batchedButtons, {
        button_name = button.Name,
        button_path = path,
    })
end

function GuiTrackingClient.init()
    UserInputService.InputBegan:Connect(onInputBegan)

    while task.wait(10) do
        if #batchedButtons == 0 then
            continue
        end

        onSendGuiImpressions:FireServer(batchedButtons)

        batchedButtons = {}
    end
end

return GuiTrackingClient