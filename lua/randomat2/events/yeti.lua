local ipairs = ipairs
local math = math
local net = net
local player = player
local table = table
local timer = timer

local PlayerIterator = player.Iterator

util.AddNetworkString("RdmtYetiDeath")

local EVENT = {}

local yeti_scale = CreateConVar("randomat_yeti_scale", 1.5, FCVAR_NONE, "The scale factor to use for the yeti", 1.1, 3.0)
CreateConVar("randomat_yeti_freeze_time", 5, FCVAR_NONE, "The amount of time to freeze players hit by the club freezing projectile", 1, 30)
local blizzard_end_on_death = CreateConVar("randomat_yeti_blizzard_end_on_death", 1, FCVAR_NONE, "Whether the blizzard ends when the Yeti dies", 0, 1)
local blizzard_damage_interval = CreateConVar("randomat_yeti_blizzard_damage_interval", 5, FCVAR_NONE, "How often (in seconds) all non-Yetis should take blizzard damage", 1, 180)
local blizzard_damage_amount = CreateConVar("randomat_yeti_blizzard_damage_amount", 1, FCVAR_NONE, "How much damage each non-Yeti should take during the blizzard", 0, 25)
local blizzard_damage_jesters = CreateConVar("randomat_yeti_blizzard_damage_jesters", 0, FCVAR_NONE, "Whether the blizzard also damages jester team members", 0, 1)
local blizzard_damage_passives = CreateConVar("randomat_yeti_blizzard_damage_passives", 0, FCVAR_NONE, "Whether the blizzard also damages roles with passive wins (e.g. Old Man)", 0, 1)

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
    local innocents = {}
    local special = nil
    local indep = nil
    -- Collect the innocents to potentially turn into a yeti
    for _, p in ipairs(self:GetAlivePlayers(true)) do
        if Randomat:IsInnocentTeam(p) and not Randomat:IsDetectiveTeam(p) then
            if p:GetRole() ~= ROLE_INNOCENT and special == nil then
                special = p
            end
            table.insert(innocents, p)
        elseif Randomat:IsIndependentTeam(p) then
            indep = p
        end
    end

    -- If we don't have a special innocent, choose a random player
    if special == nil then
        special = innocents[math.random(1, #innocents)]
    end

    -- Default the yeti to the independent player, but if there isn't one then use the chosen innocent instead
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
        local yeti_alive = false
        local other_alive = false
        for _, p in ipairs(self:GetAlivePlayers()) do
            if p:IsActive() then
                if p:GetRole() == ROLE_YETI then
                    yeti_alive = true
                elseif not p:ShouldActLikeJester() and not ROLE_HAS_PASSIVE_WIN[p:GetRole()] then
                    other_alive = true
                end
            end
        end

        if yeti_alive and not other_alive then
            return WIN_YETI
        elseif yeti_alive then
            return WIN_NONE
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

    if GetConVar("randomat_yeti_blizzard"):GetBool() then
        local interval = blizzard_damage_interval:GetInt()
        local amount = blizzard_damage_amount:GetInt()
        local damage_jesters = blizzard_damage_jesters:GetBool()
        local damage_passives = blizzard_damage_passives:GetBool()
        timer.Create("RdmtYetiBlizzardDamage", interval, 0, function()
            for _, p in PlayerIterator() do
                if not IsPlayer(p) then continue end
                if not p:Alive() or p:IsSpec() then continue end
                if p:IsRole(ROLE_YETI) then continue end
                if not damage_jesters and p:ShouldActLikeJester() then continue end
                if not damage_passives and ROLE_HAS_PASSIVE_WIN[p:GetRole()] then continue end

                local dmginfo = DamageInfo()
                dmginfo:SetDamageType(DMG_SLASH)
                dmginfo:SetDamage(amount)
                dmginfo:SetAttacker(yeti)
                dmginfo:SetInflictor(game.GetWorld())
                dmginfo:SetDamageForce(Vector(0, 0, 1))
                p:TakeDamageInfo(dmginfo)
            end
        end)

        if blizzard_end_on_death:GetBool() then
            self:AddHook("PlayerDeath", function(ply, infl, att)
                if ply ~= yeti then return end
                self:RemoveHook("PlayerDeath")
                timer.Remove("RdmtYetiBlizzardDamage")
                net.Start("RdmtYetiDeath")
                net.Broadcast()
            end)
        end
    end
end

function EVENT:End()
    self:ResetAllPlayerScales()
    timer.Remove("RdmtYetiBlizzardDamage")
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"freeze_time", "blizzard_damage_interval", "blizzard_damage_amount", "blizzard_start"}) do
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

    local checks = {}
    for _, v in ipairs({"blizzard", "blizzard_affects_yeti", "blizzard_damage_jesters", "blizzard_damage_passives", "blizzard_end_on_death"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(checks, {
                cmd = v,
                dsc = convar:GetHelpText()
            })
        end
    end

    local layout = {
        ["scale"] = 1,
        ["freeze_time"] = 2,
        ["Blizzard"] = {
            pos = 3,
            items = {
                "blizzard",
                "blizzard_end_on_death",
                "blizzard_start",
                "blizzard_affects_yeti",
                "blizzard_damage_interval",
                "blizzard_damage_amount",
                "blizzard_damage_jesters",
                "blizzard_damage_passives"
            }
        }
    }

    return sliders, checks, {}, layout
end

Randomat:register(EVENT)