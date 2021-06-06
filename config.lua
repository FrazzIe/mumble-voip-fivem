voiceData = {}
radioData = {}
callData = {}
mumbleConfig = {
	debug = false, -- enable debug msgs
	speakerRange = 1.5, -- ระยะห่างของลำโพงในหน่วยวัดระยะทาง gta (คุณต้องอยู่ใกล้ผู้เล่นอื่นมากแค่ไหนจึงจะได้ยินผู้เล่นคนอื่นทางวิทยุหรือโทรศัพท์)
	callSpeakerEnabled = true, -- ให้ผู้เล่นได้ยินผู้เข้าร่วมการสนทนาทางโทรศัพท์ทั้งหมดหากยืนอยู่ข้างคนที่กำลังคุยโทรศัพท์
	radioEnabled = true, -- เปิดหรือปิดโดยใช้วิทยุ
	micClicks = true, -- มีการเปิดใช้งานการคลิกหรือไม่
	micClickOn = true, -- เสียงคลิกเปิดใช้งานอยู่หรือไม่
	micClickOff = true, -- เสียงคลิกปิดอยู่หรือไม่
	micClickVolume = 0.1, -- เสียงคลิกดังแค่ไหน
	radioClickMaxChannel = 200, -- ตั้งค่าจำนวนช่องวิทยุสูงสุดที่จะเปิดใช้งานการคลิกวิทยุในพื้นที่
	controls = { -- Change default key binds
		radio = { -- Use radio
			pressed = false, -- don't touch
			key = "N",
		},
		speaker = { -- Toggle speaker mode (phone calls)
			pressed=false,
			key = "LSHIFT",
		}
	},
	radioChannelNames = { -- Add named radio channels (Defaults to [channel number] MHz)
		-- [1] = "LEO Tac 1",
	},
	callChannelNames = { -- Add named call channels (Defaults to [channel number])

	},
	use3dAudio = true, -- Enable 3D Audio
	useSendingRangeOnly = true, -- Use sending range only for proximity voice (don't recommend setting this to false)
	useNativeAudio = false, -- Use native audio (audio occlusion in interiors)
	useExternalServer = false, -- Use an external voice server (bigger servers need this), tutorial: https://forum.cfx.re/t/how-to-host-fivems-voice-chat-mumble-in-another-server/1487449?u=frazzle
	externalAddress = "127.0.0.1",
	externalPort = 30120,
	use2dAudioInVehicles = false, -- Workaround for hearing vehicle passengers at high speeds
	showRadioList = true, -- Optional feature to show a list of players in a radio channel, to be used with server export `SetPlayerRadioName`
}
resourceName = GetCurrentResourceName()
phoneticAlphabet = {
	"Alpha",
	"Bravo",
	"Charlie",
	"Delta",
	"Echo",
	"Foxtrot",
	"Golf",
	"Hotel",
	"India",
	"Juliet",
	"Kilo",
	"Lima",
	"Mike",
	"November",
	"Oscar",
	"Papa",
	"Quebec",
	"Romeo",
	"Sierra",
	"Tango",
	"Uniform",
	"Victor",
	"Whisky",
	"XRay",
	"Yankee",
	"Zulu",
}

if IsDuplicityVersion() then
	function DebugMsg(msg)
		if mumbleConfig.debug then
			print("\x1b[32m[" .. resourceName .. "]\x1b[0m ".. msg)
		end
	end
else
	function DebugMsg(msg)
		if mumbleConfig.debug then
			print("[" .. resourceName .. "] ".. msg)
		end
	end

	-- Update config properties from another script
	function SetMumbleProperty(key, value)
		if mumbleConfig[key] ~= nil and mumbleConfig[key] ~= "controls" and mumbleConfig[key] ~= "radioChannelNames" then
			mumbleConfig[key] = value

			if key == "callSpeakerEnabled" then
				SendNUIMessage({ speakerOption = mumbleConfig.callSpeakerEnabled })
			end
		end
	end

	function SetRadioChannelName(channel, name)
		local channel = tonumber(channel)

		if channel ~= nil and name ~= nil and name ~= "" then
			if not mumbleConfig.radioChannelNames[channel] then
				mumbleConfig.radioChannelNames[channel] = tostring(name)
			end
		end
	end

	function SetCallChannelName(channel, name)
		local channel = tonumber(channel)

		if channel ~= nil and name ~= nil and name ~= "" then
			if not mumbleConfig.callChannelNames[channel] then
				mumbleConfig.callChannelNames[channel] = tostring(name)
			end
		end
	end

	-- Make exports available on first tick
	exports("SetMumbleProperty", SetMumbleProperty)
	exports("SetTokoProperty", SetMumbleProperty)
	exports("SetRadioChannelName", SetRadioChannelName)
	exports("SetCallChannelName", SetCallChannelName)
end

function GetRandomPhoneticLetter()
	math.randomseed(GetGameTimer())

	return phoneticAlphabet[math.random(1, #phoneticAlphabet)]
end

function GetPlayersInRadioChannel(channel)
	local channel = tonumber(channel)
	local players = false

	if channel ~= nil then
		if radioData[channel] ~= nil then
			players = radioData[channel]
		end
	end

	return players
end

function GetPlayersInRadioChannels(...)
	local channels = { ... }
	local players = {}

	for i = 1, #channels do
		local channel = tonumber(channels[i])

		if channel ~= nil then
			if radioData[channel] ~= nil then
				players[#players + 1] = radioData[channel]
			end
		end
	end

	return players
end

function GetPlayersInAllRadioChannels()
	return radioData
end

function GetPlayersInPlayerRadioChannel(serverId)
	local players = false

	if serverId ~= nil then
		if voiceData[serverId] ~= nil then
			local channel = voiceData[serverId].radio
			if channel > 0 then
				if radioData[channel] ~= nil then
					players = radioData[channel]
				end
			end
		end
	end

	return players
end

function GetPlayerRadioChannel(serverId)
	if serverId ~= nil then
		if voiceData[serverId] ~= nil then
			return voiceData[serverId].radio
		end
	end
end

function GetPlayerCallChannel(serverId)
	if serverId ~= nil then
		if voiceData[serverId] ~= nil then
			return voiceData[serverId].call
		end
	end
end

exports("GetPlayersInRadioChannel", GetPlayersInRadioChannel)
exports("GetPlayersInRadioChannels", GetPlayersInRadioChannels)
exports("GetPlayersInAllRadioChannels", GetPlayersInAllRadioChannels)
exports("GetPlayersInPlayerRadioChannel", GetPlayersInPlayerRadioChannel)
exports("GetPlayerRadioChannel", GetPlayerRadioChannel)
exports("GetPlayerCallChannel", GetPlayerCallChannel)
