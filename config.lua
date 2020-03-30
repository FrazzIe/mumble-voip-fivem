voiceData = {}
radioData = {}
callData = {}
mumbleConfig = {
    debug = false, -- enable debug msgs
    voiceModes = {
        {2.5, "Whisper"}, -- Whisper speech distance in gta distance units
        {8.0, "Normal"}, -- Normal speech distance in gta distance units
        {20.0, "Shouting"}, -- Shout speech distance in gta distance units
    },
    speakerRange = 1.5, -- Speaker distance in gta distance units (how close you need to be to another player to hear other players on the radio or phone)
    callSpeakerEnabled = true, -- Allow players to hear all talking participants of a phone call if standing next to someone that is on the phone
    radioSpeakerEnabled = true, -- Allow players to hear all talking participants in a radio if standing next to someone that has a radio
    radioEnabled = true, -- Enable or disable using the radio
    micClicks = true, -- Are clicks enabled or not
    micClickOn = true, -- Is click sound on active
    micClickOff = true, -- Is click sound off active
    micClickVolume = 0.1, -- How loud a mic click is
    radioClickMaxChannel = 100, -- Set the max amount of radio channels that will have local radio clicks enabled
    controls = { -- Change default key binds
        proximity = {
            key = 20, -- Z
        }, -- Switch proximity mode
        radio = {
            pressed = false, -- don't touch
            key = 137, -- capital
        }, -- Use radio
        speaker = {
            key = 20, -- Z
            secondary = 21, -- LEFT SHIFT
        } -- Toggle speaker mode (phone calls)
    },
    radioChannelNames = { -- Add named radio channels (Defaults to [channel number] MHz)
        [1] = "LEO Tac 1",
        [2] = "LEO Tac 2",
        [3] = "EMS Tac 1",
        [4] = "EMS Tac 2",
        [500] = "Hurr Durr 500 Hurr Durr",
    },
    callChannelNames = { -- Add named call channels (Defaults to [channel number])

    },
    use3dAudio = false, -- (currently doesn't work properly) make sure setr voice_use3dAudio true and setr voice_useSendingRangeOnly true is in your server.cfg (currently doesn't work properly)
}
resourceName = GetCurrentResourceName()

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

exports("GetPlayersInRadioChannel", GetPlayersInRadioChannel)
exports("GetPlayersInRadioChannels", GetPlayersInRadioChannels)
exports("GetPlayersInAllRadioChannels", GetPlayersInAllRadioChannels)
exports("GetPlayersInPlayerRadioChannel", GetPlayersInPlayerRadioChannel)