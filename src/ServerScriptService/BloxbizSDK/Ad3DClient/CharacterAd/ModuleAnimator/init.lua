local RunService = game:GetService("RunService")
local RenderStepped = RunService.RenderStepped
local module = {}

--Keyframes: Unformatted, Formatted, Loaded

local Animate = require(script.Animate)

--Formatted keyframes here
module.animationKeyframes = {
	--[[
		[animationTrackName] = keyframedata
	]]
}

--Loaded keyframes per character here
module.animationTracks = {
	--[[
	
	[characterModel] = {
		[1] = { --animationTrack
			[1] = { --individual keyframe, sorted
				Time = 1.23;
				Keyframes = {keyframedata};
			}
		}
	}
	
	]]
}

task.spawn(function()
	while true do
		for character, animationTrackList in pairs(module.animationTracks) do
			for _, animationTrack in ipairs(animationTrackList) do
				if not animationTrack.playing then
					continue
				elseif animationTrack.playing then
					local trackEnded = Animate(character, animationTrack)

					if trackEnded then
						module.markAllTransitioning(animationTrackList, animationTrack)
					end
				end
			end
		end

		RenderStepped:Wait()
	end
end)

function module.markAllTransitioning(animationTrackList, trackThatEnded)
	for _, animationTrack in ipairs(animationTrackList) do
		if animationTrack.playing then
			animationTrack.transitionStart(trackThatEnded)
		end
	end
end

function module.formatKeyframeData(keyframeData)
	local newKeyframeData = {}

	for animTime, keyframe in pairs(keyframeData) do
		local newTable = {
			Time = animTime,
			Keyframe = keyframe,
		}

		table.insert(newKeyframeData, newTable)
	end

	table.sort(newKeyframeData, function(a, b)
		if tonumber(a.Time) > tonumber(b.Time) then
			return false
		else
			return true
		end
	end)

	return newKeyframeData
end

--formattedKeyframeData = newKeyframeData
--[[
	Returned table:
		{
			[jointObject] = CFrame;
		}
]]
function module.loadKeyframes(character, formattedKeyframeData)
	local keyframes = {}
	local motor6Ds = {}

	for _, v in pairs(character:GetDescendants()) do
		if v.ClassName == "Motor6D" then
			table.insert(motor6Ds, v)
		end
	end

	local function getMotor6DForPart(part)
		for _, v in pairs(motor6Ds) do
			if v.Part1 == part then
				return v
			end
		end
	end

	local reorganizeKeyframe
	reorganizeKeyframe = function(joints, name, reorganized)
		local reorganized = reorganized or {}

		if joints.CFrame then
			local part = character[name]
			local motor6d = getMotor6DForPart(part)

			if motor6d then
				reorganized[motor6d] = joints.CFrame
			end
		end

		for name, newJoints in pairs(joints) do
			if name ~= "CFrame" then
				reorganizeKeyframe(newJoints, name, reorganized)
			end
		end

		return reorganized
	end

	for index, keyframe in ipairs(formattedKeyframeData) do
		local organizedKeyframe = reorganizeKeyframe(keyframe.Keyframe)
		table.insert(keyframes, { Time = keyframe.Time, Keyframe = organizedKeyframe })
	end

	return keyframes
end

function module.searchForTrack(character, trackNameToSearchFor)
	for index, animationTrack in pairs(module.animationTracks[character]) do
		if animationTrack.name == trackNameToSearchFor then
			return animationTrack
		end
	end

	return false
end

function module.highestPlayingTrack(character)
	for i = 1, #module.animationTracks[character] do
		local track = module.animationTracks[character][i]
		if track.playing then
			return track
		end
	end
end

function module.loadAnimation(character, animationName, animation)
	if not module.animationTracks[character] then
		module.animationTracks[character] = {}
	end

	if module.searchForTrack(character, animationName) then
		return module.searchForTrack(character, animationName)
	end

	if not module.animationKeyframes[animationName] then
		module.animationKeyframes[animationName] = module.formatKeyframeData(animation.Keyframes)
	end

	local formattedKeyframes = module.animationKeyframes[animationName]
	local loadedKeyframes = {}

	local animationTrack = {
		name = animationName,
		looping = animation.Properties.Looping,
		priority = animation.Properties.Priority,
		loadedKeyframes = module.loadKeyframes(character, formattedKeyframes),
		playing = false, --tick if true

		length = nil,
		lastTick = nil,
		progress = 0,

		transitioning = false,
		transitionStartTime = nil,
		previousKeyframe = nil, --old loaded keyframe if Transition is true
	}

	animationTrack.length = formattedKeyframes[#formattedKeyframes].Time

	function animationTrack.reset()
		animationTrack.lastTick = tick()
		animationTrack.progress = 0
		animationTrack.playing = tick()
	end

	function animationTrack.stop()
		animationTrack.lastTick = nil
		animationTrack.progress = 0
		animationTrack.playing = false
		animationTrack.transitionEnd()
	end

	function animationTrack.transitionStart(oldTrack)
		animationTrack.transitioning = true
		animationTrack.transitionStartTime = tick()
		animationTrack.previousKeyframe = oldTrack.loadedKeyframes[#oldTrack.loadedKeyframes]
	end

	function animationTrack.transitionEnd()
		animationTrack.transitioning = false
		animationTrack.transitionStartTime = nil
		animationTrack.previousKeyframe = nil
	end

	table.insert(module.animationTracks[character], animationTrack)

	local nameToPriority = {
		["Core"] = 1,
		["Idle"] = 2,
		["Movement"] = 3,
		["Action"] = 4,
	}

	table.sort(module.animationTracks[character], function(track1, track2)
		if nameToPriority[track1.priority.Name] > nameToPriority[track2.priority.Name] then
			return false
		elseif nameToPriority[track1.priority.Name] < nameToPriority[track2.priority.Name] then
			return true
		elseif nameToPriority[track1.priority.Name] == nameToPriority[track2.priority.Name] then
			if track1.looping then
				return true
			elseif track2.looping then
				return false
			else
				return track1.length < track2.length
			end
		end
	end)

	return animationTrack
end

function module.playAnimation(character, trackName)
	if not module.animationTracks[character] then
		module.animationTracks[character] = {}
	end

	local animationTrack = module.searchForTrack(character, trackName)

	if animationTrack then
		local highestTrack = module.highestPlayingTrack(character)

		if highestTrack then
			animationTrack.transitionStart(highestTrack)
		end

		animationTrack.reset()
	end

	return animationTrack
end

function module.stopAnimation(character, trackName)
	if not module.animationTracks[character] then
		module.animationTracks[character] = {}
	end

	local animationTrack = module.searchForTrack(character, trackName)

	if animationTrack then
		animationTrack.stop()
	end

	return animationTrack
end

return module
