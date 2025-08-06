local input_service = game:GetService("UserInputService")
local tween_service = game:GetService("TweenService")
local players = game:GetService("Players")
local lighting = game:GetService("Lighting")
local replicated_storage = game:GetService("ReplicatedStorage")

local info = TweenInfo.new(.5, Enum.EasingStyle.Exponential)
local quick = TweenInfo.new(.3, Enum.EasingStyle.Exponential)
local loop = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false)
local late = TweenInfo.new(.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)

local local_player = players.LocalPlayer

local exe = local_player.PlayerGui:WaitForChild("exe")

local frame = exe:FindFirstChild("frame")

local accessibility_button = exe.accessibility_button
local options = accessibility_button.button.page.options

local menu = frame.menu_frame
local profile = frame.profile_panel

local confirmation_prompt = frame.confirmation_prompt
local resyncing_screen = frame.resyncing_screen

local direct_action_panels = frame.direct_action_panels
local tools_action_panels = frame.tools_panels
local assets_action_panels =  frame.assets_panels

local exe_storage = replicated_storage.exe_storage
local notify_module = require(exe_storage:WaitForChild("notify_module"))
local transparency_module = require(exe_storage.transparency_module)

--

type direct_panels = "kick" | "ban" | "notify" | "jail" | "teams" | "global" | "revoke" | "snapshot"
type tools_panels = "manage" | "server_privacy" | "effects" | "tools" | "announcement" | "custom_commands" | "global_announcement"
type assets_panels = "tools" | "effects" | "players_selection" | "ban_history"
type loading = "assets" | "cc" | "manage" | "team" | "tools_effects" | nil

--// GROUPINGS

local profile_group = transparency_module.CreateGroup(profile.frame:GetDescendants(), quick)
local snapshot_group = transparency_module.CreateGroup(direct_action_panels.snapshot:GetDescendants(), quick)

local kick_group = transparency_module.CreateGroup(direct_action_panels.kick_panel:GetDescendants(), quick)
local ban_group = transparency_module.CreateGroup(direct_action_panels.ban_panel:GetDescendants(), quick)
local notify_group = transparency_module.CreateGroup(direct_action_panels.notify_panel:GetDescendants(), quick)
local jail_group = transparency_module.CreateGroup(direct_action_panels.jail_panel:GetDescendants(), quick)
local teams_group = transparency_module.CreateGroup(direct_action_panels.change_team:GetDescendants(), quick)
local global_group = transparency_module.CreateGroup(direct_action_panels.global_panel:GetDescendants(), quick)
local revoke_group = transparency_module.CreateGroup(direct_action_panels.revoke_panel:GetDescendants(), quick)

local confirmation_group = transparency_module.CreateGroup(confirmation_prompt:GetDescendants(), quick)

local manage_group = transparency_module.CreateGroup(tools_action_panels.manage_panel:GetDescendants(), quick)
local tools_group = transparency_module.CreateGroup(tools_action_panels.tools_panel:GetDescendants(), quick)
local effects_group = transparency_module.CreateGroup(tools_action_panels.effects_panel:GetDescendants(), quick)
local custom_commands_group = transparency_module.CreateGroup(tools_action_panels.custom_commands_panel:GetDescendants(), quick)
local server_privacy_group = transparency_module.CreateGroup(tools_action_panels.server_privacy_panel:GetDescendants(), quick)
local announcement_group = transparency_module.CreateGroup(tools_action_panels.announcement_panel:GetDescendants(), quick)
local global_announcement_group = transparency_module.CreateGroup(tools_action_panels.global_announcement_panel:GetDescendants(), quick)

local asset_tools_group = transparency_module.CreateGroup(assets_action_panels.manage_tools_panel:GetDescendants(), quick)
local asset_effects_group = transparency_module.CreateGroup(assets_action_panels.manage_effects_panel:GetDescendants(), quick)
local asset_players_group = transparency_module.CreateGroup(assets_action_panels.select_player_panel:GetDescendants(), quick)
local asset_ban_history = transparency_module.CreateGroup(assets_action_panels.ban_history:GetDescendants(), quick)

profile_group:FadeOut()
snapshot_group:FadeOut()

kick_group:FadeOut()
ban_group:FadeOut()
notify_group:FadeOut()
jail_group:FadeOut()
teams_group:FadeOut()
global_group:FadeOut()
revoke_group:FadeOut()

confirmation_group:FadeOut()

manage_group:FadeOut()
tools_group:FadeOut()
effects_group:FadeOut()
custom_commands_group:FadeOut()
server_privacy_group:FadeOut()
announcement_group:FadeOut()
global_announcement_group:FadeOut()

asset_tools_group:FadeOut()
asset_effects_group:FadeOut()
asset_players_group:FadeOut()
asset_ban_history:FadeOut()

--

local module = {}

function module:notify(text, duration, icon, player)
	notify_module:notify(text, duration, icon, player)
end

function module:announce(announcer, text, icon, duration)
	notify_module:announce(announcer, text, icon, duration)
end

function module:menu(state)
	if state and not menu.Visible then
		menu.Visible = true
		menu.menu.Position = UDim2.new(0, -60, .5, 0)
		menu.menu.scale.Scale = .5

		tween_service:Create(menu, info, {BackgroundTransparency = .5}):Play()
		tween_service:Create(menu.menu, info, {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(0, 60, .5, 0)}):Play()
		tween_service:Create(menu.menu.scale, info, {Scale = 1}):Play()

	else
		tween_service:Create(menu, info, {BackgroundTransparency = 1}):Play()
		tween_service:Create(menu.menu, info, {AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, -60, .5, 0)}):Play()
		tween_service:Create(menu.menu.scale, info, {Scale = .5}):Play()

		--

		task.wait(.5)

		--

		menu.Visible = false
	end
