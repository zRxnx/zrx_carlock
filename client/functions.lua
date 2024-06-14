---@diagnostic disable: param-type-mismatch
ForceStopVehicle = function(plate, vehicle)
    CreateThread(function()
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        FORCED_VEHICLES[netId] = true

        CORE.Bridge.notification(Strings.vehicle_stopped)

        while FORCED_VEHICLES[netId] and IsVehicleValid(vehicle) do
            SetVehicleEngineOn(vehicle, false, false, false)
            SetVehicleUndriveable(vehicle, true)
            Wait(1000)
        end

        SetVehicleEngineOn(vehicle, true, false, false)
        SetVehicleUndriveable(vehicle, false)
    end)
end

GiveKeyMenu = function()
    local MENU = {}

    local coords = GetEntityCoords(cache.ped)
    local vehicle = lib.getClosestVehicle(coords, 3.0, true)
    local plate = GetVehicleNumberPlateText(vehicle)

    if not DoesEntityExist(vehicle) then
        return
    end

    if not HasKey(plate, true) then
        return CORE.Bridge.notification(Strings.not_owner)
    end

    local players = GetActivePlayers()
    local targetCoords, targetPed, targetDist, targetSvid, targetName

    if #players - 1 > 0 then
        for _, player in pairs(players) do
            if player == cache.playerId then
                goto continue
            end

            targetPed = GetPlayerPed(player)

            if not DoesEntityExist(targetPed) then
                goto continue
            end

            targetCoords = GetEntityCoords(targetPed)
            targetDist = #(vector3(coords.x, coords.y, coords.z) - vector3(targetCoords.x, targetCoords.y, targetCoords.z))

            if targetDist > Config.GiveKeyMenu.playerDistance then
                goto continue
            end

            targetSvid = GetPlayerServerId(player)
            targetName = GetPlayerName(player)

            MENU[#MENU + 1] = {
                title = (Strings.menu_givekey):format(targetName, targetSvid),
                description = Strings.menu_givekey_desc,
                arrow = true,
                icon = 'fa-solid fa-key',
                iconColor = Config.IconColor,
                args = {
                    id = targetSvid,
                    name = targetName,
                    plate = plate,
                },
                onSelect = function(args)
                    GiveKeyPlayer(args)
                end
            }

            ::continue::
        end
    else
        MENU[#MENU + 1] = {
            title = Strings.no_player,
            description = Strings.no_player_desc,
            arrow = false,
            icon = 'fa-solid fa-xmark',
            iconColor = Config.IconColor,
            readOnly = true,
        }
    end

    local GIVEN_KEYS = lib.callback.await('zrx_carlock:server:getGivenKeys', 500)

    MENU[#MENU + 1] = {
        title = Strings.menu_givekey_remove,
        description = Strings.menu_givekey_remove_desc,
        arrow = true,
        icon = 'fa-solid fa-pen-to-square',
        iconColor = Config.IconColor,
        disabled = CORE.Shared.IsTableEmpty(GIVEN_KEYS),
        onSelect = function()
            RemoveKeyMenu(GIVEN_KEYS)
        end
    }

    CORE.Client.CreateMenu({
        id = 'zrx_carlock:givekey:main',
        title = Strings.menu_givekey_title,
    }, MENU, Config.Menu.type ~= 'menu', Config.Menu.postition)
end

GiveKeyPlayer = function(data)
    local MENU = {}

    MENU[#MENU + 1] = {
        title = Strings.menu_givekey_perm,
        description = Strings.menu_givekey_perm_desc,
        arrow = true,
        icon = 'fa-solid fa-hand-holding-hand',
        iconColor = Config.IconColor,
        onSelect = function()
            TriggerServerEvent('zrx_carlock:server:keys', 'perm', data)
        end
    }

    MENU[#MENU + 1] = {
        title = Strings.menu_givekey_temp,
        description = Strings.menu_givekey_temp_desc,
        arrow = true,
        icon = 'fa-solid fa-hand-holding-hand',
        iconColor = Config.IconColor,
        onSelect = function()
            TriggerServerEvent('zrx_carlock:server:keys', 'temp', data)
        end
    }

    CORE.Client.CreateMenu({
        id = 'zrx_carlock:givekey:give',
        title = Strings.menu_givekeyplayer_title,
        menu = 'zrx_carlock:givekey:main'
    }, MENU, Config.Menu.type ~= 'menu', Config.Menu.postition)
end

