local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.BloxbizRemotes
local OnRunCommand = Remotes:WaitForChild("OnRunCommand")

local BloxbizSDK = script.Parent.Parent

local Utils = BloxbizSDK.Utils
local Fusion = require(Utils.Fusion)
local IconModule = require(Utils.Icon)

local ConfigReader = require(BloxbizSDK.ConfigReader)

local Value = Fusion.Value

local Config = require(script.Parent.Config)
local BuildCommandTool = require(script.BuildCommandTool)

local CommandTool = {}

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local TopbarButton

local Props = {
    Opened = Value(false),

    PlayerRanks = Value({}),

    SelectingUser = Value(false),
    SelectedCommand = Value(nil),

    IsMobile = false,

    Close = nil
}

function CommandTool.Open()
    Props.Opened:set(true)

    if TopbarButton then
        TopbarButton:select()
    end
end

function CommandTool.Close()
    Props.Opened:set(false)

    if TopbarButton then
        TopbarButton:deselect()
    end
end

function CommandTool.Toggle()
    if Props.Opened:get() then
        CommandTool.Close()
    else
        CommandTool.Open()
    end
end

function CommandTool.RunCommand(target, commandId)
    OnRunCommand:FireServer(target.Name, commandId)
end

local function setupTopbarButton()
    TopbarButton = IconModule.new()
	TopbarButton:setName("SBCommands")
    TopbarButton:setImage(ConfigReader:read("SBCommandsToolbarIcon"))
    TopbarButton:setLabel(ConfigReader:read("SBCommandsToolbarButtonLabel"))
	TopbarButton:align("Left")
	TopbarButton:bindEvent("selected", CommandTool.Open)
	TopbarButton:bindEvent("deselected", CommandTool.Close)
end

local function IsMobile()
	local viewPortSize = Camera.ViewportSize
	local touchEnabled = UserInputService.TouchEnabled

	return (viewPortSize.X <= 1200 or viewPortSize.Y <= 800) and touchEnabled
end

function CommandTool.Init()
    local DefaultRank = Config:Read("DefaultRank")

    local function applyRanks()
        local stringRanks = Player:GetAttribute("SBCommandsRanks")
        if typeof(stringRanks) ~= "string" then
            Props.PlayerRanks:set(DefaultRank)
            return
        end

        local ranks = {}
        for rank in string.gmatch(stringRanks, "([^,]+)") do
            table.insert(ranks, rank)
        end
        Props.PlayerRanks:set(ranks)
    end

    Player:GetAttributeChangedSignal("SBCommandsRanks"):Connect(applyRanks)
    applyRanks()

    Props.Close = CommandTool.Close
    Props.RunCommand = CommandTool.RunCommand

    Props.IsMobile = IsMobile()

    BuildCommandTool(Props)

    if ConfigReader:read("SBCommandsShowToolbarButton") then
        setupTopbarButton()
    end
end

return CommandTool