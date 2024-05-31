---@diagnostic disable: cast-local-type, need-check-nil
CORE = exports.zrx_utility:GetUtility()
COOLDOWN, PLAYER_CACHE, VEHICLE_KEYS, VEHICLE_OWNER, LOCKED_VEHICLES, HOTWIRED_VEHICLES, PERMANENT_VEHICLES, GIVEN_KEYS = {}, {}, {}, {}, {}, {}, {}, {}

CreateThread(function()
    if Config.CheckForUpdates then
        CORE.Server.CheckVersion('zrx_carlock')
    end

    for i, player in pairs(GetPlayers()) do
        player = tonumber(player)
        PLAYER_CACHE[player] = CORE.Server.GetPlayerCache(player)
    end

    MySQL.Sync.execute([[
        CREATE Table IF NOT EXISTS `zrx_carlock` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `owner` varchar(255) DEFAULT NULL,
            `identifier` varchar(255) DEFAULT NULL,
            `name` varchar(255) DEFAULT NULL,
            `plate` varchar(12) DEFAULT NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB;
    ]])

    local response = CORE.Bridge.getVehicleObject().getAllVehicles()
    local reponse2 = MySQL.query.await('SELECT `owner`, `identifier`, `name`, `plate` FROM `zrx_carlock`', {})

    for k, data in pairs(response) do
        if not VEHICLE_KEYS[data.owner] then
            VEHICLE_KEYS[data.owner] = {}
        end

        VEHICLE_KEYS[data.owner][CORE.Shared.Trim(data.plate)] = true
        VEHICLE_OWNER[CORE.Shared.Trim(data.plate)] = data.owner
    end

    for k, data in pairs(reponse2) do
        if not VEHICLE_KEYS[data.identifier] then
            VEHICLE_KEYS[data.identifier] = {}
        end

        VEHICLE_KEYS[data.identifier][CORE.Shared.Trim(data.plate)] = true

        if not GIVEN_KEYS[data.owner] or not GIVEN_KEYS[data.owner][data.plate] then
            GIVEN_KEYS[data.owner] = {}
            GIVEN_KEYS[data.owner][data.plate] = {}
            GIVEN_KEYS[data.owner][data.plate].players = {}
            GIVEN_KEYS[data.owner][data.plate].players[data.identifier] = { name = data.name, type = 'perm' }
        end

        GIVEN_KEYS[data.owner][data.plate].players[data.identifier] = { name = data.name, type = 'perm' }
        PERMANENT_VEHICLES[#PERMANENT_VEHICLES + 1] = { owner = data.owner, identifier = data.identifier, name = data.name, plate = data.plate }
    end

    while Config.CheckVehicleOwner.enabled do
        Wait(Config.CheckVehicleOwner.checkTime)

        response = CORE.Bridge.getVehicleObject().getAllVehicles()

        for k, data in pairs(response) do
            if VEHICLE_KEYS[data.owner] then
                VEHICLE_KEYS[data.owner][CORE.Shared.Trim(data.plate)] = true
            else
                VEHICLE_KEYS[data.owner] = {}
                VEHICLE_KEYS[data.owner][CORE.Shared.Trim(data.plate)] = true
            end

            VEHICLE_OWNER[CORE.Shared.Trim(data.plate)] = data.owner
        end
    end
end)

lib.callback.register('zrx_carlock:server:hasKey', function(player, plate, forceOwner)
    return HasKey(player, plate, forceOwner)
end)

lib.callback.register('zrx_carlock:server:giveKey', function(player, plate)
    if not IsVehicleOwner(player, plate) then
        Config.PunishPlayer(player, 'Tried to trigger "zrx_carlock:server:giveKey"')
    end

    return GiveKey(player, plate)
end)

lib.callback.register('zrx_carlock:server:removeKey', function(player, plate)
    if not IsVehicleOwner(player, plate) then
        Config.PunishPlayer(player, 'Tried to trigger "zrx_carlock:server:removeKey"')
    end

    return RemoveKey(player, plate)
end)

lib.callback.register('zrx_carlock:server:getGivenKeys', function(player)
    local xPlayer = CORE.Bridge.getPlayerObject(player)

    return GIVEN_KEYS[xPlayer.identifier]
end)

if Config.LockSpawnedVehicles then
    AddEventHandler('entityCreated', function(entity)
        if not DoesEntityExist(entity) then
            return
        end

        local entityType = GetEntityType(entity)

        if entityType ~= 2 then
            return
        end

        local netId = NetworkGetNetworkIdFromEntity(entity)
        LOCKED_VEHICLES[netId] = true

        TriggerClientEvent('zrx_carlock:client:sync', -1, 'add', { netid = netId })
    end)
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    MySQL.query.await('TRUNCATE TABLE `zrx_carlock`')

    for k, data in pairs(PERMANENT_VEHICLES) do
        MySQL.insert.await('INSERT INTO `zrx_carlock` (owner, identifier, name, plate) VALUES (?, ?, ?, ?)', { data.owner, data.identifier, data.name, data.plate })
    end
end)

