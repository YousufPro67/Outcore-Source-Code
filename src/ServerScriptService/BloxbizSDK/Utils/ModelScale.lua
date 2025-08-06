local function getConnectedMotor(model, part)
	local motor = nil

	for _, v in pairs(model:GetDescendants()) do
		if v:IsA("Motor6D") and v.Part1 == part then
			motor = v
		end
	end

	return motor
end

return function(model, scale)
	if model.PrimaryPart == nil then
		local Utils = require(script.Parent)
		Utils.pprint("[SuperBiz] No PrimaryPart was found for model " .. model.Name)
		return
	end

	local specialMeshes = {}
	local baseParts = {}
	local unAnchoredParts = {}
	for _, child in pairs(model:GetDescendants()) do
		if child:IsA("BasePart") then
			table.insert(baseParts, child)

			if not child.Anchored then
				child.Anchored = true
				table.insert(unAnchoredParts, child)
			end
		end

		if child:IsA("SpecialMesh") then
			table.insert(specialMeshes, child)
		end
	end

	for _, mesh in ipairs(specialMeshes) do
		if mesh.MeshType == Enum.MeshType.FileMesh then
			mesh.Scale = mesh.Scale * scale
		end
	end

	for _, basePart in ipairs(baseParts) do
		local connectedMotor = getConnectedMotor(model, basePart)

		if basePart == model.PrimaryPart then
			basePart.Size = basePart.Size * scale
			continue
		end

		if not connectedMotor then
			basePart.Position = model.PrimaryPart.CFrame
				* (model.PrimaryPart.CFrame:ToObjectSpace(basePart.CFrame).Position * scale)
		elseif connectedMotor then
			connectedMotor.Part1 = nil
			basePart.Position = model.PrimaryPart.CFrame
				* (model.PrimaryPart.CFrame:ToObjectSpace(basePart.CFrame).Position * scale)
			connectedMotor.C0 = connectedMotor.Part0.CFrame:ToObjectSpace(basePart.CFrame) * connectedMotor.C1
			connectedMotor.Part1 = basePart
		end

		basePart.Size = basePart.Size * scale
	end

	for _, basePart in ipairs(unAnchoredParts) do
		basePart.Anchored = false
	end
end
