DefaultData[#DefaultData + 1] = { "proximity", 1 } -- Add proximity to default player data

function VoiceProperty.proximity(src, data) -- Set voice proximity
	if config.proximity[data] ~= nil then
		VoiceData[src].proximity = data
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

		SetVoiceProperty("proximity", src, proximity, true)

		MumbleSetAudioInputDistance(config.proximity[proximity].input + 0.0)
		MumbleSetAudioOutputDistance(config.proximity[proximity].output + 0.0)

		LogMessage(("Change voice proximity to %s (%s) [input: %s, output: %s]"):format(proximity, config.proximity[proximity].name, config.proximity[proximity].input, config.proximity[proximity].output))
	end
end)

RegisterCommand("-mumble_proximity", function() end)
RegisterKeyMapping("+mumble_proximity", "Cycle Proximity", config.controls.proximity.mapper, config.controls.proximity.param)