local playerServerId = GetPlayerServerId(PlayerId())

-- Functions
function SetVoiceData(key, value)
	TriggerServerEvent("mumble:SetVoiceData", key, value)
end

-- Events
RegisterNetEvent("mumble:SetVoiceData")
AddEventHandler("mumble:SetVoiceData", function(voice, radio, call)
	voiceData = voice

	if radio then
		radioData = radio
	end

	if call then
		callData = call
	end
end)

RegisterNetEvent("mumble:RadioSound")
AddEventHandler("mumble:RadioSound", function(snd, channel)
	if channel <= mumbleConfig.radioClickMaxChannel then
		if mumbleConfig.micClicks then
			if (snd and mumbleConfig.micClickOn) or (not snd and mumbleConfig.micClickOff) then
				SendNUIMessage({ sound = (snd and "audio_on" or "audio_off"), volume = mumbleConfig.micClickVolume })
			end
		end
	end
end)
AddEventHandler("onClientMapStart", function()
	NetworkSetTalkerProximity(1.0)
end)

AddEventHandler("onClientResourceStart", function(resName)
	if GetCurrentResourceName() ~= resName then
		return
	end

	NetworkSetTalkerProximity(0.0)

	TriggerServerEvent("mumble:Initialise")

	DebugMsg("Initialising")
end)

-- Simulate PTT when radio is active
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerData = voiceData[playerServerId]
		local playerMode = 2
		local playerRadio = 0
		local playerRadioActive = false
		local playerCall = 0
		local playerCallSpeaker = false

		if playerData ~= nil then
			playerMode = playerData.mode or 2
			playerRadio = playerData.radio or 0
			playerRadioActive = playerData.radioActive or false
			playerCall = playerData.call or 0
			playerCallSpeaker = playerData.callSpeaker or false
		end

		if playerRadioActive then -- Force PTT enabled
			SetControlNormal(0, 249, 1.0)
			SetControlNormal(1, 249, 1.0)
			SetControlNormal(2, 249, 1.0)
		end

		if IsControlJustPressed(0, mumbleConfig.controls.proximity.key) then
			if mumbleConfig.controls.speaker.key == mumbleConfig.controls.proximity.key and not ((mumbleConfig.controls.speaker.secondary == nil) and true or IsControlPressed(0, mumbleConfig.controls.speaker.secondary)) then
				local voiceMode = playerMode
			
				local newMode = voiceMode + 1
			
				if newMode > #mumbleConfig.voiceModes then
					voiceMode = 1
				else
					voiceMode = newMode
				end
			
				SetVoiceData("mode", voiceMode)
			end
		end

		if mumbleConfig.radioEnabled then
			if not mumbleConfig.controls.radio.pressed then
				if IsControlJustPressed(0, mumbleConfig.controls.radio.key) then
					if playerRadio > 0 then
						SetVoiceData("radioActive", true)
						playerData.radioActive = true
						mumbleConfig.controls.radio.pressed = true

						Citizen.CreateThread(function()
							while IsControlPressed(0, mumbleConfig.controls.radio.key) do
								Citizen.Wait(0)
							end

							SetVoiceData("radioActive", false)
							playerData.radioActive = false
							mumbleConfig.controls.radio.pressed = false
						end)
					end
				end
			end
		else
			if playerRadioActive then
				SetVoiceData("radioActive", false)
				playerData.radioActive = false
			end
		end

		if mumbleConfig.radioSpeakerEnabled then
			if ((mumbleConfig.controls.speaker.secondary == nil) and true or IsControlPressed(0, mumbleConfig.controls.speaker.secondary)) then
				if IsControlJustPressed(0, mumbleConfig.controls.speaker.key) then
					if playerCall > 0 then
						SetVoiceData("callSpeaker", not playerCallSpeaker)
					end
				end
			end
		end
	end
end)

-- UI
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(200)
		local playerId = PlayerId()
		local playerData = voiceData[playerServerId]
		local playerTalking = NetworkIsPlayerTalking(playerId)
		local playerMode = 2
		local playerRadio = 0
		local playerRadioActive = false
		local playerCall = 0
		local playerCallSpeaker = false

		if playerData ~= nil then
			playerMode = playerData.mode or 2
			playerRadio = playerData.radio or 0
			playerRadioActive = playerData.radioActive or false
			playerCall = playerData.call or 0
			playerCallSpeaker = playerData.callSpeaker or false
		end

		-- Update UI
		SendNUIMessage({
			talking = playerTalking,
			mode = mumbleConfig.voiceModes[playerMode][2],
			radio = mumbleConfig.radioChannelNames[playerRadio] ~= nil and mumbleConfig.radioChannelNames[playerRadio] or playerRadio,
			radioActive = playerRadioActive,
			call = playerCall,
			speaker = playerCallSpeaker,
		})
	end
end)

