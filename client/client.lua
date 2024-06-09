CORE = exports.zrx_utility:GetUtility()
LOCKED_VEHICLES, LOCKPICKED_VEHICLES, HOTWIRED_VEHICLES, FORCED_VEHICLES, CAN_HOTWIRE, DATA_ENGINE = {}, {}, {}, {}, {}, {}

CORE.Client.RegisterKeyMappingCommand(Config.Command, Strings.cmd_toggle_desc, Config.ToggleKey, function()
    ToggleVehicle()
end)

if Config.GiveKeyMenu.enabled then
    CORE.Client.RegisterKeyMappingCommand(Config.GiveKeyMenu.command, Strings.cmd_givekey_desc, Config.GiveKeyMenu.key, function()
        GiveKeyMenu()
    end)
end

CORE.Client.RegisterKeyMappingCommand('hotwire', Strings.cmd_hotwire_desc, Config.Hotwire.key, function()
    local vehicle = GetVehiclePedIsIn(cache.ped, false)

    if not DoesEntityExist(vehicle) then
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)

    if Config.Hotwire.enabled and CAN_HOTWIRE[netId] then
        if HOTWIRED_VEHICLES[netId] and HOTWIRED_VEHICLES[netId].attempts >= Config.Hotwire.maxAttempts then
            return
        end

        StartHotwire(plate, vehicle)
    end
end)

if Config.Engine.enabled then
    CORE.Client.RegisterKeyMappingCommand(Config.Engine.command, Strings.cmd_engine_desc, Config.Engine.key, function()
        local vehicle = GetVehiclePedIsIn(cache.ped, false)
        local plate = GetVehicleNumberPlateText(vehicle)
        local netId = NetworkGetNetworkIdFromEntity(vehicle)

        if not DoesEntityExist(vehicle) then
            return
        end

        if Config.Engine.needKey and not HasKey(plate, false) then
            return CORE.Bridge.notification(Strings.no_keys)
        end

        local engineState = GetIsVehicleEngineRunning(vehicle)

        if engineState then
            DATA_ENGINE[netId] = false
            CORE.Bridge.notification(Strings.engine_stop)

            SetVehicleEngineOn(cache.vehicle, false, false, true)
            SetVehicleUndriveable(cache.vehicle, true)
            SetVehicleLights(vehicle, 0)

            if Config.Engine.keepState then
                CreateThread(function()
                    while not DATA_ENGINE[netId] and IsVehicleValid(vehicle) do
                        SetVehicleEngineOn(cache.vehicle, false, false, true)
                        SetVehicleUndriveable(cache.vehicle, true)
                        Wait(0)
                    end
                end)
            end
        else
            DATA_ENGINE[netId] = true
            CORE.Bridge.notification(Strings.engine_start)

            SetVehicleEngineOn(cache.vehicle, true, false, true)
            SetVehicleUndriveable(cache.vehicle, false)

            if Config.Engine.keepState then
                CreateThread(function()
                    while DATA_ENGINE[netId] and IsVehicleValid(vehicle) do
                        SetVehicleEngineOn(cache.vehicle, true, false, true)
                        SetVehicleUndriveable(cache.vehicle, false)
                        Wait(0)
                    end
                end)
            end

            SetVehicleLights(vehicle, 2)
        end
    end)
end

lib.onCache('vehicle', function(vehicle)
    if DoesEntityExist(vehicle) then
        return
    end

    vehicle = cache.vehicle

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local lockState = GetVehicleDoorLockStatus(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)

    if Config.Engine.keepState then
        if DATA_ENGINE[netId] then
            SetVehicleLights(vehicle, 2)
        end
    end

    if Config.AutoLockVehicle.exitVehicle.enabled then
        if not HasKey(plate, Config.AutoLockVehicle.exitVehicle.onlyOwner) then
            return
        end

        Wait(1000)

        if lockState == 0 or lockState == 1 then
            ToggleVehicle(plate, vehicle)
        end
    end
end)

lib.onCache('vehicle', function(vehicle)
    if not DoesEntityExist(vehicle) then
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    local model = GetEntityModel(vehicle)

    while IsPedGettingIntoAVehicle(cache.ped) do
        Wait(100)
    end

    if Config.Whitelist.plate[plate] then return end
    if Config.Whitelist.model[model] then return end
    if not IsVehicleValid(vehicle) then return end
    if HOTWIRED_VEHICLES[netId]?.hotwired then return end
    if HasKey(plate) then
        if Config.AutoLockVehicle.speed.enabled then
            LockVehicleAfter(vehicle)
        end

        return
    end
    if GetIsVehicleEngineRunning(vehicle) then return end

    ForceStopVehicle(plate, vehicle)

    if Config.Hotwire.enabled then
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
end)

RegisterNetEvent('zrx_carlock:client:sync', function(action, data)
    if action == 'add' then
        LOCKED_VEHICLES[data.netid] = true
        local vehicle = NetworkGetEntityFromNetworkId(data.netid)

        if not DoesEntityExist(vehicle) then
            return
        end

        SetVehicleDoorsLocked(vehicle, 2)
        SetVehicleDoorsLockedForAllPlayers(vehicle, true)
    elseif action == 'npc' then
        LOCKED_VEHICLES[data.netid] = true
        local vehicle = NetworkGetEntityFromNetworkId(data.netid)

        if not DoesEntityExist(vehicle) then
            return
        end

        SetVehicleDoorsLocked(vehicle, data.state)
    elseif action == 'remove' then
        LOCKED_VEHICLES[data.netid] = false
        local vehicle = NetworkGetEntityFromNetworkId(data.netid)

        if not DoesEntityExist(vehicle) then
            return
        end

        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, false)
        SetVehicleUndriveable(vehicle, false)
    end
end)

CreateThread(function()
    local vehicle

    while Config.PreventUnlocking.enabled do
        for k, netid in pairs(LOCKED_VEHICLES) do
            vehicle = NetworkGetEntityFromNetworkId(netid)

            if DoesEntityExist(vehicle) then
                SetVehicleDoorsLocked(vehicle, 2)
                SetVehicleDoorsLockedForAllPlayers(vehicle, true)
            end
        end

        Wait(Config.PreventUnlocking.checkTime)
    end
end)

if Config.Lockpick.enabled then
    exports.ox_target:addGlobalVehicle({
        label = Strings.target_lockpick,
        icon = 'fa-solid fa-crosshairs',
        distance = 1,
        bones = Config.Lockpick.bone,
        items = Config.Lockpick.item,
        canInteract = function(entity, distance, coords, name, bone)
            local plate = GetVehicleNumberPlateText(entity)
            local lockstate = GetVehicleDoorLockStatus(entity)

            if DoesEntityExist(GetPedInVehicleSeat(entity, -1)) or (lockstate == 0 or lockstate == 1) then
                return false
            end

            return true
        end,
        onSelect = function(data)
            StartLockpick(GetVehicleNumberPlateText(data.entity), data.entity)
        end
    })
end

if Config.ToggleTarget then
    exports.ox_target:addGlobalVehicle({
        label = Strings.target_toggle,
        icon = 'fa-solid fa-key',
        distance = 1,
        onSelect = function(data)
            local plate = GetVehicleNumberPlateText(data.entity)

            ToggleVehicle(plate, data.entity)
        end
    })
end

exports('hasKey', HasKey)
exports('giveKey', GiveKey)
exports('removeKey', RemoveKey)
exports('giveKeyMenu', GiveKeyMenu)