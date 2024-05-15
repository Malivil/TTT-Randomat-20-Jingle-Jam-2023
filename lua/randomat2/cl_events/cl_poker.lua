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

    self.PokerPlayers = vgui.Create("Poker_AllPlayerPanels", self.PokerMain)
    self.PokerPlayers:SetPos(0, 0)
    self.PokerPlayers:SetSize(self.PokerMain:GetWide(), 200)
    self.PokerPlayers:SetPlayers(self.Players)
end

function EVENT:ClosePanel()
    self.PanelActive = false

    if self.PokerMain and self.PokerMain:IsValid() then
        for _, panel in ipairs(self.PokerMain:GetChildren()) do
            panel:Remove()
            panel = nil
        end

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

function EVENT:SetupControls()
    -- if not self.PokerControls or not self.PokerControls:IsValid() then
        self.PokerControls = vgui.Create("Poker_Controls", self.PokerMain)
        self.PokerControls:SetPos(0, self.PokerPlayers:GetTall())
        self.PokerControls:SetSize(self.PokerMain:GetWide(), 100)
        self.PokerControls:Setup()
    -- end
end

function EVENT:SetupHand(newHand, isSecondDeal)
    if not self.PokerHand or not self.PokerHand:IsValid() then
        self.PokerHand = vgui.Create("Poker_Hand", self.PokerMain)
        self.PokerHand:SetPos(0, self.PokerPlayers:GetTall() + 100)
        self.PokerHand:SetSize(self.PokerMain:GetWide(), 200)
    end

    self.Hand = newHand
    self.PokerHand:SetHand(newHand)

    if isSecondDeal then
        self.PokerMain:TemporaryMessage("You have new cards") -- TODO
    end
end

function EVENT:StartBetting(ply, timeToBet)
    if ply == self.Self then
        self.PokerMain:TemporaryMessage("Your turn to bet!")
        self.PokerMain:SetTimer(timeToBet)
        self.PokerControls:EnableBetting()
    else
        self.PokerMain:TemporaryMessage(ply:Nick() .."'s turn to bet!")
    end

    self.PokerPlayers:SetPlayerAsBetting(ply)
end

function EVENT:RegisterBet(ply, betType, betAmount)
    if ply == LocalPlayer() then
        if betType == BettingStatus.FOLD then
            self.PokerMain:SetSelfFolded()
        elseif self.PokerControls and self.PokerControls:IsValid() then
            self.PokerControls:SetCurrentBet(betAmount or self.PokerControls.CurrentRaise)
        end
    else
        self.PokerPlayers:SetPlayerBet(ply, betType, betAmount)

        if betType == BettingStatus.RAISE and self.PokerControls and self.PokerControls:IsValid() and betAmount then
            self.PokerControls:SetCurrentRaise(betAmount)
        end
    end

    self.PokerMain:SetTimer(0)
end

function EVENT:EndBetting()
    self.PokerMain:TemporaryMessage("Betting completed!")
    self.PokerPlayers:SetPlayerAsBetting()
    self.PokerControls:DisableBetting()
end

function EVENT:BeginDiscarding(timeToDiscard)
    self.PokerMain:TemporaryMessage("Now, discard up to three cards!")
    self.PokerMain:SetTimer(timeToDiscard)
    self.PokerHand:SetCanDiscard(true)
end

function EVENT:EndDiscard()
    self.PokerMain:SetTimer(0)
    self.PokerMain:TemporaryMessage("Time's up, hand is locked in!")
    self.PokerHand:SetCanDiscard(false)
end

function EVENT:RegisterWinner(winner, hand)
    if winner then
        if winner == LocalPlayer() then
            self.PokerMain:PermanentMessage("You win! Getting your bonus health now!")
        else
            self.PokerMain:PermanentMessage(winner:Nick() .. " wins with " .. hand .. "!")
        end
    else
        self.PokerMain:PermanentMessage("Game over! No winning player!")
    end

    self.PokerHand:SetCanDiscard(false)
    self.PokerControls:DisableBetting()
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

    EVENT:SetupControls()
    EVENT:AlertBlinds(bigBlind, smallBlind)
end)

net.Receive("DealCards", function()
    if not EVENT.IsPlaying then return end
    local numCardsReceiving = net.ReadUInt(3)
    local newHand = {}
    for i = 1, numCardsReceiving do
        local rank = net.ReadUInt(5)
        local suit = net.ReadUInt(3)
        table.insert(newHand, {Rank = rank, Suit = suit})
    end
    local isSecondDeal = net.ReadBool()

    if numCardsReceiving == 0 then
        EVENT:SetupHand(EVENT.Hand, isSecondDeal)
    else
        EVENT:SetupHand(newHand, isSecondDeal)
    end
end)

net.Receive("StartBetting", function()
    if not EVENT.IsPlaying then return end

    local newBetter = net.ReadEntity()

    EVENT:StartBetting(newBetter, 30) -- TODO make convar
end)

net.Receive("PlayerFolded", function()
    if not EVENT.IsPlaying then return end

    local foldingPlayer = net.ReadEntity()

    EVENT:RegisterBet(foldingPlayer, BettingStatus.FOLD)
end)

net.Receive("PlayerChecked", function()
    if not EVENT.IsPlaying then return end

    local checkingPlayer = net.ReadEntity()

    EVENT:RegisterBet(checkingPlayer, BettingStatus.CHECK)
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

    EVENT:BeginDiscarding(30) -- TODO convar
end)

net.Receive("RevealHands", function()
    if not EVENT.IsPlaying then return end
    --Currently unused on the serverside
end)

net.Receive("DeclareWinner", function()
    if not EVENT.IsPlaying then return end

    local winner = net.ReadEntity()
    local hand = net.ReadString()

    EVENT:RegisterWinner(winner, hand)
end)

net.Receive("DeclareNoWinner", function()
    if not EVENT.IsPlaying then return end

    EVENT:RegisterWinner()
end)

net.Receive("ClosePokerWindow", function()
    if not EVENT.IsPlaying then return end

    EVENT:ClosePanel()
end)