RemoveKeyMenu = function(GIVEN_KEYS)
    local MENU = {}

    if CORE.Shared.IsTableEmpty(GIVEN_KEYS) then
        return CORE.Bridge.notification(Strings.no_key_given)
    end

    local players = {}
    for plate, data in pairs(GIVEN_KEYS) do
        for _, player in pairs(data.players) do
            players[#players + 1] = { label = Strings.menu_removekey_meta, value = (Strings.menu_removekey_meta_desc):format(player.name, player.type) }
        end

        MENU[#MENU + 1] = {
            title = (Strings.menu_removekey):format(plate),
            description = Strings.menu_removekey_desc,
            arrow = true,
            icon = 'fa-solid fa-trash',
            iconColor = Config.IconColor,
            metadata = players,
            onSelect = function()
                TriggerServerEvent('zrx_carlock:server:keys', 'remove', { plate = plate })
            end
        }
    end


    CORE.Client.CreateMenu({
        id = 'zrx_carlock:givekey:remove',
        title = Strings.menu_removekey_title,
        menu = 'zrx_carlock:givekey:main'
    }, MENU, Config.Menu.type ~= 'menu', Config.Menu.postition)
end

HightlightVehicle = function(vehicle)
    if not DoesEntityExist(vehicle) then
        return
    end

    CreateThread(function()
        local r, g, b = Config.IconColor:match('rgba%((%d+),%s*(%d+),%s*(%d+)')
        r, g, b = tonumber(r), tonumber(g), tonumber(b)

        SetEntityDrawOutline(vehicle, true)
        SetEntityDrawOutlineColor(r, g, b, 100)
        SetEntityDrawOutlineShader(1)
        Wait(1000)
        SetEntityDrawOutline(vehicle, false)
    end)
end

local isBusy = false
ToggleVehicle = function(plate, vehicle)
    if isBusy then
        return CORE.Bridge.notification(Strings.busy)
    end

    isBusy = true

    local coords = GetEntityCoords(cache.ped)
    vehicle = vehicle or lib.getClosestVehicle(coords, 5.0, true)

    if not DoesEntityExist(vehicle) then
        isBusy = false
        return
    end

    plate = plate or GetVehicleNumberPlateText(vehicle)

    local lockState = GetVehicleDoorLockStatus(vehicle)
    local hasKey = HasKey(plate)

    HightlightVehicle(vehicle)

    if not hasKey or CORE.Bridge.isPlayerDead() then
        isBusy = false
        return CORE.Bridge.notification(Strings.no_keys)
    end

    if not IsPedInAnyVehicle(cache.ped, false) then
        lib.requestAnimDict('anim@heists@keycard@', 100)
        TaskPlayAnim(cache.ped, 'anim@heists@keycard@', 'exit', 24.0, 16.0, 1000, 50, 0, false, false, false)
        RemoveAnimDict('anim@heists@keycard@')
    end

    CreateThread(function()
        SetVehicleEngineOn(vehicle, true, true, true)
        SetVehicleLights(vehicle, 2)
        Wait(300)
        SetVehicleLights(vehicle, 1)
        Wait(300)
        SetVehicleLights(vehicle, 2)
        Wait(300)
        SetVehicleLights(vehicle, 1)
        SetVehicleLights(vehicle, 0)
    end)


    if lockState == 0 or lockState == 1 then
        CORE.Bridge.notification(Strings.locked)
        TriggerServerEvent('zrx_carlock:server:sync', 'add', { netid = NetworkGetNetworkIdFromEntity(vehicle), plate = plate })

        PlaySyncSound(-1, 'Keycard_Fail', 'DLC_HEISTS_BIOLAB_FINALE_SOUNDS', vehicle)

        SetVehicleDoorsLocked(vehicle, 2)
        SetVehicleDoorsLockedForAllPlayers(vehicle, true)

        if GetPedInVehicleSeat(vehicle, -1) ~= cache.ped then
            SetVehicleEngineOn(vehicle, false, false, true)
            SetVehicleUndriveable(vehicle, true)
        end
    else
        CORE.Bridge.notification(Strings.unlocked)
        TriggerServerEvent('zrx_carlock:server:sync', 'remove', { netid = NetworkGetNetworkIdFromEntity(vehicle), plate = plate })

        PlaySyncSound(-1, 'Keycard_Success', 'DLC_HEISTS_BIOLAB_FINALE_SOUNDS', vehicle)

        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, true)
        SetVehicleUndriveable(vehicle, false)
    end

    isBusy = false
end

LockVehicleAfter = function(vehicle)
    local speed

    while IsVehicleValid(vehicle) do
        speed = GetEntitySpeed(vehicle) * 3.6

        if speed >= Config.AutoLockVehicle.speed.value then
            CORE.Bridge.notification(Strings.locked_auto)
            LOCKED_VEHICLES[vehicle] = true

            SetVehicleDoorsLocked(vehicle, 2)
            SetVehicleDoorsLockedForAllPlayers(vehicle, true)

            HightlightVehicle(vehicle)

            break
        end

        Wait(1000)
    end
