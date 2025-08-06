return function(props, labelName)
    local Utils = script.Parent.Parent.Parent.Utils
    local Fusion = require(Utils.Fusion)
    local IconModule = require(Utils.Icon)

    local icons = props.ICONS
    local audio = props.AudioInstance

    local maxCharCount = props.MAX_CHAR_LENGTH

    local function getSongName()
        local name = "Loading..."

        local audioData = props.PlayedAudioData:get()
        if audioData then
            name = audioData.SongName
        end

        local count = #name
        if count > maxCharCount then
            name = name:sub(1, 12) .. "..."
        end

        return name
    end

    local icon = IconModule.new()
    icon:setName("MusicPlayer")
    icon:setLabel(labelName)
    icon:align("Right")
    icon:setOrder(10)

    local songName = IconModule.new()
    songName:setLabel(getSongName())
    songName:disableStateOverlay(true)
    songName:oneClick(true)
    songName:bindEvent("selected", function()
        icon:deselect()
    end)

    local playIcon = IconModule.new()
    playIcon:setImage(icons.Pause)
    playIcon:oneClick(true)
    playIcon:bindEvent("selected", function()
        props.TogglePauseAudio()
    end)

    local nextIcon = IconModule.new()
    nextIcon:setImage(icons.Next)
    nextIcon:oneClick(true)
    nextIcon:bindEvent("selected", function()
        props.NextAudio()
    end)

    icon:setMenu({
        songName,
        playIcon,
        nextIcon,
    })

    audio.Paused:Connect(function()
        playIcon:setImage(icons.Play)
    end)

    audio.Resumed:Connect(function()
        playIcon:setImage(icons.Pause)
    end)

    audio.Played:Connect(function()
        playIcon:setImage(icons.Pause)
    end)

    Fusion.Observer(props.PlayedAudioData):onChange(function()
        songName:setLabel(getSongName())
    end)
end