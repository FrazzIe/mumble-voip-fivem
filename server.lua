local voiceData = {}

local resourceName = ""
local debug = true

function DebugMsg(msg)
    if debug then
        print("\x1b[32m[" .. resourceName .. "]\x1b[0m ".. msg)
    end
end

AddEventHandler("onServerResourceStart", function(resName)
	if GetCurrentResourceName() ~= resName then
		return
	end

	resourceName = resName
end)

RegisterNetEvent("mumble:Initialise")
AddEventHandler("mumble:Initialise", function()
    DebugMsg("Initialised player: " .. source)

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