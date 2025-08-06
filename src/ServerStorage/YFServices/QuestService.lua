local knit = require(game:GetService('ReplicatedStorage').Packages.Knit)
API = knit.CreateService({
	Name = "QuestService",
	Client = {},
	Quests = {}
})
local dataservice
local DATA = {}

function API.Init(PLR, DS)
	dataservice = DS
	DATA[PLR.UserId] = dataservice:Get(PLR)
end


function API.MakeQuest(PLR: Player, NAME: string, DIMENSION: any, CONTEXT: string, STAT: any, GOAL: number, STARTING_VALUE: number, ICON: string)
	API.Init(PLR, dataservice)
	local data = DATA[PLR.UserId]
	API.Quests[PLR.UserId] = {}
	assert(data.DIMENSIONS[DIMENSION], "no dimension found")
	if not data.DIMENSIONS[DIMENSION]["QUESTS"] then
		data.DIMENSIONS[DIMENSION]["QUESTS"] = {}
		API.Quests[PLR.UserId][DIMENSION] = {}
	end
	API.Quests[PLR.UserId][DIMENSION] = {}
	if data.DIMENSIONS[DIMENSION]["QUESTS"][NAME] then
		local q = data.DIMENSIONS[DIMENSION]["QUESTS"][NAME]
		q.CONTEXT = CONTEXT
		q.GOAL = GOAL
		q.ICON = ICON
		API.Quests[PLR.UserId][DIMENSION][NAME] = q
		return
	end
	local CURRENT_VALUE = 0
	data.DIMENSIONS[DIMENSION]["QUESTS"][NAME] = {
		["STAT"] = STAT,
		["CONTEXT"] = CONTEXT,
		["GOAL"] = GOAL,
		["STARTING_VALUE"] = STARTING_VALUE or 0,
		["CURRENT_VALUE"] = CURRENT_VALUE,
		["ICON"] = ICON,
		["COMPLETED"] = false
	}
	API.Quests[PLR.UserId][DIMENSION][NAME] = 
		data.DIMENSIONS[DIMENSION]["QUESTS"][NAME]
	API.Client.Quests = API.Quests[PLR.UserId]
end

function API.CheckQuests(PLR: Player, DIMENSION)
	API.Init(PLR, dataservice)
	local data = DATA[PLR.UserId]
	for _,q in data.DIMENSIONS[DIMENSION]["QUESTS"] do
		q.COMPLETED = q.CURRENT_VALUE >= q.GOAL
		if not q.COMPLETED then
			q.CURRENT_VALUE = data[q.STAT] - q.STARTING_VALUE
		end
	end
	API.Quests[PLR.UserId][DIMENSION] =
		data.DIMENSIONS[DIMENSION]["QUESTS"]
	API.Client.Quests = API.Quests[PLR.UserId]
end

function API.DestroyQuest(PLR: Player, DIMENSION, QUEST)
	API.Init(PLR, dataservice)
	local data = DATA[PLR.UserId]
	data[DIMENSION]["QUESTS"][QUEST] = nil
end

return API