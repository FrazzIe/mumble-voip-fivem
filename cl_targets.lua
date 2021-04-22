DefaultData[#DefaultData + 1] = { "target", 2 } -- Add target to default player data
DefaultData[#DefaultData + 1] = { "targets", {} } -- Add targets to default player data
TargetTypes = {}

function VoiceProperty.target(src, data) -- Set mumble voice target
	if data >= 0 and data <= 30 then
		VoiceData[src].target = data

		MumbleSetVoiceTarget(data)
	end
end

function VoiceProperty.targets(src, data)
	if data ~= nil then
		VoiceData[src].targets = data

		MumbleClearVoiceTargetPlayers(VoiceData[src].target)

		for serverId, _ in pairs(data) do
			MumbleAddVoiceTargetPlayerByServerId(VoiceData[src].target, serverId)
		end
	end
end

function AddTarget(src, targetId)
	local targets = GetVoiceProperty("targets", src)
	local voiceTarget = GetVoiceProperty("target", src)

	if not targets[targetId] then
		targets[targetId] = true

		MumbleAddVoiceTargetPlayerByServerId(voiceTarget, targetId)
	end
end

function RemoveTarget(src, targetId)
	local targets = GetVoiceProperty("targets", src)

	if targets[targetId] then
		local canRemove = true

		for type, _ in pairs(TargetTypes) do
			local typeData = GetVoiceProperty(type, src)

			if typeData then
				if typeData[targetId] then
					canRemove = false
					break
				end
			end
		end

		if canRemove then
			targets[targetId] = nil
			SetVoiceProperty("targets", src, targets)
		end
	end
end

AddEventHandler(config.eventPrefix .. ":initialise", function(src)
	SetVoiceProperty("target", src, GetVoiceProperty("target", src))
end)