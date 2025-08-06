local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")

local ConfigReader = require(script.Parent.Parent.ConfigReader)

local DefaultPlaylist = require(script.Parent.DefaultPlaylist)
local CompactAudioPlayer = require(script.CompactAudioPlayer)
local AudioPlayerComponent = require(script.AudioPlayerComponent)

local Fusion = require(script.Parent.Parent.Utils.Fusion)

local LocalPlayer = Players.LocalPlayer

local HeadphonesClient = {}

local currentPlaylist = {}
local currentAudioIndex = 1

local Props = {
    AudioInstance = nil,
    PlayedAudioData = Fusion.Value(),

    NextAudio = nil,
    TogglePauseAudio = nil,

    ICONS = {
        Play = "rbxassetid://17511829716",
        Pause = "rbxassetid://17511829867",
        Next = "rbxassetid://17511830096",
    },

    MAX_CHAR_LENGTH = 12,
}

local function getAudioInstance()
    local audio = SoundService:FindFirstChild("BloxbizHeadphones")
    if not audio then
        audio = Instance.new("Sound")
        audio.Name = "BloxbizHeadphones"
        audio.Parent = SoundService
    end

    Props.AudioInstance = audio

    return audio
end

local function getAudioData()
    local totalAudios = #currentPlaylist

    local audioData = currentPlaylist[currentAudioIndex]
    if not audioData then
        if currentAudioIndex < 1 then
            currentAudioIndex = totalAudios
        else
            currentAudioIndex = 1
        end
        audioData = currentPlaylist[currentAudioIndex]
    end

    Props.PlayedAudioData:set(audioData)

    return audioData
end

local endedConnection

local function playAudio()
    local audioData = getAudioData()
    if not audioData then
        warn("This playlist has no songs.")
        return
    end

    local audio = getAudioInstance()
    audio.SoundId = audioData.SoundId

    if endedConnection then
        endedConnection:Disconnect()
    end

    endedConnection = audio.Ended:Connect(function()
        currentAudioIndex += 1
        playAudio()
    end)

    audio.TimePosition = 0
    audio:Play()
end

local function nextAudio()
    currentAudioIndex += 1
    playAudio()
end

local function previousAudio()
    currentAudioIndex -= 1
    playAudio()
end

local function togglePauseAudio()
    local audio = getAudioInstance()
    if audio.IsPaused then
        audio:Resume()
    else
        audio:Pause()
    end
end

local function onCharactedAdded(character)
    local headphones = ConfigReader:read("MusicPlayerPlaylist")
    if typeof(headphones) ~= "table" then
        if typeof(headphones) == "Instance" and headphones:IsA("ModuleScript") then
            headphones = require(headphones)
        else
            warn("Bloxbiz: No music player playlist found, playing default playlist")
            headphones = DefaultPlaylist
        end
    elseif #headphones < 1 then
        warn("Bloxbiz: No music player playlist found, playing default playlist")
        headphones = DefaultPlaylist
    end

    currentPlaylist = headphones
    playAudio()

    local toggleCompactVersion = ConfigReader:read("MusicPlayerCompactDesign")
    if toggleCompactVersion then
        CompactAudioPlayer(Props, ConfigReader:read("MusicPlayerToolbarButtonLabel"))
    else
        AudioPlayerComponent(Props)
    end
end

function HeadphonesClient.Init()
    Props.NextAudio = nextAudio
    Props.TogglePauseAudio = togglePauseAudio

    if LocalPlayer.Character then
        onCharactedAdded(LocalPlayer.Character)
    else
        LocalPlayer.CharacterAdded:Wait()
        onCharactedAdded(LocalPlayer.Character)
    end
end

return HeadphonesClient