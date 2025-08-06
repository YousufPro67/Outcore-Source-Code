--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local Utils = require(script.Parent.Parent.Utils)

local Payload = require(script.Payload)
local Outfit = require(script.Outfit)

local OFFLINE_MODE = false

export type ServerFeedAction = "delete" | "undelete" | "like" | "unlike" | "boost" | "rename" | "try"
export type ServerFeedType = "all" | "this-game"
export type ServerFeedSort = "hot" | "top" | "latest" | "relevance"


export type Profile = {
	Posted: { string },
	Liked: { string },
}

export type Outfit = Outfit.Outfit
export type Item = Outfit.Item

export type Payload = Payload.Payload
export type Response = Payload.ServerResponse
export type BackendOutfit = Payload.BackendOutfit

local function GetAllowedSlot(name: string): number?
	if name == "Hat" then
		return Payload.Slots.Hat
	else
		return Payload.Slots[name.."Accessory"]
	end
end

local function GetAllowedSlotNameFromValue(value: number): string?
	for name, enumValue in pairs(Payload.Slots) do
		if value == enumValue then
			return name
		end
	end

	return
end

local function GetAccessoryType(name: string) : number?
	local enums = Enum.AccessoryType:GetEnumItems()
	for _, enum: Enum.AccessoryType in pairs(enums) do
		local enumName = enum.Name
		local match = string.match(name, enumName)
		if match then	
			return enum.Value + 1
		end
	end
	return nil
end

local function GetEnumFromValue(enum: any, value: number): Enum.AccessoryType | Enum.AvatarAssetType | nil
	for _, enumItem in ipairs(enum:GetEnumItems()) do
		if value == enumItem.Value then
			return enum[enumItem.Name]
		end
	end

	return
end

local function GetServerOutfitFromHumanoidDescription(
	name: string,
	humanoidDescription: HumanoidDescription
): Payload.Payload
	local items = {}
	local accessories = humanoidDescription:GetAccessories(true)
	table.sort(accessories, function (a, b)
		local orderA = a.Order or 0
		local orderB = b.Order or 0
		return orderA < orderB
	end)
	for _, item in pairs(accessories) do
		local slot = GetAllowedSlot(item.AccessoryType.Name)

		if slot then
			local data: Payload.Item = {
				slot = slot,
				id = item.AssetId,
			}
	
			table.insert(items, data)
		end
	end

	do -- Shirts and Pants
		table.insert(items, {
			id = humanoidDescription.Shirt,
			slot = Payload.Slots.Shirt,
		})

		table.insert(items, {
			id = humanoidDescription.Pants,
			slot = Payload.Slots.Pants,
		})
	end

	do -- Body parts
		table.insert(items, {
			id = humanoidDescription.Torso,
			slot = Payload.Slots.Torso,
		})

		table.insert(items, {
			id = humanoidDescription.RightArm,
			slot = Payload.Slots.RightArm,
		})

		table.insert(items, {
			id = humanoidDescription.RightLeg,
			slot = Payload.Slots.RightLeg,
		})

		table.insert(items, {
			id = humanoidDescription.LeftArm,
			slot = Payload.Slots.LeftArm,
		})

		table.insert(items, {
			id = humanoidDescription.LeftLeg,
			slot = Payload.Slots.LeftLeg,
		})

		table.insert(items, {
			id = humanoidDescription.Head,
			slot = Payload.Slots.Head,
		})
	end

	local constructor: Payload.Payload = {
		name = name,
		items = items,

		head_color = humanoidDescription.HeadColor:ToHex(),
		torso_color = humanoidDescription.TorsoColor:ToHex(),
		left_arm_color = humanoidDescription.LeftArmColor:ToHex(),
		right_arm_color = humanoidDescription.RightArmColor:ToHex(),
		left_leg_color = humanoidDescription.LeftLegColor:ToHex(),
		right_leg_color = humanoidDescription.RightLegColor:ToHex(),
	}

	return constructor
end


local function GetOutfitItemFromPayloadItem(item: Payload.Item): Outfit.Item?
	local allowedSlotName = GetAllowedSlotNameFromValue(item.slot)
	if allowedSlotName then
		local accessoryType = GetAccessoryType(allowedSlotName)
		if accessoryType then
			return {
				AssetId = item.id,
				AssetType = accessoryType,
				Name = item.name,
				Price = item.price,
			}
		else
			return {
				AssetId = item.id,
				AssetType = item.slot,
				Name = item.name,
				Price = item.price
			}
		end
	end

	return
end

local function GetOutfitFromServerData(outfitInfo: BackendOutfit): Outfit.Outfit
	local items = {}
	for _, item in pairs(outfitInfo.items) do
		local processedItem = GetOutfitItemFromPayloadItem(item)
		if processedItem then
			table.insert(items, processedItem)
		end	
	end

	return {
		GUID = outfitInfo.guid,
		Name = outfitInfo.name,

		Items = items,

		Colors = {
			Head = outfitInfo.head_color,
			Torso = outfitInfo.torso_color,
			LeftArm = outfitInfo.left_arm_color,
			RightArm = outfitInfo.right_arm_color,
			LeftLeg = outfitInfo.left_leg_color,
			RightLeg = outfitInfo.right_leg_color,
		},

		Likes = outfitInfo.likes or 0,
		OwnLike = outfitInfo.own_like or false,
		Boosts = outfitInfo.times_boosted or 0,

		TryOns = outfitInfo.try_on_count or 0,
		Impressions = outfitInfo.impression_count or 0,
		
		CreatorId = outfitInfo.creator,
		GameId = outfitInfo.game_id,
		CreatedAt = outfitInfo.created_at,
	}
end

local function GetOfflineMode(): boolean
	return OFFLINE_MODE
end

return {
	GetOfflineMode = GetOfflineMode,
	GetEnumFromValue = GetEnumFromValue,
	GetServerOutfitFromHumanoidDescription = GetServerOutfitFromHumanoidDescription,
	GetOutfitFromServerData = GetOutfitFromServerData,
	GetAllowedSlot = GetAllowedSlot
}
