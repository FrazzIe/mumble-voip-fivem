UIProperty = {}

function SetTalking()
	while true do
		SendNUIMessage({ isTalking = NetworkIsPlayerTalking(PlayerId()) })
		Citizen.Wait(config.uiInterval)
	end
end

AddEventHandler(config.eventPrefix .. ":initialise", function(src)
	Citizen.CreateThread(SetTalking)
end)