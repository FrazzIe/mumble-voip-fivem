local playerServerId = GetPlayerServerId(PlayerId())
local unmutedPlayers = {}
local radioTargets = {}
local callTargets = {}
local playerChunk = nil
local voiceTarget = 2

-- Functions
function SetVoiceData(key, value)
	TriggerServerEvent("mumble:SetVoiceData", key, value)
end

function PlayMicClick(channel, value)
	if channel <= mumbleConfig.radioClickMaxChannel then
		if mumbleConfig.micClicks then
			if (value and mumbleConfig.micClickOn) or (not value and mumbleConfig.micClickOff) then
				SendNUIMessage({ sound = (value and "audio_on" or "audio_off"), volume = mumbleConfig.micClickVolume })
			end
		end
	end
end

function SetGridTargets(pos) -- Used to set the players voice targets depending on where they are in the map
	local currentChunk = GetCurrentChunk(pos)

	if playerChunk ~= currentChunk then
		local nearbyChunks = GetNearbyChunks(pos)
		local nearbyChunksStr = "None"

		MumbleClearVoiceTargetChannels(voiceTarget)
		MumbleAddVoiceTargetChannel(voiceTarget, currentChunk)

		for i = 1, #nearbyChunks do
			if nearbyChunks[i] ~= currentChunk then
				MumbleAddVoiceTargetChannel(voiceTarget, nearbyChunks[i])

				if nearbyChunksStr ~= "None" then
					nearbyChunksStr = nearbyChunksStr .. ", " .. nearbyChunks[i]
				else
					nearbyChunksStr = nearbyChunks[i]
				end
			end
		end

		NetworkSetVoiceChannel(currentChunk)

		playerChunk = currentChunk

		DebugMsg("Entered Chunk: " .. currentChunk .. ", Nearby Chunks: " .. nearbyChunksStr)
	end
end

function SetPlayerTargets(...)
	local targets = { ... }
	local targetList = ""

	MumbleClearVoiceTargetPlayers(voiceTarget)

	for i = 1, #targets do
		for id, _ in pairs(targets[i]) do
			MumbleAddVoiceTargetPlayerByServerId(voiceTarget, id)

			if targetList == "" then
				targetList = targetList .. id
			else
				targetList = targetList .. ", " .. id
			end
		end
	end

	if targetList ~= "" then
		DebugMsg("Sending voice to Player " .. targetList)
	else
		DebugMsg("Sending voice to Nobody")
	end
end

function TogglePlayerVoice(serverId, value)
	DebugMsg((value and "Unmuting" or "Muting") .. " Player " .. serverId)
	if value then
		if not unmutedPlayers[serverId] then
			unmutedPlayers[serverId] = true
			MumbleSetVolumeOverrideByServerId(serverId, 1.0)
		end
	else
		if unmutedPlayers[serverId] then
			unmutedPlayers[serverId] = nil
			MumbleSetVolumeOverrideByServerId(serverId, -1.0)			
		end		
	end
end

function SetRadioChannel(channel)
	local channel = tonumber(channel)

	if channel ~= nil then
		SetVoiceData("radio", channel)

		if radioData[channel] then -- Check if anyone is talking and unmute if so
			for id, _ in pairs(radioData[channel]) do
				if id ~= playerServerId then					
					if not unmutedPlayers[id] then
						local playerData = voiceData[id]

						if playerData ~= nil then
							if playerData.radioActive then
								TogglePlayerVoice(player, true)
							end
						end
					end
				end
			end
		end
	end
end

function SetCallChannel(channel)
	local channel = tonumber(channel)

	if channel ~= nil then
		SetVoiceData("call", channel)

		if callData[channel] then -- Unmute current call participants
			for id, _ in pairs(callData[channel]) do
				if id ~= playerServerId then
					if not unmutedPlayers[id] then
						TogglePlayerVoice(id, true)
					end
				end
			end
		end
	end
end

function CheckVoiceSetting(varName, msg)
	local setting = GetConvarInt(varName, -1)

	if setting == 0 then
		SendNUIMessage({ warningId = varName, warningMsg = msg })

		Citizen.CreateThread(function()
			local varName = varName
			while GetConvarInt(varName, -1) == 0 do
				Citizen.Wait(1000)
			end

			SendNUIMessage({ warningId = varName })
		end)
	end

	DebugMsg("Checking setting: " .. varName .. " = " .. setting)
end

function CompareChannels(playerData, player, type, channel, ignoreId)
	local match = false

	if ignoreId and true or (player ~= playerServerId) then
		if playerData[type] ~= nil then
			if playerData[type] == channel then
				match = true
			end
		end
	end

	return match
end

-- Events
AddEventHandler("onClientResourceStart", function(resName) -- Initialises the script, sets up voice range, voice targets and request sync with server
	if GetCurrentResourceName() ~= resName then
		return
	end

	NetworkSetTalkerProximity(mumbleConfig.voiceModes[2][1] + 0.0)

	MumbleClearVoiceTarget(voiceTarget) -- Reset voice target
	MumbleSetVoiceTarget(voiceTarget)
	SetGridTargets(GetEntityCoords(PlayerPedId())) -- Add voice targets

	TriggerServerEvent("mumble:Initialise")

	DebugMsg("Initialising")
	
	Citizen.Wait(1000)

	SendNUIMessage({ speakerOption = mumbleConfig.callSpeakerEnabled })

	CheckVoiceSetting("profile_voiceEnable", "Voice chat disabled")
	CheckVoiceSetting("profile_voiceTalkEnabled", "Microphone disabled")
end)

