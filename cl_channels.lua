DefaultData[#DefaultData + 1] = { "channel", 0 } -- Add channel to default player data
DefaultData[#DefaultData + 1] = { "targetChannels", { [0] = true } } -- Add targetChannels to default player data

function VoiceProperty.channel(src, data) -- Set voice channel
	if data >= 0 then
		VoiceData[src].channel = data

		NetworkSetVoiceChannel(data)
	end
end

function VoiceProperty.targetChannels(src, data) -- Set voice channel
	if data ~= nil then
		VoiceData[src].targetChannels = data

		MumbleClearVoiceTargetChannels(VoiceData[src].target)

		for channel, _ in pairs(data) do
			MumbleAddVoiceTargetChannel(VoiceData[src].target, channel)
		end
	end
end

function SetChannels(src, pos)
	if not VoiceData[src] then -- Init player if data doesn't exist
		VoiceData[src] = GetDefaultData()
	end

	local currentChannel = GetCurrentChunk(pos)
	local nearbyChannels = GetNearbyChunks(pos)
	local targetChannels = {}
	local previousChannels = {}

	local currentPlayerVoiceTarget = GetVoiceProperty("target", src)
	local currentPlayerChannel = GetVoiceProperty("channel", src)
	local currentPlayerTargetChannels = GetVoiceProperty("targetChannels", src)

	local targetChannelsChanged = false

	for i = 1, #nearbyChannels do
		local channel = nearbyChannels[i].id
		if channel ~= currentChannel then
			targetChannels[channel] = true

			if currentPlayerTargetChannels[channel] then
				previousChannels[channel] = true
			else
				targetChannelsChanged = true
			end
		end
	end

	if not targetChannelsChanged then
		for channel, exists in pairs(currentPlayerTargetChannels) do
			if exists and not previousChannels[channel] then
				targetChannelsChanged = true
				break
			end
		end
	end

	if currentPlayerChannel ~= currentChannel then
		SetVoiceProperty("channel", src, currentChannel)
	end

	if targetChannelsChanged then
		SetVoiceProperty("targetChannels", src, targetChannels)
	end
end

AddEventHandler(config.eventPrefix .. ":initialise", function(src)
	Citizen.CreateThread(function()
		local src = src

		while true do
			Citizen.Wait(config.channelInterval)
			local ped = PlayerPedId()
			local pos = GetEntityCoords(ped)
			SetChannels(src, pos)
		end
	end)
end)