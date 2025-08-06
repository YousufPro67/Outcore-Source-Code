local module = {}

local properties = {
    "ClimbAnimation",
    "FallAnimation",
    "IdleAnimation",
    "JumpAnimation",
    "MoodAnimation",
    "RunAnimation",
    "SwimAnimation",
    "WalkAnimation",

    "HeadColor",
    "TorsoColor",
    "LeftArmColor",
    "LeftLegColor",
    "RightArmColor",
    "RightLegColor",

    "Face",
    "Head",
    "Torso",
    "LeftArm",
    "LeftLeg",
    "RightArm",
    "RightLeg",

    "Pants",
    "Shirt",
    "GraphicTShirt",

    "HeadScale",
    "WidthScale",
    "DepthScale",
    "HeightScale",
    "BodyTypeScale",
    "ProportionScale",
}

local propertiesDictionary = {}
for _, property in properties do
    propertiesDictionary[property] = true
end

function module.IsValidProperty(property)
    return propertiesDictionary[property]
end

function module.FetchDescriptionToTable(humanoidDescrition): {[string]: any}
    local data = {}

    for _, property in properties do
        data[property] = humanoidDescrition[property]
    end

    data.Accessories = humanoidDescrition:GetAccessories(true)

    return data
end

return module