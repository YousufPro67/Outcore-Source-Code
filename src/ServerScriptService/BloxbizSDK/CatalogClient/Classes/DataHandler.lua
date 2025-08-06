local DataHandler = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OnReplicateData = ReplicatedStorage:WaitForChild("BloxbizRemotes"):WaitForChild("OnReplicateData") :: RemoteEvent

local PlayerData = {}

local OnDataChanged = Instance.new("BindableEvent")
OnDataChanged.Name = "OnDataChanged"
DataHandler.DataChanged = OnDataChanged

local OnDataLoaded = Instance.new("BindableEvent")
OnDataLoaded.Name = "OnDataLoaded"
DataHandler.DataLoaded = OnDataLoaded

function DataHandler.GetData(key: string)
	if DataHandler.DataLoaded ~= true then
		DataHandler.DataLoaded.Event:Wait()
	end

	return PlayerData[key]
end

OnReplicateData.OnClientEvent:Connect(function(key: string, value: { [any]: any })
	if key then
		if type(value) == "table" and value.InnerKey then
			local InnerKey = value.InnerKey
			local InnerValue = value.InnerValue

			PlayerData[key][InnerKey] = InnerValue
		else
			PlayerData[key] = value
		end

		OnDataChanged:Fire(key, value)
	else
		PlayerData = value
		DataHandler.DataLoaded:Fire()
		DataHandler.DataLoaded:Destroy()
		DataHandler.DataLoaded = true
	end
end)

return DataHandler
