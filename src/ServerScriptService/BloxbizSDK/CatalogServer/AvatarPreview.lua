--!strict
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BloxbizSDK = script.Parent.Parent
local BloxbizRemotes = ReplicatedStorage.BloxbizRemotes

local OnGetFeaturedCategoriesRemote

local ANIMS = {
	MerchBoothPose = 616136790,
	["Stylish"] = 619511648,
	["Bubbly"] = 1018553897,
	["Ninja"] = 658832408,
	["Levitate"] = 619542203,
	["Elder"] = 892268340,
	["Werewolf"] = 1113752682,
	["Superhero"] = 619528125,
	["Astronaut"] = 1090133099,
	["Robot"] = 619521748,
	["Mage"] = 754637456,
	["Cartoony"] = 837011741,
	["Pirate"] = 837024662,
	["Toy"] = 973771666,
	["Knight"] = 734327140,
	["Zombie"] = 619535834,
	["Vampire"] = 1113742618,
	["Shy"] = 3576717965,
}

local AvatarPreview = {}

local function getPoses()
	return ANIMS
end

local function getChild(parent, path)
	local childrenNames = path:split(".")

	local child = parent
	for _, name in ipairs(childrenNames) do
		child = child:FindFirstChild(name)
		if not child then
			return
		end
	end

	return child
end

function AvatarPreview.Init()
	OnGetFeaturedCategoriesRemote = Instance.new("RemoteFunction")
	OnGetFeaturedCategoriesRemote.Name = "CatalogOnGetPoses"
	OnGetFeaturedCategoriesRemote.OnServerInvoke = getPoses
	OnGetFeaturedCategoriesRemote.Parent = BloxbizRemotes

	local animsFolder = Instance.new("Folder")
	animsFolder.Name = "PoseAnimations"
	animsFolder.Parent = BloxbizRemotes

	for k, animId in pairs(ANIMS) do
		task.spawn(function()
			local success, asset = pcall(function()
				return InsertService:LoadAsset(animId)
			end)

			if not success then
				ANIMS[k] = nil
				return
			end

			local emote = asset:FindFirstChildOfClass("Animation")
			if not emote then
				emote = getChild(asset, "R15Anim.idle.Animation1")
			end

			if not emote then
				ANIMS[k] = nil
				return
			end

			emote.Name = tostring(animId)
			emote.Parent = animsFolder
	
			assert(emote, ("Emote (%i) does not have an Animation"):format(animId))
		end)
	end
end

return AvatarPreview
