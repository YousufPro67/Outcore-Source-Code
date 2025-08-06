local replicated_storage = game:GetService("ReplicatedStorage")

local exe_storage = replicated_storage:WaitForChild("exe_storage")
local events = exe_storage.events

local CUSTOM_COMMANDS = {
	
	["Brightness Setting"] = {
		["ICON"] = "rbxassetid://11422153469";
		["DESCRIPTION"] = "Configures the brightness of the environment.";
		["EVENT"] = events.custom_command_events.brightness;
		
		["PROCEDURE"] = {
			["INPUT_MENU"] = false;
			["INPUT_SETTINGS"] = "none";
			
			["PLAIN_MENU"] = false;
			
			["PLAYER_MENU"] = false;
			
			["SLIDER_MENU"] = true; 
			["SLIDER_DEFAULT"] = 1;
			["SLIDER_INCREMENT"] = .1;
			["SLIDER_SETTINGS"] = NumberRange.new(0, 10);
		};
		
		["TIER"] = 4
	};
	
	["Day Time"] = {
		["ICON"] = "rbxassetid://12975580769";
		["DESCRIPTION"] = "Changes the time to day.";
		["EVENT"] = events.custom_command_events.change_time_day;

		["PROCEDURE"] = {
			["INPUT_MENU"] = false;
			["INPUT_SETTINGS"] = "none";

			["PLAIN_MENU"] = true;

			["PLAYER_MENU"] = false;

			["SLIDER_MENU"] = false;
			["SLIDER_DEFAULT"] = 1;
			["SLIDER_INCREMENT"] = .1;
			["SLIDER_SETTINGS"] = NumberRange.new(0, 10);
		};

		["TIER"] = 10
	};
	
	["Night Time"] = {
		["ICON"] = "rbxassetid://11422149927";
		["DESCRIPTION"] = "Changes the time to night.";
		["EVENT"] = events.custom_command_events.change_time_night;

		["PROCEDURE"] = {
			["INPUT_MENU"] = false;
			["INPUT_SETTINGS"] = "none";

			["PLAIN_MENU"] = true;

			["PLAYER_MENU"] = false;

			["SLIDER_MENU"] = false;
			["SLIDER_DEFAULT"] = 1;
			["SLIDER_INCREMENT"] = .1;
			["SLIDER_SETTINGS"] = NumberRange.new(0, 10);
		};

		["TIER"] = 10
	};
	
	["Character Scale "] = {
		["ICON"] = "rbxassetid://11422917070";
		["DESCRIPTION"] = "Setting the scale of the selected player's character.";
		["EVENT"] = events.custom_command_events.char_scale;

		["PROCEDURE"] = {
			["INPUT_MENU"] = true;
			["INPUT_SETTINGS"] = "number";

			["PLAIN_MENU"] = false;

			["PLAYER_MENU"] = true;

			["SLIDER_MENU"] = false;
			["SLIDER_DEFAULT"] = 1;
			["SLIDER_INCREMENT"] = .1;
			["SLIDER_SETTINGS"] = NumberRange.new(0, 10);
		};

		["TIER"] = 6
	};
}

local module = {}

function module:GET_CUSTOM_COMMANDS()
	return CUSTOM_COMMANDS
end

function module.GET_CUSTOM_COMMAND(name)
	return CUSTOM_COMMANDS[name]
end

return module