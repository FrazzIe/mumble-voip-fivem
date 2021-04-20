DefaultData[#DefaultData + 1] = { "proximity", 1 } -- Add proximity to default player data

function VoiceProperty.proximity(src, data) -- Set voice proximity
	local proximityMode = config.proximity[data]
	if proximityMode ~= nil then
		VoiceData[src].proximity = data

		MumbleSetAudioInputDistance(proximityMode.input + 0.0)
		MumbleSetAudioOutputDistance(proximityMode.output + 0.0)

		LogMessage(("Change voice proximity to %s (%s) [input: %s, output: %s]"):format(data, proximityMode.name, proximityMode.input, proximityMode.output))
	end
end

RegisterCommand("+mumble_proximity", function(src, args, raw)
	local src = GetPlayerServerId(PlayerId())
	local proximity = GetVoiceProperty("proximity", src)

	if proximity ~= nil then
		proximity = proximity + 1

		if proximity > #config.proximity then
			proximity = 1
		end

		SetVoiceProperty("proximity", src, proximity)
	end
end)

RegisterCommand("-mumble_proximity", function() end)
RegisterKeyMapping("+mumble_proximity", "Cycle Proximity", config.controls.proximity.mapper, config.controls.proximity.param)