DefaultData[#DefaultData + 1] = { "radio", 0 } -- Add radio to default player data
DefaultData[#DefaultData + 1] = { "radioTargets", {} } -- Add targets to default player data
DefaultData[#DefaultData + 1] = { "radioActive", false } -- Add radioActive to default player data
TargetTypes[#TargetTypes + 1] = { -- Add radioTargets to target types
	id = "radioTargets",
	preventMute = "radioActive",
}
RadioData = {}

function VoiceProperty.radio(src, data)
	if data >= 0 then
		local isClient = ClientServerId == src
		local clientRadio = GetVoiceProperty("radio", ClientServerId)
		local clientRadioTargets = GetVoiceProperty("radioTargets", ClientServerId)
		local previousChannel = VoiceData[src].radio
		local newChannel = data

		VoiceData[src].radio = data

		if previousChannel > 0 then -- Remove from channel
			if RadioData[previousChannel] then
				if RadioData[previousChannel][src] then
					RadioData[previousChannel][src] = nil

					if not isClient then -- Remove from client targets (random player left radio)
						if previousChannel == clientRadio then
							if clientRadioTargets[src] then
								clientRadioTargets[src] = nil
								RemoveTarget(ClientServerId, src)
							end
						end
					else -- Remove all client targets (client left radio)
						SetVoiceProperty("radioTargets", ClientServerId, {})
						RemoveTarget(ClientServerId, clientRadioTargets)
					end
				end
			end
		end

		if data > 0 then -- Add to channel
			if not RadioData[newChannel] then
				RadioData[newChannel] = {}
			end

			if not isClient then -- Add new player to client targets (random player joined our radio)
				if data == clientRadio then
					if not clientRadioTargets[src] then
						clientRadioTargets[src] = true
						AddTarget(ClientServerId, src)
					end
				end
			else -- Add players to client targets (client joined radio)
				for serverId, _ in pairs(RadioData[newChannel]) do
					if not clientRadioTargets[src] then
						clientRadioTargets[src] = true
						AddTarget(src, serverId)
					end
				end
			end

			RadioData[newChannel][src] = true
		end
	end
end

function VoiceProperty.radioTargets(src, data)
	if data ~= nil then
		VoiceData[src].radioTargets = data
	end
end

function VoiceProperty.radioActive(src, data)
	if data ~= nil then
		local isClient = ClientServerId == src

		if not isClient then
			local clientRadio = GetVoiceProperty("radio", ClientServerId)
			local channel = VoiceData[src].radio

			if channel > 0 and channel == clientRadio then
				-- Play sound
				-- Unmute player
			end
		end
		VoiceData[src].radioActive = data
	end
end

function ForceTalking()
	while true do
		local isTalking = GetVoiceProperty("radioActive", ClientServerId)

		if isTalking then
			SetControlNormal(0, 249, 1.0)
			SetControlNormal(1, 249, 1.0)
			SetControlNormal(2, 249, 1.0)
		end

		Citizen.Wait(0)
	end
end

AddEventHandler(config.eventPrefix .. ":initialise", function(src)
	Citizen.CreateThread(ForceTalking)
	SetVoiceProperty("radio", src, 1)
end)

RegisterCommand("+mumble_radio", function(src, args, raw)
	local src = ClientServerId
	local channel = GetVoiceProperty("radio", src)

	if channel > 0 then
		SetVoiceProperty("radioActive", src, true, true)
	end
end)

RegisterCommand("-mumble_radio", function(src, args, raw)
	local src = ClientServerId
	local channel = GetVoiceProperty("radio", src)

	if channel > 0 then
		SetVoiceProperty("radioActive", src, false, true)
	end
end)

RegisterKeyMapping("+mumble_radio", config.controls.radio.description, config.controls.radio.mapper, config.controls.radio.param)