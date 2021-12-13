UnmutedData = {}

function Unmute(serverId)
	if UnmutedData[serverId] then
		return
	end

	UnmutedData[serverId] = true
	MumbleSetVolumeOverrideByServerId(serverId, 1.0)

	LogMessage("INFO", ("Unmuting [%s]"):format(serverId))
end

function Mute(serverId, targetType)
	if not UnmutedData[serverId] then
		return
	end

	if targetType then
		for i = 1, #TargetTypes do
			local type = TargetTypes[i]
			if targetType ~= type.id and type.preventMute then
				local typeData = GetVoiceProperty(type, src)

				if typeData then
					if typeData[serverId] then
						local data = GetVoiceProperty(type.preventMute, serverId)

						if data == nil or data then
							return LogMessage("INFO", ("Failed muting [%s] (type: %s, prevent: %s, result: %s)"):format(serverId, type.id, type.preventMute, data))
						end
					end
				end
			end
		end
	end

	UnmutedData[serverId] = nil
	MumbleSetVolumeOverrideByServerId(serverId, -1.0)

	LogMessage("INFO", ("Muting [%s]"):format(serverId))
end