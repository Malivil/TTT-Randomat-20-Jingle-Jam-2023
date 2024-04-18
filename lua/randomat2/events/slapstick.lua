local player = player

local PlayerIterator = player.Iterator

local EVENT = {}

local endsound = CreateConVar("randomat_slapstick_endsound", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Whether to play the sound at the end of the event")

EVENT.Title = "Slapstick"
EVENT.Description = "Swaps out game sounds with funny replacements"
EVENT.id = "slapstick"
EVENT.Type = EVENT_TYPE_GUNSOUNDS
EVENT.Categories = {"fun", "smallimpact"}

util.AddNetworkString("TriggerSlapstick")
util.AddNetworkString("EndSlapstick")

local StringFormat = string.format

-- Sound file paths
local beeping_sound_path = "slapstick/beeping/beeping%s.wav"
local blerg_sound_path = "slapstick/blerg/blerg%s.mp3"
local bones_cracking_sound_path = "slapstick/bones_cracking/bones_cracking%s.wav"
local door_opening_sound_path = "slapstick/door_opening/door_opening%s.wav"
local door_closing_sound_path = "slapstick/door_closing/door_closing%s.wav"
local explosion_sound_path = "slapstick/explosion/explosion%s.wav"
local footsteps_sound_path = "slapstick/footsteps/footsteps%s.mp3"
local gunshot_sound_path = "slapstick/weapons/gunshot/gunshot%s.wav"
local jump_sound_path = "slapstick/jump/jump%s.mp3"
local reload_sound_path = "slapstick/weapons/reload/reload%s.wav"
local smashing_glass_sound_path = "slapstick/smashing_glass/smashing_glass%s.wav"
local outro_sound_path = "slapstick/outro/outro%s.mp3"

-- Sound file counts
local beeping_sound_count = 1
local blerg_sound_count = 10
local bones_cracking_sound_count = 2
local door_opening_sound_count = 2
local door_closing_sound_count = 3
local explosion_sound_count = 4
local footsteps_sound_count = 4
local gunshot_sound_count = 5
local jump_sound_count = 4
local reload_sound_count = 1
local smashing_glass_sound_count = 1
local outro_sound_count = 2

-- Sound patterns and path-count mappings
local footsteps_pattern = ".*player/footsteps/.*%..*"
local reload_sounds = {reload_sound_path, reload_sound_count}
local death_sounds = {blerg_sound_path, blerg_sound_count}
local smashing_glass_sounds = {smashing_glass_sound_path, smashing_glass_sound_count}
local sound_mapping = {
    -- Footsteps
    [footsteps_pattern] = {footsteps_sound_path, footsteps_sound_count},
    -- Explosions
    [".*weapons/.*explode.*%..*"] = {explosion_sound_path, explosion_sound_count},
    -- C4 Beeps
    [".*weapons/.*beep.*%..*"] = {beeping_sound_path, beeping_sound_count},
    -- Glass breaking
    [".*physics/glass/.*break.*%..*"] = smashing_glass_sounds,
    [".*physics/glass/glass_impact_.*%..*"] = smashing_glass_sounds,
    -- Fall damage (which don't work when converted to MP3 for some reason)
    [".*player/damage*."] = {bones_cracking_sound_path, bones_cracking_sound_count},
    -- Player death
    [".*player/death.*"] = death_sounds,
    [".*vo/npc/male01/pain*."] = death_sounds,
    [".*vo/npc/barney/ba_pain*."] = death_sounds,
    [".*vo/npc/barney/ba_ohshit03.*"] = death_sounds,
    [".*vo/npc/barney/ba_no01.*"] = death_sounds,
    [".*vo/npc/male01/no02.*"] = death_sounds,
    [".*hostage/hpain/hpain.*"] = death_sounds,
    -- Reload
    [".*weapons/.*out%..*"] = reload_sounds,
    [".*weapons/.*in%..*"] = reload_sounds,
    [".*weapons/.*reload.*%..*"] = reload_sounds,
    [".*weapons/.*boltcatch.*%..*"] = reload_sounds,
    [".*weapons/.*insertshell.*%..*"] = reload_sounds,
    [".*weapons/.*selectorswitch.*%..*"] = reload_sounds,
    [".*weapons/.*rattle.*%..*"] = reload_sounds,
    [".*weapons/.*lidopen.*%..*"] = reload_sounds,
    [".*weapons/.*fetchmag.*%..*"] = reload_sounds,
    [".*weapons/.*beltjingle.*%..*"] = reload_sounds,
    [".*weapons/.*beltalign.*%..*"] = reload_sounds,
    [".*weapons/.*lidclose.*%..*"] = reload_sounds,
    [".*weapons/.*magslap.*%..*"] = reload_sounds
}

local function DoorIsOpen(door)
    if not IsValid(door) then return false end

    local doorClass = door:GetClass()
    if doorClass == "func_door" or doorClass == "func_door_rotating" then
        return door:GetInternalVariable("m_toggle_state") == 0
    elseif doorClass == "prop_door_rotating" then
        return door:GetInternalVariable("m_eDoorState") ~= 0
    end
    return false
end

function EVENT:Initialize()
    local function PrecacheSounds(path, count)
        for i=1,count do
            util.PrecacheSound(StringFormat(path, i))
        end
    end

    PrecacheSounds(beeping_sound_path, beeping_sound_count)
    PrecacheSounds(blerg_sound_path, blerg_sound_count)
    PrecacheSounds(bones_cracking_sound_path, bones_cracking_sound_count)
    PrecacheSounds(door_opening_sound_path, door_opening_sound_count)
    PrecacheSounds(door_closing_sound_path, door_closing_sound_count)
    PrecacheSounds(explosion_sound_path, explosion_sound_count)
    PrecacheSounds(footsteps_sound_path, footsteps_sound_count)
    PrecacheSounds(gunshot_sound_path, gunshot_sound_count)
    PrecacheSounds(jump_sound_path, jump_sound_count)
    PrecacheSounds(reload_sound_path, reload_sound_count)
    PrecacheSounds(smashing_glass_sound_path, smashing_glass_sound_count)
    PrecacheSounds(outro_sound_path, outro_sound_count)
end

local started = false
function EVENT:Begin()
    started = true
    if endsound:GetBool() then
        self:DisableRoundEndSounds()
    end

    net.Start("TriggerSlapstick")
    net.Broadcast()

    for _, ply in PlayerIterator() do
        for _, wep in ipairs(ply:GetWeapons()) do
            local chosen_sound = StringFormat(gunshot_sound_path, math.random(gunshot_sound_count))
            Randomat:OverrideWeaponSound(wep, chosen_sound)
        end
    end

    self:AddHook("WeaponEquip", function(wep, ply)
        timer.Create("SlapstickDelay", 0.1, 1, function()
            net.Start("TriggerSlapstick")
            net.Send(ply)
            local chosen_sound = StringFormat(gunshot_sound_path, math.random(gunshot_sound_count))
            Randomat:OverrideWeaponSound(wep, chosen_sound)
        end)
    end)

    self:AddHook("EntityEmitSound", function(data)
        local current_sound = data.SoundName:lower()
        local new_sound = nil
        for pattern, sounds in pairs(sound_mapping) do
            if string.find(current_sound, pattern) then
                -- If this is a player "footstep"-ing in mid-air, they are jumping or using a ladder
                if footsteps_pattern == pattern and IsPlayer(data.Entity) and not data.Entity:IsOnGround() then
                    -- Don't replace the sound if the player is on a ladder
                    if data.Entity:GetMoveType() ~= MOVETYPE_LADDER then
                        new_sound = StringFormat(jump_sound_path, math.random(jump_sound_count))
                    end
                else
                    local sound_path = sounds[1]
                    local sound_index = math.random(sounds[2])
                    new_sound = StringFormat(sound_path, sound_index)
                end
                break
            end
        end

        if new_sound then
            data.SoundName = new_sound
            return true
        -- Door opening/closing
        elseif current_sound == "doors/default_move.wav" then
            if DoorIsOpen(data.Entity) then
                data.SoundName = StringFormat(door_closing_sound_path, math.random(door_closing_sound_count))
            else
                data.SoundName = StringFormat(door_opening_sound_path, math.random(door_opening_sound_count))
            end
            -- Increase the volume of these so they can be heard
            data.Volume = 2
            data.SoundLevel = 100
            return true
        else
            local chosen_sound = StringFormat(gunshot_sound_path, math.random(gunshot_sound_count))
            return Randomat:OverrideWeaponSoundData(data, chosen_sound)
        end
    end)
end

function EVENT:End()
    if not started then return end

    started = false

    local postround = GetConVar("ttt_posttime_seconds"):GetInt()

    net.Start("EndSlapstick")
    net.WriteBool(endsound:GetBool())
    net.WriteUInt(math.random(outro_sound_count), 2)
    net.WriteUInt(postround, 8)
    net.Broadcast()

    timer.Simple(postround / 2, function()
        Randomat:Notify("That's all folks!", postround / 2, nil, true, true, COLOR_WHITE)
    end)

    timer.Remove("SlapstickDelay")

    for _, ply in PlayerIterator() do
        for _, wep in ipairs(ply:GetWeapons()) do
            Randomat:RestoreWeaponSound(wep)
        end
    end
end

function EVENT:GetConVars()
    local checks = {}
    for _, v in ipairs({"endsound"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(checks, {
                cmd = v,
                dsc = convar:GetHelpText()
            })
        end
    end
    return {}, checks
end

Randomat:register(EVENT)