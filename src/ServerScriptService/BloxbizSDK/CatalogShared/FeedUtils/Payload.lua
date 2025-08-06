export type Item = {
	id: number,
	name: string?,
	layered: boolean?,
	slot: number,
	price: number?,
}

export type Payload = {
	name: string,
	items: { Item },

	head_color: string?,
	torso_color: string?,
	left_arm_color: string?,
	right_arm_color: string?,
	left_leg_color: string?,
	right_leg_color: string?,
}

export type GameStats = {
	creator: number,
	game_id: number,
}

export type Private = {
	likes: number,
	own_like: boolean?,
}

export type ServerResponse = {
	guid: string,
	name: string,

	created_at: string,
}

export type BackendOutfit = {
	creator: number,
	game_id: number,

	guid: string,
	name: string,

	likes: number,
	own_like: boolean?,
    times_boosted: number,

	created_at: string,
	items: { Item },

	head_color: string?,
	torso_color: string?,
	left_arm_color: string?,
	right_arm_color: string?,
	left_leg_color: string?,
	right_leg_color: string?,
}

local ALLOWED_SLOTS = {
	TShirt = 2,
    Hat = 8,
    Shirt = 11,
    Pants = 12,

    Head = 17,
    Face = 18,
    Gear = 19,
    DynamicHead = 79,

    Torso = 27,
    RightArm = 28,
    LeftArm = 29,
    LeftLeg = 30,
    RightLeg = 31,

    HairAccessory = 41,
    FaceAccessory = 42,
    NeckAccessory = 43,
    ShoulderAccessory = 44,
    FrontAccessory = 45,
    BackAccessory = 46,
    WaistAccessory = 47,
    TShirtAccessory = 64,
    ShirtAccessory = 65,
    PantsAccessory = 66,
    JacketAccessory = 67,
    SweaterAccessory = 68,
    ShortsAccessory = 69,
    LeftShoeAccessory = 70,
    RightShoeAccessory = 71,
    DressSkirtAccessory = 72,
    EyebrowAccessory = 76,
    EyelashAccessory = 77,

    ClimbAnimation = 48,
    DeathAnimation = 49,
    FallAnimation = 50,
    IdleAnimation = 51,
    JumpAnimation = 52,
    RunAnimation = 53,
    SwimAnimation = 54,
    WalkAnimation = 55,
    PoseAnimation = 56,
    EmoteAnimation = 61,
    MoodAnimation = 78,
}
table.freeze(ALLOWED_SLOTS)


return {
	Slots = ALLOWED_SLOTS,
}