RegisterNetEvent('zrx_carlock:server:sync', function(action, data)
    if action ~= 'hotwire' and not HasKey(source, data.plate) then
        return Config.PunishPlayer('Tried to trigger "zrx_carlock:server:sync"')
    end

    if Webhook.Links.sync:len() > 0 then
        local message = ([[
            The data was synced

            Type: **%s**
        ]]):format(action)

        CORE.Server.DiscordLog(source, 'SYNCED', message, Webhook.Links.sync)
    end

    if action == 'add' then
        LOCKED_VEHICLES[data.netid] = true
    elseif action == 'remove' then
        LOCKED_VEHICLES[data.netid] = false
    elseif action == 'lockpick' then
        if not LOCKED_VEHICLES[data.netid] then
            return Config.PunishPlayer('Tried to trigger "zrx_carlock:server:sync"')
        end

        LOCKED_VEHICLES[data.netid] = false
    elseif action == 'hotwire' then
        HOTWIRED_VEHICLES[data.netid] = true
    end

    TriggerClientEvent('zrx_carlock:client:sync', -1, action, data)
end)

RegisterNetEvent('zrx_carlock:server:keys', function(action, data)
    if not HasKey(source, data.plate) then
        return Config.PunishPlayer('Tried to trigger "zrx_carlock:server:keys"')
    end

    local xPlayer = CORE.Bridge.getPlayerObject(source)
    local xTarget

    if action ~= 'remove' then
        xTarget = CORE.Bridge.getPlayerObject(data.id)
    end

    if action == 'perm' then
        PERMANENT_VEHICLES[#PERMANENT_VEHICLES + 1] = { owner = xPlayer.identifier, identifier = xTarget.identifier, name = xTarget.name, plate = data.plate }

        if not GIVEN_KEYS[xPlayer.identifier] or not GIVEN_KEYS[xPlayer.identifier][data.plate] then
            GIVEN_KEYS[xPlayer.identifier] = {}
            GIVEN_KEYS[xPlayer.identifier][data.plate] = {}
            GIVEN_KEYS[xPlayer.identifier][data.plate].players = {}
            GIVEN_KEYS[xPlayer.identifier][data.plate].players[xTarget.identifier] = { name = xTarget.name, type = 'perm' }
        end

        GIVEN_KEYS[xPlayer.identifier][data.plate].players[xTarget.identifier] = { name = xTarget.name, type = 'perm' }

        GiveKey(data.id, data.plate)

        if Webhook.Links.givekey:len() > 0 then
            local message = ([[
                The player got a key
    
                Plate: **%s**
                Type: **Permanent**
            ]]):format(data.plate)

            CORE.Server.DiscordLog(data.id, 'GIVE KEY', message, Webhook.Links.givekey)
        end

        CORE.Bridge.notification(xPlayer.player, (Strings.gave_perm):format(xTarget.name, data.id))
        CORE.Bridge.notification(xTarget.player, (Strings.got_perm):format(xPlayer.name, xPlayer.player))
    elseif action == 'temp' then
        if not GIVEN_KEYS[xPlayer.identifier] or not GIVEN_KEYS[xPlayer.identifier][data.plate] then
            GIVEN_KEYS[xPlayer.identifier] = {}
            GIVEN_KEYS[xPlayer.identifier][data.plate] = {}
            GIVEN_KEYS[xPlayer.identifier][data.plate].players = {}
            GIVEN_KEYS[xPlayer.identifier][data.plate].players[xTarget.identifier] = { name = xTarget.name, type = 'temp' }
        end

        GIVEN_KEYS[xPlayer.identifier][data.plate].players[xTarget.identifier] = { name = xTarget.name, type = 'temp' }

        GiveKey(data.id, data.plate)

        if Webhook.Links.givekey:len() > 0 then
            local message = ([[
                The player got a key
    
                Plate: **%s**
                Type: **Temporary**
            ]]):format(data.plate)

            CORE.Server.DiscordLog(data.id, 'GIVE KEY', message, Webhook.Links.givekey)
        end

        CORE.Bridge.notification(xPlayer.player, (Strings.gave_temp):format(xTarget.name, data.id))
        CORE.Bridge.notification(xTarget.player, (Strings.got_temp):format(xPlayer.name, xPlayer.player))
    elseif action == 'remove' then
        local toRemove = GIVEN_KEYS[xPlayer.identifier][data.plate]

        for identifier, data2 in pairs(toRemove.players) do
            VEHICLE_KEYS[identifier][CORE.Shared.Trim(data.plate)] = false

            if data2.type == 'perm' then
                for id, data3 in pairs(PERMANENT_VEHICLES) do
                    if data3.plate == data.plate then
                        PERMANENT_VEHICLES[id] = nil
                    end
                end
            end
        end

        GIVEN_KEYS[xPlayer.identifier][data.plate] = nil

        CORE.Bridge.notification(xPlayer.player, (Strings.removed_all_keys):format(data.plate))
    end
end)

exports('hasKey', HasKey)
exports('giveKey', GiveKey)
exports('removeKey', RemoveKey)
exports('updatePlate', UpdatePlate)