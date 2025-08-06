local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local MetricsClient = require(script.Parent.Parent.MetricsClient)

local RenderStepped = RunService.RenderStepped

local module = {}

--branch = current branch
--branchOption = branch that was pressed

--called everytime displayed and before closing
local function branchEntry(dialogueObject, branch, branchName)
	local oldBranchEntered = dialogueObject.branchEntered

	dialogueObject.branchEntered = {
		branch_start_time = os.time(),
		timestamp = os.time(), --naming issue
		current_branch = branchName,
		bloxbiz_ad_id = dialogueObject.adData.bloxbiz_ad_id,
		dialogue_guid = dialogueObject.dialogueGUID,
		response_guid = HttpService:GenerateGUID(false),
	}

	if branchName ~= "Branch1" then
		dialogueObject.branchEntered.response_time = tick() - oldBranchEntered.branch_start_time_tick
		dialogueObject.branchEntered.previous_branch = oldBranchEntered.current_branch
		dialogueObject.branchEntered.previous_branch_text =
			dialogueObject.branchData[oldBranchEntered.current_branch].Text
		dialogueObject.branchEntered.previous_response = oldBranchEntered.response
	else
		dialogueObject.branchEntered.response_time = 0
		dialogueObject.branchEntered.previous_branch = ""
		dialogueObject.branchEntered.previous_branch_text = ""
		dialogueObject.branchEntered.previous_response = ""
	end

	if branch then
		dialogueObject.branchEntered.current_branch_text = dialogueObject.branchData[branchName].Text
	else
		dialogueObject.branchEntered.current_branch_text = ""
	end

	MetricsClient.queueBranchEntry(dialogueObject)

	dialogueObject.branchEntered.branch_start_time_tick = tick()
end

local function update(dialogueObject, branch, branchName)
	local main = dialogueObject.main

	local isLikertScale = #branch.BranchOptions == 5
	local likertButtonConnections = {}

	local maxSizeX = Workspace.CurrentCamera.ViewportSize.X * 0.8

	if maxSizeX > 1 then
		main.UISizeConstraint.MaxSize = Vector2.new(Workspace.CurrentCamera.ViewportSize.X * 0.9, math.huge)
	end

	local optionFrameExample
	if not isLikertScale then
		optionFrameExample = main.Options["Option1"]:Clone()
		optionFrameExample.TextButton.Text = "Text for min text size."
		optionFrameExample.Name = "Option"
	end

	local optionDebounce = false

	local function optionClicked(branchOption)
		if optionDebounce then
			return
		end

		optionDebounce = true

		if isLikertScale then
			for _, connection in likertButtonConnections do
				connection:Disconnect()
			end
			likertButtonConnections = nil

			main.LikertScale.Visible = false
		end

		local oldBranchEntered = dialogueObject.branchEntered
		local nextBranchName = branchOption.Next
		local isDuplicateEntry = (oldBranchEntered and oldBranchEntered.current_branch == nextBranchName)

		if isDuplicateEntry then
			return
		end

		dialogueObject.branchEntered.response = branchOption.Text

		if branchOption.Next == "" then
			branchEntry(dialogueObject, false, branchOption.Next)
			dialogueObject:endDialogue()
			return
		end

		dialogueObject:handleEvent(branchOption.Event)
		local nextBranch = dialogueObject.branchData[branchOption.Next]
		dialogueObject.DisplayBranch.display(dialogueObject, nextBranch, nextBranchName)
	end

	if isLikertScale then
		for i = 1, 5 do
			local branchOption = branch.BranchOptions[i]
			local button = main.LikertScale:FindFirstChild("Option" .. i)

			if branchOption and button then
				local label = button.TextLabel
				label.Text = branchOption.Text

				if branchOption.Text:match("%s") then
					label.Size = UDim2.fromScale(0.845, 0.6)
				else
					label.Size = UDim2.fromScale(0.845, 0.3)
				end

				table.insert(likertButtonConnections, button.MouseButton1Click:Connect(function()
					optionClicked(branchOption)
				end))
			end
		end
	else
		for _, option in pairs(main.Options:GetChildren()) do
			if option:IsA("Frame") then
				option:Destroy()
			end
		end

		for i = 1, 4 do
			local branchOption = branch.BranchOptions[i]

			if branchOption then
				local optionFrame = optionFrameExample:Clone()
				optionFrame.Parent = main.Options
				optionFrame.Name = "Option" .. i
				optionFrame.TextButton.Text = branchOption.Text

				optionFrame.TextButton.MouseButton1Click:Connect(function()
					optionClicked(branchOption)
				end)
			end
		end
	end

	local option3Exists = main.Options:FindFirstChild("Option3")
	local option4Exists = main.Options:FindFirstChild("Option4")

	if not option3Exists and not option4Exists then
		main.UIAspectRatioConstraint.AspectRatio = 4.2783
		main.Options.UIGridLayout.CellSize = UDim2.new(0.494, 0, 1, 0)
		main.Options.Size = UDim2.new(1, 0, 0.475, 0)
		main.Options.Position = UDim2.new(0.5, 0, 0.55, 0)
		main.CharacterName.Size = UDim2.new(main.CharacterName.Size.X.Scale, 0, 0.2, 0)
		main.PaidAdLabel.Size = UDim2.new(main.PaidAdLabel.Size.X.Scale, 0, 0.2, 0)
		main.Size = UDim2.new(1, 0, 0.235, 0)

		main.Content.TextLabel.Text = branch.Text

		main.Content.TextLabel.Size = UDim2.new(0.9, 0, 1, -(64.88 / 114.27) * main.Options.Option1.AbsoluteSize.Y)
		local sizeAdded = dialogueObject.FormatText.resizeParentYToFitTextWithAlpha(
			main.Content.TextLabel,
			branch.Text,
			0.677,
			0.33 + 0.189,
			true
		)

		main.Content.Position = UDim2.new(0.5, 0, -0.019, 0) - UDim2.new(0, 0, sizeAdded, 0)
		main.PaidAdLabel.Position = UDim2.new(0.962, 0, -0.025, 0) - UDim2.new(0, 0, sizeAdded, 0)
		main.CharacterName.Position = UDim2.new(0.038, 0, -0.025, 0) - UDim2.new(0, 0, sizeAdded, 0)
	elseif option3Exists or option4Exists then
		main.UIAspectRatioConstraint.AspectRatio = 2.844
		main.Options.UIGridLayout.CellSize = UDim2.new(0.494, 0, 0.475, 0)
		main.Options.Size = UDim2.new(1, 0, 0.656, 0)
		main.Options.Position = UDim2.new(0.5, 0, 0.344, 0)
		main.CharacterName.Size = UDim2.new(main.CharacterName.Size.X.Scale, 0, 0.133, 0)
		main.PaidAdLabel.Size = UDim2.new(main.PaidAdLabel.Size.X.Scale, 0, 0.133, 0)
		main.Size = UDim2.new(1, 0, 0.353, 0)

		main.Content.TextLabel.Text = branch.Text

		main.Content.TextLabel.Size = UDim2.new(0.9, 0, 1, -(64.88 / 114.27) * main.Options.Option1.AbsoluteSize.Y)
		local sizeAdded = dialogueObject.FormatText.resizeParentYToFitTextWithAlpha(
			main.Content.TextLabel,
			branch.Text,
			0.677,
			0.33,
			true
		)

		main.Content.Position = UDim2.new(0.5, 0, -0.019, 0) - UDim2.new(0, 0, sizeAdded, 0)
		main.PaidAdLabel.Position = UDim2.new(0.962, 0, -0.025, 0) - UDim2.new(0, 0, sizeAdded, 0)
		main.CharacterName.Position = UDim2.new(0.038, 0, -0.025, 0) - UDim2.new(0, 0, sizeAdded, 0)
	end

	local ad_disclaimer_text = "Paid Ad"

	if dialogueObject.adModelData.ad_disclaimer_text then
		ad_disclaimer_text = dialogueObject.adModelData.ad_disclaimer_text
	end

	main.PaidAdLabel.Visible = dialogueObject.adModelData.show_ad_disclaimer_in_dialogue
	dialogueObject.FormatText.resizeParentXToFitTextWithAlpha(
		main.PaidAdLabel.TextLabel,
		ad_disclaimer_text,
		0.759,
		0.031,
		true
	)
	dialogueObject.FormatText.resizeParentXToFitTextWithAlpha(
		main.CharacterName.TextLabel,
		dialogueObject.adModelData.ad_character_name,
		0.759,
		nil,
		true
	)

	--arbitrary padding
	main.CharacterName.Size = main.CharacterName.Size + UDim2.new(0.04, 0, 0, 0)

	dialogueObject.FormatText.descendantsUniformTextSize(main.Options, 0.45, true)

	main.LikertScale.Position = main.Options.Position
