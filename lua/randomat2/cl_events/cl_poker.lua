--// Logan Christianson

local EVENT = {}
local EventSounds = {
    "poker/poker_decks.ogg",
    "poker/poker_practically_touching.ogg",
    "poker/poker_they_touched.ogg"
}
local EventVariantSounds = {
    "poker/colluding_live_women.ogg",
    "poker/colluding_pyrion.ogg",
    "poker/colluding_zylush.ogg"
}

EVENT.Players = {}
EVENT.Hand = {}
EVENT.ExtraHand = {}
EVENT.IsPlaying = false
EVENT.CurrentlyBetting = false
EVENT.ShouldPlayStartSound = true
EVENT.IsVariantMode = false

function EVENT:SetupPanel(isContinuedGame)
    self.PanelActive = true

    self.PokerMain = vgui.Create("Poker_Frame", nil, "Poker Randomat Frame")
    self.PokerMain:SetSize(375, 500)
    self.PokerMain:SetPos(ScrW() - self.PokerMain:GetWide(), 200)

    self.PokerPlayers = vgui.Create("Poker_AllPlayerPanels", self.PokerMain)
    self.PokerPlayers:SetPos(0, 0)
    self.PokerPlayers:SetSize(self.PokerMain:GetWide(), 200)
    self.PokerPlayers:SetPlayers(self.Players)

    if ConVars.EnableRoundStateAudioCues:GetBool() then
        if self.ShouldPlayStartSound then
            if ConVars.EnableYogsification:GetBool() then
                timer.Simple(1, function()
                    local tbl = EventSounds
                    if self.IsVariantMode then tbl = EventVariantSounds end

                    surface.PlaySound(tbl[math.random(#tbl)])
                end)
            end
        else
            timer.Simple(0, function()
                surface.PlaySound("poker/shuffle.ogg")
            end)
        end
    end
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

    if self.Close and self.Close:IsValid() then
        for _, panel in ipairs(self.Close:GetChildren()) do
            panel:Remove()
            panel = nil
        end

        self.Close:Remove()
        self.Close = nil
    end

    if self.ExtraPokerHandFrame and self.ExtraPokerHandFrame:IsValid() then
        for _, panel in ipairs(self.ExtraPokerHandFrame:GetChildren()) do
            panel:Remove()
            panel = nil
        end

        self.ExtraPokerHandFrame:Remove()
        self.ExtraPokerHandFrame = nil
    end

    self.Players = {}
    self.Hand = {}
    self.ExtraHand = {}
    self.IsPlaying = false
    self.CurrentlyBetting = false
    -- self.ShouldPlayStartSound = false
    self.IsVariantMode = false
end

function EVENT:RegisterPlayers(newPlayersTbl, selfIsIncluded, isContinuedGame)
    self.IsPlaying = selfIsIncluded
    self.Players = newPlayersTbl

    if self.IsPlaying and not self.PanelActive then
        self:SetupPanel(isContinuedGame)
    end
end

function EVENT:AlertBlinds(bigBlind, littleBlind)
    local textToDisplay = ""

    if bigBlind == self.Self then
        local amount = ""
        if ConVars.EnableSmallerBets:GetBool() then
            amount = "20%"
        else
            amount = "Half"
        end

        textToDisplay = "YOU ARE THE BIG BLIND!\n" .. amount .. " of your HP has been\nadded to the pot automatically."
    else
        textToDisplay = "The Big Blind is: " .. bigBlind:Nick()
    end

    textToDisplay = textToDisplay .. "\n\n"

    if littleBlind == self.Self then
        local amount = ""
        if ConVars.EnableSmallerBets:GetBool() then
            amount = "10%"
        else
            amount = "A quarter"
        end

        textToDisplay = textToDisplay .. "YOU ARE THE LITTLE BLIND!\n" .. amount .. " of your HP has been\nadded to the pot automatically."
    else
        textToDisplay = textToDisplay .. "The Little Blind is: " .. littleBlind:Nick()
    end

    self.PokerMain:TemporaryMessage(textToDisplay)
    self.PokerPlayers:SetBlinds(littleBlind, bigBlind)
    self:RegisterBet(littleBlind, BettingStatus.RAISE, GetLittleBlindBet())
    self:RegisterBet(bigBlind, BettingStatus.RAISE, GetBigBlindBet())
    self.PokerPlayers:ResetPlayerActions()
end

function EVENT:SetupControls()
    self.PokerControls = vgui.Create("Poker_Controls", self.PokerMain)
    self.PokerControls:SetPos(0, self.PokerPlayers:GetTall())
    self.PokerControls:SetSize(self.PokerMain:GetWide(), 100)
    self.PokerControls:Setup()
end

function EVENT:SetupHand(newHand, isSecondDeal)
    if not self.PokerHand or not self.PokerHand:IsValid() then
        self.PokerHand = vgui.Create("Poker_Hand", self.PokerMain)
        self.PokerHand:SetPos(0, self.PokerPlayers:GetTall() + self.PokerControls:GetTall() - 1)
        self.PokerHand:SetSize(self.PokerMain:GetWide(), 200)
    end

    local newCards = ""
    if self.Hand then
        for _, oldCard in ipairs(self.Hand) do
            for _, newCard in ipairs(newHand) do
                if oldCard.Suit == newCard.Suit and oldCard.Rank == newCard.Rank then
                    newCard.Kept = true
                end
            end
        end

        for _, card in ipairs(newHand) do
            if not card.Kept then
                newCards = newCards .. CardRankToName(card.Rank) .. " of " .. CardSuitToName(card.Suit) .. "\n"
            end
        end
    end

    self.Hand = newHand
    self.PokerHand:SetHand(newHand)

    if isSecondDeal then
        if newCards ~= "" then
            self.PokerMain:TemporaryMessage("Your new cards:\n" .. newCards)
        else
            self.PokerMain:TemporaryMessage("No new cards given")
        end
    end
end

function EVENT:StartBetting(ply, timeToBet)
    if ply == self.Self then
        self.PokerMain:TemporaryMessage("Your turn to bet!")
        self.PokerMain:SetTimer(timeToBet)
        self.PokerControls:EnableBetting()

        if ConVars.EnableRoundStateAudioCues:GetBool() then
            surface.PlaySound("poker/chips.ogg")
        end
    else
        self.PokerMain:TemporaryMessage(ply:Nick() .."'s turn to bet!")
    end

    self.PokerPlayers:SetPlayerAsBetting(ply)
    self.PokerHand:SetCanDiscard(false)
end

function EVENT:RegisterBet(ply, betType, betAmount, plySteamId)
    if ply == LocalPlayer() then
        if betType == BettingStatus.FOLD then
            self.PokerMain:SetSelfFolded()
            self:EnableClose()
        elseif self.PokerControls and self.PokerControls:IsValid() then
            self.PokerControls:SetCurrentBet(betAmount or self.PokerControls.CurrentRaise)
            self.PokerControls:DisableBetting()
        end
    
        self.PokerMain:SetTimer(0)
    else
        self.PokerPlayers:SetPlayerBet(ply, betType, betAmount or self.PokerControls:GetCurrentRaise(), plySteamId)

        if betType == BettingStatus.RAISE and self.PokerControls and self.PokerControls:IsValid() and betAmount then
            self.PokerControls:SetCurrentRaise(betAmount)
        end
    end

    if IsAllIn(betAmount) then
        self.PokerControls:DisableRaising()
    end
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
    self.PokerPlayers:ResetPlayerActions()

    if ConVars.EnableRoundStateAudioCues:GetBool() then
        surface.PlaySound("poker/shuffle.ogg")
    end
end

function EVENT:EndDiscard()
    self.PokerMain:SetTimer(0)
end

function EVENT:RegisterWinner(winner, hand)
    if winner then
        if winner == LocalPlayer() then
            self.PokerMain:PermanentMessage("You win! Getting your bonus health now!")

            if ConVars.EnableYogsification:GetBool() and self.ShouldPlayStartSound then
                surface.PlaySound("poker/you_won.ogg")
            end
        else
            self.PokerMain:PermanentMessage(winner:Nick() .. " wins the hand with \n" .. hand .. "!")

            if ConVars.EnableYogsification:GetBool() and self.ShouldPlayStartSound  then
                surface.PlaySound("poker/robbed.ogg")
            end
        end
    else
        self.PokerMain:PermanentMessage("Game over. No winning player!\nAt least two players must remain alive to play!")
    end

    self.PokerHand:SetCanDiscard(false)
    self.PokerControls:DisableBetting()
end

function EVENT:EnableClose()
    self.Close = vgui.Create("DFrame", nil, "Poker Randomat Close Button")
    self.Close:SetSize(70, 34)
    self.Close:SetPos(ScrW() - (self.PokerMain:GetWide() * 0.5) - (self.Close:GetWide() * 0.5), 200 + self.PokerMain:GetTall() + 4)
    self.Close:ShowCloseButton(false)
    self.Close:SetTitle("")

    self.CloseButton = vgui.Create("Control_Button", self.Close)
    self.CloseButton:SetPos(0, 0)
    self.CloseButton:SetSize(self.Close:GetWide(), self.Close:GetTall())
    self.CloseButton:SetText("CLOSE")
    self.CloseButton.CustomDoClick = function()
        if self then
            self:ClosePanel()
        end
    end

    if self.ExtraPokerHandFrame and self.ExtraPokerHandFrame:IsValid() then
        self.Close:SetPos(ScrW() - (self.PokerMain:GetWide() * 0.5) - (self.Close:GetWide() * 0.5), 200 + self.PokerMain:GetTall() + 4 + self.ExtraPokerHandFrame:GetTall() + 4)
    end
end

net.Receive("StartPokerRandomat", function()
    EVENT.Self = LocalPlayer()

    local numPlayers = net.ReadUInt(3)
    for i = 1, numPlayers do
        local ply = net.ReadEntity()

        if ply == EVENT.Self then
            net.Start("StartPokerRandomatCallback")
            net.SendToServer()

            break
        end
    end
end)

net.Receive("BeginPokerRandomat", function()
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

    if selfIsPlaying then
        while players[1] ~= LocalPlayer() do
            table.insert(players, table.remove(players, 1))
        end
    end

    EVENT:RegisterPlayers(players, selfIsPlaying, isContinuedGame)
    DynamicTimerPlayerCount = numPlayers
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

    EVENT:EndDiscard()

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

    EVENT:StartBetting(newBetter, GetDynamicRoundTimerValue("RoundStateBetting"))
end)

net.Receive("PlayerFolded", function()
    if not EVENT.IsPlaying then return end

    local foldingPlayer = net.ReadEntity()
    local foldingPlayerID = net.ReadString()

    EVENT:RegisterBet(foldingPlayer, BettingStatus.FOLD, nil, foldingPlayerID)
end)

net.Receive("PlayerChecked", function()
    if not EVENT.IsPlaying then return end

    local checkingPlayer = net.ReadEntity()

    EVENT:RegisterBet(checkingPlayer, BettingStatus.CHECK)
end)

net.Receive("PlayerCalled", function()
    if not EVENT.IsPlaying then return end

    local callingPlayer = net.ReadEntity()

    EVENT:RegisterBet(callingPlayer, BettingStatus.CALL, call)
end)

net.Receive("PlayerRaised", function()
    if not EVENT.IsPlaying then return end

    local raisingPlayer = net.ReadEntity()
    local raise = net.ReadUInt(4)

    EVENT:RegisterBet(raisingPlayer, BettingStatus.RAISE, raise)
end)

net.Receive("PlayersFinishedBetting", function()
    if not EVENT.IsPlaying then return end

    EVENT:EndBetting()
end)

net.Receive("StartDiscard", function()
    if not EVENT.IsPlaying then return end

    EVENT:BeginDiscarding(GetDynamicRoundTimerValue("RoundStateDiscarding"))
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

    local continuousEnd = net.ReadBool()
    if continuousEnd then
        EVENT.ShouldPlayStartSound = false
    end
end)

hook.Add("TTTEndRound", "Reset Poker Randomat Sound Play", function(result)
    EVENT.ShouldPlayStartSound = true
end)

--// Variant Event

function EVENT:SetupExtraHand(plyName, extraHand)
    if not self.ExtraPokerHandFrame or not self.ExtraPokerHandFrame:IsValid() then
        self.ExtraPokerHandFrame = vgui.Create("DFrame", nil, "Poker Randomat Extra Hand Frame")
        self.ExtraPokerHandFrame:SetSize(self.PokerMain:GetWide(), 160)
        self.ExtraPokerHandFrame:SetPos(ScrW() - self.PokerMain:GetWide(), 200 + self.PokerMain:GetTall() + 4)
        self.ExtraPokerHandFrame:ShowCloseButton(false)
        self.ExtraPokerHandFrame:SetTitle("")

        self.ExtraPokerHand = vgui.Create("Poker_Hand", self.ExtraPokerHandFrame)
        self.ExtraPokerHand:SetPos(0, 0)
        self.ExtraPokerHand:SetSize(self.ExtraPokerHandFrame:GetWide(), self.ExtraPokerHandFrame:GetTall())

        if ConVars.AnonymizeCollusions:GetBool() then
            self.ExtraPokerHand:SetTitle("Colluded Hand")
        else
            self.ExtraPokerHand:SetTitle(plyName .. "'s Hand")
        end
    end

    self.ExtraHand = extraHand
    self.ExtraPokerHand:SetHand(extraHand)
end

net.Receive("MarkRoundVariant", function()
    EVENT.IsVariantMode = true
end)

net.Receive("ShareCards", function()
    local colludingPlayer = net.ReadEntity()
    local colludingPlayerHand = {}
    for i = 1, 5 do
        local rank = net.ReadUInt(5)
        local suit = net.ReadUInt(3)
        table.insert(colludingPlayerHand, {Rank = rank, Suit = suit})
    end
    
    EVENT:SetupExtraHand(colludingPlayer:Nick(), colludingPlayerHand)
end)

--[[
    Legacy bugs (didn't fix outright but stopped running into):
    - Was running into bet looping issues
    - Folding seemed to trigger an infinite loop
        * Unable to reproduce?
    - Non-blind player calling instantly ends the first round of betting BIG ISSUE
        * Seems to break a lot of other functionality
    - It's possible if all other players die to earn negative bonus health, which does reduce your health
        * Seems to only be an issue with bots

    Bugs:
    - Sometimes colluded hand isn't showing up
]]