-- Main thread
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(500)

		local playerId = PlayerId()
		local playerPed = PlayerPedId()
		local playerPos = GetPedBoneCoords(playerPed, headBone)
		local playerList = GetActivePlayers()
		local playerData = voiceData[playerServerId]
		local playerMode = 2
		local playerRadio = 0
		local playerCall = 0

		if playerData ~= nil then
			playerMode = playerData.mode or 2
			playerRadio = playerData.radio or 0
			playerCall = playerData.call or 0
		end

		local voiceList = {}
		local muteList = {}
		local callList = {}
		local radioList = {}

		-- Check if a player is close to the source voice mode distance, if close send voice
		for i = 1, #playerList do -- Proximity based voice (probably won't work for infinity?)
			local remotePlayerId = playerList[i]

			if playerId ~= remotePlayerId then
				local remotePlayerServerId = GetPlayerServerId(remotePlayerId)
				local remotePlayerPed = GetPlayerPed(remotePlayerId)
				local remotePlayerPos = GetPedBoneCoords(remotePlayerPed, headBone)
				local remotePlayerData = voiceData[remotePlayerServerId]

				local distance = #(playerPos - remotePlayerPos)
				local mode = 2
				local radio = 0
				local radioActive = false
				local call = 0
				local callSpeaker = false

				if remotePlayerData ~= nil then
					mode = remotePlayerData.mode or 2
					radio = remotePlayerData.radio or 0
					radioActive = remotePlayerData.radioActive or false
					call = remotePlayerData.call or 0
					callSpeaker = remotePlayerData.callSpeaker or false
				end

				local inRange = false

				if mumbleConfig.use3dAudio then
					inRange = distance < mumbleConfig.voiceModes[playerMode][1]
				else
					inRange = distance < mumbleConfig.voiceModes[mode][1]
				end

				-- Check if player is in range
				if inRange then
					local idx = #voiceList + 1

					voiceList[idx] = {
						id = remotePlayerServerId,
						player = remotePlayerId,
					}

					if not mumbleConfig.use3dAudio then
						local volume = 1.0 - (distance / mumbleConfig.voiceModes[mode][1])^0.5

						if volume < 0 then
							volume = 0.0
						end

						voiceList[idx].volume = volume
					end

					if distance < mumbleConfig.speakerRange then
						local volume = 1.0 - (distance / mumbleConfig.speakerRange)^0.5

						if mumbleConfig.callSpeakerEnabled then
							if call > 0 then -- Collect all players in the phone call
								if callSpeaker then
									local callParticipants = callData[call]
									if callParticipants ~= nil then
										for id, _ in pairs(callParticipants) do
											if id ~= remotePlayerServerId then
												callList[id] = volume
											end
										end
									end
								end
							end
						end
						
						if mumbleConfig.radioSpeakerEnabled then
							if radio > 0 then -- Collect all players in the radio channel
								local radioParticipants = radioData[radio]
								if radioParticipants then
									for id, _ in pairs(radioParticipants) do
										if id ~= remotePlayerServerId then
											radioList[id] = volume
										end
									end
								end
							end
						end
					end
				else
					muteList[#muteList + 1] = {
						id = remotePlayerServerId,
						player = remotePlayerId,
						volume = mumbleConfig.use3dAudio and -1.0 or 0.0,
						radio = radio,
						radioActive = radioActive,
						distance = distance,
						call = call,
					}					
				end
			end
		end
		
		if mumbleConfig.use3dAudio then
			MumbleClearVoiceTarget(0)

			for j = 1, #voiceList do
				MumbleSetVolumeOverride(voiceList[j].player, -1.0) -- Re-enable 3d audio
				MumbleAddVoiceTargetPlayer(2, voiceList[j].player) -- Broadcast voice to player if they are in my voice range
			end

			MumbleSetVoiceTarget(0)
		else
			for j = 1, #voiceList do
				MumbleSetVolumeOverride(voiceList[j].player, voiceList[j].volume)
			end
		end
		
		for j = 1, #muteList do
			if callList[muteList[j].id] ~= nil then
				if callList[muteList[j].id] > muteList[j].volume then
					muteList[j].volume = callList[muteList[j].id]
				end
			end

			if radioList[muteList[j].id] ~= nil then
				if muteList[j].radioActive then
					if radioList[muteList[j].id] > muteList[j].volume then
						muteList[j].volume = radioList[muteList[j].id]
					end
				end
			end

			if muteList[j].radio > 0 and muteList[j].radio == playerRadio and muteList[j].radioActive then
				muteList[j].volume = 1.0
			end

			if muteList[j].call > 0 and muteList[j].call == playerCall then
				muteList[j].volume = 1.2
			end

			MumbleSetVolumeOverride(muteList[j].player, muteList[j].volume) -- Set player volume
		end
	end
end)

-- Exports
function SetRadioChannel(channel)
	local channel = tonumber(channel)

	if channel ~= nil then
		SetVoiceData("radio", channel)
	end
end

function SetCallChannel(channel)
	local channel = tonumber(channel)

	if channel ~= nil then
		SetVoiceData("call", channel)
	end
end

exports("SetRadioChannel", SetRadioChannel)
exports("addPlayerToRadio", SetRadioChannel)
exports("removePlayerFromRadio", function()
	SetRadioChannel(0)
end)

exports("SetCallChannel", SetCallChannel)
exports("addPlayerToCall", SetCallChannel)
exports("removePlayerFromCall", function()
	SetCallChannel(0)
end)