end

function module.onWindowSizeChange(dialogueObject)
	if dialogueObject.dialogueEnded then
		return
	end

	local branchName = dialogueObject.branchEntered.current_branch
	local branch = dialogueObject.branchData[branchName]

	--Give it a frame to update GUI properties
	task.wait()

	update(dialogueObject, branch, branchName)
end

--[[
	for AbsoluteSize to be read correctly:
		-GUI has to be visible
		-GUI has to be enabled
		-We have to wait one frame
]]
function module.setTransparency(dialogueObject, transparency)
	local main = dialogueObject.main
	main.CharacterName.Transparency = transparency
	main.CharacterName.TextLabel.TextTransparency = transparency
	main.Content.Transparency = transparency
	main.Content.TextLabel.TextTransparency = transparency
	main.PaidAdLabel.Transparency = transparency
	main.PaidAdLabel.TextLabel.TextTransparency = transparency

	for _, obj in pairs(main.Options:GetChildren()) do
		if obj:IsA("Frame") then
			obj.Transparency = transparency
			obj.TextButton.TextTransparency = transparency
		end
	end
end

function module.restoreTransparency(dialogueObject)
	module.setTransparency(dialogueObject, 0)

	local main = dialogueObject.main
	main.Content.Transparency = 0.05

	for _, obj in pairs(main.Options:GetChildren()) do
		if obj:IsA("Frame") then
			obj.Transparency = 0.05
		end
	end
end

function module.display(dialogueObject, branch, branchName)
	local main = dialogueObject.main
	module.setTransparency(dialogueObject, 0.99)
	main.Visible = true --false

	local branch = branch or dialogueObject.branchData["Branch1"]

	branchEntry(dialogueObject, branch, branchName)

	--Give it a frame to update GUI properties
	task.wait()

	update(dialogueObject, branch, branchName)

	module.restoreTransparency(dialogueObject)

	for i = 1, 4 do
		local optionFrame = main.Options:FindFirstChild("Option" .. i)

		if optionFrame then
			optionFrame.Visible = false
		end
	end

	main.LikertScale.Visible = false
	main.Visible = true

	task.spawn(function()
		dialogueObject:animateText1(main.Content.TextLabel, branch.Text, 0.03)

		if not dialogueObject.dialogueEnded then
			local isLikertScale = #branch.BranchOptions == 5
			if isLikertScale then
				main.LikertScale.Visible = true
			else
				for i = 1, 4 do
					local optionFrame = main.Options:FindFirstChild("Option" .. i)
					local branchOption = branch.BranchOptions[i]

					if optionFrame and branchOption then
						optionFrame.Visible = true
					end
				end
			end
		end
	end)
end

return module
