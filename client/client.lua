CORE = exports.zrx_utility:GetUtility()
LOCKED_VEHICLES, LOCKPICKED_VEHICLES, HOTWIRED_VEHICLES, FORCED_VEHICLES, CAN_HOTWIRE = {}, {}, {}, {}, {}

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

lib.onCache('vehicle', function(vehicle)
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
    if GetIsVehicleEngineRunning(vehicle) then return end
    if HasKey(plate) then
        if Config.LockVehicle.enabled then
            LockVehicleAfter(vehicle)
        end

        return
    end

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
    elseif action == 'remove' then
        LOCKED_VEHICLES[data.netid] = false
        local vehicle = NetworkGetEntityFromNetworkId(data.netid)

        if not DoesEntityExist(vehicle) then
            return
        end

        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, true)
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

            if DoesEntityExist(GetPedInVehicleSeat(entity, -1)) or HasKey(plate) or (lockstate == 0 or lockstate == 1) then
                return false
            end

            return true
        end,
        onSelect = function(data)
            print(GetVehicleNumberPlateText(data.entity), data.entity)
            StartLockpick(GetVehicleNumberPlateText(data.entity), data.entity)
        end
    })
end

if Config.ToggleTarget then
    exports.ox_target:addGlobalVehicle({
        label = Strings.target_toggle,
        icon = 'fa-solid fa-key',
        distance = 1,
        canInteract = function(entity, distance, coords, name, bone)
            local plate = GetVehicleNumberPlateText(entity)

            if DoesEntityExist(GetPedInVehicleSeat(entity, -1)) and HasKey(plate) then
                return false
            end

            return true
        end,
        onSelect = function(data)
            ToggleVehicle(GetVehicleNumberPlateText(data.entity), data.entity)
        end
    })
end

exports('hasKey', HasKey)
exports('giveKey', GiveKey)
exports('removeKey', RemoveKey)
exports('giveKeyMenu', GiveKeyMenu)