YETI = {
    registered = false
}

function YETI:RegisterRole()
    if self.registered then return end

    self.registered = true

    -- Register the Yeti
    local role = {
        nameraw = "yeti",
        name = "Yeti",
        nameplural = "Yetis",
        nameext = "a Yeti",
        nameshort = "yeti",
        team = ROLE_TEAM_INDEPENDENT,
        translations = {
            ["english"] = {
            }
        }
    }

    CreateConVar("ttt_yeti_enabled", "0", FCVAR_REPLICATED)
    CreateConVar("ttt_yeti_spawn_weight", "1")
    CreateConVar("ttt_yeti_min_players", "0")
    CreateConVar("ttt_yeti_starting_health", "200")
    CreateConVar("ttt_yeti_max_health", "200")
    CreateConVar("ttt_yeti_name", role.name, FCVAR_REPLICATED)
    CreateConVar("ttt_yeti_name_plural", role.nameplural, FCVAR_REPLICATED)
    CreateConVar("ttt_yeti_name_article", "", FCVAR_REPLICATED)
    CreateConVar("ttt_yeti_shop_random_percent", "0", FCVAR_REPLICATED)
    CreateConVar("ttt_yeti_shop_random_enabled", "0", FCVAR_REPLICATED)
    CreateConVar("ttt_yeti_can_see_jesters", "1", FCVAR_REPLICATED)
    CreateConVar("ttt_yeti_update_scoreboard", "1", FCVAR_REPLICATED)
    CreateConVar("ttt_yeti_shop_mode", "0", FCVAR_REPLICATED)
    RegisterRole(role)

    if SERVER then
        -- Generate this after registering the roles so we have the role IDs
        WIN_YETI = GenerateNewWinID(ROLE_YETI)

        -- And sync the ID to the client
        net.Start("TTT_SyncWinIDs")
        net.WriteTable(WINS_BY_ROLE)
        net.WriteUInt(WIN_MAX, 16)
        net.Broadcast()
    end

    if CLIENT then
        hook.Add("TTTSyncWinIDs", "RdmtYetisWin_TTTWinIDsSynced", function()
            -- Grab the new win ID from the lookup table
            WIN_YETI = WINS_BY_ROLE[ROLE_YETI]
        end)

        LANG.AddToLanguage("english", "win_yeti", "The yeti has beaten back the hunters for a win!")
        LANG.AddToLanguage("english", "ev_win_yeti", "The yeti has beaten back the hunters for a win!")

        LANG.AddToLanguage("english", "yeticlub_help_pri", "Press {primaryfire} to damage and knock back players.")
        LANG.AddToLanguage("english", "yeticlub_help_sec", "Press {secondaryfire} to launch a freezing projectile.")

        -- Popup
        LANG.AddToLanguage("english", "info_popup_yeti", [[You are {role}!

Use your club to kill your enemies or freeze them in place!]])
    end
end