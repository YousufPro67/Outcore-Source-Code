local Common = {}

local MORE_OPTIONS_BUTTON_WIDTH = 50
local GAP = 10
local TOP_ELEMENT_HEIGHT = 50
local HAMBURGER_BUTTON_WIDTH = 24

Common.Enums = {
	COUNTER_END_TIME = 30, -- seconds
}

function Common.calcualteXPosition(
	width: number,
	viewportSizeX: number,
	moreOptionsButtonWidth: number,
	gap: number
): number
	if not viewportSizeX then
		viewportSizeX = game.Workspace.CurrentCamera.ViewportSize.X
	end

	if not moreOptionsButtonWidth then
		moreOptionsButtonWidth = MORE_OPTIONS_BUTTON_WIDTH
	end

	if not gap then
		gap = GAP
	end

	return viewportSizeX - width - moreOptionsButtonWidth - gap
end

function Common.calcualteYPosition(height: number, viewportSizeY: number, topElementHeight: number): number
	if not viewportSizeY then
		viewportSizeY = game.Workspace.CurrentCamera.ViewportSize.Y
	end

	if not topElementHeight then
		topElementHeight = TOP_ELEMENT_HEIGHT
	end

	return viewportSizeY - (viewportSizeY - height - topElementHeight)
end

function Common.calculatePlayerWidth(width: number, numberOfPlaylists: number): number
	local newWidth = if numberOfPlaylists <= 1 then width - HAMBURGER_BUTTON_WIDTH else width

	return newWidth
end

return Common
