local playerServerId = GetPlayerServerId(PlayerId())
local mutedPlayers = {}

-- Functions
function SetVoiceData(key, value)
	TriggerServerEvent("mumble:SetVoiceData", key, value)
end

function PlayMicClick(channel, value)
	print(channel, tostring(value))
	if channel <= mumbleConfig.radioClickMaxChannel then
		if mumbleConfig.micClicks then
			if (value and mumbleConfig.micClickOn) or (not value and mumbleConfig.micClickOff) then
				SendNUIMessage({ sound = (value and "audio_on" or "audio_off"), volume = mumbleConfig.micClickVolume })
			end
		end
	end	
end

-- Events
RegisterNetEvent("mumble:SetVoiceData")
AddEventHandler("mumble:SetVoiceData", function(player, key, value)
    if not voiceData[player] then
        voiceData[player] = {
            mode = 2,
            radio = 0,
            radioActive = false,
            call = 0,
            callSpeaker = false,
        }
	end

	local radioChannel = voiceData[player]["radio"]
    local callChannel = voiceData[player]["call"]
	local radioActive = voiceData[player]["radioActive"]

    if key == "radio" and radioChannel ~= value then -- Check if channel has changed
        if radioChannel > 0 then -- Check if player was in a radio channel
            if radioData[radioChannel] then  -- Remove player from radio channel
                if radioData[radioChannel][player] then
                    DebugMsg("Player " .. player .. " was removed from radio channel " .. radioChannel)
                    radioData[radioChannel][player] = nil
                end
            end
        end

        if value > 0 then
            if not radioData[value] then -- Create channel if it does not exist
                DebugMsg("Player " .. player .. " is creating channel: " .. value)
                radioData[value] = {}
            end
            
            DebugMsg("Player " .. player .. " was added to channel: " .. value)
            radioData[value][player] = true -- Add player to channel
        end
    elseif key == "call" and callChannel ~= value then
        if callChannel > 0 then -- Check if player was in a call channel
            if callData[callChannel] then  -- Remove player from call channel
                if callData[callChannel][player] then
                    DebugMsg("Player " .. player .. " was removed from call channel " .. callChannel)
                    callData[callChannel][player] = nil
                end
            end
        end

        if value > 0 then
            if not callData[value] then -- Create call if it does not exist
                DebugMsg("Player " .. player .. " is creating call: " .. value)
                callData[value] = {}
            end
            
            DebugMsg("Player " .. player .. " was added to call: " .. value)
            callData[value][player] = true -- Add player to call
        end
    elseif key == "radioActive" and radioActive ~= value then
        DebugMsg("Player " .. player .. " radio talking state was changed from: " .. tostring(radioActive):upper() .. " to: " .. tostring(value):upper())
        if radioChannel > 0 then
			local playerData = voiceData[playerServerId]

			if playerData.radio ~= nil then
				if playerData.radio == radioChannel then -- Check if player is in the same radio channel as you
					PlayMicClick(radioChannel, value)
				end
			end
        end
    end

	voiceData[player][key] = value

    DebugMsg("Player " .. player .. " changed " .. key .. " to: " .. tostring(value))
end)

RegisterNetEvent("mumble:SyncVoiceData")
AddEventHandler("mumble:SyncVoiceData", function(voice, radio, call)
	voiceData = voice
	radioData = radio
	callData = call
end)

RegisterNetEvent("mumble:RemoveVoiceData")
AddEventHandler("mumble:RemoveVoiceData", function(player)
    if voiceData[player] then
		local radioChannel = voiceData[player]["radio"] or 0
		local callChannel = voiceData[player]["call"] or 0

        if radioChannel > 0 then -- Check if player was in a radio channel
            if radioData[radioChannel] then  -- Remove player from radio channel
                if radioData[radioChannel][player] then
                    DebugMsg("Player " .. player .. " was removed from radio channel " .. radioChannel)
                    radioData[radioChannel][player] = nil
                end
            end
        end

        if callChannel > 0 then -- Check if player was in a call channel
            if callData[callChannel] then  -- Remove player from call channel
                if callData[callChannel][player] then
                    DebugMsg("Player " .. player .. " was removed from call channel " .. callChannel)
                    callData[callChannel][player] = nil
                end
            end
        end

        voiceData[player] = nil
    end
end)

