net.Receive("RandomatCrackersBegin", function()
    hook.Add("PreDrawViewModel", "CrackersRandomatCandyCaneTexture", function(vm, _, wep)
        vm:SetMaterial("ttt_randomat_jingle_jam_2023/candy_cane.png")
    end)
end)

net.Receive("RandomatCrackersEnd", function()
    hook.Remove("PreDrawViewModel", "CrackersRandomatCandyCaneTexture")
end)