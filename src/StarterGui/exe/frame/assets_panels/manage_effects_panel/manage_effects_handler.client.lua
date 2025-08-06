local input_service = game:GetService("UserInputService")
local tween_service = game:GetService("TweenService")
local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")

local info = TweenInfo.new(.3, Enum.EasingStyle.Exponential)
local loop = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false)

local exe_storage = replicated_storage.exe_storage
local exe_module = require(exe_storage:WaitForChild("exe_module"))
local events = exe_storage.events
local banit_events = events.banit_events

local frame = script.Parent
local background = frame.Parent

local search = frame.scroll.search

local close = frame.close
local clear = frame.clear
local refresh = frame.refresh

--// APPLIED EFFECTS LIST

function add(effect)
	local template = frame.scroll.list.effect:Clone()

	template.Name = effect.Name
	template.Parent = frame.scroll
	template.Size = UDim2.new(0, 0, 0, 60)

	template.properties.effect.Value = effect

	template.texture.Image = effect:GetAttribute("EffectIcon") or "rbxassetid://14188388240"
	template.effect_name.Text = effect.Name
	template.to.adornee.Text = effect:GetAttribute("To") or "HumanoidRootPart"

	--

	tween_service:Create(template, info, {Size = UDim2.new(1, 0, 0, 60)}):Play()

	--

	for i, quick in pairs(template.actions:GetChildren()) do
		if quick:IsA("ImageButton") then
			tween_service:Create(quick.gradient, loop, {Rotation = 360}):Play()
		end
	end

	--

	effect.Destroying:Connect(function()
		remove(effect)
	end)
end

function add_bulk(effect, tag)
	local folder = frame.scroll:FindFirstChild(tag)

	if folder then
		local template = folder.elements.list.effect:Clone()

		template.Name = effect.Name
		template.Parent = folder.elements
		template.Size = UDim2.new(0, 0, 0, 40)

		template.properties.effect.Value = effect

		template.effect_name.Text = effect.Name

		--

		tween_service:Create(template, info, {Size = UDim2.new(1, 0, 0, 40)}):Play()
	else
		local bulk = frame.scroll.list.bulk_effects:Clone()
		local template = bulk.elements.list.effect:Clone()

		bulk.Name = tag
		bulk.Parent = frame.scroll
		bulk.Size = UDim2.new(0, 0, 0, 60)

		bulk.texture.Image = effect:GetAttribute("EffectIcon") or "rbxassetid://14188388240"
		bulk.effect_name.Text = tag
		bulk.to.adornee.Visible = false

		--

		template.Name = effect.Name
		template.Parent = bulk.elements
		template.Size = UDim2.new(0, 0, 0, 40)

		template.properties.effect.Value = effect

		template.effect_name.Text = effect.Name

		--

		tween_service:Create(bulk, info, {Size = UDim2.new(1, 0, 0, 60)}):Play()
		tween_service:Create(template, info, {Size = UDim2.new(1, 0, 0, 40)}):Play()
	end
	
	local success, error = pcall(function()
		effect.Destroying:Connect(function()
			remove_bulk(effect:GetAttribute("tagged"), effect)
		end)
	end)
end

function remove(effect)
	for i, items in pairs(frame.scroll:GetChildren()) do
		if items:IsA("ImageButton") and not items:HasTag("bulk") then
			local properties = items:FindFirstChild("properties")

			if properties and properties.effect.Value == effect then
				tween_service:Create(items, info, {Size = UDim2.new(0, 0, 0, 60)}):Play()

				--

				task.wait(.3)

				--

				items:Destroy()
			end
		end
	end
end

function remove_bulk(tag, effect)
	if effect then
		local folder = frame.scroll:FindFirstChild(tag)

		for i, elements in pairs(folder.elements:GetChildren()) do
			if elements:IsA("ImageButton") and elements.properties.effect.Value == effect then
				if #folder.elements:GetChildren() <= 4 then
					tween_service:Create(folder, info, {Size = UDim2.new(0, 0, 0, 60)}):Play()

					--

					task.wait(.3)

					--

					folder:Destroy()
				else
					tween_service:Create(elements, info, {Size = UDim2.new(0, 0, 0, 40)}):Play()

					--

					task.wait(.3)

					--

					elements:Destroy()
				end
			end
		end
	else
		local folder = frame.scroll:FindFirstChild(tag)

		tween_service:Create(folder, info, {Size = UDim2.new(0, 0, 0, 40)}):Play()

		--

		task.wait(.3)

		--

		folder:Destroy()
	end
end

