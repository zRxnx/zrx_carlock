CORE = exports.zrx_utility:GetUtility()
COOLDOWN, PLAYER_CACHE = {}, {}

CreateThread(function()
    if Config.CheckForUpdates then
        CORE.Server.CheckVersion('zrx_carlock')
    end

    for i, player in pairs(GetPlayers()) do
        player = tonumber(player)
        PLAYER_CACHE[player] = CORE.Server.GetPlayerCache(player)
    end
end)