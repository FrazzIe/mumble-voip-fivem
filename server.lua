local voiceData = {}

RegisterNetEvent("mumble:Initialise")
AddEventHandler("mumble:Initialise", function()
    print("[mumble]: Initialised player: ".. source)

    if not voiceData[source] then
        voiceData[source] = {
            mode = 2
        }
    end

    TriggerClientEvent("mumble:SetVoiceData", -1, voiceData)
end)

RegisterNetEvent("mumble:SetVoiceMode")
AddEventHandler("mumble:SetVoiceMode", function(mode)
    print("[mumble]: Player ".. source .. " changed mode to: "..mode)
    
    if not voiceData[source] then
        voiceData[source] = {
            mode = 2
        }
    end

    voiceData[source].mode = mode

    TriggerClientEvent("mumble:SetVoiceData", -1, voiceData)
end)