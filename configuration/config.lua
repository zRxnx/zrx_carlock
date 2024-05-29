Config = {}

--[[
TODO

SHOWCASE
DOCS
]]

Config.Command = 'carlock' --| Command name
Config.ToggleKey = 'F7' --| Its a keymapping
Config.ToggleTarget = true --| Use target to unlock/lock
Config.UseSounds = true
Config.IconColor  = 'rgba(173, 216, 230, 1)' --| rgba format
Config.LockSpawnedVehicles = true
Config.CheckForUpdates = true --| check for updates?

Config.Menu = {
    type = 'context', --| context or menu
    postition = 'top-left' --| top-left, top-right, bottom-left or bottom-right
}

Config.GiveKeyMenu = {
    enabled = true,

    command = 'givekeymenu',
    key = 'F11',
    playerDistance = 5.0, --| Distance to show players in menu
}

Config.PreventUnlocking = {
    enabled = true, --| Every x time it will lock all locked vehicles
    checkTime = 1000, --| msec
}

Config.CheckVehicleOwner = { --| WARNING: Can impact the server stability massively
    enabled = true, --| Every x time check the vehicle owners and grant them automatically keys
    checkTime = 60000, --| msec
}

Config.LockVehicle = {
    enabled = true, --| Lock vehicle when the speed is reached
    speed = 10, --| KPH
}

Config.Lockpick = { --| Requires ox_target
    enabled = true,
    item = false, --| Needed item | False to disable
    maxAttempts = 2, --| Max attempts
    bone = 'door_dside_f', --| https://docs.fivem.net/natives/?_0xFB71170B7E76ACBA

    difficulties = { --| Remove lines if you want to disable lockpicking for desired categories
        [0] = { 'medium', 'medium', 'medium' }, --| Compacts
        [1] = { 'medium', 'medium', 'medium' }, --| Sedans
        [2] = { 'medium', 'medium', 'medium' }, --| Compacts
        [3] = { 'medium', 'medium', 'medium' }, --| Coupes
        [4] = { 'medium', 'medium', 'medium' }, --| Muscle
        [5] = { 'medium', 'medium', 'medium' }, --| Sports Classics
        [6] = { 'medium', 'medium', 'medium' }, --| Sports
        [7] = { 'medium', 'medium', 'medium' }, --| Super
        [8] = { 'medium', 'medium', 'medium' }, --| Motorcycles
        [9] = { 'medium', 'medium', 'medium' }, --| Off-road
        [10] = { 'medium', 'medium', 'medium' }, --| Industrial
        [11] = { 'medium', 'medium', 'medium' }, --| Utility
        [12] = { 'medium', 'medium', 'medium' }, --| Vans
        [13] = { 'medium', 'medium', 'medium' }, --| Cycles
        [14] = { 'medium', 'medium', 'medium' }, --| Boats
        [15] = { 'medium', 'medium', 'medium' }, --| Helicopters
        [16] = { 'medium', 'medium', 'medium' }, --| Planes
        [17] = { 'medium', 'medium', 'medium' }, --| Service
        --[18] = { 'medium', 'medium', 'medium' }, --| Emergency
        --[19] = { 'medium', 'medium', 'medium' }, --| Military
        [20] = { 'medium', 'medium', 'medium' }, --| Commercial
        --[21] = { 'medium', 'medium', 'medium' }, --| Trains
        [22] = { 'medium', 'medium', 'medium' }, --| Open Wheel
    },

    usedKeys = { 'e', 'g', 'f', 'w', 'a', 's', 'd'  },
}

Config.Hotwire = {
    enabled = true,
    item = false, --| Needed item | False to disable
    maxAttempts = 2, --| Max attempts
    string = '[E] - Hotwire',
    key = 'E',

    difficulties = { --| Remove lines if you want to disable lockpicking for desired categories
        [0] = { 'medium', 'medium', 'medium' }, --| Compacts
        [1] = { 'medium', 'medium', 'medium' }, --| Sedans
        [2] = { 'medium', 'medium', 'medium' }, --| Compacts
        [3] = { 'medium', 'medium', 'medium' }, --| Coupes
        [4] = { 'medium', 'medium', 'medium' }, --| Muscle
        [5] = { 'medium', 'medium', 'medium' }, --| Sports Classics
        [6] = { 'medium', 'medium', 'medium' }, --| Sports
        [7] = { 'medium', 'medium', 'medium' }, --| Super
        [8] = { 'medium', 'medium', 'medium' }, --| Motorcycles
        [9] = { 'medium', 'medium', 'medium' }, --| Off-road
        [10] = { 'medium', 'medium', 'medium' }, --| Industrial
        [11] = { 'medium', 'medium', 'medium' }, --| Utility
        [12] = { 'medium', 'medium', 'medium' }, --| Vans
        [13] = { 'medium', 'medium', 'medium' }, --| Cycles
        [14] = { 'medium', 'medium', 'medium' }, --| Boats
        [15] = { 'medium', 'medium', 'medium' }, --| Helicopters
        [16] = { 'medium', 'medium', 'medium' }, --| Planes
        [17] = { 'medium', 'medium', 'medium' }, --| Service
        --[18] = { 'medium', 'medium', 'medium' }, --| Emergency
        --[19] = { 'medium', 'medium', 'medium' }, --| Military
        [20] = { 'medium', 'medium', 'medium' }, --| Commercial
        --[21] = { 'medium', 'medium', 'medium' }, --| Trains
        [22] = { 'medium', 'medium', 'medium' }, --| Open Wheel
    },

    usedKeys = { 'e', 'g', 'f', 'w', 'a', 's', 'd'  },
}

Config.Whitelist = { --| Not lockable
    plate = {
        ['123 ABC'] = true
    },

    model = {
        [`t20`] = true
    }
}

--| Place here your punish actions
Config.PunishPlayer = function(player, reason)
    if not IsDuplicityVersion() then return end
    if Webhook.Links.punish:len() > 0 then
        local message = ([[
            The player got punished

            Reason: **%s**
        ]]):format(reason)

        CORE.Server.DiscordLog(player, 'Punish', message, Webhook.Links.punish)
    end

    DropPlayer(player, reason)
end