AddEventHandler("onClientMapStart", function()
	NetworkSetTalkerProximity(1.0)
end)

AddEventHandler("onClientResourceStart", function(resName)
	if GetCurrentResourceName() ~= resName then
		return
	end

	if mumbleConfig.use3dAudio then
		NetworkSetTalkerProximity(mumbleConfig.voiceModes[2][1] + 0.0)
	else
		NetworkSetTalkerProximity(0.0)
	end

	TriggerServerEvent("mumble:Initialise")

	DebugMsg("Initialising")

	SendNUIMessage({ speakerOption = mumbleConfig.callSpeakerEnabled })
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
				
				if mumbleConfig.use3dAudio then
					NetworkSetTalkerProximity(mumbleConfig.voiceModes[voiceMode][1])
				end

				SetVoiceData("mode", voiceMode)
				playerData.mode = voiceMode
			end
		end

		if mumbleConfig.radioEnabled then
			if not mumbleConfig.controls.radio.pressed then
				if IsControlJustPressed(0, mumbleConfig.controls.radio.key) then
					if playerRadio > 0 then
						SetVoiceData("radioActive", true)
						playerData.radioActive = true
						PlayMicClick(playerRadio, true)
						mumbleConfig.controls.radio.pressed = true

						Citizen.CreateThread(function()
							while IsControlPressed(0, mumbleConfig.controls.radio.key) do
								Citizen.Wait(0)
							end

							SetVoiceData("radioActive", false)
							PlayMicClick(playerRadio, false)
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
						playerData.callSpeaker = not playerCallSpeaker
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
			call = mumbleConfig.callChannelNames[playerCall] ~= nil and mumbleConfig.callChannelNames[playerCall] or playerCall,
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
				if mutedPlayers[voiceList[j].id] ~= nil then -- Only re-enable 3d audio if player was muted
					mutedPlayers[voiceList[j].id] = nil
					MumbleSetVolumeOverride(voiceList[j].player, -1.0) -- Re-enable 3d audio
				end

				MumbleAddVoiceTargetPlayer(2, voiceList[j].player) -- Broadcast voice to player if they are in my voice range
			end

			MumbleSetVoiceTarget(0)
		else
			for j = 1, #voiceList do
				if mutedPlayers[voiceList[j].id] ~= nil then
					mutedPlayers[voiceList[j].id] = nil
				end

				MumbleSetVolumeOverride(voiceList[j].player, voiceList[j].volume)
			end
		end
		
		for j = 1, #muteList do
			if mumbleConfig.callSpeakerEnabled then
				if callList[muteList[j].id] ~= nil then
					if callList[muteList[j].id] > muteList[j].volume then
						muteList[j].volume = callList[muteList[j].id]
					end
				end
			end

			if mumbleConfig.radioSpeakerEnabled then
				if radioList[muteList[j].id] ~= nil then
					if muteList[j].radioActive then
						if radioList[muteList[j].id] > muteList[j].volume then
							muteList[j].volume = radioList[muteList[j].id]
						end
					end
				end
			end

			if muteList[j].radio > 0 and muteList[j].radio == playerRadio and muteList[j].radioActive then
				muteList[j].volume = 1.0
			end

			if muteList[j].call > 0 and muteList[j].call == playerCall then
				muteList[j].volume = 1.2
			end

			if mutedPlayers[muteList[j].id] ~= muteList[j].volume then -- Only update volume if its changed
				mutedPlayers[muteList[j].id] = muteList[j].volume
				MumbleSetVolumeOverride(muteList[j].player, muteList[j].volume) -- Set player volume
			end
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