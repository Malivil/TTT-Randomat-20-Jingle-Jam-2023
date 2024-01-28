local EVENT = {}

local math = math

local MathMax = math.max
local MathMin = math.min
local MathRound = math.Round

local deteggtive_health = CreateConVar("randomat_deteggtive_health", 200, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "How much health the deteggtive should have", 100, 300)
local deteggtive_speed_mult = CreateConVar("randomat_deteggtive_speed_mult", 0.8, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "The deteggtive's speed multiplier (e.g. 0.8 = 80% of normal speed)", 0.1, 2.0)

EVENT.Title = "Hard Boiled Det-EGG-tive"
EVENT.Description = ""
EVENT.id = "deteggtive"
EVENT.Type = EVENT_TYPE_WEAPON_OVERRIDE
EVENT.Categories = {"moderateimpact", "modelchange"}

function EVENT:Begin()
    local detective = nil
    for _, p in ipairs(self:GetAlivePlayers(true)) do
        if Randomat:IsGoodDetectiveLike(p) then
            detective = p
        end
    end

    -- Sanity check
    if not IsPlayer(detective) then return end

    local maxhealth = detective:GetMaxHealth()
    local health = detective:Health()
    local healthscale = health / maxhealth
    local newmaxhealth = deteggtive_health:GetInt()
    detective:SetMaxHealth(newmaxhealth)

    -- Scale the player's health to match their new max
    -- If they were at 100/100 before, they'll be at 150/150 now
    local newhealth = MathMax(MathMin(newmaxhealth, MathRound(newmaxhealth * healthscale, 0)), 1)
    detective:SetHealth(newhealth)

    local speed_mult = deteggtive_speed_mult:GetFloat()
    -- Reduce the player speed on the client
    net.Start("RdmtSetSpeedMultiplier")
    net.WriteFloat(speed_mult)
    net.WriteString("RdmtDeteggtiveSpeed")
    net.Send(detective)

    self:AddHook("TTTSpeedMultiplier", function(ply, mults)
        if not ply:Alive() or ply:IsSpec() then return end
        if ply ~= detective then return end
        table.insert(mults, speed_mult)
    end)

    -- Remove all weapons they aren't allowed to use anymore
    for _, wep in ipairs(detective:GetWeapons()) do
        if not IsValid(wep) or Randomat:IsWeaponBuyable(wep) then continue end
        if wep.Category == WEAPON_CATEGORY_ROLE then continue end

        local wep_class = WEPS.GetClass(wep)
        if wep_class == "weapon_zm_carry" or wep_class == "weapon_zm_improvised" or wep_class == "weapon_ttt_unarmed" then continue end

        detective:StripWeapon(wep_class)
    end

    -- TODO: Change their model

    -- Prevent them from picking up non-buyable weapons
    self:AddHook("PlayerCanPickupWeapon", function(ply, wep)
        -- Invalid, dead, spectator, and non-detectives can pick up whatever they want
        if not IsValid(ply) or not ply:Alive() or ply:IsSpec() or ply ~= detective then
            return
        end
        -- The detective can only use buyable weapons and the revolver
        return IsValid(wep) and (Randomat:IsWeaponBuyable(wep) or WEPS.GetClass(wep) == "weapon_ttt_randomatrevolver")
    end)

    -- Give them an infinite-ammo revolver
    local revolver = detective:Give("weapon_ttt_randomatrevolver")
    if IsValid(revolver) then
        revolver.ForceReload = false
        revolver.Primary.Delay = 1
    end
end

function EVENT:End()
    -- Reset the player speed on the client
    net.Start("RdmtRemoveSpeedMultiplier")
    net.WriteString("RdmtDeteggtiveSpeed")
    net.Broadcast()
end

function EVENT:Condition()
    local has_detective = false
    for _, p in ipairs(self:GetAlivePlayers()) do
        if Randomat:IsGoodDetectiveLike(p) then
            has_detective = true
        end
    end

    return has_detective
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"health"}) do
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

    for _, v in ipairs({"speed_mult"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = 2
            })
        end
    end
    return sliders
end

Randomat:register(EVENT)