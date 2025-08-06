local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommandToolConfig = ReplicatedStorage:FindFirstChild("SBCommandsConfig")
if CommandToolConfig then
	CommandToolConfig = require(CommandToolConfig)
end

local CharModifier = require(script.Parent.Server.CharacterModifier)

local Commands = {
    dwarf = {
        Name = "Dwarf",
        Description = "Makes a player into a dwarf",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.ChangeHumanoidDescriptionProperty(target, "DepthScale", 0.75)
            CharModifier.ChangeHumanoidDescriptionProperty(target, "HeightScale", 0.5)
            CharModifier.ChangeHumanoidDescriptionProperty(target, "WidthScale", 0.75)
            CharModifier.ChangeHumanoidDescriptionProperty(target, "HeadScale", 1.4)
        end,
    },

    giantdwarf = {
        Name = "GiantDwarf",
        Description = "Makes a player into a giant dwarf",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.ChangeHumanoidDescriptionProperty(target, "DepthScale", 0.75 * 3)
            CharModifier.ChangeHumanoidDescriptionProperty(target, "HeightScale", 0.5 * 3)
            CharModifier.ChangeHumanoidDescriptionProperty(target, "WidthScale", 0.75 * 3)
            CharModifier.ChangeHumanoidDescriptionProperty(target, "HeadScale", 1.4 * 3)
        end,
    },

    squash = {
        Name = "Squash",
        Description = "Makes a player squashed",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.ChangeHumanoidDescriptionProperty(target, "HeightScale", 0.1)
            CharModifier.ChangeHumanoidDescriptionProperty(target, "HeadScale", 0.5)
        end,
    },

    thin = {
        Name = "Thin",
        Description = "Makes a player skinny",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.ChangeHumanoidDescriptionProperty(target, "WidthScale", 0.2)
            CharModifier.ChangeHumanoidDescriptionProperty(target, "DepthScale", 0.2)
        end,
    },

    fat = {
        Name = "Fat",
        Description = "Makes a player fat",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.ChangeHumanoidDescriptionProperty(target, "WidthScale", 2)
            CharModifier.ChangeHumanoidDescriptionProperty(target, "DepthScale", 1.5)
        end,
    },

    respawn = {
        Name = "Respawn",
        Description = "Respawns a  player",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            target:LoadCharacter()
        end,
    },

    clearhats = {
        Name = "ClearHats",
        Description = "Removes player's hats",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.ClearAccessories(target)
        end,
    },

    freeze = {
        Name = "Freeze",
        Description = "Freezes a player",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            local root = CharModifier.GetRootPart(target)
            if not root then
                return
            end
            root.Anchored = true
        end,
    },

    unfreeze = {
        Name = "UnFreeze",
        Description = "Unfreezes a player",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            local root = CharModifier.GetRootPart(target)
            if not root then
                return
            end
            root.Anchored = false
        end,
    },

    sparkles = {
        Name = "Sparkles",
        Description = "Gives player sparkles",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.AddSFX(target, "Sparkles")
        end,
    },

    stopsparkles = {
        Name = "StopSparkles",
        Description = "Stops sparkles from a player",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.RemoveSFX(target, "Sparkles")
        end,
    },

    smoke = {
        Name = "Smoke",
        Description = "Smokes a player",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.AddSFX(target, "Smoke")
        end,
    },

    unsmoke = {
        Name = "UnSmoke",
        Description = "Stops smoke from a player",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.RemoveSFX(target, "Smoke")
        end,
    },

    fire = {
        Name = "Fire",
        Description = "Lights a player on fire",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.AddSFX(target, "Fire")
        end,
    },

    stopfire = {
        Name = "StopFire",
        Description = "Removes a player's fire",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.RemoveSFX(target, "Fire")
        end,
    },

    forcefield = {
        Name = "ForceField",
        Description = "Gives a player a force field",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.AddSFX(target, "ForceField")
        end,
    },

    stopforcefield = {
        Name = "StopForceField",
        Description = "Removes a player's force field",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.RemoveSFX(target, "ForceField")
        end,
    },

    heal = {
        Name = "Heal",
        Description = "Heals a player to max health",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            local humanoid = CharModifier.GetHumanoid(target)
            if humanoid then
                humanoid.Health = humanoid.MaxHealth
            end
        end,
    },

    god = {
        Name = "God",
        Description = "Gives player infinite health",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            local humanoid = CharModifier.GetHumanoid(target)
            if humanoid then
                humanoid.MaxHealth = math.huge
                humanoid.Health = humanoid.MaxHealth
            end
        end,
    },

    ungod = {
        Name = "UnGod",
        Description = "Resets player's health to normal",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            local humanoid = CharModifier.GetHumanoid(target)
            if humanoid then
                humanoid.MaxHealth = 100
                humanoid.Health = humanoid.MaxHealth
            end
        end,
    },

    superdamage = {
        Name = "SuperDamage",
        Description = "Deals a player 60 damage",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            local humanoid = CharModifier.GetHumanoid(target)
            if humanoid then
                humanoid:TakeDamage(60)
            end
        end,
    },

    damage = {
        Name = "Damage",
        Description = "Deals a player 20 damage",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            local humanoid = CharModifier.GetHumanoid(target)
            if humanoid then
                humanoid:TakeDamage(20)
            end
        end,
    },

    handtool = {
        Name = "HandTool",
        Description = "Hands a player your tool",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            local char = player.Character
            if not char then
                return
            end

            local tool = char:FindFirstChildOfClass("Tool")
            if not tool then
                return
            end

            tool:Clone().Parent = target.Backpack
            char.Humanoid:UnequipTools()
            tool:Destroy()
        end,
    },

    explode = {
        Name = "Explode",
        Description = "Explodes a player",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            local targetRoot = CharModifier.GetRootPart(target)
            if not targetRoot then
                return
            end

            local explosion = Instance.new("Explosion")
            explosion.Position = targetRoot.Position
            explosion.Parent = target.Character
            explosion.DestroyJointRadiusPercent = 0
            target.Character:BreakJoints()
        end,
    },

    fling = {
        Name = "Fling",
        Description = "Flings a player",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]

            local playerHum = CharModifier.GetHumanoid(player)
            local targetHum = CharModifier.GetHumanoid(target)
            local playerRoot = CharModifier.GetRootPart(player)
            local targetRoot = CharModifier.GetRootPart(target)
            if not playerHum or not targetHum or not playerRoot or not targetRoot then
                return
            end

            if playerRoot and targetRoot and targetHum then
                local flingDistance = 50
                local speakerPos = playerRoot.Position
                local plrPos = targetRoot.Position
                local bodyPosition = Instance.new("BodyPosition")
                bodyPosition.MaxForce = Vector3.new(10000000, 10000000, 10000000)
                bodyPosition.Name = "HDAdminFlingBP"
                bodyPosition.D = 450
                bodyPosition.P = 10000
                if target == player then
                    plrPos = (targetRoot.CFrame * CFrame.new(0,0,-4)).p
                end
                local direction = (plrPos - speakerPos).Unit
                bodyPosition.Position = plrPos + Vector3.new(direction.X, 1.4, direction.Z) * flingDistance

                local spin = Instance.new("BodyAngularVelocity")
                spin.MaxTorque = Vector3.new(300000, 300000, 300000)
                spin.P = 300
                spin.AngularVelocity = Vector3.new(10, 10 ,10)
                spin.Name = "HDAdminFlingSpin"
                spin.Parent = targetRoot
                Debris:AddItem(spin, 0.1)

                bodyPosition.Parent = targetRoot
                Debris:AddItem(bodyPosition, 0.1)
                targetHum.PlatformStand = true
                task.wait(5)
                targetHum.PlatformStand = false
            end
        end,
    },

    resetranks = {
        Name = "ResetRanks",
        Description = "Resets all player's ranks",

        Args = {"Player",},
        Callback = function(player, args)
            local ServerScriptService = game:GetService("ServerScriptService")
            local BloxbizAPI = require(ServerScriptService.BloxbizSDK.PublicAPI)

            local target = args[1]
            BloxbizAPI.ClearRanks(target)
        end,
    },

    resetstats = {
        Name = "ResetStats",
        Description = "Resets player's stats",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            local leaderstats = target:FindFirstChild("leaderstats")
            if not leaderstats then
                return
            end

            for _, stat in leaderstats:GetChildren() do
                if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                    stat.Value = 0
                elseif stat:IsA("BoolValue") then
                    stat.Value = false
                end
            end
        end,
    },

    punish = {
        Name = "Punish",
        Description = "Punishes a player",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            if target and target.Character then
                target.Character.Parent = nil
            end
        end,
    },

    unpunish = {
        Name = "Unpunish",
        Description = "Stops a player's punishment",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            if target and target.Character then
                target.Character.Parent = workspace
            end
        end,
    },

    shadowson = {
        Name = "ShadowsOn",
        Description = "Enables game shadows",

        Args = "None",
        Callback = function(player, args)
            Lighting.GlobalShadows = true
        end,
    },

    shadowsoff = {
        Name = "ShadowsOff",
        Description = "Disables game shadows",

        Args = "None",
        Callback = function(player, args)
            Lighting.GlobalShadows = false
        end,
    },

    midday = {
        Name = "MidDay",
        Description = "Sets the time to midday",

        Args = "None",
        Callback = function(player, args)
            Lighting.ClockTime = 12
        end,
    },

    midnight = {
        Name = "MidNight",
        Description = "Sets the time to midnight",

        Args = "None",
        Callback = function(player, args)
            Lighting.ClockTime = 0
        end,
    },

    shutdown = {
        Name = "ShutDown",
        Description = "Shuts down the current server",

        Args = {"Player",},
        Callback = function(player, args)
            local kickMessage = "The server has been shutdown by " .. player.Name
            for _, plr in Players:GetPlayers() do
                plr:Kick(kickMessage)
            end
            Players.PlayerAdded:Connect(function(plr)
                plr:Kick(kickMessage)
            end)
        end,
    },

    reset = {
        Name = "Reset",
        Description = "Resets player's character",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.UnapplyBundle(target)
            CharModifier.StopAnimation(target)
        end,
    },

    resetoutfit = {
        Name = "ResetOutfit",
        Description = "Resets player's outfit to original",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.UnapplyBundle(target)
        end,
    },

    stopanimation = {
        Name = "StopAnimation",
        Description = "Stops any SBCommands animation",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.StopAnimation(target)
        end,
    },

    bighead = {
        Name = "BigHead",
        Description = "Gives a player a big head",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.ChangeHumanoidDescriptionProperty(target, "HeadScale", 1.75)
        end,
    },

    smallhead = {
        Name = "SmallHead",
        Description = "Gives a player a small head",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.ChangeHumanoidDescriptionProperty(target, "HeadScale", 0.7)
        end,
    },

    kick = {
        Name = "Kick",
        Description = "Kicks a player",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]

            local kickText = string.format("Kicked by: %s", player.Name)
            target:Kick(kickText)
        end,
    },

    to = {
        Name = "To",
        Description = "Teleports you to a player",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]

            local char = CharModifier.GetCharacter(player)
            local targetChar = CharModifier.GetCharacter(target)
            if not char or not targetChar then
                return
            end

            char:PivotTo(targetChar:GetPivot())
        end,
    },

    bring = {
        Name = "Bring",
        Description = "Teleports a player to you",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]

            local char = CharModifier.GetCharacter(player)
            local targetChar = CharModifier.GetCharacter(target)
            if not char or not targetChar then
                return
            end

            targetChar:PivotTo(char:GetPivot())
        end,
    },

    kill = {
        Name = "Kill",
        Description = "Kills a player",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]

            local targetHum = CharModifier.GetHumanoid(target)
            if not targetHum then
                return
            end

            targetHum.Health = 0
        end,
    },

    superwalk = {
        Name = "SuperWalk",
        Description = "Doubles player's walk speed",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]

            local targetHum = CharModifier.GetHumanoid(target)
            if not targetHum then
                return
            end

            targetHum.WalkSpeed *= 2
        end,
    },

    loserwalk = {
        Name = "LoserWalk",
        Description = "Halves player's walk speed",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]

            local targetHum = CharModifier.GetHumanoid(target)
            if not targetHum then
                return
            end

            targetHum.WalkSpeed /= 2
        end,
    },

    superjump = {
        Name = "SuperJump",
        Description = "Doubles player's jump height",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]

            local targetHum = CharModifier.GetHumanoid(target)
            if not targetHum then
                return
            end

            targetHum.JumpHeight *= 2
        end,
    },

    loserjump = {
        Name = "LoserJump",
        Description = "Halves player's jump height",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]

            local targetHum = CharModifier.GetHumanoid(target)
            if not targetHum then
                return
            end

            targetHum.JumpHeight /= 2
        end,
    },
}