function fetch_effects(player)
	local character = player.Character or player.CharacterAdded:Wait()

	for i, items in pairs(frame.scroll:GetChildren()) do
		if items:IsA("ImageButton") then
			tween_service:Create(items, info, {Size = UDim2.new(0, 0, 0, 60)}):Play()

			items:Destroy()
		end
	end

	for i, effect in pairs(character:GetDescendants()) do
		if (effect:IsA("Fire") or effect:IsA("Smoke") or effect:IsA("ParticleEmitter")
			or effect:IsA("Sparkles") or effect:IsA("Explosion") or effect:IsA("Light")) then

			if effect:GetAttribute("tagged") then
				add_bulk(effect, effect:GetAttribute("tagged"))
			else
				add(effect)
			end
		end
	end
end

function run()
	for i, items in pairs(frame.scroll:GetChildren()) do
		if items:IsA("ImageButton") then
			if items:HasTag("bulk") then

				items.actions.delete.MouseButton1Click:Connect(function()
					banit_events.delete_effect:FireServer(background.properties.username.Value, items.Name)
				end)

				--

				for i, elements in pairs(items.elements:GetChildren()) do
					if elements:IsA("ImageButton") then
						elements.actions.delete.MouseButton1Click:Connect(function()
							banit_events.delete_effect:FireServer(background.properties.username.Value, elements.properties.effect.Value)
						end)

						items.elements.ChildRemoved:Connect(function()
							local e = items:FindFirstChild("elements")

							if e then
								if #e:GetChildren() < 4 then
									remove_bulk(items.Name)
								end
							end
						end)

						--

						for i, quick in pairs(elements.actions:GetChildren()) do
							if quick:IsA("ImageButton") then

								quick.MouseEnter:Connect(function()
									quick.gradient.Enabled = true

									tween_service:Create(quick, info, {BackgroundTransparency = .2}):Play()
									tween_service:Create(quick.icon.scale, info, {Scale = 1.2}):Play()
								end)

								quick.MouseButton1Down:Connect(function()
									tween_service:Create(quick, info, {BackgroundTransparency = .4}):Play()
									tween_service:Create(quick.icon.scale, info, {Scale = .8}):Play()
								end)

								quick.InputEnded:Connect(function()
									quick.gradient.Enabled = false

									tween_service:Create(quick, info, {BackgroundTransparency = 0}):Play()
									tween_service:Create(quick.icon.scale, info, {Scale = 1}):Play()
								end)

							end
						end
					end
				end
			else
				items.actions.delete.MouseButton1Click:Connect(function()
					banit_events.delete_effect:FireServer(background.properties.username.Value, items.properties.effect.Value)
				end)
			end

			--

			for i, quick in pairs(items.actions:GetChildren()) do
				if quick:IsA("ImageButton") then

					quick.MouseEnter:Connect(function()
						quick.gradient.Enabled = true

						tween_service:Create(quick, info, {BackgroundTransparency = .2}):Play()
						tween_service:Create(quick.icon.scale, info, {Scale = 1.2}):Play()
					end)

					quick.MouseButton1Down:Connect(function()
						tween_service:Create(quick, info, {BackgroundTransparency = .4}):Play()
						tween_service:Create(quick.icon.scale, info, {Scale = .8}):Play()
					end)

					quick.InputEnded:Connect(function()
						quick.gradient.Enabled = false

						tween_service:Create(quick, info, {BackgroundTransparency = 0}):Play()
						tween_service:Create(quick.icon.scale, info, {Scale = 1}):Play()
					end)

				end
			end

		end
	end
end

background:GetPropertyChangedSignal("Visible"):Connect(function()
	if (background.Visible and background.page.CurrentPage == frame) then
		local player = players:GetPlayerByUserId(background.properties.id.Value)

		exe_module:prompt_resync(true, "Fetching...", "assets")

		--

		task.wait(.5)

		--

		fetch_effects(player)
		run()

		--

		task.wait(Random.new():NextNumber(.5, 1))

		--

		exe_module:prompt_resync(false)

		--

		if frame.scroll.list.AbsoluteContentSize.Y <= 0 then
			tween_service:Create(frame.empty, info, {GroupTransparency = 0}):Play()
		else
			tween_service:Create(frame.empty, info, {GroupTransparency = 1}):Play()
		end
	end
end)

--

frame.scroll.list.Changed:Connect(function()
	if frame.scroll.list.AbsoluteContentSize.Y <= 0 then
		tween_service:Create(frame.empty, info, {GroupTransparency = 0}):Play()
	else
		tween_service:Create(frame.empty, info, {GroupTransparency = 1}):Play()
	end
end)

