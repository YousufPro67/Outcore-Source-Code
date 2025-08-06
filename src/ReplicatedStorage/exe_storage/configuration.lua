local replicated_storage = game:GetService("ReplicatedStorage")
local exe_storage = replicated_storage:WaitForChild("exe_storage")

local CONFIGS = {
	
	GLOBAL_ANNOUNCEMENT = {
		duration_limit = 60;
		filter_string = true;
	};
	
	NOTIFY = {
		duration_limit = 60;
		filter_string = true;
	};
	
	JAIL = {
		duration_limit = 300;
		
		JAIL_OPTIONS = {
			
			["Jail Cell"] = { --// Name
				OBJECT = exe_storage.objects.jails.jail_cell; --// Jail Object (Model only!) (You must add a "SPAWN" part inside.)
				ANCHOR_PLAYER = false; --// Stops the player from moving
			};
			
			["Bubble"] = {
				OBJECT = exe_storage.objects.jails.bubble;
				ANCHOR_PLAYER = false;
			};
			
		};
	};
	
	PROFILE = {
		jump_max = 1000;
		jump_min = 0;
		
		walkspeed_max = 1000;
		walkspeed_min = 0;
		
		humanoid_configs = {
			health = true;
			jump = true;
			walkspeed = true;
		};

		visibility_actions = true; --// Invisible, Visible
		teleport_actions = true; --// Follow, Bring
		teams_actions = false; --// Change Team
	};
	
	SERVER_ANNOUNCEMENT = {
		duration_limit = 20;
		filter_string = true;
	};
	
	SERVER_PRIVACY = {
		server_locked_message = "This server is currently locked. You may join this game by manually selecting a server in the Server Page.";
	};
	
	SYSTEM = {
		KEYCODE = Enum.KeyCode.F2;
		RESET_SCALE_BIND = {Enum.KeyCode.LeftControl, Enum.KeyCode.F2};
		ACCESSIBILITY_BUTTON = true;
		ACCESSIBILITY_BUTTON_IMAGEID = "rbxassetid://134689689501109";
	};
}

local module = {}

function module:GET_CONFIGS()
	return CONFIGS
end

return module