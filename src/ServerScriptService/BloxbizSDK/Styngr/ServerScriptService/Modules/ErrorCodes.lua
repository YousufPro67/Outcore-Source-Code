local StatusCodes = {
	UnprocessableEntity = 422,
}

return {
	PlaylistEnded = StatusCodes.UnprocessableEntity,
	EmptyPlaylist = StatusCodes.UnprocessableEntity,
}
