local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local scriptParent = script.Parent

local frameSamples = {}
local sampleCount = 30 -- Number of frames to average over
local lastUpdateTime = 0

RunService.RenderStepped:Connect(function(dt)
    table.insert(frameSamples, dt)
    if #frameSamples > sampleCount then
        table.remove(frameSamples, 1)
    end

    local currentTime = tick()
    if currentTime - lastUpdateTime >= 0.1 then
        lastUpdateTime = currentTime
        
        local sum = 0
        for _, sample in ipairs(frameSamples) do
            sum = sum + sample
        end
        
        local averageDt = sum / #frameSamples
        if averageDt > 0 then
            local fps = math.floor(1 / averageDt)
            scriptParent.Text = tostring(fps)
        else
            scriptParent.Text = "..."
        end
    end
end)
