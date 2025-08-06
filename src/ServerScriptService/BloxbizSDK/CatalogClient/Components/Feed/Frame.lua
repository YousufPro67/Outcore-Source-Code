--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local BloxbizSDK = script.Parent.Parent.Parent.Parent
local CatalogClient = BloxbizSDK:FindFirstChild("CatalogClient")
local CatalogShared = BloxbizSDK:FindFirstChild("CatalogShared")

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Utils = require(UtilsStorage)

local AvatarHandler = require(CatalogClient.Classes:WaitForChild("AvatarHandler"))
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local GeneralUtils = require(CatalogShared.CatalogUtils)
local FeedUtils = require(CatalogShared.FeedUtils)

local Components = BloxbizSDK.CatalogClient.Components
local GenericComponents = Components.Generic

local Button = require(GenericComponents.Button)
local ScrollingFrame = require(GenericComponents.ScrollingFrame)
local Viewport = require(GenericComponents.ViewportFrame)

export type Props = {
	Feeds: Fusion.Value<{[string]: FeedData}>,
	Enabled: boolean,
	Data: FeedUtils.Outfit,
	ActionCallback: (action: string) -> boolean,
	OnImpression: () -> (),
	Items: { TextButton },
	HumanoidDescription: HumanoidDescription,
	EquippedItems: Fusion.Value,
}

type ButtonProps = {
	Action: FeedUtils.ServerFeedAction,
	Text: Fusion.Computed<string> | string,
	Image: Fusion.Computed<string> | string,
	Outfit: FeedUtils.Outfit,
	Callback: (action: string) -> boolean,
	Enabled: boolean,
	Likes: Fusion.Value<number>,
	Boosts: Fusion.Value<number>,
	OwnLike: Fusion.Value<boolean>,
}

export type FeedData = {
	Name: string,
	Frame: Frame,

	PostedTime: string,
	StringValue: Fusion.Value<string>,

	Likes: Fusion.Value<number>,
	Boosts: Fusion.Value<number>,
	OwnLike: Fusion.Value<boolean>,
}

local function CreateButton(buttonProps: ButtonProps): TextButton
	local props: Button.Props = {
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromScale(0.3, 0.8),
		AnchorPoint = Vector2.new(0.5, 0),
		CornerRadius = UDim.new(0.2, 0),

		Text = buttonProps.Text,
		Name = buttonProps.Action,
		Image = buttonProps.Image,
		-- TextSize = buttonProps.TextSize,
		TextScaled = false,
		TextWrapped = false,

		Enabled = buttonProps.Enabled,

		ImageTransparency = {
			Default = 0,
			Hover = 0.1,
			MouseDown = 0.2,
			Disabled = 0.5,
		},
		ImageColor3 = {
			Default = Color3.fromRGB(255, 255, 255),
			Hover = Color3.fromRGB(255, 255, 255),
			MouseDown = Color3.fromRGB(255, 255, 255),
			Disabled = Color3.fromRGB(75, 75, 75),
		},

		BackgroundColor3 = {
			Default = Color3.new(1, 1, 1),
			Hover = Color3.fromHex("#c5c5c5"),
			MouseDown = Color3.fromRGB(138, 138, 138),
			Disabled = Color3.fromRGB(138, 138, 138),
		},
		BackgroundTransparency = {
			Default = 0,
			Hover = 0.1,
			MouseDown = 0.2,
			Disabled = 0.3,
		},

		TextColor3 = {
			Default = Color3.new(0, 0, 0),
			Hover = Color3.new(0, 0, 0),
			MouseDown = Color3.new(0, 0, 0),
			Disabled = Color3.new(0, 0, 0),
		},
		TextTransparency = {
			Default = 0,
			Hover = 0.1,
			MouseDown = 0.2,
			Disabled = 0.3,
		},

		Callback = function(enabled: Fusion.Value<boolean>, selected: Fusion.Value<boolean>)
			if enabled:get() then
				enabled:set(false)

				local action = buttonProps.Action
				if action == "like" and buttonProps.OwnLike:get() then
					action = "unlike"
				end

				if action == "like" then
					buttonProps.Likes:set(buttonProps.Likes:get() + 1)
					buttonProps.OwnLike:set(true)
				elseif action == "unlike" then
					buttonProps.Likes:set(buttonProps.Likes:get() - 1)
					buttonProps.OwnLike:set(false)
				end

				task.spawn(function()
					local success = buttonProps.Callback(action)
					if not success then
						if action == "like" then
							buttonProps.Likes:set(buttonProps.Likes:get() - 1)
							buttonProps.OwnLike:set(false)
						elseif action == "unlike" then
							buttonProps.Likes:set(buttonProps.Likes:get() + 1)
							buttonProps.OwnLike:set(true)
						end
					end
				end)
				enabled:set(true)
			end
		end,
	}

	return Button(props)
