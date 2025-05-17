local EVENT = {}

local yeti_scale = CreateConVar("randomat_yeti_scale", 1.5, FCVAR_NONE, "The scale factor to use for the yeti", 1.1, 3.0)
CreateConVar("randomat_yeti_freeze_time", 5, FCVAR_NONE, "The amount of time to freeze players hit by the club freezing projectile", 1, 30)

EVENT.Title = "Yeti Hunt"
EVENT.Description = "A Yeti has been spotted!"
EVENT.id = "yeti"
EVENT.Type = EVENT_TYPE_WEAPON_OVERRIDE
EVENT.Categories = {"rolechange", "entityspawn", "largeimpact"}

function EVENT:Initialize()
    timer.Simple(1, function()
        YETI:RegisterRole()
    end)
end

function EVENT:Begin()
    local yeti_scale_val = yeti_scale:GetFloat()
    local traitors = {}
    local special = nil
    local indep = nil
    -- Collect the traitors to potentially turn into a yeti
    for _, p in ipairs(self:GetAlivePlayers(true)) do
        if Randomat:IsTraitorTeam(p) then
            if p:GetRole() ~= ROLE_TRAITOR and special == nil then
                special = p
            end
            table.insert(traitors, p)
        elseif Randomat:IsIndependentTeam(p) then
            indep = p
        end
    end

    -- If we don't have a special traitor, choose a random player
    if special == nil then
        special = traitors[math.random(1, #traitors)]
    end

    -- Default the yeti to the independent player, but if there isn't one then use the chosen traitor instead
    local yeti = indep
    if not IsValid(yeti) then
        yeti = special
    end

    local yeti_health = GetConVar("ttt_yeti_max_health"):GetInt()
    local max_hp = yeti:GetMaxHealth()
    Randomat:SetRole(yeti, ROLE_YETI, false)
    yeti:SetMaxHealth(yeti_health)
    yeti:SetHealth(yeti_health - (max_hp - yeti:Health()))

    -- Reset FOV to unscope
    yeti:SetFOV(0, 0.2)
    yeti:StripWeapons()
    yeti:Give("weapon_yeti_club")

    Randomat:SetPlayerScale(yeti, yeti_scale_val, self.id)

    yeti:QueueMessage(MSG_PRINTBOTH, "You are the Yeti! Use your club to kill your enemies or freeze them in place!")
    SendFullStateUpdate()

    self:AddHook("TTTPrintResultMessage", function(win_type)
        if win_type == WIN_YETI then
            LANG.Msg("win_yeti")
            ServerLog("Result: The yeti wins.\n")
            return true
        end
    end)

    self:AddHook("TTTCheckForWin", function()
        local yeti_win = true
        for _, p in ipairs(self:GetAlivePlayers()) do
            -- If there is a living non-yeti then go back to the default check logic
            -- Exceptions for non-clown Jesters
            if not p:IsRole(ROLE_YETI) and (p:GetRole() == ROLE_CLOWN or not Randomat:IsJesterTeam(p)) then
                yeti_win = false
                break
            end
        end

        if yeti_win then
            return WIN_YETI
        end
    end)

    self:AddHook("PlayerCanPickupWeapon", function(ply, wep)
        -- Invalid, dead, spectator, and non-yetis can pick up whatever they want
        if not IsValid(ply) or not ply:Alive() or ply:IsSpec() or not ply:IsRole(ROLE_YETI) then
            return
        end
        -- The yeti can only use the club
        return IsValid(wep) and WEPS.GetClass(wep) == "weapon_yeti_club"
    end)

    self:AddHook("TTTCanOrderEquipment", function(ply, id, is_item)
        if not IsValid(ply) then return end
        if not ply:IsRole(ROLE_YETI) then return end
        if not is_item then
            ply:ChatPrint("You can only buy passive items during '" .. Randomat:GetEventTitle(EVENT) .. "'!\nYour purchase has been refunded.")
            return false
        end
    end)

    self:AddHook("TTTSprintStaminaPost", function(ply)
        if not ply:IsRole(ROLE_YETI) then return end

        -- Infinite sprint through fixed infinite stamina
        return 100
    end)

    self:AddHook("PlayerFootstep", function(ply, pos, foot, sound, volume, rf)
        if not IsValid(ply) or ply:IsSpec() or not ply:Alive() then return true end
        if ply:WaterLevel() ~= 0 then return end
        if not ply:IsRole(ROLE_YETI) then return end

        net.Start("TTT_PlayerFootstep")
            net.WritePlayer(ply)
            net.WriteVector(pos)
            net.WriteAngle(ply:GetAimVector():Angle())
            net.WriteBit(foot)
            net.WriteTable(COLOR_WHITE)
            -- Footstep display time
            net.WriteUInt(10, 8)
            net.WriteFloat(yeti_scale_val)
        net.Broadcast()
    end)
end

function EVENT:End()
    self:ResetAllPlayerScales()
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"freeze_time"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = 0
            })
        end
    end

    for _, v in ipairs({"scale"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = 1
            })
        end
    end
    return sliders
end

Randomat:register(EVENT)