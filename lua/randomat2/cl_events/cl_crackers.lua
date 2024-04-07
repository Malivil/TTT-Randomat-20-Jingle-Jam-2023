local music

net.Receive("RandomatCrackersBegin", function()
    hook.Add("PreDrawViewModel", "CrackersRandomatCandyCaneTexture", function(vm, _, wep)
        vm:SetMaterial("ttt_randomat_jingle_jam_2023/candy_cane.png")
    end)

    local mat = Material("ttt_randomat_jingle_jam_2023/white_vignette")

    hook.Add("RenderScreenspaceEffects", "CrackersRandomatScreenEffect", function()
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
    end)

    music = net.ReadBool()

    if music then
        for i = 1, 2 do
            surface.PlaySound("crackers/christmas_rap.mp3")
        end

        timer.Create("CrackersRandomatMusicLoop", 175.99, 0, function()
            for i = 1, 2 do
                surface.PlaySound("crackers/christmas_rap.mp3")
            end
        end)

        timer.Simple(5, function()
            chat.AddText("Press 'M' to mute music")
        end)

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
    end

    hook.Remove("PreDrawViewModel", "CrackersRandomatCandyCaneTexture")
    hook.Remove("HUDPaintBackground", "CrackersRandomatScreenEffect")
end)