function results()
	local term = string.lower(search.textbox.Text)

	for i, v in pairs(frame.scroll:GetChildren()) do
		if v:IsA("ImageButton") then
			if term ~= "" then
				local item = string.lower(v.Name)

				if string.find(item, term) then
					v.LayoutOrder = 1
				else
					v.LayoutOrder = 2
				end

				tween_service:Create(search.clear_button.icon.scale, info, {Scale = 1}):Play()
			else
				v.LayoutOrder = 1

				tween_service:Create(search.clear_button.icon.scale, info, {Scale = 0}):Play()
			end
		end
	end

	if search.textbox:IsFocused() then
		tween_service:Create(search.icon, info, {ImageTransparency = Random.new():NextNumber(.3, .9)}):Play()
	else
		tween_service:Create(search.icon, info, {ImageTransparency = .5}):Play()
	end
end

search.textbox.Changed:Connect(results)

search.textbox.Focused:Connect(function()
	tween_service:Create(search, info, {BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0}):Play()
end)

search.textbox.FocusLost:Connect(function()
	tween_service:Create(search, info, {BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = .7}):Play()
end)

search.clear_button.MouseButton1Click:Connect(function()
	if input_service:IsKeyDown(Enum.KeyCode.LeftShift) then
		search.textbox.Text = ""
		search.textbox:CaptureFocus()
	else
		search.textbox.Text = ""
	end
end)

search.clear_button.MouseEnter:Connect(function()
	if search.textbox.Text ~= "" then
		tween_service:Create(search.clear_button.background, info, {BackgroundTransparency = .8}):Play()
		search.clear_button.background.gradient.Enabled = true
	end
end)

search.clear_button.InputEnded:Connect(function()
	tween_service:Create(search.clear_button.background, info, {BackgroundTransparency = 1}):Play()
	search.clear_button.background.gradient.Enabled = false
end)

--// CORE NAVIGATIONS

background.MouseButton1Click:Connect(function()
	exe_module:assets_panels("effects", false)
end)

--// HOVER

tween_service:Create(search.clear_button.background.gradient, loop, {Rotation = 360}):Play()
tween_service:Create(close.gradient, loop, {Rotation = 360}):Play()
tween_service:Create(clear.gradient, loop, {Rotation = 360}):Play()
tween_service:Create(refresh.gradient, loop, {Rotation = 360}):Play()

close.MouseEnter:Connect(function()
	close.gradient.Enabled = true

	tween_service:Create(close.icon.scale, info, {Scale = 1.2}):Play()
end)

close.MouseButton1Down:Connect(function()
	tween_service:Create(close.icon.scale, info, {Scale = .8}):Play()
end)

close.InputEnded:Connect(function()
	close.gradient.Enabled = false

	tween_service:Create(close.icon.scale, info, {Scale = 1}):Play()
end)

close.MouseButton1Click:Connect(function()
	exe_module:assets_panels("effects", false)
end)

--

refresh.MouseEnter:Connect(function()
	refresh.gradient.Enabled = true

	tween_service:Create(refresh.icon.scale, info, {Scale = 1.2}):Play()
end)

refresh.MouseButton1Down:Connect(function()
	tween_service:Create(refresh.icon.scale, info, {Scale = .8}):Play()
end)

refresh.InputEnded:Connect(function()
	refresh.gradient.Enabled = false

	tween_service:Create(refresh.icon.scale, info, {Scale = 1}):Play()
end)

refresh.MouseButton1Click:Connect(function()
	local player = players:GetPlayerByUserId(background.properties.id.Value)

	exe_module:prompt_resync(true, "Fetching...")

	--

	task.wait(.5)

	--

	fetch_effects(player)
	run()

	--

	task.wait(Random.new():NextNumber(.5, 1))

	exe_module:prompt_resync(false)

	--

	if frame.scroll.list.AbsoluteContentSize.Y <= 0 then
		tween_service:Create(frame.empty, info, {GroupTransparency = 0}):Play()
	else
		tween_service:Create(frame.empty, info, {GroupTransparency = 1}):Play()
	end
end)

--

clear.MouseEnter:Connect(function()
	clear.gradient.Enabled = true

	tween_service:Create(clear.icon.scale, info, {Scale = 1.2}):Play()
end)

clear.MouseButton1Down:Connect(function()
	tween_service:Create(clear.icon.scale, info, {Scale = .8}):Play()
end)

clear.InputEnded:Connect(function()
	clear.gradient.Enabled = false

	tween_service:Create(clear.icon.scale, info, {Scale = 1}):Play()
end)

clear.MouseButton1Click:Connect(function()
	banit_events.clear_effects:FireServer(background.properties.username.Value)

	exe_module:assets_panels("effects", false)
end)