local MorphCommands = {
    {"Buff", 594200},
    {"Snowman", 173035},
    {"Worm", 394523},
    {"Skeleton", 4778},
    {"Chibi", 6470},
    {"Plush", 3416},
    {"Chunky", 637696},
    {"Crab", 332725},
    {"Spider", 338165},
    {"Frog", 386731},
    {"Rat", 365520},
    {"Hamster", 8232},
    {"Capybara", 295597},
    {"Penguin", 319025},
    {"Duck", 394166},
    {"Goose", 310626},
    {"Sponge", 393419},
    {"Freak", 1186597},
    {"Buffify", 594200, "Buffifies a player"},
    {"Wormify", 394523, "Wormifies a player"},
    {"Chibify", 6470, "Chibifies a player"},
    {"Plushify", 3416, "Plushifies a player"},
    {"Freakify", 1186597, "Freakifies a player"},
    {"Frogify", 386731, "Frogifies a player"},
    {"Spongify", 393419, "Spongifies a player"},
    {"Bigify", 455999, "Bigifies a player"},
    {"Creepify", 946396, "Creepifies a player"},
    {"Dinofy", 369985, "Dinofies a player"},
    {"Fatify", 637696, "Fatifies a player"},
}

local AnimationCommands = {
    {"Cheer", 507770677},
    {"Climb", 507765644},
    {"Dance1", 507771019},
    {"Dance2", 507776043},
    {"Dance3", 507777268},
    {"Fall", 507767968},
    {"Idle", 507766388},
    {"Jump", 507765000},
    {"Laugh", 507770818},
    {"Point", 507770453},
    {"Run", 913376220},
    {"Sit", 2506281703},
    {"Swim", 913384386},
    {"SwimIdle", 913389285},
    {"ToolLunge", 522638767},
    {"ToolSlash", 522635514},
    {"Walk", 913402848},
    {"Wave", 507770239},
}

