local RunService = game:GetService("RunService")

local Gui = script.Parent.Gui
local Windows = Gui.Windows
local Components = Gui.Components

local IsStudio = RunService:IsStudio()

local HotReload = {}

HotReload.MakeGuiData = {}

if IsStudio then
    local function refresh()
        for _, data in HotReload.MakeGuiData do
            local newGui = data.Function(data.Props)

            data.Gui:Destroy()
            data.Gui = newGui

            newGui.Parent = data.Parent
        end
    end

    local function connectModules(modules)
        for _, module in modules:GetChildren() do
            if not module:IsA("ModuleScript") then
                continue
            end

            local parent = module.Parent
            local clone = module:Clone()
            clone.Parent = parent

            module.Parent = nil

            module.Changed:Connect(function()
                clone:Destroy()
                clone = module:Clone()
                clone.Parent = parent

                refresh()
            end)
        end
    end

    connectModules(Windows)
    connectModules(Components)
end

return HotReload