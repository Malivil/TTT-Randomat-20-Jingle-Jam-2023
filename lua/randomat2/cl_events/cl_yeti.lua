local EVENT = {}
EVENT.id = "yeti"

function EVENT:Initialize()
    timer.Simple(1, function()
        YETI:RegisterRole()
    end)
end

function EVENT:Begin()
    self:AddHook("TTTScoringWinTitle", function(wintype, wintitle, title)
        if wintype == WIN_YETI then
            return { txt = "hilite_win_role_singular", params = { role = ROLE_STRINGS[ROLE_YETI]:upper() }, c = ROLE_COLORS[ROLE_YETI] }
        end
    end)

    self:AddHook("TTTEventFinishText", function(e)
        if e.win == WIN_YETI then
            return LANG.GetTranslation("ev_win_yeti")
        end
    end)

    self:AddHook("TTTEventFinishIconText", function(e, win_string, role_string)
        if e.win == WIN_YETI then
            return win_string, ROLE_STRINGS[ROLE_YETI]
        end
    end)

    -- Enable the tutorial page for this role when the event is running
    self:AddHook("TTTTutorialRoleEnabled", function(role)
        if role == ROLE_YETI and Randomat:IsEventActive("yeti") then
            return true
        end
    end)

    self:AddHook("TTTTutorialRoleText", function(role, titleLabel)
        if role ~= ROLE_YETI then return end

        local roleColor = ROLE_COLORS[ROLE_YETI]
        local html = "The " .. ROLE_STRINGS[ROLE_YETI] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent</span> role whose job is to kill all of their enemies, both innocent and traitor, using their club."

        html = html .. "<span style='display: block; margin-top: 10px;'>When attacking a target with the club, the target will get <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>knocked back</span>.</span>"

        html = html .. "<span style='display: block; margin-top: 10px;'>If a player is hit by the " .. ROLE_STRINGS[ROLE_YETI] .. " club's freezing projectile, they will be <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>frozen in place</span> temporarily.</span>"

        return html
    end)

    self:AddHook("TTTSprintStaminaPost", function()
        -- Infinite sprint through fixed infinite stamina
        return 100
    end)

    if GetConVar("randomat_yeti_blizzard"):GetBool() then
        -- If the local player is a Yeti and they arne't affected by the blizzard then don't bother with this stuff
        if IsPlayer(Randomat.Client) and Randomat.Client:IsRole(ROLE_YETI) and not GetConVar("randomat_yeti_blizzard_affects_yeti"):GetBool() then return end

        local start = GetConVar("randomat_yeti_blizzard_start"):GetInt()
        local function IsHidden(cli, ply)
            -- Magic number to scale this distance to the fog distance even though they supposedly use the same unit
            local scale = 12.4
            local dist = cli:GetPos():Distance(ply:GetPos())
            return dist / scale > start
        end

        -- Hide all of the info shown in the target ID on mouse over
        self:AddHook("TTTTargetIDPlayerBlockInfo", function(ply, cli)
            if IsHidden(cli, ply, start) then
                return true
            end
        end)

        --Limits the player's view distance like in among us
        self:AddHook("SetupWorldFog", function()
            render.FogMode(MATERIAL_FOG_LINEAR)
            render.FogColor(255, 255, 255)
            render.FogMaxDensity(1)
            render.FogStart(start)
            render.FogEnd(600)

            return true
        end)

        --If a map has a 3D skybox, apply a fog effect to that too
        self:AddHook("SetupSkyboxFog", function(scale)
            render.FogMode(MATERIAL_FOG_LINEAR)
            render.FogColor(255, 255, 255)
            render.FogMaxDensity(1)
            render.FogStart(start * scale)
            render.FogEnd(600 * scale)

            return true
        end)

        net.Receive("RdmtYetiDeath", function()
            self:RemoveHook("TTTTargetIDPlayerBlockInfo")
            self:RemoveHook("SetupWorldFog")
            self:RemoveHook("SetupSkyboxFog")
        end)
    end
end

Randomat:register(EVENT)