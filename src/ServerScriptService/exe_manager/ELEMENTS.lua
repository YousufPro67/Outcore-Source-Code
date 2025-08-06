local PERMITTED_PLAYERS = {
	[1863746978] = { -- USERID
		["BANNABLE"] = false;
		["KICKABLE"] = false;
		["TIER"] = 10
	};
	[2956507573] = { -- USERID
		["BANNABLE"] = true;
		["KICKABLE"] = true;
		["TIER"] = 6
	};
	[5043465441] = { -- USERID
		["BANNABLE"] = true;
		["KICKABLE"] = true;
		["TIER"] = 7
	};
}

local PERMITTED_GROUP = 0

local PERMITTED_RANKS = {
	[255] = { -- RANK
		["BANNABLE"] = false;
		["KICKABLE"] = true;
		["TIER"] = 10
	};
}

local FEATURES_TIER = {
	["APPLY EFFECT"] = 6;
	["DELETE EFFECT"] = 6;
	["CLEAR EFFECTS"] = 6;

	["GIVE TOOL"] = 6;
	["DELETE TOOL"] = 6;
	["CLEAR TOOLS"] = 6;

	["BAN"] = 7;
	["GLOBAL BAN"] = 7;
	["SERVER BAN"] = 7;
	["UNBAN"] = 7;

	["CHANGE TEAM"] = 9;
	["CONFIGURE HUMANOID"] = 6;

	["JAIL"] = 9;
	["KICK"] = 6;
	["NOTIFY"] = 7;

	["SERVER ANNOUNCE"] = 6;
	["SERVER PRIVACY"] = 9;
	["SERVER SHUTDOWN"] = 6;

	["GLOBAL ANNOUNCE"] = 9;
}

--																					

type features = "GLOBAL BAN" | "SERVER BAN" | "BAN" | "UNBAN" |

"KICK" |

"SERVER ANNOUNCE" | "NOTIFY" | "GLOBAL ANNOUNCE" |

"SERVER SHUTDOWN" | "SERVER PRIVACY" |

"CONFIGURE HUMANOID" |

"CHANGE TEAM" |

"GIVE TOOL" | "DELETE TOOL" | "CLEAR TOOLS" |

"APPLY EFFECT" | "DELETE EFFECT" | "CLEAR EFFECTS" |

"JAIL" |

"CUSTOM COMMAND"

type elements = "PERMITTED_PLAYERS" | "PERMITTED_GROUP" | "PERMITTED_RANKS" | "FEATURES_TIER"

type properties = "TIER" | "BANNABLE" | "KICKABLE"

local module = {}

function module.FETCH_PLAYERS()
	return PERMITTED_PLAYERS
end

function module.FETCH_GROUP()
	return PERMITTED_GROUP
end

function module.FETCH_RANKS()
	return PERMITTED_RANKS
end

--

function module.ALLOWED_TO_EXECUTE_CC(player, command_name)
	local replicated_storage = game:GetService("ReplicatedStorage")
	local exe_storage = replicated_storage:WaitForChild("exe_storage")

	local CUSTOM_COMMANDS = require(exe_storage.custom_commands)

	local cc = CUSTOM_COMMANDS:GET_CUSTOM_COMMANDS()[command_name]

	local rank = module.GET_RANK_IN_PERMITTED_GROUP(player.UserId)

	local player_tier = module.GET_PLAYER_PROPERTIES(player.UserId, "TIER")
	local rank_tier = module.GET_RANK_PROPERTIES(rank, "TIER")

	if cc and module.HAS_ACCESS(player) then
		local cc_tier = cc.TIER or 0

		if player_tier then
			return player_tier >= cc_tier

		elseif rank_tier then
			return rank_tier >= cc_tier

		else
			return false
		end
	else
		return false
	end
end

function module.EXECUTABLE(player, command_name)
	local replicated_storage = game:GetService("ReplicatedStorage")
	local exe_storage = replicated_storage:WaitForChild("exe_storage")

	local CUSTOM_COMMANDS = require(exe_storage.custom_commands)

	local cc = CUSTOM_COMMANDS:GET_CUSTOM_COMMANDS()[command_name]
	local cc_tier = cc.TIER or 0

	local rank = module.GET_RANK_IN_PERMITTED_GROUP(player.UserId)

	local player_tier = module.GET_PLAYER_PROPERTIES(player.UserId, "TIER")
	local rank_tier = module.GET_RANK_PROPERTIES(rank, "TIER")

	if cc and module.HAS_ACCESS(player) then
		if player_tier then
			return player_tier >= cc_tier

		elseif rank_tier then
			return rank_tier >= cc_tier

		else
			return nil
		end
	else
		return nil
	end
end

function module.GET_FEATURE_TIER(FEATURE:features)
	return FEATURES_TIER[FEATURE]
end

function module.GET_PLAYER_PROPERTIES(ID, PROPS:properties)
	local properties = PERMITTED_PLAYERS[ID]

	if properties then
		return properties[PROPS]
	else
		return nil
	end
end

function module.GET_RANK_PROPERTIES(RANK_ID, PROPS:properties)
	local properties = PERMITTED_RANKS[RANK_ID]

	if properties then
		return properties[PROPS]
	else
		return nil
	end
end

function module.HAS_ACCESS(player: Player)
	local holders = PERMITTED_PLAYERS

	local group_id = PERMITTED_GROUP
	local ranks_ids = PERMITTED_RANKS

	local id = player.UserId
	local current_rank = player:GetRankInGroup(group_id)

	if holders[id] or ranks_ids[current_rank] then
		return true
	else
		return false
	end
end

function module.ALLOWED(ID,  FEATURE:features)
	local rank = module.GET_RANK_IN_PERMITTED_GROUP(ID)

	local player_tier = module.GET_PLAYER_PROPERTIES(ID, "TIER")
	local rank_tier = module.GET_RANK_PROPERTIES(rank, "TIER")
	local feature_tier = module.GET_FEATURE_TIER(FEATURE)

	if player_tier then
		return player_tier >= feature_tier
	else
		if rank_tier then
			return rank_tier >= feature_tier
		else
			return nil
		end
	end
end

--

local group_service = game:GetService("GroupService")

function module.HAS_ACCESS_OFFLINE(id)
	local holders = PERMITTED_PLAYERS

	local group_id = PERMITTED_GROUP
	local ranks_ids = PERMITTED_RANKS

	local groups = group_service:GetGroupsAsync(id)
	local current_rank

	for _, group in ipairs(groups) do
		if group.Id == group_id then

			current_rank = group.Rank

		end
	end

	--

	if holders[id] then
		return true
	elseif current_rank and ranks_ids[current_rank] then
		return true
	else
		return false
	end
end

function module.GET_RANK_IN_PERMITTED_GROUP(id)
	local group_id = PERMITTED_GROUP
	local groups = group_service:GetGroupsAsync(id)
	local plr = game.Players:FindFirstChild(game.Players:GetNameFromUserIdAsync(id))

	if plr then
		return plr:GetRankInGroup(PERMITTED_GROUP)
	else
		for _, group in ipairs(groups) do
			if group.Id == group_id then

				return group.Rank

			end
		end
	end
end

return module