--// Variables
local knit = require(game.ReplicatedStorage.Packages.Knit)
knit.Start():await()
local PlrMovement = knit.GetService("PlayerMovement")
local setting = knit.GetService("SettingService")
local plrService = knit.GetService("PlayerState")
local questservice = knit.GetService("QuestService")
local plrdata = knit.GetService("PlayerDataManager")
local players = game.Players
local plrSettings = {}
local playerdata = {}
local cs = knit.GetService("CounterService")
local SkipStage = game.ReplicatedStorage.RemoteEvents.SkipStage
local resetGui = game.StarterGui.MainMenu.RetryGUI:Clone()
local finishgui = game.StarterGui.MainMenu.FinishGUI:Clone()
local spont = workspace.Spawnpoints:GetChildren()
local connections = {}
local spoints = {}

--// Setup
players.RespawnTime  = math.huge
for _,point:SpawnLocation in spont do
	spoints[point.Value.Value] = point
end
plrService.initvals(plrdata,cs,setting)

--// Functions
local function UpdateTimer(plr:Player, profile)
	local plrgui
	local succes, erro = pcall(function()
		plrgui = plr.PlayerGui	
	end)
	if not succes then return end
	local SpeedrunGui = plr.PlayerGui.SpeedrunTimer
	if not SpeedrunGui then return end
	local hum:Humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
	if plrSettings[plr.UserId].INGAME then
		SpeedrunGui.TextLabel.Visible = true
		SpeedrunGui.Meters.Visible = true
		local Profile = profile
		local Settings = plrSettings[plr.UserId]
		local Stage = Settings.SPS
		if (Profile.LEVELS < Stage + 1) and (Profile.LEVELS < 9) then
			SpeedrunGui.Skip.Visible = true
		else
			SpeedrunGui.Skip.Visible = false
		end
		if hum.MoveDirection.Magnitude > 0 then
			if cs:GetTimer(plr.UserId).Running == false then
				cs:StartTimer(plr.UserId)
			end
		end
	else
		SpeedrunGui.TextLabel.Visible = false
		SpeedrunGui.Meters.Visible = false
		SpeedrunGui.Skip.Visible = false
		cs:StopTimer(plr.UserId)
	end
	cs:UpdateTimer(plr.UserId)
	local timer = cs:GetTimer(plr.UserId)
	if timer.Running then
		SpeedrunGui.TextLabel.Text = string.format("%02d:%02d:%02d", timer.Minutes, timer.Seconds, timer.Milliseconds)
	else
		SpeedrunGui.TextLabel.Text = "00:00:00"
	end
end
function SetValue(plr:Player,value,name)
	if name == "INGAME" or name == "SPS" then
		plrService:onPlayerRespawn(plr,plrSettings[plr.UserId].INGAME,plrSettings[plr.UserId].SPS,spoints)
	elseif name == "FOLLOW" then
		plr.Character:FindFirstChildOfClass("Humanoid").JumpPower = value and 50 or 0
		plr.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = value and playerdata[plr.UserId].SPEED or 0
	end
end
local function DataChanged(player:Player,data)
	if data then
		playerdata[player.UserId] = data
	end
end
local function SettingsChanged(player:Player, data)
	if data then
		plrSettings[player.UserId] = data
	end
end
local function PlrDied(player:Player)
	plrService:IsDied(player,plrSettings[player.UserId].INGAME,plrSettings[player.UserId].FOLLOW)
end
local function OnPlayerAdded(player:Player)
	connections[player.UserId] = {}
	setting.Players:Initialize(player)
	setting.Players.OnValueChanged:Connect(player,SetValue)
	setting.Players.OnDataChanged:Connect(player,SettingsChanged)
	
	for _, v in  workspace.Spawnpoints:GetChildren() do
		player:AddReplicationFocus(v)
	end
	cs:CreateTimer(player.UserId)
	player:LoadCharacter()
	plrSettings[player.UserId] = setting.Players:Get(player)
	
	playerdata[player.UserId] = plrdata:Get(player)
	
	questservice.Init(player, plrdata)
	questservice.MakeQuest(player, "STUDS", "SKYHOP", "Sprint %d/%d studs.", "STUDS", 150000, playerdata[player.UserId].STUDS, "rbxassetid://12975608939")
	questservice.MakeQuest(player, "JUMPS", "SKYHOP", "Jump %d/%d times.", "JUMPS", 100, playerdata[player.UserId].JUMPS, "rbxassetid://11432860708")
	questservice.MakeQuest(player, "FINISHES", "SKYHOP", "Finish %d/%d levels.", "FINISHES", 25, playerdata[player.UserId].FINISHES, "rbxassetid://12966839549")
	questservice.MakeQuest(player, "KILLS", "SKYHOP", "Kill %d/%d enemies.", "KILLS", 50, playerdata[player.UserId].KILLS, "rbxassetid://12966829486")
	plrdata.OnDataChanged:Connect(player,DataChanged)
	local character = player.Character or player.CharacterAdded:Wait()
	plrService:onPlayerRespawn(player,plrSettings[player.UserId].INGAME,plrSettings[player.UserId].SPS,spoints)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	humanoid.WalkSpeed = playerdata[player.UserId].SPEED
	table.insert(connections[player.UserId], player.CharacterAdded:Connect(function(character: Model) 
		questservice.CheckQuests(player, "SKYHOP")
		game.ReplicatedStorage.RemoteEvents.UpdateQuests:FireClient(player)
		plrService:onPlayerRespawn(player,plrSettings[player.UserId].INGAME,plrSettings[player.UserId].SPS,spoints)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		humanoid.WalkSpeed = playerdata[player.UserId].SPEED
		humanoid.Died:Once(function() 
			PlrDied(player)
		end)
	end))
	if playerdata[player.UserId].MUSIC == true or playerdata[player.UserId].MUSIC == false then
		plrdata:Set(player, "MUSIC", 100)
		plrdata:Save(player)
	end
	--[[PlrMovement:Init(player)
	PlrMovement:SetSpeed(player,30,100,2)
	
	game:GetService("RunService").Stepped:Connect(function(deltaTime: number) 
		task.wait(0.5)
		if not PlrMovement:CheckIdle(player) and plrSettings[player.UserId].INGAME and plrSettings[player.UserId].FOLLOW then
			PlrMovement:Accelerate(player,true)
		end
		
	end)]]
	table.insert(connections[player.UserId], game["Run Service"].Stepped:Connect(function()
		UpdateTimer(player, playerdata[player.UserId])
	end))
