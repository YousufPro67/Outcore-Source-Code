--[[
	Looping
	Keyframes
	Length
	Progress
]]

local TIME_TOLERANCE_FOR_NO_LERP = 0.016
local ANIM_TRACK_TRANSITION_TIME = 0.25

local function getKeyframe(animationTrack)
	local keyframe, nextKeyframe = nil, nil

	for i, currentKeyframe in ipairs(animationTrack.loadedKeyframes) do
		if animationTrack.progress >= currentKeyframe.Time then
			keyframe, nextKeyframe = currentKeyframe, animationTrack.loadedKeyframes[i + 1]
		end
	end

	return keyframe, nextKeyframe
end

local function displayKeyframe(keyframe)
	for jointObject, CFrame in pairs(keyframe) do
		jointObject.Transform = CFrame
	end
end

local function lerpKeyframe(baseKeyframe, goalKeyframe, delta)
	local newKeyframe = {}

	for jointObject, baseCf in pairs(baseKeyframe) do
		if goalKeyframe[jointObject] then
			newKeyframe[jointObject] = baseCf:lerp(goalKeyframe[jointObject], delta)
		else
			newKeyframe[jointObject] = baseCf
		end
	end

	return newKeyframe
end

return function(character, animationTrack)
	local lastFrame = false
	local t = tick()
	local timeDelta = (t - animationTrack.lastTick)
	animationTrack.progress = animationTrack.progress + timeDelta
	animationTrack.lastTick = t

	if animationTrack.progress >= animationTrack.length then
		if animationTrack.looping then
			animationTrack.reset()
			return false
		else
			lastFrame = true
			animationTrack.progress = animationTrack.length
		end
	end

	local keyframe, nextKeyframe = getKeyframe(animationTrack)
	local deltaKeyframeBaseTime = t - (animationTrack.playing + keyframe.Time)
	local newKeyframe

	if animationTrack.transitioning then
		if t - animationTrack.transitionStartTime > ANIM_TRACK_TRANSITION_TIME then
			animationTrack.transitionEnd()
		else
			nextKeyframe = keyframe
			keyframe = animationTrack.previousKeyframe
			deltaKeyframeBaseTime = t - animationTrack.transitionStartTime
			newKeyframe = lerpKeyframe(
				keyframe.Keyframe,
				nextKeyframe.Keyframe,
				deltaKeyframeBaseTime / ANIM_TRACK_TRANSITION_TIME
			)
		end
	end

	if not nextKeyframe or deltaKeyframeBaseTime < TIME_TOLERANCE_FOR_NO_LERP then
		displayKeyframe(keyframe.Keyframe)
	else
		newKeyframe = newKeyframe
			or lerpKeyframe(
				keyframe.Keyframe,
				nextKeyframe.Keyframe,
				deltaKeyframeBaseTime / (nextKeyframe.Time - keyframe.Time)
			)
		displayKeyframe(newKeyframe)
	end

	if lastFrame then
		animationTrack.stop()
		return true
	else
		return false
	end
end
