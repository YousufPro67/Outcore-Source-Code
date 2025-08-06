local Utils = script.Parent.Parent.Parent.Parent.Utils
local ModuleCombiner = require(Utils.ModuleCombiner)

local toCombine = {
    [1] = script:WaitForChild('IdleAnim1');
    [2] = script:WaitForChild('IdleAnim2');
    [3] = script:WaitForChild('IdleAnim3');
}

local combined = {
	Properties = {
		Looping = true,
		Priority = Enum.AnimationPriority.Core
	};
	Keyframes = ModuleCombiner.combine(toCombine);
}

return combined