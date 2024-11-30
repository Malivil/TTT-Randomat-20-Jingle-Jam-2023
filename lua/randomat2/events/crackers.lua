local EVENT = {}

CreateConVar("randomat_crackers_item_blocklist", "", FCVAR_ARCHIVE, "Comma-separated list of weapon classnames to not give when a player wins a cracker (E.g. \"weapon_ttt_knife,weapon_ttt_harpoon\")")

local musicConvar = CreateConVar("randomat_crackers_music", "1", FCVAR_ARCHIVE, "Play music during this randomat", 0, 1)

EVENT.Title = "Christmas Crackers"
EVENT.Description = "Open your crackers and spread some Christmas cheer!"
EVENT.id = "crackers"

EVENT.Categories = {"item", "largeimpact"}

EVENT.Type = EVENT_TYPE_MUSIC
util.AddNetworkString("RandomatCrackersBegin")
util.AddNetworkString("RandomatCrackersEnd")
local crackerClass = "weapon_ttt_cracker"

-- Changes the texture of weapons or thrown grenades
local function SetCandyCaneTexture(ent, remove)
    if IsValid(ent) and (ent:IsWeapon() or (ent.Base and ent.Base == "ttt_basegrenade_proj")) then
        if remove then
            ent:SetMaterial("")
        else
            ent:SetMaterial("ttt_randomat_jingle_jam_2023/candy_cane")
        end
    end
end

function EVENT:Begin()
    -- Gives everyone a christmas cracker, containing a joke, paper hat and random item
    for _, ply in player.Iterator() do
        ply:Give(crackerClass)
        ply:SelectWeapon(crackerClass)
    end

    -- Apply a candy cane texture to every weapon
    for _, ent in ents.Iterator() do
        SetCandyCaneTexture(ent)
    end

    -- This hook is called by Gmod a little too early, entities are not fully created when this hook is called
    -- The 0 second timer is recommended by the Gmod wiki as a work-around
    self:AddHook("OnEntityCreated", function(ent)
        timer.Simple(0, function()
            SetCandyCaneTexture(ent)
        end)
    end)

    net.Start("RandomatCrackersBegin")
    net.WriteBool(musicConvar:GetBool())
    net.Broadcast()

    -- Disable round end sounds and 'Ending Flair' event so ending music can play
    if musicConvar:GetBool() then
        self:DisableRoundEndSounds()
    end
end

function EVENT:End()
    -- Remove the crackers and candy cane texture from every weapon in time with the music
    timer.Simple(5.34, function()
        for _, ent in ents.Iterator() do
            SetCandyCaneTexture(ent, true)

            if IsValid(ent) and ent:GetClass() == crackerClass then
                ent:Remove()
            end
        end
    end)
end

function EVENT:GetConVars()
    local checkboxes = {}

    for _, v in pairs({"music"}) do
        local name = "randomat_" .. self.id .. "_" .. v

        if ConVarExists(name) then
            local convar = GetConVar(name)

            table.insert(checkboxes, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = 0
            })
        end
    end

    return {}, checkboxes
end

Randomat:register(EVENT)