net.Receive("RandomatYetiBegin", function()
    YETI:RegisterRole()

    hook.Add("TTTScoringWinTitle", "RandomatYetiScoring", function(wintype, wintitle, title)
        if wintype == WIN_YETI then
            return { txt = "hilite_win_role_singular", params = { role = ROLE_STRINGS[ROLE_YETI]:upper() }, c = ROLE_COLORS[ROLE_YETI] }
        end
    end)

    hook.Add("TTTEventFinishText", "RandomatYetiEventFinishText", function(e)
        if e.win == WIN_YETI then
            return LANG.GetTranslation("ev_win_yeti")
        end
    end)

    hook.Add("TTTEventFinishIconText", "RandomatYetiEventFinishText", function(e, win_string, role_string)
        if e.win == WIN_YETI then
            return win_string, ROLE_STRINGS[ROLE_YETI]
        end
    end)

    -- Enable the tutorial page for this role when the event is running
    hook.Add("TTTTutorialRoleEnabled", "RandomatYetiTutorialRoleEnabled", function(role)
        if role == ROLE_YETI and Randomat:IsEventActive("yeti") then
            return true
        end
    end)

    hook.Add("TTTTutorialRoleText", "RandomatYetiTutorialRoleText", function(role, titleLabel)
        if role ~= ROLE_YETI then return end

        local roleColor = ROLE_COLORS[ROLE_YETI]
        local html = "The " .. ROLE_STRINGS[ROLE_YETI] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent</span> role whose job is to kill all of their enemies, both innocent and traitor, using their club."

        html = html .. "<span style='display: block; margin-top: 10px;'>When attacking a target with the club, the target will get <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>knocked back</span>.</span>"

        html = html .. "<span style='display: block; margin-top: 10px;'>If a player is hit by the " .. ROLE_STRINGS[ROLE_YETI] .. " club's freezing projectile, they will be <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>frozen in place</span> temporarily.</span>"

        return html
    end)

    hook.Add("TTTSprintStaminaPost", "RandomatYetiSprintPost", function()
        -- Infinite sprint through fixed infinite stamina
        return 100
    end)
end)

net.Receive("RandomatYetiEnd", function()
    hook.Remove("TTTScoringWinTitle", "RandomatYetiScoring")
    hook.Remove("TTTEventFinishText", "RandomatYetiEventFinishText")
    hook.Remove("TTTEventFinishIconText", "RandomatYetiEventFinishText")
    hook.Remove("TTTTutorialRoleEnabled", "RandomatYetiTutorialRoleEnabled")
    hook.Remove("TTTTutorialRoleText", "RandomatYetiTutorialRoleText")
    hook.Remove("TTTSprintStaminaPost", "RandomatYetiSprintPost")
end)