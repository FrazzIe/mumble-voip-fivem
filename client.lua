local voiceData = {}
local voiceModes = {
	{2.5, "Whisper"},
	{8, "Normal"},
	{20, "Shouting"},
}
local voiceMode = 2

-- local targetChunks = {}
-- local lastChunks = {}

RegisterCommand("+voiceMode", function()
	local newMode = voiceMode + 1

	if newMode > #voiceModes then
		voiceMode = 1
	else
		voiceMode = newMode
	end

	TriggerServerEvent("mumble:SetVoiceMode", voiceMode)
end)

RegisterCommand("-voiceMode", function()
	
end)

RegisterKeyMapping("+voiceMode", "Change voice distance", "keyboard", "x")

AddEventHandler("onClientResourceStart", function (resourceName)
	if GetCurrentResourceName() ~= resourceName then
		return
	end

	TriggerServerEvent("mumble:Initialise")
end)

RegisterNetEvent("mumble:SetVoiceData")
AddEventHandler("mumble:SetVoiceData", function(data)
	voiceData = data
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerId = PlayerId()


				--print("player:" .. remotePlayerServerId, "distance: " .. distance, "mode:" .. voiceModes[mode][1], "volume:" .. volume)



					MumbleSetVolumeOverride(remotePlayerId, volume)
				else
					MumbleSetVolumeOverride(remotePlayerId, 0.0)
				end
			end
		end
	end
end)

-- local deltas = {
--     vector2(-1, -1),
--     vector2(-1, 0),
--     vector2(-1, 1),
--     vector2(0, -1),
--     vector2(1, -1),
--     vector2(1, 0),
--     vector2(1, 1),
--     vector2(0, 1),
-- }

-- function GetGridChunk(x)
--     return math.floor((x + 8192) / 128)
-- end

-- function GetGridBase(x)
--     return (x * 128) - 8192
-- end

-- function GetChunkChannel(v)
--     return (v.x << 8) | v.y
-- end

-- loop
--neptunium
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerId = PlayerId()
		local playerPed = PlayerPedId()
		local playerHeading = math.rad(GetGameplayCamRot().z % 360)
		local playerPos = GetPedBoneCoords(playerPed, headBone)
		local playerList = GetActivePlayers()

		-- local currentChunk = vector2(GetGridChunk(playerPos.x), GetGridChunk(playerPos.y)) -- Chunk player is in
		-- local chunkChannel = GetChunkChannel(currentChunk) -- Get voice channel for chunk

		-- NetworkSetVoiceChannel(chunkChannel) -- Set voice channel

		-- targetChunks = {} -- Clear list of target chunks

		-- for i = 1, #deltas do -- Get nearby chunks
		-- 	local chunkSize = playerPos.xy + (deltas[i] * 20) -- edge size
		-- 	local chunk = vector2(GetGridChunk(chunkSize.x), GetGridChunk(chunkSize.y)) -- get nearby chunk
		-- 	local channel = GetChunkChannel(chunk) -- Get voice channel for chunk

		-- 	targetChunks[channel] = true -- add chunk to target list
		-- end
		
		-- -- super naive hash difference
		-- local different = false

		-- for channel, _ in pairs(targetChunks) do
		-- 	if not lastChunks[channel] then -- Check for any new chunks
		-- 		different = true
		-- 		break
		-- 	end
		-- end

		-- if not different then
		-- 	for channel, _ in pairs(lastChunks) do
		-- 		if not targetChunks[channel] then -- Checks for any redundant chunks
		-- 			different = true
		-- 			break
		-- 		end
		-- 	end
		-- end

		-- if different then
		-- 	-- you might want to swap between two targets when changing
		-- 	MumbleClearVoiceTarget(2) -- Clear voice targets
			
		-- 	for channel, _ in pairs(targetChunks) do
		-- 		MumbleAddVoiceTargetChannel(2, channel) -- Add chunk channels to voice target
		-- 	end
			
		-- 	MumbleSetVoiceTarget(2) -- Broadcast voice to target

		-- 	lastChunks = targetChunks -- Store chunks list
		-- end

		for i = 1, #playerList do -- Proximity based voice (probably won't work for infinity? near a grid border?)
			local remotePlayerId = playerList[i]

			if playerId ~= remotePlayerId then
				local remotePlayerServerId = GetPlayerServerId(remotePlayerId)
				local remotePlayerPed = GetPlayerPed(remotePlayerId)
				local remotePlayerPos = GetPedBoneCoords(remotePlayerPed, headBone)
				local remotePlayerData = voiceData[remotePlayerServerId]

				local distance = #(playerPos - remotePlayerPos)
				local mode = 2

				if remotePlayerData ~= nil then
					mode = remotePlayerData.mode or 2
				end

				if distance < voiceModes[mode][1] then
					local volume = 1.0 - (distance / voiceModes[mode][1])^0.5

					if volume < 0 then
						volume = 0.0
					end

					print("player:" .. remotePlayerServerId, "distance: " .. distance, "mode:" .. voiceModes[mode][1], "volume:" .. volume)

					MumbleSetVolumeOverride(remotePlayerId, volume)
				else
					MumbleSetVolumeOverride(remotePlayerId, 0.0)
				end
			end
		end
	end
end)