end

function module:profile_view(state, plr)
	if state and not profile.Visible then
		local pfp = players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)

		profile.properties.id.Value = plr.UserId
		profile.properties.username.Value = plr.Name

		profile.Visible = true
		profile.ImageTransparency = 1

		profile.frame.ImageTransparency = 1
		profile.frame.scale.Scale = 1.2

		--

		profile.frame.scroll.CanvasPosition = Vector2.new(0, 0)
		profile.frame.scroll.details.profile.Image = pfp
		profile.frame.scroll.details.display_name.Text = plr.DisplayName
		profile.frame.scroll.details.username.Text = "@" .. plr.Name

		--// ACCESSIBILITY BUTTON RECENT

		options.recent.icon.Image = pfp
		options.recent.icon.corner.CornerRadius = UDim.new(1, 0)

		options.recent.func:SetAttribute("profile", true)
		options.recent.func:SetAttribute("dashboard", false)
		options.recent.func:SetAttribute("credits", false)

		options.recent.func.player_name.Value = plr.Name

		--

		tween_service:Create(profile, info, {ImageTransparency = .5}):Play()
		tween_service:Create(profile.frame, info, {ImageTransparency = .1}):Play()
		tween_service:Create(profile.frame.scale, info, {Scale = 1}):Play()

		profile_group:FadeIn()

	else
		tween_service:Create(profile, quick, {ImageTransparency = 1}):Play()
		tween_service:Create(profile.frame, quick, {ImageTransparency = 1}):Play()
		tween_service:Create(profile.frame.scale, quick, {Scale = 1.2}):Play()

		profile_group:FadeOut()

		--

		task.wait(.3)

		--

		profile.Visible = false
	end
end

function module:prompt_confirmation(state, confirmation_id, title, description)
	if state and not confirmation_prompt.Visible then
		confirmation_prompt.confirmation_id.Value = confirmation_id

		confirmation_prompt.Visible = true
		confirmation_prompt.ImageTransparency = 1

		confirmation_prompt.prompt.header.Text = title
		confirmation_prompt.prompt.description.Text = description

		confirmation_prompt.prompt.ImageTransparency = 1
		confirmation_prompt.prompt.scale.Scale = 1.2

		--

		tween_service:Create(confirmation_prompt, info, {ImageTransparency = .5}):Play()
		tween_service:Create(confirmation_prompt.prompt, info, {ImageTransparency = .1}):Play()
		tween_service:Create(confirmation_prompt.prompt.scale, info, {Scale = 1}):Play()

		confirmation_group:FadeIn()
	else
		tween_service:Create(confirmation_prompt, quick, {ImageTransparency = 1}):Play()
		tween_service:Create(confirmation_prompt.prompt, quick, {ImageTransparency = 1}):Play()
		tween_service:Create(confirmation_prompt.prompt.scale, quick, {Scale = 1.2}):Play()

		confirmation_group:FadeOut()

		--

		task.wait(.3)

		--

		confirmation_prompt.Visible = false
	end
end

tween_service:Create(resyncing_screen.panel.throbber, loop, {Rotation = 360}):Play()

