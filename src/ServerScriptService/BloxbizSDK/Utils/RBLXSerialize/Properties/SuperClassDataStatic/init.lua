local Utils = script.Parent.Parent.Parent.Parent.Utils
local ModuleCombiner = require(Utils.ModuleCombiner)

local toCombine = {
    [1] = script:WaitForChild('Data1');
    [2] = script:WaitForChild('Data2');
    [3] = script:WaitForChild('Data3');
}

local combined = ModuleCombiner.combine(toCombine)

return combined