RegisterNetEvent("mumble:SetVoiceData") -- Used to sync players data each time something changes
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
	local playerData = voiceData[playerServerId]

	if not playerData then
		playerData  = {
			mode = 2,
			radio = 0,
			radioActive = false,
			call = 0,
			callSpeaker = false,
		}
	end

	if key == "radio" and radioChannel ~= value then -- Check if channel has changed
		if radioChannel > 0 then -- Check if player was in a radio channel
			if radioData[radioChannel] then  -- Remove player from radio channel
				if radioData[radioChannel][player] then
					DebugMsg("Player " .. player .. " was removed from radio channel " .. radioChannel)
					radioData[radioChannel][player] = nil

					if CompareChannels(playerData, player, "radio", radioChannel) then
						TogglePlayerVoice(player, false) -- mute player on radio channel leave

						if radioTargets[player] then
							radioTargets[player] = nil									
							-- Maybe clear player targets here? might cut the audio for other people on the radio until the func is complete?
						end
					end
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

			if CompareChannels(playerData, player, "radio", value) then
				if not radioTargets[player] then
					radioTargets[player] = true							
					
					if playerData.radioActive then -- Send voice to newly joined player if we are currently talking
						MumbleAddVoiceTargetPlayerByServerId(voiceTarget, player)
					end
				end
			elseif playerServerId == player then
				for id, _ in pairs(radioData[value]) do
					if id ~= playerServerId then
						if not radioTargets[id] then
							radioTargets[id] = true
						end
					end
				end
			end
		end
	elseif key == "call" and callChannel ~= value then
		if callChannel > 0 then -- Check if player was in a call channel
			if callData[callChannel] then  -- Remove player from call channel
				if callData[callChannel][player] then
					DebugMsg("Player " .. player .. " was removed from call channel " .. callChannel)
					callData[callChannel][player] = nil

					if CompareChannels(playerData, player, "call", callChannel) then
						TogglePlayerVoice(player, false) -- mute player on call channel leave

						if callTargets[player] then
							callTargets[player] = nil
							SetPlayerTargets(callTargets, playerData.radioActive and radioTargets or nil)
						end
					end
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

			if CompareChannels(playerData, player, "call", value) then
				TogglePlayerVoice(player, value)

				if not callTargets[player] then
					callTargets[player] = true
					MumbleAddVoiceTargetPlayerByServerId(voiceTarget, player) -- Send voice to player who just joined call
				end
			elseif playerServerId == player then
				for id, _ in pairs(callData[value]) do
					if id ~= playerServerId then
						if not unmutedPlayers[id] then
							TogglePlayerVoice(id, true)
						end

						if not callTargets[id] then
							callTargets[id] = true
							MumbleAddVoiceTargetPlayerByServerId(voiceTarget, id) -- Send voice to call participant
						end
					end
				end
			end			
		end
	elseif key == "radioActive" and radioActive ~= value then
		DebugMsg("Player " .. player .. " radio talking state was changed from: " .. tostring(radioActive):upper() .. " to: " .. tostring(value):upper())
		if radioChannel > 0 then
			if CompareChannels(playerData, player, "radio", radioChannel) then -- Check if player is in the same radio channel as you
				TogglePlayerVoice(player, value) -- unmute/mute player
				PlayMicClick(radioChannel, value) -- play on/off clicks
			end
		end
	end

	voiceData[player][key] = value

	DebugMsg("Player " .. player .. " changed " .. key .. " to: " .. tostring(value))
end)

RegisterNetEvent("mumble:SyncVoiceData") -- Used to sync players data on initialising
AddEventHandler("mumble:SyncVoiceData", function(voice, radio, call)
	voiceData = voice
	radioData = radio
	callData = call
end)

RegisterNetEvent("mumble:RemoveVoiceData") -- Used to remove redundant data when a player disconnects
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
				
				NetworkSetTalkerProximity(mumbleConfig.voiceModes[voiceMode][1])

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
						SetPlayerTargets(callTargets, radioTargets) -- Send voice to everyone in the radio and call
						PlayMicClick(playerRadio, true)
						mumbleConfig.controls.radio.pressed = true

						Citizen.CreateThread(function()
							while IsControlPressed(0, mumbleConfig.controls.radio.key) do
								Citizen.Wait(0)
							end

							SetVoiceData("radioActive", false)
							SetPlayerTargets(callTargets) -- Stop sending voice to everyone in the radio
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

-- Manage Grid Target Channels
Citizen.CreateThread(function()
	while true do
		local playerPed = PlayerPedId()
		local playerCoords = GetEntityCoords(playerPed)

		SetGridTargets(playerCoords)

		Citizen.Wait(2500)
	end
end)

-- Exports
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