function module:prompt_resync(state, label, loading:loading)
	if state and not resyncing_screen.Visible then
		resyncing_screen.Visible = true
		resyncing_screen.ImageTransparency = 1

		if loading == "assets" then
			resyncing_screen.panel.Visible = false
			resyncing_screen.assets_loading.Visible = true
			resyncing_screen.custom_commands_loading.Visible = false
			resyncing_screen.manage_loading.Visible = false
			resyncing_screen.team_loading.Visible = false
			resyncing_screen.tools_effects_loading.Visible = false

			resyncing_screen.assets_loading.GroupTransparency = 1
			resyncing_screen.assets_loading.scale.Scale = 1.2

			--

			tween_service:Create(resyncing_screen.assets_loading, quick, {GroupTransparency = 0}):Play()
			tween_service:Create(resyncing_screen.assets_loading.scale, info, {Scale = 1}):Play()

		elseif loading == "cc" then
			resyncing_screen.panel.Visible = false
			resyncing_screen.assets_loading.Visible = false
			resyncing_screen.custom_commands_loading.Visible = true
			resyncing_screen.manage_loading.Visible = false
			resyncing_screen.team_loading.Visible = false
			resyncing_screen.tools_effects_loading.Visible = false

			resyncing_screen.custom_commands_loading.GroupTransparency = 1
			resyncing_screen.custom_commands_loading.scale.Scale = 1.2

			--

			tween_service:Create(resyncing_screen.custom_commands_loading, quick, {GroupTransparency = 0}):Play()
			tween_service:Create(resyncing_screen.custom_commands_loading.scale, info, {Scale = 1}):Play()

		elseif loading == "manage" then
			resyncing_screen.panel.Visible = false
			resyncing_screen.assets_loading.Visible = false
			resyncing_screen.custom_commands_loading.Visible = false
			resyncing_screen.manage_loading.Visible = true
			resyncing_screen.team_loading.Visible = false
			resyncing_screen.tools_effects_loading.Visible = false

			resyncing_screen.manage_loading.GroupTransparency = 1
			resyncing_screen.manage_loading.scale.Scale = 1.2

			--

			tween_service:Create(resyncing_screen.manage_loading, quick, {GroupTransparency = 0}):Play()
			tween_service:Create(resyncing_screen.manage_loading.scale, info, {Scale = 1}):Play()

		elseif loading == "team" then
			resyncing_screen.panel.Visible = false
			resyncing_screen.assets_loading.Visible = false
			resyncing_screen.custom_commands_loading.Visible = false
			resyncing_screen.manage_loading.Visible = false
			resyncing_screen.team_loading.Visible = true
			resyncing_screen.tools_effects_loading.Visible = false

			resyncing_screen.team_loading.GroupTransparency = 1
			resyncing_screen.team_loading.scale.Scale = 1.2

			--

			tween_service:Create(resyncing_screen.team_loading, quick, {GroupTransparency = 0}):Play()
			tween_service:Create(resyncing_screen.team_loading.scale, info, {Scale = 1}):Play()

		elseif loading == "tools_effects" then
			resyncing_screen.panel.Visible = false
			resyncing_screen.assets_loading.Visible = false
			resyncing_screen.custom_commands_loading.Visible = false
			resyncing_screen.manage_loading.Visible = false
			resyncing_screen.team_loading.Visible = false
			resyncing_screen.tools_effects_loading.Visible = true

			resyncing_screen.tools_effects_loading.GroupTransparency = 1
			resyncing_screen.tools_effects_loading.scale.Scale = 1.2

			--

			tween_service:Create(resyncing_screen.tools_effects_loading, quick, {GroupTransparency = 0}):Play()
			tween_service:Create(resyncing_screen.tools_effects_loading.scale, info, {Scale = 1}):Play()

		else
			resyncing_screen.panel.Visible = true
			resyncing_screen.assets_loading.Visible = false
			resyncing_screen.custom_commands_loading.Visible = false
			resyncing_screen.manage_loading.Visible = false
			resyncing_screen.team_loading.Visible = false
			resyncing_screen.tools_effects_loading.Visible = false

			resyncing_screen.tools_effects_loading.GroupTransparency = 1
			resyncing_screen.tools_effects_loading.scale.Scale = 1.2

			resyncing_screen.panel.header.Text = label or "Resyncing..."

			--

			tween_service:Create(resyncing_screen, info, {ImageTransparency = .5}):Play()
			tween_service:Create(resyncing_screen.panel, info, {GroupTransparency = 0}):Play()
			tween_service:Create(resyncing_screen.panel.scale, info, {Scale = 1}):Play()
		end
	else
		tween_service:Create(resyncing_screen.assets_loading, info, {GroupTransparency = 1}):Play()
		tween_service:Create(resyncing_screen.custom_commands_loading, info, {GroupTransparency = 1}):Play()
		tween_service:Create(resyncing_screen.manage_loading, info, {GroupTransparency = 1}):Play()
		tween_service:Create(resyncing_screen.team_loading, info, {GroupTransparency = 1}):Play()
		tween_service:Create(resyncing_screen.tools_effects_loading, info, {GroupTransparency = 1}):Play()
		tween_service:Create(resyncing_screen.panel, quick, {GroupTransparency = 1}):Play()

		tween_service:Create(resyncing_screen, quick, {ImageTransparency = 1}):Play()

		--
		task.wait(.3)
		--

		resyncing_screen.Visible = false
	end
end

