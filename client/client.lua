CORE = exports.zrx_utility:GetUtility()

CORE.Client.RegisterKeyMappingCommand(Config.Command, Strings.cmd_desc, Config.Key, function()
    StartCarlock()
end)

lib.onCache('vehicle', function(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    local model = GetEntityModel(vehicle)

    if Config.Whitelist.plate[plate] then return end
    if Config.Whitelist.model[model] then return end
    if GetPedInVehicleSeat(vehicle, -1) ~= cache.ped then return end

    ForceStopVehicle(vehicle)
end)