for _, animation in AnimationCommands do
    local commandName = animation[1]
    local animationId = animation[2]
    local description = animation[3]

    Commands[commandName:lower()] = {
        Name = commandName,
        Description = description or "Plays a " .. commandName .. " animation",

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.PlayAnimation(target, animationId)
        end,
    }
end

for _, morph in MorphCommands do
    local commandName = morph[1]
    local bundleId = morph[2]
    local description = morph[3]

    Commands[commandName:lower()] = {
        Name = commandName,
        Description = description or "Morphs you into a " .. commandName,

        Args = {"Player",},
        Callback = function(player, args)
            local target = args[1]
            CharModifier.ApplyBundle(target, bundleId)
        end,
    }
end

if CommandToolConfig then
    local modifiers = CommandToolConfig.ModifyCommands
    local removeCommands = CommandToolConfig.DisableDefaultCommands

    if removeCommands then
        Commands = {}
    end

    if modifiers and typeof(modifiers) == "table" then
        local function applyModifiers(command, modifiedCommand, commandId)
            local modifiedArgs
            if typeof(modifiedCommand.Args) == "table" then
                modifiedArgs = modifiedCommand.Args
            end

            local modifiedCallback
            if typeof(modifiedCommand.Callback) == "function" then
                modifiedCallback = modifiedCommand.Callback
            end

            return {
                Name = modifiedCommand.Name or command.Name or "Unnamed",
                Description = modifiedCommand.Description or command.Description or "No description",

                Args = modifiedArgs or command.Args or {"Player",},
                Callback = modifiedCallback or command.Callback or function()
                    warn(string.format("[Bloxbiz Command Tool]: Command %s has no callback set.", commandId))
                end,
            }
        end

        for commandId, command in modifiers do
            if command == false then
                Commands[commandId] = nil
            elseif typeof(command) == "table" then
                Commands[commandId] = applyModifiers(Commands[commandId] or {}, command, commandId)
            end
        end
    end
end

return Commands