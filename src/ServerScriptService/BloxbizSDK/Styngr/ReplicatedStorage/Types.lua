export type CustomMetadata = {
	id: string,
	key: string,
}

export type Track = {
	artistNames: { string },
	audioAssetId: number,
	customMetadata: CustomMetadata,
	imageUrl: string,
	isLiked: string,
	remainingNumberOfSeconds: number,
	title: string,
	trackId: number,
	availableCountries: { string },
}

export type Session = {
	playlistId: number,
	sessionId: number,
	track: Track,
}

export type ClientTrack = {
	title: string,
	artistNames: { string },
	isLiked: boolean,
	assetId: number,
	encryptionKey: string,
	playlistId: string,
	timePosition: number,
	type: string,
	playing: boolean,
}

export type GeoBlocking = {
	include: { string },
	exclude: { string },
}

return {}