end

local function CreateViewport(humDesc: HumanoidDescription): ViewportFrame
	local model = AvatarHandler.GetModel(humDesc)

	local track
	local animateScript = model:FindFirstChild("Animate")
	if animateScript then
		animateScript.Disabled = true
	end

	-- if animateScript then
	-- 	local idle = animateScript:FindFirstChild("idle")
	-- 	local anim1 = idle:FindFirstChild("Animation1")
	-- 	if anim1 then
	-- 		local humanoid = model:FindFirstChild("Humanoid")
	-- 		local animator = humanoid:FindFirstChild("Animator")

	-- 		if animator then
	-- 			-- Due to a Roblox engine bug, the animator can't load animations under viewport WorldModels and has to be done in workspace.
	-- 			-- The character is immediately removed from workspace after the animation loads
	-- 			model.Parent = workspace
	-- 			track = animator:LoadAnimation(anim1)
				
	-- 			track.Looped = true
	-- 			track:Play()
	-- 		end
	-- 	end
	-- end

	local props = {
		RotateEnabled = true,
		AutoRotateEnabled = true,

		Model = model,
		Size = UDim2.fromScale(0.19, 1),
		Position = UDim2.fromScale(0.00159, 0.5),
		AnchorPoint = Vector2.new(0, 0.5),
		AnimTrack = track
	}

	local viewport = Viewport(props)
	return viewport
end

local function CreateItemList(items: { TextButton }): ScrollingFrame
	local props: ScrollingFrame.Props = {
		Size = UDim2.fromScale(1, 0.7),
		Position = UDim2.fromScale(0.5, 0.675),
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 0,

		Layout = {
			Type = "UIListLayout",
			Padding = UDim.new(0.025, 0),
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.Name,

			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		},
	}

	local scrollingFrame = ScrollingFrame(props)
	local itemFrame = scrollingFrame:FindFirstChild("ItemFrame")

	for _, item: TextButton in pairs(items) do
		item.Parent = itemFrame
	end

	return scrollingFrame
end

