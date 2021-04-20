local showChannels = false
local showProximity = false
local zoneRadius = GetGridChunkRadius()

local function GetGridChunkBounds(x, y)
	local base = vector2(GetGridBase(x), GetGridBase(y))

	return {
		base,
		vector2(base.x, base.y + zoneRadius),
		base.xy + zoneRadius,
		vector2(base.x + zoneRadius, base.y),
	}, base.xy + (zoneRadius/2)
end

local function AddText(text, x, y)
	SetTextScale(1.0, 0.3)
	SetTextOutline(true)
	BeginTextCommandDisplayText("CELL_EMAIL_BCON")
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(x, y)
end

local function ShowChannels()
	local blips = {}
	local channelList = ""

	Citizen.CreateThread(function()
		while showChannels do
			AddText("~b~Channel Info", 0.481, 0.63)
			AddText("Channels: " .. channelList, 0.5, 0.65)
			Citizen.Wait(0)
		end
	end)

	while showChannels do
		local ped = PlayerPedId()
		local pos = GetEntityCoords(ped)
		local nearbyChunks = GetNearbyChunks(pos)
		local newBlips = {}
		local newChannelList = ""

		for i = 1, #nearbyChunks do
			local chunk = nearbyChunks[i]

			if blips[chunk.id] ~= nil then
				newBlips[chunk.id] = blips[chunk.id]
				blips[chunk.id] = nil

				if newChannelList == "" then
					newChannelList = chunk.id
				else
					newChannelList = newChannelList .. ", " .. chunk.id
				end
				goto next
			elseif chunk.id < 0 or chunk.id > GetMaxChunkId() then
				goto next
			end

			local bounds, centre = GetGridChunkBounds(chunk.pos.x, chunk.pos.y)

			newBlips[chunk.id] = {}
			local blipIdx

			local edges = {
				{ 1, 0, (zoneRadius/2), 1.0, zoneRadius },
				{ 1, (zoneRadius/2), 0, zoneRadius, 1.0 },
				{ 3, 0, -(zoneRadius/2), 1.0, zoneRadius },
				{ 3, -(zoneRadius/2), 0, -zoneRadius, 1.0 },
			}

			for edge = 1, #edges do
				local line = edges[edge]
				blipIdx = #newBlips[chunk.id] + 1
				newBlips[chunk.id][blipIdx] = AddBlipForArea(bounds[line[1]].x + line[2], bounds[line[1]].y + line[3], 0, line[4] + 0.0, line[5] + 0.0)
				SetBlipColour(newBlips[chunk.id][blipIdx], 1)
				SetBlipRotation(newBlips[chunk.id][blipIdx], 0)
				SetBlipAsShortRange(newBlips[chunk.id][blipIdx], true)
			end

			blipIdx = #newBlips[chunk.id] + 1
			newBlips[chunk.id][blipIdx] = AddBlipForArea(centre.x, centre.y, 0, zoneRadius + 0.0, zoneRadius + 0.0)
			SetBlipColour(newBlips[chunk.id][blipIdx], 5)
			SetBlipAlpha(newBlips[chunk.id][blipIdx], 64)
			SetBlipRotation(newBlips[chunk.id][blipIdx], 0)
			SetBlipAsShortRange(newBlips[chunk.id][blipIdx], true)

			local chunkId = tostring(chunk.id)
			local numCount = math.ceil(#chunkId / 2)
			local offsets = {
				{0, 0},
				{-8, 16},
				{-12, 12},
			}

			for digit = 1, #chunkId, 2 do
				local num = chunkId:sub(digit, digit + 1)
				blipIdx = #newBlips[chunk.id] + 1
				newBlips[chunk.id][blipIdx] = AddBlipForCoord(centre.x + offsets[numCount][1], centre.y, 0)
				ShowNumberOnBlip(newBlips[chunk.id][blipIdx], tonumber(num))
				ShowHeightOnBlip(newBlips[chunk.id][blipIdx], false)
				SetBlipRotation(newBlips[chunk.id][blipIdx], 0)
				SetBlipAsShortRange(newBlips[chunk.id][blipIdx], true)
				offsets[numCount][1] = offsets[numCount][1] + offsets[numCount][2]
			end

			if newChannelList == "" then
				newChannelList = chunk.id
			else
				newChannelList = newChannelList .. ", " .. chunk.id
			end
			::next::
		end

		for chunk, values in pairs(blips) do
			for i = 1, #values do
				RemoveBlip(values[i])
			end
		end

		blips = newBlips
		channelList = newChannelList
		Citizen.Wait(500)
	end
end

local function ShowProximity()
	local blips = {}
	local playersCanHear = ""
	local playersCanTalk = ""

	Citizen.CreateThread(function()
		while showProximity do
			AddText("~b~Proximity Info", 0.481, 0.68)
			AddText("Players that can hear you: [" .. playersCanTalk .. "]", 0.5, 0.7)
			AddText("Players you can hear:        [" .. playersCanHear .. "]", 0.5, 0.72)
			Citizen.Wait(0)
		end
	end)

	while showProximity do
		local myId = GetPlayerServerId(PlayerId())
		local myProximity =  GetVoiceProperty("proximity", myId)
		local players = GetActivePlayers()
		local newBlips = {}

		playersCanHear = ""
		playersCanTalk = ""

		for i = 1, #players do
			local player = players[i]
			local id = GetPlayerServerId(player)
			local proximity = GetVoiceProperty("proximity", id)

			if not proximity then
				goto next
			end

			local ped = GetPlayerPed(player)
			local pos = GetEntityCoords(ped)

			if id ~= myId and myProximity then
				local myPed = PlayerPedId()
				local myPos = GetEntityCoords(myPed)
				local dist = #(myPos - pos)

				if (dist - config.proximity[proximity].input) <= config.proximity[myProximity].output then
					if playersCanTalk == "" then
						playersCanTalk = id
					else
						playersCanTalk = playersCanTalk .. ", " .. id
					end
				end

				if (dist - config.proximity[myProximity].input) <= config.proximity[proximity].output then
					if playersCanHear == "" then
						playersCanHear = id
					else
						playersCanHear = playersCanHear .. ", " .. id
					end
				end
			end

			if blips[id] then
				if blips[id].proximity ~= proximity then
					for blip = 1, #blips[id].blips do
						RemoveBlip(blips[id].blips[blip])
					end

					blips[id] = nil
					goto continue
				end

				if #(blips[id].pos - pos) > 1 then
					for blip = 1, #blips[id].blips do
						SetBlipCoords(blips[id].blips[blip], pos.x, pos.y, pos.z)
					end

					blips[id].pos = pos
					newBlips[id] = blips[id]
					blips[id] = nil
					goto next
				end

				newBlips[id] = blips[id]
				blips[id] = nil
				goto next
			end

			::continue::
			local data = config.proximity[proximity]

			newBlips[id] = {}
			newBlips[id].proximity = proximity
			newBlips[id].pos = pos
			newBlips[id].blips = {}

			local blipIdx = #newBlips[id].blips + 1
			newBlips[id].blips[blipIdx] = AddBlipForRadius(pos.x, pos.y, pos.z, config.proximity[proximity].output)
			SetBlipColour(newBlips[id].blips[blipIdx], 5)
			SetBlipAlpha(newBlips[id].blips[blipIdx], 64)
			SetBlipRotation(newBlips[id].blips[blipIdx], 0)
			SetBlipAsShortRange(newBlips[id].blips[blipIdx], false)

			local blipIdx = #newBlips[id].blips + 1
			newBlips[id].blips[blipIdx] = AddBlipForRadius(pos.x, pos.y, pos.z, config.proximity[proximity].input)
			SetBlipColour(newBlips[id].blips[blipIdx], 1)
			SetBlipAlpha(newBlips[id].blips[blipIdx], 65)
			SetBlipRotation(newBlips[id].blips[blipIdx], 0)
			SetBlipAsShortRange(newBlips[id].blips[blipIdx], false)

			::next::
		end

		for id, data in pairs(blips) do
			for i = 1, #data.blips do
				RemoveBlip(data.blips[i])
			end
		end

		blips = newBlips
		Citizen.Wait(200)
	end
end

function LogMessage(msg)
	if config.debug then
		print(("[LOG]: %s"):format(msg))
	end
end

RegisterCommand("mdc", function(src, args, raw)
	if config.debug then
		showChannels = not showChannels
		if showChannels then
			Citizen.CreateThread(ShowChannels)
		end
	end
end)

RegisterCommand("mdp", function(src, args, raw)
	if config.debug then
		showProximity = not showProximity
		if showProximity then
			Citizen.CreateThread(ShowProximity)
		end
	end
end)