local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")
local MarketplaceService = game:GetService("MarketplaceService")

local BloxbizSDK = script.Parent.Parent.Parent.Parent

local UtilsStorage = BloxbizSDK:FindFirstChild("Utils")
local Fusion = require(UtilsStorage:WaitForChild("Fusion"))

local AvatarHandler = require(BloxbizSDK.CatalogClient.Classes.AvatarHandler)

local New = Fusion.New
local Ref = Fusion.Ref
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local OnChange = Fusion.OnChange
local Observer = Fusion.Observer
local Children = Fusion.Children
local Computed = Fusion.Computed
local ForValues = Fusion.ForValues

local Components = script.Parent.Parent
local ScrollingFrame = require(Components.Generic.ScrollingFrame)
local LoadingFrame = require(Components.LoadingFrame)
local ScaledText = require(Components.ScaledText)
local Dropdown = require(Components.Dropdown)
local Button = require(script.Parent.Button)

local function getResultsFromId(id, type)
    local results = {}

    id = tonumber(id)
    if not id then
        return results
    end

    local successUser, playerInfo = pcall(function()
        return Players:GetNameFromUserIdAsync(id)
    end)

    if (successUser and not type) or (successUser and type and type == "user") then
        table.insert(results, {Type = "User", Data = playerInfo, Id = id,})
    end

    local successGroup, groupInfo = pcall(function()
        return GroupService:GetGroupInfoAsync(id)
    end)

    if (successGroup and not type) or (successGroup and type and type == "group") then
        table.insert(results, {Type = "Group", Data = groupInfo.Name, Id = id,})
    end

    local successAsset, productInfo = pcall(function()
        return MarketplaceService:GetProductInfo(id)
    end)

    if (successAsset and not type) or (successAsset and type and type == "item") then
        if AvatarHandler.IsValidAssetType(productInfo.AssetTypeId) then
            print(productInfo)
            table.insert(results, {Type = "Item", Data = productInfo.Name, Id = id,})
        end
    end

    local successBundle, bundleInfo = pcall(function()
        return MarketplaceService:GetProductInfo(id, Enum.InfoType.Bundle)
    end)

    if (successBundle and not type) or (successBundle and type and type == "item") then
        table.insert(results, {Type = "Item", Data = bundleInfo.Name, Id = id, IsBundle = true})
    end

    return results
end

local function getResultsFromUrl(text)
    local results = {}

    local isUser = text:find("users/")
    local isItem = text:find("catalog/") or text:find("bundles/")
    local isGroup = text:find("groups/")

    local Id = text:match("%d+")

    if isUser then
        results = getResultsFromId(Id, "user")
    end

    if isGroup then
        results = getResultsFromId(Id, "group")
    end

    if isItem then
        results = getResultsFromId(Id, "item")
    end

    return results
end

local function getSearchResults(text)
    local results = {}

    if #text == 0 or text == "" then
        return results
    end

    local isId = tonumber(text)
    if isId then
        results = getResultsFromId(text)
        if #results > 0 then
            return results
        end
    end

    results = getResultsFromUrl(text)
    if #results > 0 then
        return results
    end

    results[1] = {
        Id = text,
        Type = "Search term",
        Data = text,
    }

    return results
end

