local StringFormat = string.format

local EVENT = {}
EVENT.id = "slapstick"

-- Sound file paths
local beeping_sound_path = "slapstick/beeping/beeping%s.wav"
local blerg_sound_path = "slapstick/blerg/blerg%s.mp3"
local bones_cracking_sound_path = "slapstick/bones_cracking/bones_cracking%s.wav"
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
local explosion_sound_count = 4
local footsteps_sound_count = 4
local gunshot_sound_count = 5
local jump_sound_count = 4
local reload_sound_count = 1
local smashing_glass_sound_count = 1

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

local function UpdateWeaponSounds()
    local client = LocalPlayer()
    if not IsValid(client) then return end

    for _, wep in ipairs(client:GetWeapons()) do
        local chosen_sound = StringFormat(gunshot_sound_path, math.random(gunshot_sound_count))
        Randomat:OverrideWeaponSound(wep, chosen_sound)
    end
end

function EVENT:Begin()
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
        else
            local chosen_sound = StringFormat(gunshot_sound_path, math.random(gunshot_sound_count))
            return Randomat:OverrideWeaponSoundData(data, chosen_sound)
        end
    end)

    UpdateWeaponSounds()
end

Randomat:register(EVENT)

local function DrawCircle(x, y, radius, seg)
    local cir = {}
    for i = 0, seg do
        local a = math.rad((i / seg) * -360)
        table.insert(cir, { x = x + math.sin(a) * radius, y = y + math.cos(a) * radius, u = math.sin(a) / 2 + 0.5, v = math.cos(a) / 2 + 0.5 })
    end
    surface.DrawPoly(cir)
end

net.Receive("RdmtSlapstickEnd", function()
    local playoutro = net.ReadBool()
    local outro = net.ReadUInt(2)
    local postround = net.ReadUInt(8)
    local starttime = CurTime()
    local endtime = starttime + (postround / 2)

    -- Do outro song if its enabled
    if playoutro then
        surface.PlaySound(StringFormat(outro_sound_path, outro))
    end

    -- And print outro circle
    hook.Add("HUDPaint", "SlapstickHUDPaint", function()
        local stencil = CurTime() < endtime
        if stencil then
            -- Reset everything to known good
            render.SetStencilWriteMask(0xFF)
            render.SetStencilTestMask(0xFF)
            render.SetStencilReferenceValue(0)
            render.SetStencilCompareFunction(STENCIL_ALWAYS)
            render.SetStencilPassOperation(STENCIL_KEEP)
            render.SetStencilFailOperation(STENCIL_KEEP)
            render.SetStencilZFailOperation(STENCIL_KEEP)
            render.ClearStencil()

            -- Enable stencils
            render.SetStencilEnable(true)
            -- Set everything so it draws to the stencil buffer instead of the screen
            render.SetStencilReferenceValue(1)
            render.SetStencilCompareFunction(STENCIL_NEVER)
            render.SetStencilFailOperation(STENCIL_REPLACE)

            draw.NoTexture()
            surface.SetDrawColor(COLOR_WHITE)
            DrawCircle(ScrW() / 2, ScrH() / 2, ScrW() - (ScrW() * ((CurTime() - starttime) / (endtime - starttime))), 100)

            -- Only draw things that are not in the stencil buffer
            render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
            render.SetStencilFailOperation(STENCIL_KEEP)
        end

        -- Draw the background
        surface.SetDrawColor(COLOR_BLACK)
        surface.DrawRect(0, 0, ScrW(), ScrH())

        if stencil then
            -- Let everything render normally again
            render.SetStencilEnable(false)
        end
    end)
    timer.Simple(postround, function()
        hook.Remove("HUDPaint", "SlapstickHUDPaint")
    end)

    local client = LocalPlayer()
    if not IsValid(client) then return end

    for _, wep in ipairs(client:GetWeapons()) do
        Randomat:RestoreWeaponSound(wep)
    end
end)

net.Receive("RdmtSlapstickUpdateWeaponSounds", UpdateWeaponSounds)