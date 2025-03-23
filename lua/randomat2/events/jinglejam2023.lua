local EVENT = {}

local ipairs = ipairs

util.AddNetworkString("RdmtJingleJam2023Begin")

local time = CreateConVar("randomat_jinglejam2023_time", 30, FCVAR_NONE, "How long to jam player screens for", 5, 120)
local targetall = CreateConVar("randomat_jinglejam2023_targetall", 0, FCVAR_NONE, "Whether to target all players. If disabled, only non-innocents are targeted", 0, 1)

EVENT.Title = "Jingle Jam 2023"
EVENT.Description = "\"There's only one man who would DARE give me the raspberry\""
EVENT.id = "jinglejam2023"
EVENT.Categories = {"biased_innocent", "biased", "moderateimpact"}

local function IsTarget(ply)
    if not ply:Alive() or ply:IsSpec() then return false end
    if targetall:GetBool() then return true end
    if Randomat:IsInnocentTeam(ply) then return false end
    return true
end

function EVENT:Begin()
    net.Start("RdmtJingleJam2023Begin")
    net.WriteUInt(time:GetInt(), 8)
    net.WriteBool(targetall:GetBool())
    net.Broadcast()

    local endTime = CurTime() + time:GetInt()
    self:AddHook("TTTCanOrderEquipment", function(ply, id, is_item)
        if CurTime() >= endTime then return end
        if not IsValid(ply) then return end
        if not IsTarget(ply) then return end

        if is_item == EQUIP_RADAR then
            ply:ChatPrint("Radars are disabled while you are jammed!\nYour purchase has been refunded.")
            return false
        end
    end)
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"time"}) do
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

    local checks = {}
    for _, v in ipairs({"targetall"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(checks, {
                cmd = v,
                dsc = convar:GetHelpText()
            })
        end
    end
    return sliders, checks
end

Randomat:register(EVENT)