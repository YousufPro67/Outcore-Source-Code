local module = {}

function round(num, numDecimalPlaces)
	local mult = 10 ^ (numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

--"Alpha" throughout entire script refers to the ratio: (TextSize/AbsoluteSize.Y)

function module.scaleTextToMaxAlpha(textObj)
	local fitSize = 0
	textObj.TextSize = fitSize
	textObj.TextScaled = false

	repeat
		fitSize = fitSize + 1
		textObj.TextSize = fitSize
	until textObj.TextFits == false or fitSize > 100

	fitSize = fitSize - 1
	textObj.TextSize = fitSize

	return fitSize
end

function module.descendantsUniformTextSize(guiObj, maxAlphaSize, waited1Frame)
	--if not waited1Frame then
	--need to wait otherwise AbsoluteSize will read incorrectly
	--task.wait()
	--end

	local smallestSize = 999
	local textObjSizeDict = {}

	for _, v in pairs(guiObj:GetDescendants()) do
		if v:IsA("TextButton") or v:IsA("TextLabel") then
			local size = module.scaleTextToMaxAlpha(v)
			textObjSizeDict[v] = size

			if maxAlphaSize then
				local alphaSize = math.ceil(v.AbsoluteSize.Y * maxAlphaSize)
				size = math.min(size, alphaSize)
				textObjSizeDict[v] = size
			end

			if smallestSize > size then
				smallestSize = size
			end
		end
	end

	for obj, _ in pairs(textObjSizeDict) do
		obj.TextSize = smallestSize
	end

	return smallestSize
end

function module.setTextSizeWithAlpha(textObj, alpha, dontSetMax, waited1Frame)
	--if not waited1Frame then
	--need to wait otherwise AbsoluteSize will read incorrectly
	--task.wait()
	--end

	local absoluteSize = textObj.AbsoluteSize.Y
	local sizeToSet = math.ceil(absoluteSize * alpha)
	textObj.TextScaled = false
	textObj.TextWrapped = true
	textObj.TextSize = sizeToSet

	if not textObj.TextFits and not dontSetMax then
		module.scaleTextToMaxAlpha(textObj)
	end

	return textObj.TextSize
end

function module.resizeParentXToFitTextWithAlpha(textObj, text, alpha, extraPadding, waited1Frame)
	textObj.Text = text
	textObj.TextScaled = false
	textObj.TextWrapped = true

	local parentStartSize = textObj.Parent.Size
	local parentXSize = 0
	local textSize = module.setTextSizeWithAlpha(textObj, alpha, true, waited1Frame)

	repeat
		parentXSize = parentXSize + 0.01
		textObj.Parent.Size =
			UDim2.new(parentXSize, parentStartSize.X.Offset, parentStartSize.Y.Scale, parentStartSize.Y.Offset)
	until textObj.TextFits

	if extraPadding then
		textObj.Parent.Size = textObj.Parent.Size + UDim2.new(extraPadding, 0, 0, 0)
		parentXSize = parentXSize + extraPadding
	end

	return parentXSize
end

function module.resizeParentYToFitTextWithAlpha(textObj, text, alpha, parentYStartSize, waited1Frame)
	textObj.Text = text
	textObj.TextScaled = false
	textObj.TextWrapped = true

	local parentOriginalSize = textObj.Parent.Size
	local parentYSize = parentYStartSize or 0
	local sizeAdded = 0

	--prevent infinite growth
	textObj.Parent.Size =
		UDim2.new(parentOriginalSize.X.Scale, parentOriginalSize.X.Offset, parentYSize, parentOriginalSize.Y.Offset)
	module.setTextSizeWithAlpha(textObj, alpha, true, waited1Frame)

	local function expandUntilTextFits()
		while not textObj.TextFits do
			parentYSize = parentYSize + 0.005
			sizeAdded = sizeAdded + 0.005
			textObj.Parent.Size =
				UDim2.new(parentOriginalSize.X.Scale, parentOriginalSize.X.Offset, parentYSize, parentOriginalSize.Y.Offset)
		end
	end

	--Sometimes TextFits property is wrong if not waited a frame
	repeat
		expandUntilTextFits()
		task.wait()
	until textObj.TextFits

	return sizeAdded
end

return module
