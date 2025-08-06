--TODO: investigate - does ordering matter here? need to check all the faces
return {
	[Enum.NormalId.Front] = {
		{ 1, 1, -1 }, --v1 - top front right
		{ 1, -1, -1 }, --v2 - bottom front right
		{ -1, -1, -1 }, --v3 - bottom front left
		{ -1, 1, -1 }, --v4 - top front left
	},
	[Enum.NormalId.Back] = {
		{ 1, 1, 1 }, --v5 - top back right
		{ 1, -1, 1 }, --v6 - bottom back right
		{ -1, -1, 1 }, --v7 - bottom back left
		{ -1, 1, 1 },  --v8 - top back left
	},
	[Enum.NormalId.Left] = {
		{ -1, -1, -1 }, --v3 - bottom front left
		{ -1, 1, -1 }, --v4 - top front left
		{ -1, -1, 1 }, --v7 - bottom back left
		{ -1, 1, 1 },  --v8 - top back left
	},
	[Enum.NormalId.Right] = {
		{ 1, 1, -1 }, --v1 - top front right
		{ 1, -1, -1 }, --v2 - bottom front right
		{ 1, 1, 1 }, --v5 - top back right
		{ 1, -1, 1 }, --v6 - bottom back right
	},
	[Enum.NormalId.Top] = {
		{ 1, 1, -1 }, --v1 - top front right
		{ -1, 1, -1 }, --v4 - top front left
		{ 1, 1, 1 }, --v5 - top back right
		{ -1, 1, 1 },  --v8 - top back left
	},
	[Enum.NormalId.Bottom] = {
		{ 1, -1, -1 }, --v2 - bottom front right
		{ -1, -1, -1 }, --v3 - bottom front left
		{ 1, -1, 1 }, --v6 - bottom back right
		{ -1, -1, 1 }, --v7 - bottom back left
	},
}
