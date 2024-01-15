--// Logan Christianson

local Players = {}

net.Receive("StartPokerRandomat", function()
    local numPlayers = net.ReadUInt(3)

    for i = 1, numPlayers do
        table.insert(Players, net.ReadEntity())
    end

    if table.KeyFromValue(LocalPlayer()) then
        net.Start("StartPokerRandomatCallback")
        net.SendToServer()
    end
end)

net.Receive("StartPokerRandomatCallback", function()

end)

net.Receive("NotifyBlinds", function()

end)

net.Receive("DealCards", function()

end)

net.Receive("StartBetting", function()

end)

net.Receive("MakeBet", function()

end)

net.Receive("PlayerFolded", function()

end)

net.Receive("PlayerChecked", function()

end)

net.Receive("PlayerCalled", function()

end)

net.Receive("PlayerRaised", function()

end)

net.Receive("StartDiscard", function()

end)

net.Receive("PlayersFinishedBetting", function()

end)

net.Receive("MakeDiscard", function()

end)

net.Receive("RevealHands", function()

end)

net.Receive("DeclareWinner", function()

end)

net.Receive("ClosePokerWindow", function()

end)
