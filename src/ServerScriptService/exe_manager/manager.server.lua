local player_service = game:GetService("Players")
local lighting = game:GetService("Lighting")
local replicated_storage = game:GetService("ReplicatedStorage")
local server_script_service = game:GetService("ServerScriptService")

local folder = script.Parent

local notify_module = require(replicated_storage.exe_storage.notify_module)

local blur = Instance.new("BlurEffect")
blur.Name = "exe_admin_panel_blur"
blur.Size = 0
blur.Parent = lighting

local ELEMENTS = require(folder.ELEMENTS)

function set_states()
	folder.exe_scripts.Parent = server_script_service
end

set_states()

local exe_storage = replicated_storage:WaitForChild("exe_storage")
local exe_scripts = server_script_service:WaitForChild("exe_scripts")

local configs = require(exe_storage.configuration):GET_CONFIGS() 

function setup_effects()
	for i, effects in pairs(exe_storage.effects:GetChildren()) do
		if not effects:GetAttribute("EffectIcon") then
			if effects:IsA("Smoke") then
				effects:SetAttribute("EffectIcon", "rbxassetid://14189165983")
			elseif effects:IsA("Sparkles") then
				effects:SetAttribute("EffectIcon", "rbxassetid://14188610031")
			elseif effects:IsA("ParticleEmitter") then
				effects:SetAttribute("EffectIcon", "rbxassetid://14188611594")
			elseif effects:IsA("Light") then
				effects:SetAttribute("EffectIcon", "rbxassetid://14188534372")
			else
				effects:SetAttribute("EffectIcon", "rbxassetid://14188388240")
			end
		end
		
		if not effects:GetAttribute("To") and not effects:IsA("Folder") then
			effects:SetAttribute("To", "HumanoidRootPart")
		end

		if effects:IsA("Folder") then
			for i, elements in pairs(effects:GetChildren()) do
				elements:SetAttribute("tagged", effects.Name)
				elements:SetAttribute("EffectIcon", effects:GetAttribute("EffectIcon"))
				
				if not elements:GetAttribute("To") then
					elements:SetAttribute("To", "HumanoidRootPart")
				end
			end
		end
	end
end

setup_effects()

local CC = require(exe_storage.custom_commands)

local data = {
	Build = 513;
	Version = 5;
}

local function SETUP_CC(player)
	local allowed = {}

	for name, cc in pairs(CC:GET_CUSTOM_COMMANDS()) do
		if ELEMENTS.EXECUTABLE(player, name) then
			table.insert(allowed, name)
		end
	end
	
	replicated_storage:WaitForChild("exe_storage").events.banit_events.send_allowed_CC:FireClient(player, allowed)
end

player_service.PlayerAdded:Connect(function(plr)
	local server_banned = exe_scripts.server_bans:FindFirstChild(plr.UserId)
	local panel_holder = ELEMENTS.HAS_ACCESS(plr) 
	
	if not server_banned then
		if exe_scripts.server_status.server_locked.Value then
			if exe_scripts.server_status.server_locked:GetAttribute("holders_only") then
				if panel_holder then
					local exe = plr.PlayerGui:WaitForChild("exe")

					SETUP_CC(plr)

					exe:SetAttribute("build", data.Build)
					exe:SetAttribute("version", data.Version)
					
					exe.accessibility_button.Visible = configs.SYSTEM.ACCESSIBILITY_BUTTON
					exe.accessibility_button.button.page.front.open.icon.Image = configs.SYSTEM.ACCESSIBILITY_BUTTON_IMAGEID
					
					exe_storage.events.setup:FireAllClients()
					
					warn("Exe user joined.")
				else
					plr:Kick(configs.SERVER_PRIVACY.server_locked_message)
				end
			else
				plr:Kick(configs.SERVER_PRIVACY.server_locked_message)
			end
		else
			if panel_holder then
				local exe = plr.PlayerGui:WaitForChild("exe")
				
				SETUP_CC(plr)
				
				exe:SetAttribute("build", data.Build)
				exe:SetAttribute("version", data.Version)
				
				exe.accessibility_button.Visible = configs.SYSTEM.ACCESSIBILITY_BUTTON
				exe.accessibility_button.button.page.front.open.icon.Image = configs.SYSTEM.ACCESSIBILITY_BUTTON_IMAGEID
				
				exe_storage.events.setup:FireAllClients()
				
			else
				local exe = plr.PlayerGui:WaitForChild("exe")
				
				for i, client in pairs(exe.frame:GetDescendants()) do
					if client:IsA("LocalScript") then
						client.Enabled = false
						client:Destroy()
					end
				end
			end
		end
	else
		plr:Kick("You are banned from this server; " .. server_banned:GetAttribute("reason"))
	end
end)

player_service.PlayerAdded:Connect(function(plr)
	if game.CreatorType == Enum.CreatorType.User then
		local properties = ELEMENTS.GET_PLAYER_PROPERTIES(game.CreatorId, "TIER")
		
		if not properties then
			warn("YOU CANNOT ACCESS EXE BECAUSE YOU HAVE NOT ASSIGNED YOURSELF IN THE ELEMENTS MODULE.")
		end
	elseif game.CreatorType == Enum.CreatorType.Group then
		local id = ELEMENTS.FETCH_GROUP()
		
		if game.CreatorId ~= id then
			warn("YOU CANNOT ACCESS EXE BECAUSE YOU HAVE NOT ASSIGNED YOUR GROUP IN THE ELEMENTS MODULE.")
		end
	end
end)

--// SERVER UPTIME

local count = 0

function uptime()
	while true do
		count += 1
		exe_storage.objects.uptime.Value = count

		task.wait(1)
	end
end

uptime()