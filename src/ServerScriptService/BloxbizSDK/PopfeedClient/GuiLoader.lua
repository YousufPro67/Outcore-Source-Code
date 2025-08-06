local RunService = game:GetService("RunService")

local HotReload = require(script.Parent.HotReload)

local GuiLoader = {}

local IsStudio = RunService:IsStudio()

function GuiLoader.Load(MakeGuiFunction, Parent, Props)
    local Gui = MakeGuiFunction(Props)
    Gui.Parent = Parent

    if IsStudio then
        table.insert(HotReload.MakeGuiData, {
            Gui = Gui,
            Props = Props,
            Parent = Parent,
            Function = MakeGuiFunction,
        })
    end

    return Gui
end

return GuiLoader