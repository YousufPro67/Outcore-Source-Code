export type Item = {
	AssetId: number,
	AssetType: number,
	Price: number?,
	Name: string?,
}

export type Outfit = {
	GUID: string,
	Name: string,

	Items: { Item },
	Colors: {
		Head: string?,
		Torso: string?,
		LeftArm: string?,
		LeftLeg: string?,
		RightArm: string?,
		RightLeg: string?,
	},

	Likes: number,
	OwnLike: boolean,
	Boosts: number,

	CreatorId: number,
	GameId: number,
	CreatedAt: string,
}



return {}