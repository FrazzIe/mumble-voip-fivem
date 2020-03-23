local voiceData = {}
local radioData = {}
local callData = {}
local voiceModes = {
	{2.5, "Whisper"},
	{8, "Normal"},
	{20, "Shouting"},
}
local speakerRange = 1.5
local playerServerId = GetPlayerServerId(PlayerId())

function SetVoiceData(key, value)
	TriggerServerEvent("mumble:SetVoiceData", key, value)
end

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
AddEventHandler("mumble:RadioSound", function(snd)
	SendNUIMessage({ sound = (snd and "audio_on" or "audio_off"), volume = 0.1 })
end)

RegisterCommand("+voiceMode", function()
	local playerData = voiceData[playerServerId]
	local voiceMode = 2

	if playerData then
		voiceMode = playerData.mode
	end

	local newMode = voiceMode + 1

	if newMode > #voiceModes then
		voiceMode = 1
	else
		voiceMode = newMode
	end

	SetVoiceData("mode", voiceMode)
end)

RegisterCommand("-voiceMode", function()
	
end)

RegisterCommand("+radio", function()
	if exports["rp-radio"]:CanRadioBeUsed() then
		local playerData = voiceData[playerServerId]


		if playerData then
			if playerData.radio ~= nil then
				if playerData.radio > 0 then
					SetVoiceData("radioActive", true)
				end
			end
		end
	end
end)

RegisterCommand("-radio", function()
	local playerData = voiceData[playerServerId]


	if playerData then
		if playerData.radio ~= nil then
			if playerData.radio > 0 then
				if playerData.radioActive then
					SetVoiceData("radioActive", false)
				end
			end
		end
	end
end)

RegisterCommand("+speaker", function()
	local playerData = voiceData[playerServerId]

	if playerData then
		if playerData.radio ~= nil then
			if playerData.call > 0 then
				SetVoiceData("callSpeaker", not playerData.callSpeaker)
			end
		end
	end
end)

RegisterCommand("-speaker", function()

end)

RegisterKeyMapping("+voiceMode", "Change voice distance", "keyboard", "f3")
RegisterKeyMapping("+radio", "Talk on the radio", "keyboard", "capital")
RegisterKeyMapping("+speaker", "Toggle speaker mode", "keyboard", "f4")

AddEventHandler("onClientResourceStart", function (resourceName)
	if GetCurrentResourceName() ~= resourceName then
		return
	end

	TriggerServerEvent("mumble:Initialise")
end)

Citizen.CreateThread(function()
	local talkingAnim = { "mic_chatter", "mp_facial" }
	local normalAnim = { "mood_normal_1", "facials@gen_male@base" }

	RequestAnimDict(talkingAnim[3])

	while not HasAnimDictLoaded(talkingAnim[2]) do
		Citizen.Wait(150)
	end

	RequestAnimDict(normalAnim[2])

	while not HasAnimDictLoaded(normalAnim[2]) do
		Citizen.Wait(150)
	end

	while true do
		Citizen.Wait(0)
		local playerId = PlayerId()
		local playerPed = PlayerPedId()
		local playerHeading = math.rad(GetGameplayCamRot().z % 360)
		local playerPos = GetPedBoneCoords(playerPed, headBone)
		local playerList = GetActivePlayers()
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

		SendNUIMessage({
			talking = playerTalking,
			mode = voiceModes[playerMode][2],
			radio = playerRadio,
			radioActive = playerRadioActive,
			call = playerCall,
			speaker = playerCallSpeaker,
		})

		if playerRadioActive then -- Force PTT enabled
			SetControlNormal(0, 249, 1.0)
			SetControlNormal(1, 249, 1.0)
			SetControlNormal(2, 249, 1.0)
		end

		local voiceList = {}
		local muteList = {}
		local callList = {}
		local radioList = {}

		for i = 1, #playerList do -- Proximity based voice (probably won't work for infinity? near a grid border?)
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

				-- Mouth animations
				local remotePlayerTalking = NetworkIsPlayerTalking(remotePlayerId)

				if remotePlayerTalking then
					PlayFacialAnim(remotePlayerPed, talkingAnim[1], talkingAnim[2])
				else
					PlayFacialAnim(remotePlayerPed, normalAnim[1], normalAnim[2])
				end

				-- Check if player is in range
				if distance < voiceModes[mode][1] then
					local volume = 1.0 - (distance / voiceModes[mode][1])^0.5

					if volume < 0 then
						volume = 0.0
					end

					voiceList[#voiceList + 1] = {
						id = remotePlayerServerId,
						player = remotePlayerId,
						volume = volume,
					}

					if call > 0 then -- Collect all players in the phone call
						if callSpeaker then
							local callParticipants = callData[call]
							if callParticipants ~= nil then
								for id, _ in pairs(callParticipants) do
									if id ~= remotePlayerServerId then
										callList[id] = true
									end
								end
							end
						end
					end

					if radio > 0 then -- Collect all players in the radio channel
						local radioParticipants = radioData[radio]
						if radioParticipants then
							for id, _ in pairs(radioParticipants) do
								if id ~= remotePlayerServerId then
									radioList[id] = true
								end
							end
						end
					end
				else
					muteList[#muteList + 1] = {
						id = remotePlayerServerId,
						player = remotePlayerId,
						volume = 0.0,
						radio = radio,
						radioActive = radioActive,
						distance = distance,
						call = call,
					}					
				end

				for j = 1, #voiceList do
					MumbleSetVolumeOverride(voiceList[j].player, voiceList[j].volume)
				end

				for j = 1, #muteList do
					if callList[muteList[j].id] or radioList[muteList[j].id] then
						if distance < speakerRange then
							muteList[j].volume = 1.0 - (muteList[j].distance / speakerRange)^0.5
						end
					end

					if muteList[j].radio > 0 and muteList[j].radio == playerRadio and muteList[j].radioActive then
						muteList[j].volume = 1.0
					end

					if muteList[j].call > 0 and muteList[j].call == playerCall then
						muteList[j].volume = 1.2
					end
					
					MumbleSetVolumeOverride(muteList[j].player, muteList[j].volume)
				end
			end
		end
	end
end)

exports("SetRadio", function(channel)
	SetVoiceData("radio", channel)
end)

exports("SetCall", function(channel)
	local channel = tonumber(channel)

	if channel ~= nil then
		SetVoiceData("call", channel)
	end
end)

-- TokoVOIP legacy exports
exports("addPlayerToRadio", function(channel)
	local channel = tonumber(channel)

	if channel ~= nil then
		SetVoiceData("radio", channel)
	end
end)

exports("removePlayerFromRadio", function(channel)
	SetVoiceData("radio", 0)
end)

exports("addPlayerToCall", function(channel)
	local channel = tonumber(channel)

	if channel ~= nil then
		SetVoiceData("call", channel)
	end
end)

exports("removePlayerFromCall", function()
	SetVoiceData("call", 0)
end)