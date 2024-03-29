local EVENT = {}

local adminabuse_rate = CreateConVar("randomat_adminabuse_rate", 0.3, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "How often (in seconds) the Admin gains power", 0.01, 10)

EVENT.Title = "Admin Abuse"
EVENT.Description = "Turns the detective into an Admin with greatly increased admin power"
EVENT.id = "adminabuse"
EVENT.Categories = {"biased_innocent", "biased", "rolechange", "largeimpact"}

function EVENT:Begin()
    local detective = nil
    for _, p in ipairs(self:GetAlivePlayers(true)) do
        if Randomat:IsGoodDetectiveLike(p) then
            detective = p
            break
        end
    end

    -- Sanity check
    if not IsPlayer(detective) then return end

    self:StripRoleWeapons(detective)
    Randomat:SetRole(detective, ROLE_ADMIN)
    detective:Give("weapon_ttt_adm_menu")
    SendFullStateUpdate()

    local rate = adminabuse_rate:GetFloat()
    timer.Adjust("AdminPowerTimer", rate, 0, nil)
end

function EVENT:End()
    if timer.Exists("AdminPowerTimer") then
        local rate = cvars.Number("ttt_admin_power_rate", 1.5)
        timer.Adjust("AdminPowerTimer", rate, 0, nil)
    end
end

function EVENT:Condition()
    local has_detective = false
    for _, p in ipairs(self:GetAlivePlayers()) do
        if Randomat:IsGoodDetectiveLike(p) then
            has_detective = true
        end
    end

    return has_detective and Randomat:CanRoleSpawn(ROLE_ADMIN)
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"rate"}) do
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