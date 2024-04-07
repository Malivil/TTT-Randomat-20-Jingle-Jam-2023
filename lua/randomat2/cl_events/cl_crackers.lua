local music

net.Receive("RandomatCrackersBegin", function()
    -- Applies the candy cane texture for weapons in your hands
    local client = LocalPlayer()

    if IsValid(client) then
        local vm = client:GetViewModel()

        if IsValid(vm) then
            vm:SetMaterial("ttt_randomat_jingle_jam_2023/candy_cane")
        end
    end

    -- Adds a "cold" screen effect
    local mat = Material("ttt_randomat_jingle_jam_2023/white_vignette")

    hook.Add("HUDPaintBackground", "CrackersRandomatScreenEffect", function()
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
    end)

    -- Plays christmassy music on a loop
    music = net.ReadBool()

    if music then
        surface.PlaySound("crackers/christmas_rap.mp3")

        timer.Create("CrackersRandomatMusicLoop", 175.99, 0, function()
            surface.PlaySound("crackers/christmas_rap.mp3")
        end)

        timer.Simple(5, function()
            chat.AddText("Press 'M' to mute music")
        end)

        -- Prevents the music from playing, looping again, and the ending music from playing as well
        hook.Add("PlayerButtonDown", "CrackersMuteMusicButton", function(ply, button)
            if button == KEY_M then
                RunConsoleCommand("stopsound")
                chat.AddText("Music muted")
                music = false
                timer.Remove("CrackersRandomatMusicLoop")
                hook.Remove("PlayerButtonDown", "CrackersMuteMusicButton")
            end
        end)
    end
end)

net.Receive("RandomatCrackersEnd", function()
    -- Plays the ending music
    if music then
        timer.Remove("CrackersRandomatMusicLoop")
        RunConsoleCommand("stopsound")

        timer.Simple(0.1, function()
            surface.PlaySound("crackers/christmas_rap_end.mp3")
        end)

        music = false
    end

    -- Remove effects in time with the ending music
    timer.Simple(5.34, function()
        hook.Remove("PlayerButtonDown", "CrackersMuteMusicButton")
        hook.Remove("HUDPaintBackground", "CrackersRandomatScreenEffect")
        -- Removes the candy cane texture for held weapons
        local client = LocalPlayer()

        if IsValid(client) then
            local vm = client:GetViewModel()

            if IsValid(vm) then
                vm:SetMaterial("")
            end
        end
    end)
end)