return function(props: Props): Frame
	local data = props.Data
	local ownerUserId = data.CreatorId

	local ownerUserName = Players:GetNameFromUserIdAsync(ownerUserId) or "N/A"
	local content, isReady =
		Players:GetUserThumbnailAsync(ownerUserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420) or nil,
		nil

	local t = 1
	repeat
		task.wait()
		t += 1
	until isReady or t > 60

	local postTime = data.CreatedAt
	local viewport = CreateViewport(props.HumanoidDescription)

	local outfit = props.Data
	local likes = Fusion.Value(outfit.Likes or 0)
	local boosts = Fusion.Value(outfit.Boosts or 0)
	local tryOns = Fusion.Value(outfit.TryOns or 0)
	local impressions = Fusion.Value(outfit.Impressions or 0)
	local ownLike = Fusion.Value(outfit.OwnLike)

	local convertedTime, level = GeneralUtils.GetTime(postTime)
	if level >= 4 then
		convertedTime = GeneralUtils.FormatIsoDate(postTime)
	end

	local name = Fusion.Value(GeneralUtils.GetNameRichText(ownerUserName, convertedTime))
	local nameCompute = Fusion.Computed(function()
		return name:get()
	end, Fusion.cleanup)

	local numberOfLikesCompute = Fusion.Computed(function()
		local count = likes:get()
		if count > 0 then
			local likes = count > 1 and "Likes" or "Like"
			return Utils.toLocaleNumber(count) .. " " .. likes
		else
			return "Like"
		end
	end, Fusion.cleanup)

	local numberOfBoostsCompute = Fusion.Computed(function()
		local count = boosts:get()
		if count > 0 then
			local boosts = count > 1 and "Boosts" or "Boost"
			return Utils.toLocaleNumber(count) .. " " .. boosts
		else
			return "Boost"
		end
	end, Fusion.cleanup)

	local ownLikeCompute = Fusion.Computed(function()
		if ownLike:get() then
			return "rbxassetid://14110764348"
		else
			return "rbxassetid://14375965247"
		end
	end, Fusion.cleanup)

	local tryButton = CreateButton({
		Action = "try",
		Text = "Try On",
		Image = "rbxassetid://14248504143",
		Outfit = data,
		Callback = props.ActionCallback,
		Enabled = true,
		OwnLike = ownLike,
		Boosts = boosts,
		Likes = likes,
	})

	local likeButton = CreateButton({
		Action = "like",
		Text = numberOfLikesCompute,
		Image = ownLikeCompute,
		Outfit = data,
		Callback = props.ActionCallback,
		Enabled = props.Enabled,
		OwnLike = ownLike,
		Boosts = boosts,
		Likes = likes,
	})

	local boostButton = CreateButton({
		Action = "boost",
		Text = numberOfBoostsCompute,
		Image = "rbxassetid://14110768489",
		Outfit = data,
		Callback = props.ActionCallback,
		Enabled = props.Enabled,
		OwnLike = ownLike,
		Boosts = boosts,
		Likes = likes,
		TextSize = UDim2.fromScale(0.55, 0.8)
	})

	local frameRef = Fusion.Value()
	local reportedImpression = false

	local frame = Fusion.New("Frame")({
		Name = outfit.GUID,
		BackgroundColor3 = Color3.fromRGB(41, 43, 48),
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 0.369),

		[Fusion.Ref] = frameRef,
		[Fusion.OnChange("AbsolutePosition")] = function(pos)
			-- detect outfit impressions

			if reportedImpression then
				return
			end

			local frame = frameRef:get()

			if frame then
				local size = frame.AbsoluteSize

				local minY = 0
				local maxY = workspace.Camera.ViewportSize.Y - (size.Y/2)

				if (pos.Y > minY) and (pos.Y < maxY) then
					reportedImpression = true
					props.OnImpression()
				end
			end
		end,

		[Fusion.Children] = {
			Fusion.New("UICorner")({
				Name = "UICorner",
				CornerRadius = UDim.new(0.065, 0),
			}),

			Fusion.New("Frame")({
				Name = "Holder",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.98, 0.9),

				[Fusion.Children] = {
					Fusion.New("Frame")({
						Name = "Content",
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.602, 0.5),
						Size = UDim2.fromScale(0.796, 1),

						[Fusion.Children] = {
							Fusion.New("Frame")({
								Name = "Buttons",
								Active = true,
								AnchorPoint = Vector2.new(1, 0.5),
								BackgroundColor3 = Color3.fromRGB(79, 173, 116),
								BackgroundTransparency = 1,
								BorderSizePixel = 0,
								Position = UDim2.fromScale(1, 0.1),
								Selectable = true,
								Size = UDim2.fromScale(0.55, 0.26),

								[Fusion.Children] = {
									Fusion.New("UIListLayout")({
										Name = "UIListLayout",
										Padding = UDim.new(0.02, 0),
										FillDirection = Enum.FillDirection.Horizontal,
										HorizontalAlignment = Enum.HorizontalAlignment.Right,
										SortOrder = Enum.SortOrder.LayoutOrder,
										VerticalAlignment = Enum.VerticalAlignment.Center,
									}),

									tryButton,
									likeButton,
									boostButton,
								},
							}),

							CreateItemList(props.Items),

							Fusion.New("TextLabel")({
								Name = "OutfitName",
								Text = data.Name,
								TextColor3 = Color3.fromRGB(255, 255, 255),
								TextScaled = true,
								TextSize = 22,
								TextWrapped = true,
								TextXAlignment = Enum.TextXAlignment.Left,
								AnchorPoint = Vector2.new(0, 0.2),
								BackgroundColor3 = Color3.fromRGB(255, 255, 255),
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0, 0),
								Size = UDim2.fromScale(0.45, 0.2),
							}),

							Fusion.New("ImageLabel")({
								Name = "Icon",
								AnchorPoint = Vector2.new(0, 0.5),
								Image = content,
								Position = UDim2.fromScale(0, 0.235),
								Size = UDim2.fromScale(0.2, 0.11),
								BackgroundTransparency = 0.5,
								BackgroundColor3 = Color3.new(1, 1, 1),

								[Fusion.Children] = {
									Fusion.New("UIAspectRatioConstraint")({}),

									Fusion.New("UICorner")({
										Name = "UICorner",
										CornerRadius = UDim.new(1, 0),
									}),

									Fusion.New("TextLabel")({
										Name = "Username",
										Text = nameCompute,
										TextColor3 = Color3.fromRGB(255, 255, 255),
										TextScaled = true,
										TextSize = 22,
										TextWrapped = true,
										RichText = true,
										TextXAlignment = Enum.TextXAlignment.Left,
										AnchorPoint = Vector2.new(0, 0.5),
										BackgroundColor3 = Color3.fromRGB(255, 255, 255),
										BackgroundTransparency = 1,
										Position = UDim2.fromScale(1.5, 0.5),
										Size = UDim2.fromScale(12, 1),
									}),
								},
							}),
						},
					}),

					viewport,
				},
			}),
		},
	}) :: Frame

	local feedData: FeedData = {
		Name = ownerUserName,
		Frame = frame,

		PostedTime = postTime,
		StringValue = name,

		Likes = likes,
		Boosts = boosts,
		TryOns = tryOns,
		Impressions = impressions,
		OwnLike = ownLike,
	}
	props.Feeds[outfit.GUID] = feedData

	return frame
end
