mumbleConfig = {
    voiceModes = {
        {2.5, "Whisper"}, -- Whisper speech distance in gta distance units
        {8, "Normal"}, -- Normal speech distance in gta distance units
        {20, "Shouting"}, -- Shout speech distance in gta distance units
    },
    speakerRange = 1.5, -- Speaker distance in gta distance units (how close you need to be to another player to hear other players on the radio or phone)
    callSpeakerEnabled = true, -- Allow players to hear all talking participants of a phone call if standing next to someone that is on the phone
    radioSpeakerEnabled = true, -- Allow players to hear all talking participants in a radio if standing next to someone that has a radio
    radioEnabled = true, -- Enable or disable using the radio
    micClickOn = true, -- Is click sound on active
    micClickOff = true, -- Is click sound off active
    micClickVolume = 0.1, -- How loud a mic click is
    radioClickMaxChannel = 100, -- Set the max amount of radio channels that will have local radio clicks enabled
    faceAnimations = true, -- Enable mouth movement when a player talks
    controls = { -- Change default key binds
        proximity = "z", -- Switch proximity mode
        radio = "capital", -- Use radio
        speaker = "x" -- Toggle speaker mode (phone calls)
    }
}

-- Update config properties from another script
function SetMumbleProperty(key, value)
	if mumbleConfig[key] ~= nil and mumbleConfig[key] ~= "controls" then
		mumbleConfig[key] = value
	end
end

-- Make exports available on first tick
exports("SetMumbleProperty", SetMumbleProperty)
exports("SetTokoProperty", SetMumbleProperty)