end
local function OnPlayerRemoved(player:Player)
	if cs:GetTimer(player.UserId) ~= nil then
		cs:RemoveTimer(player.UserId)
	end
	for _,c:RBXScriptConnection in connections[player.UserId] do
		c:Disconnect()
	end
end

--// Player Added
players.PlayerAdded:Connect(function(player: Player) 
	OnPlayerAdded(player)
end)
for _, plr in pairs(players:GetPlayers()) do
	if plrSettings[plr.UserId] then
		continue
	end
	OnPlayerAdded(plr)
end

local debounce = {} -- Debounce table to track players who recently triggered the finish

for _, obj in workspace:GetDescendants() do
    if obj.Name == "Finish" and obj:IsA("BasePart") then
        obj.Touched:Connect(function(otherPart)
            local humanoid = otherPart.Parent:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local plr = players:GetPlayerFromCharacter(otherPart.Parent)
                if plr then
                    -- Check debounce to prevent multiple triggers
                    if debounce[plr.UserId] then
                        return
                    end
                    debounce[plr.UserId] = true

                    -- Pause the timer immediately
                    cs:PauseTimer(plr.UserId)
                    
                    -- Rest of your finish logic
                    local Timer = cs:GetTimer(plr.UserId)
                    local Time = string.format("%02d:%02d:%02d", Timer.Minutes, Timer.Seconds, Timer.Milliseconds)
                    local Settings = plrSettings[plr.UserId]
                    local Stage = Settings.SPS
                    local Profile;
                    local Best;
                    local BestTime;

                    local function ParseTimeString(timeString)
                        local Minutes, Seconds, Milliseconds = string.match(timeString, "(%d+):(%d+):(%d+)")
                        return {
                            Minutes = tonumber(Minutes),
                            Seconds = tonumber(Seconds),
                            Milliseconds = tonumber(Milliseconds)
                        }
                    end

                    local function AssignValues()
                        playerdata[plr.UserId] = plrdata:Get(plr)
                        Profile = plrdata:Get(plr)
                        Best = Profile.BEST_TIMES[Stage]
                        BestTime = Best and ParseTimeString(Best) or nil
                    end

                    local function isBetterTime(currentTime, bestTime)
                        if currentTime.Minutes < bestTime.Minutes then
                            return true
                        elseif currentTime.Minutes == bestTime.Minutes then
                            if currentTime.Seconds < bestTime.Seconds then
                                return true
                            elseif currentTime.Seconds == bestTime.Seconds then
                                if currentTime.Milliseconds < bestTime.Milliseconds then
                                    return true
                                end
                            end
                        end
                        return false
                    end

                    AssignValues()
                    plrService:IsFinished(plr, Settings.INGAME, Settings.FOLLOW, Stage)
					print("Finish triggered for player:", plr.Name)
					Profile.FINISHES = Profile.FINISHES + 1

                    if Profile.LEVELS < Stage + 1 then
                        plrdata:Set(plr, "LEVELS", Stage + 1)
                    end

                    if Profile.BEST_TIMES[Stage] == nil then
                        Profile.BEST_TIMES[Stage] = Time
                        AssignValues()
                    end

                    if isBetterTime(Timer, BestTime) then
                        Profile.BEST_TIMES[Stage] = Time
                        AssignValues()
                        game.ReplicatedStorage.RemoteEvents.UpdateButton:FireClient(plr, plrSettings[plr.UserId].SPS, Best)
                    end

                    plrdata:Save(plr)

                    -- Reset debounce after 5 seconds (adjust as needed)
                    task.delay(5, function()
                        debounce[plr.UserId] = nil
                    end)
                end
            end
        end)
    end
end

SkipStage.OnServerEvent:Connect(function(plr: Player)
	local Settings = plrSettings[plr.UserId]
	local Stage = Settings.SPS
	local Profile = plrdata:Get(plr)
	if Profile.LEVELS < Stage + 1 then
		plrdata:Set(plr, "LEVELS", Stage + 1)
	end
	setting.Players:Set(plr, "FOLLOW", true)
	if game.Lighting:FindFirstChild("MUIBlur") then
		game.Lighting.MUIBlur:Destroy()
	end
	
	plrService:IsFinished(plr, Settings.INGAME, Settings.FOLLOW)
end)
--// Player Removing
players.PlayerRemoving:Connect(OnPlayerRemoved)
