local showChannels = false
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

local function ShowChannels()
	local blips = {}
	while showChannels do
		local ped = PlayerPedId()
		local pos = GetEntityCoords(ped)
		local nearbyChunks = GetNearbyChunks(pos)
		local newBlips = {}

		for i = 1, #nearbyChunks do
			local chunk = nearbyChunks[i]

			if blips[chunk.id] ~= nil then
				newBlips[chunk.id] = blips[chunk.id]
				blips[chunk.id] = nil
				goto next
			end

			local bounds, centre = GetGridChunkBounds(chunk.pos.x, chunk.pos.y)

			newBlips[chunk.id] = {}
			local blipIdx

			for edge = 1, #bounds do
				blipIdx = #newBlips[chunk.id] + 1
				newBlips[chunk.id][blipIdx] = AddBlipForCoord(bounds[edge].x, bounds[edge].y, 0)
				SetBlipColour(newBlips[chunk.id][blipIdx], 1)
				SetBlipScale(newBlips[chunk.id][blipIdx], 0.6)
			end

			blipIdx = #newBlips[chunk.id] + 1
			newBlips[chunk.id][blipIdx] = AddBlipForArea(centre.x, centre.y, 0, zoneRadius + 0.0, zoneRadius + 0.0)
			SetBlipColour(newBlips[chunk.id][blipIdx], 5)
			SetBlipAlpha(newBlips[chunk.id][blipIdx], 64)
			SetBlipRotation(newBlips[chunk.id][blipIdx], 0)

			local id = tostring(chunk.id)
			local textOffset = -12

			for digit = 1, #id, 2 do
				local num = id:sub(digit, digit + 1)
				blipIdx = #newBlips[chunk.id] + 1
				newBlips[chunk.id][blipIdx] = AddBlipForCoord(centre.x + textOffset, centre.y, 0)
				ShowNumberOnBlip(newBlips[chunk.id][blipIdx], tonumber(num))
				ShowHeightOnBlip(newBlips[chunk.id][blipIdx], false)
				SetBlipRotation(newBlips[chunk.id][blipIdx], 0)
				textOffset = textOffset + 12
			end

			::next::
		end

		for chunk, values in pairs(blips) do
			for i = 1, #values do
				RemoveBlip(values[i])
			end
		end

		blips = newBlips
		Citizen.Wait(500)
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