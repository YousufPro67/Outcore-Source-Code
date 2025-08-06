-- Important note: Precision checks currently only for 'players' and the 'localplayer', not 'parts'.

-- enumName, enumValue, additionalProperty
return {
	{"WholeBody", 1}, -- Multiple checks will be casted over an entire players character
	{"Centre", 2}, -- A singular check will be performed on the players HumanoidRootPart
}