--// Logan Christianson

local EVENT = {}

EVENT.Self = LocalPlayer()
EVENT.Players = {}
EVENT.IsPlaying = false

function EVENT:SetupPanel()
    -- Set up the base panel here
    self.PanelActive = true

    self.PokerMain = vgui.Create("DFrame", nil, "Poker Randomat Frame")
    self.PokerMain:SetSize(500, 500)
    self.PokerMain:SetPos(ScrW() - self.PokerMain:GetWide(), 200)
    self.PokerMain:SetTitle("")
	self.PokerMain:SetVisible(true)
	self.PokerMain:SetDraggable(false)
	self.PokerMain:ShowCloseButton(false)
    self.PokerMain.Paint = function()
        --Set background color here?
    end

    self.PokerPlayers = vgui.Create("Poker_AllPlayerCards", self.PokerMain)
    self.PokerPlayers:SetPlayers(self.Players)
end

function EVENT:ClosePanel()
    self.PanelActive = false
    self.PokerMain:Close()
end

function EVENT:RegisterPlayers(newPlayersTbl, selfIsIncluded)
    self.IsPlaying = selfIsIncluded
    self.Players = newPlayersTbl

    if self.IsPlaying and not self.PanelActive then
        self:SetupPanel()
    end
end

net.Receive("StartPokerRandomat", function()
    local players = []
    local selfIsPlaying = false

    local numPlayers = net.ReadUInt(3)
    for i = 1, numPlayers do
        local ply = net.ReadEntity()

        table.insert(players, ply)

        if ply == EVENT.Self then
            selfIsPlaying = true
        end
    end

    -- TODO probably sort the players table so the "first" in it is the player to the "left" of LocalPlayer

    EVENT:RegisterPlayers(players, selfIsPlaying)

    if selfIsPlaying then
        net.Start("StartPokerRandomatCallback")
        net.SendToServer()
    end
end)

net.Receive("NotifyBlinds", function()
    if not EVENT.IsPlaying then return end

    local smallBlind = net.ReadEntity()
    local bigBlind = net.ReadEntity()
end)

net.Receive("DealCards", function()
    if not EVENT.IsPlaying then return end

end)

net.Receive("StartBetting", function()
    if not EVENT.IsPlaying then return end

end)

net.Receive("MakeBet", function()
    if not EVENT.IsPlaying then return end

end)

net.Receive("PlayerFolded", function()
    if not EVENT.IsPlaying then return end

end)

net.Receive("PlayerChecked", function()
    if not EVENT.IsPlaying then return end

end)

net.Receive("PlayerCalled", function()
    if not EVENT.IsPlaying then return end

end)

net.Receive("PlayerRaised", function()
    if not EVENT.IsPlaying then return end

end)

net.Receive("StartDiscard", function()
    if not EVENT.IsPlaying then return end

end)

net.Receive("PlayersFinishedBetting", function()
    if not EVENT.IsPlaying then return end

end)

net.Receive("MakeDiscard", function()
    if not EVENT.IsPlaying then return end

end)

net.Receive("RevealHands", function()
    if not EVENT.IsPlaying then return end

end)

net.Receive("DeclareWinner", function()
    if not EVENT.IsPlaying then return end

end)

net.Receive("ClosePokerWindow", function()
    if not EVENT.IsPlaying then return end

end)
