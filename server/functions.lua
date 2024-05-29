HasKey = function(player, plate, forceOwner)
    local xPlayer = CORE.Bridge.getPlayerObject(player)
    local toReturn

    if forceOwner then
        toReturn = IsVehicleOwner(player, plate)
    else
        if not VEHICLE_KEYS[xPlayer.identifier] then
            VEHICLE_KEYS[xPlayer.identifier] = {}
        end

        toReturn = not not VEHICLE_KEYS[xPlayer.identifier]?[CORE.Shared.Trim(plate)]
    end

    if Webhook.Links.haskey:len() > 0 then
        local message = ([[
            The player request their keys

            Plate: **%s**
            Force Owner: **%s**
        ]]):format(plate, forceOwner)

        CORE.Server.DiscordLog(source, 'HAS KEY', message, Webhook.Links.haskey)
    end

    return toReturn
end

GiveKey = function(player, plate)
    local xPlayer = CORE.Bridge.getPlayerObject(player)

    if not VEHICLE_KEYS[xPlayer.identifier] then
        VEHICLE_KEYS[xPlayer.identifier] = {}
    end

    if Webhook.Links.givekey:len() > 0 then
        local message = ([[
            The player got keys

            Plate: **%s**
        ]]):format(plate)

        CORE.Server.DiscordLog(source, 'GIVE KEY', message, Webhook.Links.givekey)
    end

    VEHICLE_KEYS[xPlayer.identifier][CORE.Shared.Trim(plate)] = true
end

RemoveKey = function(player, plate)
    local xPlayer = CORE.Bridge.getPlayerObject(player)

    if not VEHICLE_KEYS[xPlayer.identifier] then
        VEHICLE_KEYS[xPlayer.identifier] = {}
    end

    if Webhook.Links.removekey:len() > 0 then
        local message = ([[
            The player got keys removed

            Plate: **%s**
        ]]):format(plate)

        CORE.Server.DiscordLog(source, 'REMOVE KEY', message, Webhook.Links.removekey)
    end

    VEHICLE_KEYS[xPlayer.identifier][CORE.Shared.Trim(plate)] = false
end

UpdatePlate = function(oldPlate, newPlate)
    oldPlate = CORE.Shared.Trim(oldPlate)
    newPlate = CORE.Shared.Trim(newPlate)

    if VEHICLE_OWNER[oldPlate] then
        VEHICLE_OWNER[newPlate] = VEHICLE_OWNER[oldPlate]
        VEHICLE_OWNER[oldPlate] = nil
    end

    for owner, data in pairs(VEHICLE_KEYS) do
        for plate, data2 in pairs(data) do
            if plate == oldPlate then
                VEHICLE_KEYS[owner][newPlate] = VEHICLE_KEYS[owner][oldPlate]
                VEHICLE_KEYS[owner][oldPlate] = nil
            end
        end
    end

    for id, data in pairs(PERMANENT_VEHICLES) do
        if data.plate == oldPlate then
            PERMANENT_VEHICLES[id].plate = newPlate
        end
    end

    for identifier, data in pairs(GIVEN_KEYS) do
        for plate, data2 in pairs(data) do
            if plate == oldPlate then
                GIVEN_KEYS[identifier][newPlate] = GIVEN_KEYS[identifier][oldPlate]
                GIVEN_KEYS[identifier][oldPlate] = {}
                GIVEN_KEYS[identifier][oldPlate].players = {}
            end
        end
    end
end

IsVehicleOwner = function(player, plate)
    local xPlayer = CORE.Bridge.getPlayerObject(player)

    return VEHICLE_OWNER[CORE.Shared.Trim(plate)] == xPlayer.identifier
end