--// Logan Christianson

local EVENT = {}

EVENT.Players = {}
EVENT.Hand = {}
EVENT.IsPlaying = false
EVENT.CurrentlyBetting = false

function EVENT:SetupPanel()
    self.PanelActive = true

    self.PokerMain = vgui.Create("Poker_Frame", nil, "Poker Randomat Frame")
    self.PokerMain:SetSize(375, 500)
    self.PokerMain:SetPos(ScrW() - self.PokerMain:GetWide(), 200)
    self.PokerMain:ShowCloseButton(false)
    self.PokerMain:SetTitle("")

    self.PokerPlayers = vgui.Create("Poker_AllPlayerPanels", self.PokerMain)
    self.PokerPlayers:SetPos(0, 0)
    self.PokerPlayers:SetSize(self.PokerMain:GetWide(), 200)
    self.PokerPlayers:SetPlayers(self.Players)
end

function EVENT:ClosePanel()
    self.PanelActive = false

    if self.PokerMain and self.PokerMain:IsValid() then
        self.PokerMain:Remove()
        self.PokerMain = nil
    end

    self.Players = {}
    self.Hand = {}
    self.IsPlaying = false
    self.CurrentlyBetting = false
end

function EVENT:RegisterPlayers(newPlayersTbl, selfIsIncluded)
    self.IsPlaying = selfIsIncluded
    self.Players = newPlayersTbl

    if self.IsPlaying and not self.PanelActive then
        self:SetupPanel()
    end
end

function EVENT:AlertBlinds(bigBlind, littleBlind)
    local textToDisplay = ""

    if bigBlind == self.Self then
        textToDisplay = "YOU ARE THE BIG BLIND!\nHalf of your HP has been\nadded to the pot automatically."
    else
        textToDisplay = "The Big Blind is: " .. bigBlind:Nick()
    end

    textToDisplay = textToDisplay .. "\n\n"

    if littleBlind == self.Self then
        textToDisplay = textToDisplay .. "YOU ARE THE LITTLE BLIND!\nA quarter of your HP has been\nadded to the pot automatically."
    else
        textToDisplay = textToDisplay .. "The Little Blind is: " .. littleBlind:Nick()
    end

    self.PokerMain:TemporaryMessage(textToDisplay)
    self.PokerPlayers:SetBlinds(littleBlind, bigBlind)
    self:RegisterBet(littleBlind, BettingStatus.RAISE, Bets.QUARTER)
    self:RegisterBet(bigBlind, BettingStatus.RAISE, Bets.HALF)
end

function EVENT:SetupHand()
    if not self.PokerControls or not self.PokerControls:IsValid() then
        self.PokerControls = vgui.Create("Poker_Controls", self.PokerMain)
        self.PokerControls:SetPos(0, self.PokerPlayers:GetTall())
        self.PokerControls:SetSize(self.PokerMain:GetWide(), 100)
        self.PokerControls:Setup()
    end

    if not self.PokerHand or not self.PokerHand:IsValid() then
        self.PokerHand = vgui.Create("Poker_Hand", self.PokerMain)
        self.PokerHand:SetPos(0, self.PokerPlayers:GetTall() + 100)
        self.PokerHand:SetSize(self.PokerMain:GetWide(), 200)
    end

    self.PokerHand:SetHand(self.Hand)
end

function EVENT:StartBetting(ply)
    if ply == self.Self then
        self.PokerMain:TemporaryMessage("Your turn to bet!")
        self.PokerControls:EnableBetting(30) -- TO IMPLEMENT, TODO should be a server/client convar
    else
        self.PokerMain:TemporaryMessage(ply:Nick() .."'s turn to bet!")
    end

    self.PokerPlayers:SetPlayerAsBetting(ply)
end

function EVENT:RegisterBet(ply, betType, betAmount)
    if ply == LocalPlayer() and betType == BettingStatus.FOLD then
        self.PokerMain:SetSelfFolded()
    else
        self.PokerPlayers:SetPlayerBet(ply, betType, betAmount)
    end
end

function EVENT:EndBetting()
    -- Display some message that betting is over (if localplayer is still in the game)
    -- Used for both phase 1 and phase 2 of betting
    self.PokerMain:TemporaryMessage("Betting completed!")
    self.PokerPlayers:SetPlayerAsBetting()
    self.PokerControls:DisableBetting() -- TO IMPLEMENT
end

function EVENT:BeginDiscarding(timeToDiscard)
    self.PokerMain:TemporaryMessage("Now, discard up to three cards!")
    self.PokerControls:EnableDiscarding(30) -- TO IMPLEMENT -- TODO should be server/client convar
    self.PokerHand:SetCanDiscard(true)
end

function EVENT:RegisterWinner(winner)
    -- Announce game winner
    -- Disable all controls
end

net.Receive("StartPokerRandomat", function()
    EVENT.Self = LocalPlayer()
    local players = {}
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
    
    EVENT:AlertBlinds(bigBlind, smallBlind)
end)

net.Receive("DealCards", function()
    if not EVENT.IsPlaying then return end

    local numCardsReceiving = net.ReadUInt(3)

    for i = 1, numCardsReceiving do
        local rank = net.ReadUInt(5)
        local suit = net.ReadUInt(3)

        table.insert(EVENT.Hand, {Rank = rank, Suit = suit})
    end

    EVENT:SetupHand()
end)

net.Receive("StartBetting", function()
    if not EVENT.IsPlaying then return end

    local newBetter = net.ReadEntity()

    EVENT:StartBetting(newBetter) -- TODO Marks the start of phase 1 and phase 2 of the betting
end)

net.Receive("PlayerFolded", function()
    if not EVENT.IsPlaying then return end

    local foldingPlayer = net.ReadEntity()

    EVENT:RegisterBet(foldingPlayer, BettingStatus.FOLD)
end)

net.Receive("PlayerChecked", function()
    if not EVENT.IsPlaying then return end

    local checkingPlayer = net.ReadEntity()
    local call = net.ReadUInt(3)

    EVENT:RegisterBet(checkingPlayer, BettingStatus.CHECK, call)
end)

net.Receive("PlayerCalled", function()
    if not EVENT.IsPlaying then return end

    local callingPlayer = net.ReadEntity()

    EVENT:RegisterBet(callingPlayer, BettingStatus.CALL)
end)

net.Receive("PlayerRaised", function()
    if not EVENT.IsPlaying then return end

    local raisingPlayer = net.ReadEntity()
    local raise = net.ReadUInt(3)

    EVENT:RegisterBet(raisingPlayer, BettingStatus.RAISE, raise)
end)

net.Receive("PlayersFinishedBetting", function()
    if not EVENT.IsPlaying then return end

    EVENT:EndBetting()
end)

net.Receive("StartDiscard", function()
    if not EVENT.IsPlaying then return end

    local timeToDiscard = net.ReadUInt(6)

    EVENT:BeginDiscarding(timeToDiscard)
end)

net.Receive("RevealHands", function()
    if not EVENT.IsPlaying then return end
    --Currently unused on the serverside
end)

net.Receive("DeclareWinner", function()
    if not EVENT.IsPlaying then return end

    local winner = net.ReadEntity()

    EVENT:RegisterWinner(winner)
end)

net.Receive("DeclareNoWinner", function()
    if not EVENT.IsPlaying then return end

    EVENT:RegisterWinner()
end)

net.Receive("ClosePokerWindow", function()
    if not EVENT.IsPlaying then return end

    EVENT:ClosePanel()
end)
