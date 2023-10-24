Config = {}

Config.Command = 'carlock' --| Command name
Config.Key = 'F12' --| Its a keymapping
Config.Cooldown = 3 --| Cooldown in seconds
Config.CheckForUpdates = true --| check for updates?

Config.Whitelist = {
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