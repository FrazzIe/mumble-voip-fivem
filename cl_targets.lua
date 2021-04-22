DefaultData[#DefaultData + 1] = { "target", 2 } -- Add target to default player data

function VoiceProperty.target(src, data) -- Set mumble voice target
	if data >= 0 and data <= 30 then
		VoiceData[src].target = data

		MumbleSetVoiceTarget(data)
	end
end

AddEventHandler(config.eventPrefix .. ":initialise", function(src)
	SetVoiceProperty("target", src, GetVoiceProperty("target", src))
end)