end

StartLockpick = function(plate, vehicle)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    if LOCKPICKED_VEHICLES[netId] and LOCKPICKED_VEHICLES[netId].attempts >= Config.Lockpick.maxAttempts then
        return CORE.Bridge.notification(Strings.lockpick_max)
    end

    if HasKey(plate) then
        return
    end

    local class = GetVehicleClass(vehicle)
    local bone = GetEntityBoneIndexByName(vehicle, Config.Lockpick.bone)
    local boneCoords = GetEntityCoords(bone)

    TaskTurnPedToFaceCoord(cache.ped, boneCoords.x, boneCoords.y, boneCoords.z, 2500)
    Wait(2500)
    TaskStartScenarioInPlace(cache.ped, 'PROP_HUMAN_PARKING_METER', 0, true)

    local skillCheck = lib.skillCheck(Config.Lockpick.difficulties[class], Config.Lockpick.usedKeys)

    if skillCheck then
        TriggerServerEvent('zrx_carlock:server:sync', 'lockpick', { netid = NetworkGetNetworkIdFromEntity(vehicle), plate = plate })

        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)

        HightlightVehicle(vehicle)

        CORE.Bridge.notification(Strings.lockpicked)
    else
        CORE.Bridge.notification(Strings.lockpick_failed)

        if LOCKPICKED_VEHICLES[netId]?.attempts then
            LOCKPICKED_VEHICLES[netId].attempts += 1
        else
            LOCKPICKED_VEHICLES[netId] = {}
            LOCKPICKED_VEHICLES[netId].attempts = 1
        end
    end

    ClearPedTasks(cache.ped)
end

PlaySyncSound = function(id, name, ref, entity, cancel)
    if not Config.UseSounds then
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(entity)

    TriggerServerEvent('zrx_carlock:server:syncSound', {
        id = id,
        name = name,
        ref = ref,
        netId = netId,
        cancel = cancel
    })
end

StartHotwire = function(plate, vehicle)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    lib.hideTextUI()

    if HOTWIRED_VEHICLES[netId] and HOTWIRED_VEHICLES[netId].attempts >= Config.Hotwire.maxAttempts then
        return CORE.Bridge.notification(Strings.hotwire_max)
    end

    local class = GetVehicleClass(vehicle)
    local skillCheck = lib.skillCheck(Config.Hotwire.difficulties[class], Config.Hotwire.usedKeys)

    if skillCheck then
        TriggerServerEvent('zrx_carlock:server:sync', 'hotwire', { netid = netId, plate = plate })
        PlaySyncSound(-1, 'Security_Box_Offline_Gun', 'dlc_ch_heist_finale_security_alarms_sounds', vehicle)

        FORCED_VEHICLES[netId] = false

        if HOTWIRED_VEHICLES[netId] then
            HOTWIRED_VEHICLES[netId].hotwired = true
        else
            HOTWIRED_VEHICLES[netId] = {}
            HOTWIRED_VEHICLES[netId].hotwired = true
        end

        CORE.Bridge.notification(Strings.hotwired)

        PlaySyncSound(GetSoundId(), 'Drop_Zone_Alarm', 'DLC_Exec_Air_Drop_Sounds', vehicle, {
            enabled = true,
            time = 10000
        })

        HightlightVehicle(vehicle)

        CAN_HOTWIRE[netId] = false
    else
        CORE.Bridge.notification(Strings.hotwire_failed)

        if HOTWIRED_VEHICLES[netId]?.attempts then
            HOTWIRED_VEHICLES[netId].attempts += 1
        else
            HOTWIRED_VEHICLES[netId] = {}
            HOTWIRED_VEHICLES[netId].attempts = 1
        end

        if HOTWIRED_VEHICLES[netId] and HOTWIRED_VEHICLES[netId].attempts >= Config.Hotwire.maxAttempts then
            return
        end

        CAN_HOTWIRE[netId] = true
        lib.showTextUI(Config.Hotwire.string)

        CreateThread(function()
            while IsVehicleValid(vehicle) do
                Wait(1000)
            end

            lib.hideTextUI()
        end)
    end

end

HasKey = function(plate, forceOwner)
    return lib.callback.await('zrx_carlock:server:hasKey', 1000, plate, not not forceOwner)
end

GiveKey = function(plate)
    lib.callback.await('zrx_carlock:server:giveKey', 100, plate)
end

RemoveKey = function(plate)
    lib.callback.await('zrx_carlock:server:removeKey', 100, plate)
end

IsVehicleValid = function(vehicle)
    return not not (DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == cache.ped)
end