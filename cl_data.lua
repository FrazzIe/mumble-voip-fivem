VoiceData = {}
VoiceProperty = {}
DefaultData = {}
ClientServerId = nil

function GetDefaultData() -- Generate default player voice data
	local t = {}

	for i = 1, #DefaultData do
		t[DefaultData[i][1]] = DefaultData[i][2]
	end

	return t
end

function SetVoiceProperty(property, src, data, send) -- Set voice data properties
	if VoiceProperty[property] then -- Check if property exists
		if not VoiceData[src] then -- Init player if data doesn't exist
			VoiceData[src] = GetDefaultData()
		end

		LogMessage("INFO", ("Setting [%s] to [%s]"):format(property, data)) -- Log property change

		VoiceProperty[property](src, data) -- Set voice property

		if send then -- Notify server of local change
			TriggerServerEvent("mumble:SetVoiceProperty", property, data)
		end
	end
end

function GetVoiceProperty(property, src)
	if VoiceProperty[property] then -- Check if property exists
		if not VoiceData[src] then -- Init player if data doesn't exist
			VoiceData[src] = GetDefaultData()
		end

		return VoiceData[src][property]
	end

	return nil
end

AddEventHandler("onClientResourceStart", function(resName)
	if GetCurrentResourceName() ~= resName then
		return
	end

	local resVersion = GetResourceMetadata(resName, "version", 0)
	local resAuthor = GetResourceMetadata(resName, "author", 0)
	LogMessage("INFO", ("Initialising v%s created by %s"):format(resVersion, resAuthor))

	ClientServerId = GetPlayerServerId(PlayerId())

	Citizen.Wait(1000)

	VoiceData[ClientServerId] = GetDefaultData()

	TriggerEvent(config.eventPrefix .. ":initialise", ClientServerId)
end)