return function(props)
    local itemsList = props.SelectedItems
    local selectedGroup = props.SelectedGroup

    local selectedResult = Value()
    local disabledButton = Value(true)
    local trayOpened = Value(true)

    local textBox = Value()

    local searchResults = Value({})
    local searchResultsCount = Value(0)

    Observer(selectedResult):onChange(function()
        local result = selectedResult:get()

        if result then
            textBox:get().Text = result.Data
        end

        disabledButton:set(result == nil)
    end)

    local currentText, currentSearchText = "", ""

    local function clearTextBox()
        currentText, currentSearchText = "", ""

        textBox:get().Text = ""
        searchResults:set({})
        searchResultsCount:set(0)
        selectedResult:set(nil)
    end

    local function isDuplicate(id, type)
        local items = itemsList:get()
        local itemId = id .. "_" .. type

        return items[itemId] ~= nil
    end

    local function onItemSelect(result)
        currentText = ""
        selectedResult:set(result)
    end

    local function onItemAdd()
        local result = selectedResult:get()
        if not result then
            return
        end

        clearTextBox()

        local items = itemsList:get()

        local itemId = result.Id .. "_" .. result.Type
        items[itemId] = result

        itemsList:set(items)
    end

    local function displaySelectedGroupAsResult()
        local group = selectedGroup:get()
        if not group then
            return
        end

        if isDuplicate(group.value, group.type) then
            return
        end

        searchResults:set({
            {
                Data = group.label,
                Type = group.type,
                Id = group.value,
            },
        })
        searchResultsCount:set(1)
    end

    local function onFocused()
        local textbox = textBox:get()
        local textSize = #textbox.Text
        textbox.CursorPosition = textSize + 1

        if textSize < 1 then
            displaySelectedGroupAsResult()
        end

        trayOpened:set(true)
    end

    local function onFocusLost()
        task.delay(0.1, function()
            trayOpened:set(false)
        end)
    end

    local currentQuery
    local function onTextChanged(text)
        if selectedResult:get() then
            if #currentText > #text then
                selectedResult:set(nil)

                textBox:get().Text = currentSearchText
                textBox:get().CursorPosition = #currentSearchText + 1
            else
                currentText = text
            end
            return
        else
            currentSearchText = text
        end

        if currentQuery then
            coroutine.close(currentQuery)
        end

        currentQuery = coroutine.create(function()
            task.wait(0.5)

            local results = getSearchResults(text)
            searchResults:set(results)
            searchResultsCount:set(#results)
        end)

        coroutine.resume(currentQuery)
    end

    local containerHeight = Value(0)
    local absCornerRadius = Computed(function()
        return UDim.new(0, 0.225 * containerHeight:get())
    end)

    return {
        Button {
            Text = "Add",
            Size = UDim2.fromScale(0.13, 1),
            Position = UDim2.fromScale(0.87, 0),
            IgnoreAspecetRatio = true,

            Color = {
                Default = Color3.fromRGB(66, 168, 255),
                MouseDown = Color3.fromRGB(85, 152, 211),
                Hover = Color3.fromRGB(55, 109, 156),
                Selected = Color3.fromRGB(255, 255, 255)
            },
            TextColor3 = Color3.fromRGB(25, 25, 25),

            OnClick = onItemAdd,
            Disabled = disabledButton,
        },

        New "Frame" {
            Size = UDim2.fromScale(0.855, 1),
            Position = UDim2.fromScale(0, 0),
            BackgroundColor3 = Color3.fromRGB(41, 43, 48),

            [OnChange "AbsoluteSize"] = function(size)
                containerHeight:set(size.Y)
            end,

            [Children] = {
                New "TextBox" {
                    Name = "SearchBox",
                    FontFace = Font.fromEnum(Enum.Font.GothamMedium),
                    PlaceholderColor3 = Color3.fromRGB(149, 149, 149),
                    PlaceholderText = "Enter asset ID or URL to add groups, users, or items",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextScaled = true,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(0.9, 0.52),
                    Position = UDim2.fromScale(0.05, 0.5),
                    AnchorPoint = Vector2.new(0, 0.5),

                    [Ref] = textBox,

                    [OnEvent "Focused"] = onFocused,
                    [OnEvent "FocusLost"] = onFocusLost,

                    [OnChange "Text"] = onTextChanged,

                    [Children] = {
                        ScaledText {
                            Visible = false,

                            Name = "SelectedResult",
                            Size = UDim2.fromScale(1, 1),
                            TextXAlignment = Enum.TextXAlignment.Left,

                            Text = Computed(function()
                                local result = selectedResult:get()
                                if not result then
                                    return ""
                                end

                                return result.Data
                            end),
                        },
                    },
                },

                New "Frame" {
                    Name = "Tray",
                    Position = UDim2.new(0, 0, 1, 8),
                    ClipsDescendants = true,
                    BackgroundColor3 = Color3.fromRGB(41, 43, 48),                    

                    Size = Computed(function()
                        return UDim2.new(1, 0, 0, searchResultsCount:get() * containerHeight:get())
                    end),

                    Visible = Computed(function()
                        return trayOpened:get()
                    end),

                    [Children] = {
                        New "UICorner" {
                            CornerRadius = absCornerRadius,
                        },

                        New "UIListLayout" {
                            SortOrder = Enum.SortOrder.LayoutOrder,
                        },

                        ForValues(searchResults, function(result)
                            return New "TextButton" {
                                Name = result.Type,
                                Size = UDim2.new(1, 0, 0, containerHeight:get()),
                                BackgroundColor3 = Color3.fromRGB(41, 43, 48),
                                AutoButtonColor = true,
                                Text = "",

                                Visible = Computed(function()
                                    return not isDuplicate(result.Id, result.Type)
                                end),

                                [OnEvent "Activated"] = function()
                                    onItemSelect(result)
                                end,

                                [Children] = {
                                    ScaledText {
                                        Name = "ResultValue",
                                        Text = result.Data,
                                        Size = UDim2.fromScale(0.6, 0.5),
                                        Position = UDim2.fromScale(0.05, 0.5),
                                        AnchorPoint = Vector2.new(0, 0.5),
                                        TextXAlignment = Enum.TextXAlignment.Left,
                                    },

                                    ScaledText {
                                        Name = "ResultType",
                                        Text = result.Type,
                                        Size = UDim2.fromScale(0.3, 0.45),
                                        Position = UDim2.fromScale(0.95, 0.5),
                                        AnchorPoint = Vector2.new(1, 0.5),
                                        TextColor3 = Color3.new(0.7, 0.7, 0.7),
                                        TextXAlignment = Enum.TextXAlignment.Right,
                                    },

                                    New "UICorner" {
                                        CornerRadius = UDim.new(0, absCornerRadius:get().Offset + 1)
                                    },
                                },
                            }
                        end, Fusion.cleanup),
                    },
                },

                New "UICorner" {
                    CornerRadius = UDim.new(0.3),
                },
            },
        },
    }
end