function module:direct_panels(panel:direct_panels, state, plr)
	if panel == "kick" then
		if state and not direct_action_panels.Visible then
			direct_action_panels.properties.id.Value = plr.UserId
			direct_action_panels.properties.username.Value = plr.Name

			direct_action_panels.page:JumpTo(direct_action_panels.kick_panel)

			direct_action_panels.Visible = true
			direct_action_panels.ImageTransparency = 1

			direct_action_panels.kick_panel.ImageTransparency = 1
			direct_action_panels.kick_panel.scale.Scale = 1.2
			direct_action_panels.kick_panel.reason.container.CanvasPosition = Vector2.new(0, 0)
			direct_action_panels.kick_panel.reason.container.textbox.Text = ""

			--

			tween_service:Create(direct_action_panels, info, {ImageTransparency = .5}):Play()
			tween_service:Create(direct_action_panels.kick_panel, info, {ImageTransparency = .1}):Play()
			tween_service:Create(direct_action_panels.kick_panel.scale, info, {Scale = 1}):Play()

			kick_group:FadeIn()
		else
			tween_service:Create(direct_action_panels, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(direct_action_panels.kick_panel, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(direct_action_panels.kick_panel.scale, quick, {Scale = 1.2}):Play()

			kick_group:FadeOut()

			--

			task.wait(.3)

			--

			direct_action_panels.Visible = false

			if input_service:GetFocusedTextBox() then
				input_service:GetFocusedTextBox():ReleaseFocus()
			end
		end

	elseif panel == "ban" then
		if state and not direct_action_panels.Visible then
			direct_action_panels.properties.id.Value = plr.UserId
			direct_action_panels.properties.username.Value = plr.Name

			direct_action_panels.page:JumpTo(direct_action_panels.ban_panel)
			direct_action_panels.ban_panel.pages.page:JumpTo(direct_action_panels.ban_panel.pages.ban_page)

			direct_action_panels.Visible = true
			direct_action_panels.ImageTransparency = 1

			direct_action_panels.ban_panel.ImageTransparency = 1
			direct_action_panels.ban_panel.scale.Scale = 1.2

			direct_action_panels.ban_panel.pages.ban_page.scroll.CanvasPosition = Vector2.new(0, 0)
			direct_action_panels.ban_panel.pages.ban_page.scroll.reason.container.CanvasPosition = Vector2.new(0, 0)
			direct_action_panels.ban_panel.pages.ban_page.scroll.reason.container.textbox.Text = ""
			direct_action_panels.ban_panel.pages.ban_page.scroll.moderator_note.textbox.Text = ""

			direct_action_panels.ban_panel.pages.settings_page.scroll.CanvasPosition = Vector2.new(0, 0)

			--

			tween_service:Create(direct_action_panels, info, {ImageTransparency = .5}):Play()
			tween_service:Create(direct_action_panels.ban_panel, info, {ImageTransparency = .1}):Play()
			tween_service:Create(direct_action_panels.ban_panel.scale, info, {Scale = 1}):Play()

			ban_group:FadeIn()
		else
			tween_service:Create(direct_action_panels, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(direct_action_panels.ban_panel, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(direct_action_panels.ban_panel.scale, quick, {Scale = 1.2}):Play()

			ban_group:FadeOut()

			--

			task.wait(.3)

			--

			direct_action_panels.Visible = false

			if input_service:GetFocusedTextBox() then
				input_service:GetFocusedTextBox():ReleaseFocus()
			end
		end

	elseif panel == "notify" then

		if state and not direct_action_panels.Visible then
			direct_action_panels.properties.id.Value = plr.UserId
			direct_action_panels.properties.username.Value = plr.Name

			direct_action_panels.page:JumpTo(direct_action_panels.notify_panel)

			direct_action_panels.Visible = true
			direct_action_panels.ImageTransparency = 1

			direct_action_panels.notify_panel.scroll.CanvasPosition = Vector2.new(0, 0)
			direct_action_panels.notify_panel.ImageTransparency = 1
			direct_action_panels.notify_panel.scale.Scale = 1.2
			direct_action_panels.notify_panel.scroll.description.container.CanvasPosition = Vector2.new(0, 0)
			direct_action_panels.notify_panel.scroll.description.container.textbox.Text = ""

			--

			tween_service:Create(direct_action_panels, info, {ImageTransparency = .5}):Play()
			tween_service:Create(direct_action_panels.notify_panel, info, {ImageTransparency = .1}):Play()
			tween_service:Create(direct_action_panels.notify_panel.scale, info, {Scale = 1}):Play()

			notify_group:FadeIn()
		else
			tween_service:Create(direct_action_panels, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(direct_action_panels.notify_panel, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(direct_action_panels.notify_panel.scale, quick, {Scale = 1.2}):Play()

			notify_group:FadeOut()

			--

			task.wait(.3)

			--

			direct_action_panels.Visible = false

			if input_service:GetFocusedTextBox() then
				input_service:GetFocusedTextBox():ReleaseFocus()
			end
		end

	elseif panel == "jail" then

		if state and not direct_action_panels.Visible then
			direct_action_panels.properties.id.Value = plr.UserId
			direct_action_panels.properties.username.Value = plr.Name

			direct_action_panels.page:JumpTo(direct_action_panels.jail_panel)

			direct_action_panels.Visible = true
			direct_action_panels.ImageTransparency = 1

			direct_action_panels.jail_panel.scroll.CanvasPosition = Vector2.new(0, 0)
			direct_action_panels.jail_panel.ImageTransparency = 1
			direct_action_panels.jail_panel.scale.Scale = 1.2

			direct_action_panels.jail_panel.scroll.jail_type.Visible = true

			--

			tween_service:Create(direct_action_panels, info, {ImageTransparency = .5}):Play()
			tween_service:Create(direct_action_panels.jail_panel, info, {ImageTransparency = .1}):Play()
			tween_service:Create(direct_action_panels.jail_panel.scale, info, {Scale = 1}):Play()

			jail_group:FadeIn()
		else
			direct_action_panels.jail_panel.scroll.jail_type.Visible = false

			tween_service:Create(direct_action_panels, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(direct_action_panels.jail_panel, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(direct_action_panels.jail_panel.scale, quick, {Scale = 1.2}):Play()

			jail_group:FadeOut()

			--

			task.wait(.3)

			--

			direct_action_panels.Visible = false

			if input_service:GetFocusedTextBox() then
				input_service:GetFocusedTextBox():ReleaseFocus()
			end
		end

	elseif panel == "teams" then

		if state and not direct_action_panels.Visible then
			direct_action_panels.properties.id.Value = plr.UserId
			direct_action_panels.properties.username.Value = plr.Name

			direct_action_panels.page:JumpTo(direct_action_panels.change_team)

			direct_action_panels.Visible = true
			direct_action_panels.ImageTransparency = 1

			direct_action_panels.change_team.scroll.Visible = true
			direct_action_panels.change_team.scroll.CanvasPosition = Vector2.new(0, 0)
			direct_action_panels.change_team.ImageTransparency = 1
			direct_action_panels.change_team.scale.Scale = 1.2

			--

			tween_service:Create(direct_action_panels, info, {ImageTransparency = .5}):Play()
			tween_service:Create(direct_action_panels.change_team, info, {ImageTransparency = .1}):Play()
			tween_service:Create(direct_action_panels.change_team.scale, info, {Scale = 1}):Play()

			teams_group:FadeIn()
		else
			direct_action_panels.change_team.scroll.Visible = false

			tween_service:Create(direct_action_panels, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(direct_action_panels.change_team, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(direct_action_panels.change_team.scale, quick, {Scale = 1.2}):Play()

			teams_group:FadeOut()

			--

			task.wait(.3)

			--

			direct_action_panels.Visible = false

			if input_service:GetFocusedTextBox() then
				input_service:GetFocusedTextBox():ReleaseFocus()
			end
		end

	elseif panel == "global" then

		if state and not direct_action_panels.Visible then
			direct_action_panels.page:JumpTo(direct_action_panels.global_panel)
			direct_action_panels.global_panel.pages.page:JumpTo(direct_action_panels.global_panel.pages.ban_page)

			direct_action_panels.Visible = true
			direct_action_panels.ImageTransparency = 1

			direct_action_panels.global_panel.ImageTransparency = 1
			direct_action_panels.global_panel.scale.Scale = 1.2

			direct_action_panels.global_panel.pages.ban_page.scroll.CanvasPosition = Vector2.new(0, 0)
			direct_action_panels.global_panel.pages.ban_page.scroll.reason.container.CanvasPosition = Vector2.new(0, 0)
			direct_action_panels.global_panel.pages.ban_page.scroll.reason.container.textbox.Text = ""
			direct_action_panels.properties.global_ban.username.Value = ""

			direct_action_panels.global_panel.pages.settings_page.scroll.CanvasPosition = Vector2.new(0, 0)
			
			--

			exe_storage.events.global_open:Fire()

			--

			tween_service:Create(direct_action_panels, info, {ImageTransparency = .5}):Play()
			tween_service:Create(direct_action_panels.global_panel, info, {ImageTransparency = .1}):Play()
			tween_service:Create(direct_action_panels.global_panel.scale, info, {Scale = 1}):Play()

			global_group:FadeIn()
		else
			tween_service:Create(direct_action_panels, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(direct_action_panels.global_panel, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(direct_action_panels.global_panel.scale, quick, {Scale = 1.2}):Play()

			global_group:FadeOut()

			--

			task.wait(.3)

			--

			direct_action_panels.Visible = false

			if input_service:GetFocusedTextBox() then
				input_service:GetFocusedTextBox():ReleaseFocus()
			end
		end

	elseif panel == "revoke" then

		if state and not direct_action_panels.Visible then
			direct_action_panels.page:JumpTo(direct_action_panels.revoke_panel)

			direct_action_panels.Visible = true
			direct_action_panels.ImageTransparency = 1

			direct_action_panels.revoke_panel.ImageTransparency = 1
			direct_action_panels.revoke_panel.scale.Scale = 1.2

			direct_action_panels.revoke_panel.scroll.CanvasPosition = Vector2.new(0, 0)

			--

			tween_service:Create(direct_action_panels, info, {ImageTransparency = .5}):Play()
			tween_service:Create(direct_action_panels.revoke_panel, info, {ImageTransparency = .1}):Play()
			tween_service:Create(direct_action_panels.revoke_panel.scale, info, {Scale = 1}):Play()

			revoke_group:FadeIn()
		else
			tween_service:Create(direct_action_panels, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(direct_action_panels.revoke_panel, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(direct_action_panels.revoke_panel.scale, quick, {Scale = 1.2}):Play()

			revoke_group:FadeOut()

			--

			task.wait(.3)

			--

			direct_action_panels.Visible = false

			if input_service:GetFocusedTextBox() then
				input_service:GetFocusedTextBox():ReleaseFocus()
			end
		end

	elseif panel == "snapshot" then

		if state and not direct_action_panels.Visible then
			direct_action_panels.page:JumpTo(direct_action_panels.snapshot)

			direct_action_panels.Visible = true
			direct_action_panels.ImageTransparency = 1

			direct_action_panels.snapshot.content.scroll.CanvasPosition = Vector2.new(0, 0)
			direct_action_panels.snapshot.ImageTransparency = 1
			direct_action_panels.snapshot.scale.Scale = 1.2

			--

			tween_service:Create(direct_action_panels, info, {ImageTransparency = .5}):Play()
			tween_service:Create(direct_action_panels.snapshot, info, {ImageTransparency = .1}):Play()
			tween_service:Create(direct_action_panels.snapshot.scale, info, {Scale = 1}):Play()

			snapshot_group:FadeIn()
		else
			tween_service:Create(direct_action_panels, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(direct_action_panels.snapshot, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(direct_action_panels.snapshot.scale, quick, {Scale = 1.2}):Play()

			snapshot_group:FadeOut()

			--

			task.wait(.3)

			--

			direct_action_panels.Visible = false
		end

	end
end

function module:tools_panels(panel:tools_panels, state)	
	if panel == "manage" then
		if state and not tools_action_panels.Visible then
			tools_action_panels.page:JumpTo(tools_action_panels.manage_panel)

			tools_action_panels.Visible = true
			tools_action_panels.ImageTransparency = 1

			tools_action_panels.manage_panel.ImageTransparency = 1
			tools_action_panels.manage_panel.scale.Scale = 1.2
			tools_action_panels.manage_panel.scroll.CanvasPosition = Vector2.new(0, 0)
			tools_action_panels.manage_panel.scroll.Visible = true
			tools_action_panels.manage_panel.scroll.search.textbox.Text = ""

			--// ACCESSIBILITY BUTTON RECENT

			options.recent.icon.Image = "rbxassetid://11419666512"
			options.recent.func.panel.Value = panel

			--

			tween_service:Create(tools_action_panels, info, {ImageTransparency = .5}):Play()
			tween_service:Create(tools_action_panels.manage_panel, info, {ImageTransparency = .1}):Play()
			tween_service:Create(tools_action_panels.manage_panel.scale, info, {Scale = 1}):Play()

			manage_group:FadeIn()
		else
			tools_action_panels.manage_panel.scroll.Visible = false

			tween_service:Create(tools_action_panels, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(tools_action_panels.manage_panel, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(tools_action_panels.manage_panel.scale, quick, {Scale = 1.2}):Play()

			manage_group:FadeOut()

			--

			task.wait(.3)

			--

			tools_action_panels.Visible = false

			if input_service:GetFocusedTextBox() then
				input_service:GetFocusedTextBox():ReleaseFocus()
			end
		end

	elseif panel == "tools" then

		if state and not tools_action_panels.Visible then
			tools_action_panels.page:JumpTo(tools_action_panels.tools_panel)

			tools_action_panels.Visible = true
			tools_action_panels.ImageTransparency = 1

			tools_action_panels.tools_panel.ImageTransparency = 1
			tools_action_panels.tools_panel.scale.Scale = 1.2

			tools_action_panels.tools_panel.player_list.CanvasPosition = Vector2.new(0, 0)
			tools_action_panels.tools_panel.tool_list.CanvasPosition = Vector2.new(0, 0)
			tools_action_panels.tools_panel.player_list.Visible = true
			tools_action_panels.tools_panel.tool_list.Visible = true

			--// ACCESSIBILITY BUTTON RECENT

			options.recent.icon.Image = "rbxassetid://11432855214"
			options.recent.func.panel.Value = panel

			--

			tween_service:Create(tools_action_panels, info, {ImageTransparency = .5}):Play()
			tween_service:Create(tools_action_panels.tools_panel, info, {ImageTransparency = .1}):Play()
			tween_service:Create(tools_action_panels.tools_panel.scale, info, {Scale = 1}):Play()

			tools_group:FadeIn()
		else
			tools_action_panels.tools_panel.player_list.Visible = false
			tools_action_panels.tools_panel.tool_list.Visible = false

			tween_service:Create(tools_action_panels, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(tools_action_panels.tools_panel, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(tools_action_panels.tools_panel.scale, quick, {Scale = 1.2}):Play()

			tools_group:FadeOut()

			--

			task.wait(.3)

			--

			tools_action_panels.Visible = false

			if input_service:GetFocusedTextBox() then
				input_service:GetFocusedTextBox():ReleaseFocus()
			end
		end

	elseif panel == "effects" then

		if state and not tools_action_panels.Visible then
			tools_action_panels.page:JumpTo(tools_action_panels.effects_panel)

			tools_action_panels.Visible = true
			tools_action_panels.ImageTransparency = 1

			tools_action_panels.effects_panel.ImageTransparency = 1
			tools_action_panels.effects_panel.scale.Scale = 1.2

			tools_action_panels.effects_panel.player_list.CanvasPosition = Vector2.new(0, 0)
			tools_action_panels.effects_panel.effects_list.CanvasPosition = Vector2.new(0, 0)
			tools_action_panels.effects_panel.player_list.Visible = true
			tools_action_panels.effects_panel.effects_list.Visible = true

			--// ACCESSIBILITY BUTTON RECENT

			options.recent.icon.Image = "rbxassetid://12974219084"
			options.recent.func.panel.Value = panel

			--

			tween_service:Create(tools_action_panels, info, {ImageTransparency = .5}):Play()
			tween_service:Create(tools_action_panels.effects_panel, info, {ImageTransparency = .1}):Play()
			tween_service:Create(tools_action_panels.effects_panel.scale, info, {Scale = 1}):Play()

			effects_group:FadeIn()
		else
			tools_action_panels.effects_panel.player_list.Visible = false
			tools_action_panels.effects_panel.effects_list.Visible = false

			tween_service:Create(tools_action_panels, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(tools_action_panels.effects_panel, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(tools_action_panels.effects_panel.scale, quick, {Scale = 1.2}):Play()

			effects_group:FadeOut()

			--

			task.wait(.3)

			--

			tools_action_panels.Visible = false

			if input_service:GetFocusedTextBox() then
				input_service:GetFocusedTextBox():ReleaseFocus()
			end
		end

	elseif panel == "custom_commands" then

		if state and not tools_action_panels.Visible then
			tools_action_panels.page:JumpTo(tools_action_panels.custom_commands_panel)

			tools_action_panels.Visible = true
			tools_action_panels.ImageTransparency = 1

			tools_action_panels.custom_commands_panel.ImageTransparency = 1
			tools_action_panels.custom_commands_panel.scale.Scale = 1.2

			tools_action_panels.custom_commands_panel.scroll.Visible = true
			tools_action_panels.custom_commands_panel.scroll.search.textbox.Text = ""

			--// ACCESSIBILITY BUTTON RECENT

			options.recent.icon.Image = "rbxassetid://11419714821"
			options.recent.func.panel.Value = panel

			--

			tween_service:Create(tools_action_panels, info, {ImageTransparency = .5}):Play()
			tween_service:Create(tools_action_panels.custom_commands_panel, info, {ImageTransparency = .1}):Play()
			tween_service:Create(tools_action_panels.custom_commands_panel.scale, info, {Scale = 1}):Play()

			custom_commands_group:FadeIn()
		else
			tools_action_panels.custom_commands_panel.scroll.Visible = false

			tween_service:Create(tools_action_panels, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(tools_action_panels.custom_commands_panel, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(tools_action_panels.custom_commands_panel.scale, quick, {Scale = 1.2}):Play()

			custom_commands_group:FadeOut()

			--

			task.wait(.3)

			--

			tools_action_panels.Visible = false

			if input_service:GetFocusedTextBox() then
				input_service:GetFocusedTextBox():ReleaseFocus()
			end
		end

	elseif panel == "server_privacy" then

		if state and not tools_action_panels.Visible then
			tools_action_panels.page:JumpTo(tools_action_panels.server_privacy_panel)

			tools_action_panels.Visible = true
			tools_action_panels.ImageTransparency = 1

			tools_action_panels.server_privacy_panel.ImageTransparency = 1
			tools_action_panels.server_privacy_panel.scale.Scale = 1.2

			tools_action_panels.server_privacy_panel.scroll.CanvasPosition = Vector2.new(0, 0)
			tools_action_panels.server_privacy_panel.scroll.Visible = true

			--// ACCESSIBILITY BUTTON RECENT

			options.recent.icon.Image = "rbxassetid://14187755345"
			options.recent.func.panel.Value = panel

			--

			tween_service:Create(tools_action_panels, info, {ImageTransparency = .5}):Play()
			tween_service:Create(tools_action_panels.server_privacy_panel, info, {ImageTransparency = .1}):Play()
			tween_service:Create(tools_action_panels.server_privacy_panel.scale, info, {Scale = 1}):Play()

			server_privacy_group:FadeIn()
		else
			tools_action_panels.server_privacy_panel.scroll.Visible = false

			tween_service:Create(tools_action_panels, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(tools_action_panels.server_privacy_panel, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(tools_action_panels.server_privacy_panel.scale, quick, {Scale = 1.2}):Play()

			server_privacy_group:FadeOut()

			--

			task.wait(.3)

			--

			tools_action_panels.Visible = false

			if input_service:GetFocusedTextBox() then
				input_service:GetFocusedTextBox():ReleaseFocus()
			end
		end

	elseif panel == "announcement" then

		if state and not tools_action_panels.Visible then
			tools_action_panels.page:JumpTo(tools_action_panels.announcement_panel)

			tools_action_panels.Visible = true
			tools_action_panels.ImageTransparency = 1

			tools_action_panels.announcement_panel.ImageTransparency = 1
			tools_action_panels.announcement_panel.scale.Scale = 1.2

			tools_action_panels.announcement_panel.scroll.CanvasPosition = Vector2.new(0, 0)
			tools_action_panels.announcement_panel.scroll.Visible = true
			tools_action_panels.announcement_panel.scroll.description.container.textbox.Text = ""

			--// ACCESSIBILITY BUTTON RECENT

			options.recent.icon.Image = "rbxassetid://12966403319"
			options.recent.func.panel.Value = panel

			--

			tween_service:Create(tools_action_panels, info, {ImageTransparency = .5}):Play()
			tween_service:Create(tools_action_panels.announcement_panel, info, {ImageTransparency = .1}):Play()
			tween_service:Create(tools_action_panels.announcement_panel.scale, info, {Scale = 1}):Play()

			announcement_group:FadeIn()
		else
			tools_action_panels.announcement_panel.scroll.Visible = false

			tween_service:Create(tools_action_panels, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(tools_action_panels.announcement_panel, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(tools_action_panels.announcement_panel.scale, quick, {Scale = 1.2}):Play()

			announcement_group:FadeOut()

			--

			task.wait(.3)

			--

			tools_action_panels.Visible = false

			if input_service:GetFocusedTextBox() then
				input_service:GetFocusedTextBox():ReleaseFocus()
			end
		end

	elseif panel == "global_announcement" then

		if state and not tools_action_panels.Visible then
			tools_action_panels.page:JumpTo(tools_action_panels.global_announcement_panel)

			tools_action_panels.Visible = true
			tools_action_panels.ImageTransparency = 1

			tools_action_panels.global_announcement_panel.ImageTransparency = 1
			tools_action_panels.global_announcement_panel.scale.Scale = 1.2

			tools_action_panels.global_announcement_panel.scroll.CanvasPosition = Vector2.new(0, 0)
			tools_action_panels.global_announcement_panel.scroll.Visible = true
			tools_action_panels.global_announcement_panel.scroll.description.container.textbox.Text = ""

			--// ACCESSIBILITY BUTTON RECENT

			options.recent.icon.Image = "rbxassetid://11293979388"
			options.recent.func.panel.Value = panel

			--

			tween_service:Create(tools_action_panels, info, {ImageTransparency = .5}):Play()
			tween_service:Create(tools_action_panels.global_announcement_panel, info, {ImageTransparency = .1}):Play()
			tween_service:Create(tools_action_panels.global_announcement_panel.scale, info, {Scale = 1}):Play()

			global_announcement_group:FadeIn()
		else
			tools_action_panels.global_announcement_panel.scroll.Visible = false

			tween_service:Create(tools_action_panels, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(tools_action_panels.global_announcement_panel, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(tools_action_panels.global_announcement_panel.scale, quick, {Scale = 1.2}):Play()

			global_announcement_group:FadeOut()

			--

			task.wait(.3)

			--

			tools_action_panels.Visible = false

			if input_service:GetFocusedTextBox() then
				input_service:GetFocusedTextBox():ReleaseFocus()
			end
		end
	end

	--// ACCESSIBILITY BUTTON

	options.recent.func:SetAttribute("profile", false)
	options.recent.func:SetAttribute("dashboard", true)
	options.recent.func:SetAttribute("credits", false)

	options.recent.icon.corner.CornerRadius = UDim.new(0, 0)
end

function module:assets_panels(panel:assets_panels, state, plr, object_reference)	
	if panel == "tools" then
		if state and not assets_action_panels.Visible then
			assets_action_panels.properties.id.Value = plr.UserId
			assets_action_panels.properties.username.Value = plr.Name

			assets_action_panels.page:JumpTo(assets_action_panels.manage_tools_panel)

			assets_action_panels.Visible = true
			assets_action_panels.ImageTransparency = 1

			assets_action_panels.manage_tools_panel.ImageTransparency = 1
			assets_action_panels.manage_tools_panel.scale.Scale = 1.2
			assets_action_panels.manage_tools_panel.scroll.CanvasPosition = Vector2.new(0, 0)
			assets_action_panels.manage_tools_panel.scroll.Visible = true
			assets_action_panels.manage_tools_panel.scroll.search.textbox.Text = ""

			--

			tween_service:Create(assets_action_panels, info, {ImageTransparency = .5}):Play()
			tween_service:Create(assets_action_panels.manage_tools_panel, info, {ImageTransparency = .1}):Play()
			tween_service:Create(assets_action_panels.manage_tools_panel.scale, info, {Scale = 1}):Play()

			asset_tools_group:FadeIn()
		else
			assets_action_panels.manage_tools_panel.scroll.Visible = false

			tween_service:Create(assets_action_panels, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(assets_action_panels.manage_tools_panel, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(assets_action_panels.manage_tools_panel.scale, quick, {Scale = 1.2}):Play()

			asset_tools_group:FadeOut()

			--

			task.wait(.3)

			--

			assets_action_panels.Visible = false

			if input_service:GetFocusedTextBox() then
				input_service:GetFocusedTextBox():ReleaseFocus()
			end
		end

	elseif panel == "effects" then

		if state and not assets_action_panels.Visible then
			assets_action_panels.properties.id.Value = plr.UserId
			assets_action_panels.properties.username.Value = plr.Name

			assets_action_panels.page:JumpTo(assets_action_panels.manage_effects_panel)

			assets_action_panels.Visible = true
			assets_action_panels.ImageTransparency = 1

			assets_action_panels.manage_effects_panel.ImageTransparency = 1
			assets_action_panels.manage_effects_panel.scale.Scale = 1.2
			assets_action_panels.manage_effects_panel.scroll.CanvasPosition = Vector2.new(0, 0)
			assets_action_panels.manage_effects_panel.scroll.Visible = true
			assets_action_panels.manage_effects_panel.scroll.search.textbox.Text = ""

			--

			tween_service:Create(assets_action_panels, info, {ImageTransparency = .5}):Play()
			tween_service:Create(assets_action_panels.manage_effects_panel, info, {ImageTransparency = .1}):Play()
			tween_service:Create(assets_action_panels.manage_effects_panel.scale, info, {Scale = 1}):Play()

			asset_effects_group:FadeIn()
		else
			assets_action_panels.manage_effects_panel.scroll.Visible = false

			tween_service:Create(assets_action_panels, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(assets_action_panels.manage_effects_panel, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(assets_action_panels.manage_effects_panel.scale, quick, {Scale = 1.2}):Play()

			asset_effects_group:FadeOut()

			--

			task.wait(.3)

			--

			assets_action_panels.Visible = false

			if input_service:GetFocusedTextBox() then
				input_service:GetFocusedTextBox():ReleaseFocus()
			end
		end

	elseif panel == "players_selection" then

		if state and not assets_action_panels.Visible then
			assets_action_panels.properties.object_reference.Value = object_reference

			assets_action_panels.page:JumpTo(assets_action_panels.select_player_panel)

			assets_action_panels.Visible = true
			assets_action_panels.ImageTransparency = 1

			assets_action_panels.select_player_panel.ImageTransparency = 1
			assets_action_panels.select_player_panel.scale.Scale = 1.2
			assets_action_panels.select_player_panel.scroll.CanvasPosition = Vector2.new(0, 0)
			assets_action_panels.select_player_panel.scroll.Visible = true
			assets_action_panels.select_player_panel.scroll.search.textbox.Text = ""

			--

			tween_service:Create(assets_action_panels, info, {ImageTransparency = .5}):Play()
			tween_service:Create(assets_action_panels.select_player_panel, info, {ImageTransparency = .1}):Play()
			tween_service:Create(assets_action_panels.select_player_panel.scale, info, {Scale = 1}):Play()

			asset_players_group:FadeIn()
		else
			assets_action_panels.select_player_panel.scroll.Visible = false

			tween_service:Create(assets_action_panels, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(assets_action_panels.select_player_panel, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(assets_action_panels.select_player_panel.scale, quick, {Scale = 1.2}):Play()

			asset_players_group:FadeOut()

			--

			task.wait(.3)

			--

			assets_action_panels.Visible = false

			if input_service:GetFocusedTextBox() then
				input_service:GetFocusedTextBox():ReleaseFocus()
			end
		end

	elseif panel == "ban_history" then

		if state and not assets_action_panels.Visible then
			assets_action_panels.properties.id.Value = plr["ID"]
			assets_action_panels.properties.username.Value = plr["USERNAME"]

			assets_action_panels.page:JumpTo(assets_action_panels.ban_history)

			assets_action_panels.Visible = true
			assets_action_panels.ImageTransparency = 1

			assets_action_panels.ban_history.ImageTransparency = 1
			assets_action_panels.ban_history.scale.Scale = 1.2
			assets_action_panels.ban_history.scroll.CanvasPosition = Vector2.new(0, 0)
			assets_action_panels.ban_history.scroll.Visible = true

			--

			tween_service:Create(assets_action_panels, info, {ImageTransparency = .5}):Play()
			tween_service:Create(assets_action_panels.ban_history, info, {ImageTransparency = .1}):Play()
			tween_service:Create(assets_action_panels.ban_history.scale, info, {Scale = 1}):Play()

			asset_ban_history:FadeIn()
		else
			assets_action_panels.ban_history.scroll.Visible = false

			tween_service:Create(assets_action_panels, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(assets_action_panels.ban_history, quick, {ImageTransparency = 1}):Play()
			tween_service:Create(assets_action_panels.ban_history.scale, quick, {Scale = 1.2}):Play()

			asset_ban_history:FadeOut()

			--

			task.wait(.3)

			--

			assets_action_panels.Visible = false

			if input_service:GetFocusedTextBox() then
				input_service:GetFocusedTextBox():ReleaseFocus()
			end
		end

	end
end

return module