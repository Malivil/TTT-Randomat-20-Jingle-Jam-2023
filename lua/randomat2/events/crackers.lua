local EVENT = {}

CreateConVar("randomat_crackers_item_blocklist", "", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Comma-separated list of weapon classnames to not give when a player wins a cracker")

EVENT.Title = "Christmas Crackers"
EVENT.Description = "Open your crackers and spread some Christmas cheer!"
EVENT.id = "crackers"

EVENT.Categories = {"item", "largeimpact"}

util.AddNetworkString("RandomatCrackersBegin")
util.AddNetworkString("RandomatCrackersEnd")
local crackerClass = "weapon_ttt_cracker"

function EVENT:Begin()
    -- Gives everyone a christmas cracker, containing a joke, paper hat and random item
    for _, ply in player.Iterator() do
        ply:Give(crackerClass)
        ply:SelectWeapon(crackerClass)
    end

    -- Apply a candy cane texture to every weapon that isn't the christmas cracker
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent:IsWeapon() and WEPS.GetClass(ent) ~= crackerClass then
            ent:SetMaterial("ttt_randomat_jingle_jam_2023/candy_cane.png")
        end
    end

    net.Start("RandomatCrackersBegin")
    net.Broadcast()
end

function EVENT:End()
    net.Start("RandomatCrackersEnd")
    net.Broadcast()
end

function EVENT:GetConVars()
    local textboxes = {}

    for _, v in ipairs({"item_blocklist"}) do
        local name = "randomat_" .. self.id .. "_" .. v

        if ConVarExists(name) then
            local convar = GetConVar(name)

            table.insert(textboxes, {
                cmd = v,
                dsc = convar:GetHelpText()
            })
        end
    end

    return {}, {}, textboxes
end

Randomat:register(EVENT)