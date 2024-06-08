--// Logan Christianson

local EVENT = {}
local EventSounds = {
    "poker/poker_decks.ogg",
    "poker/poker_practically_touching.ogg",
    "poker/poker_they_touched.ogg"
}

EVENT.Players = {}
EVENT.Hand = {}
EVENT.IsPlaying = false
EVENT.CurrentlyBetting = false
EVENT.IsContinuedGame = false

function EVENT:SetupPanel(isContinuedGame)
    self.PanelActive = true

    self.PokerMain = vgui.Create("Poker_Frame", nil, "Poker Randomat Frame")
    self.PokerMain:SetSize(375, 500)
    self.PokerMain:SetPos(ScrW() - self.PokerMain:GetWide(), 200)

    self.PokerPlayers = vgui.Create("Poker_AllPlayerPanels", self.PokerMain)
    self.PokerPlayers:SetPos(0, 0)
    self.PokerPlayers:SetSize(self.PokerMain:GetWide(), 200)
    self.PokerPlayers:SetPlayers(self.Players)

    if ConVars.EnableYogsification:GetBool() and ConVars.EnableRoundStateAudioCues:GetBool() and not self.IsContinuedGame then
        timer.Simple(1, function()
            surface.PlaySound(EventSounds[math.random(#EventSounds)])
        end)
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

    self.Players = {}
    self.Hand = {}
    self.IsPlaying = false
    self.CurrentlyBetting = false
    self.IsContinuedGame = true
end

function EVENT:RegisterPlayers(newPlayersTbl, selfIsIncluded, isContinuedGame)
    -- local isContinuousPlay = #self.Players > 0
    self.IsPlaying = selfIsIncluded
    self.Players = newPlayersTbl

    if self.IsPlaying and not self.PanelActive then
        self:SetupPanel(isContinuedGame)
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
    self:RegisterBet(littleBlind, BettingStatus.RAISE, GetLittleBlindBet())
    self:RegisterBet(bigBlind, BettingStatus.RAISE, GetBigBlindBet())
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
            -- surface.PlaySound("common/wpn_select.wav")
            surface.PlaySound("poker/chips.ogg")
        end
    else
        self.PokerMain:TemporaryMessage(ply:Nick() .."'s turn to bet!")
    end

    self.PokerPlayers:SetPlayerAsBetting(ply)
    self.PokerHand:SetCanDiscard(false)
end

function EVENT:RegisterBet(ply, betType, betAmount)
    if ply == LocalPlayer() then
        if betType == BettingStatus.FOLD then
            self.PokerMain:SetSelfFolded()
        elseif self.PokerControls and self.PokerControls:IsValid() then
            self.PokerControls:SetCurrentBet(betAmount or self.PokerControls.CurrentRaise)
            self.PokerControls:DisableBetting()
        end
    else
        self.PokerPlayers:SetPlayerBet(ply, betType, betAmount or self.PokerControls:GetCurrentRaise())

        if betType == BettingStatus.RAISE and self.PokerControls and self.PokerControls:IsValid() and betAmount then
            self.PokerControls:SetCurrentRaise(betAmount)
        end
    end

    if IsAllIn(betAmount) then
        self.PokerControls:DisableRaising()
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

    if ConVars.EnableRoundStateAudioCues:GetBool() then
        surface.PlaySound("poker/shuffle.ogg")
    end
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
            self.PokerMain:PermanentMessage(winner:Nick() .. " wins the hand with a\n" .. hand .. "!")
        end
    else
        self.PokerMain:PermanentMessage("Game over. No winning player!\nAt least two players must remain alive to play!")
    end

    self.PokerHand:SetCanDiscard(false)
    self.PokerControls:DisableBetting()
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
    print("StartPokerRandomat called")
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

    -- TODO probably sort the players table so the "first" in it is the player to the "left" of LocalPlayer
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
    print("NotifyBlinds called")
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

    EVENT:StartBetting(newBetter, GetDynamicRoundTimerValue("RoundStateBetting"))
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

    local continuousEnd = net.ReadBool()
    if continuousEnd then
        EVENT.IsContinuedGame = false
    end
end)

--// Variant Event

net.Receive("StartPokerVariantRandomat", function()
    EVENT.Self = LocalPlayer()

    local numPlayers = net.ReadUInt(3)
    for i = 1, numPlayers do
        local ply = net.ReadEntity()

        if ply == EVENT.Self then
            net.Start("StartPokerVariantRandomatCallback")
            net.SendToServer()

            break
        end
    end
    print("StartPokerVariantRandomat called")
end)

net.Receive("BeginPokerVariantRandomat", function()
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

    EVENT:RegisterPlayers(players, selfIsPlaying)
    print("BeginPokerVariantRandomat called")
end)

--[[
    Feature Improvements:
    - Need to finish variant mode
    - Addition SFX on different round states (Lewis request)
    - Button to close window after Folded
        TO TEST
    - Special ConVars to add:
        - Anything else I missed I left a comment for

    Test 2:
    - Was running into bet looping issues
    - Folding seemed to trigger an infinite loop
        - Unable to reproduce?

    Test 3:
    * To note, raising sets status to 4, all calls set status to 3 - is this causing issues?
    - If player dies during discard phase, everything breaks (immediately jumps into betting phase instead of finishing out discard) BIG ISSUE
        - TO TEST with 3+ players
    - Non-blind player calling instantly ends the first round of betting BIG ISSUE
        - Seems to break a lot of other functionality
        - Does not trigger with bots??? TO TEST with 3+ players

    Bugs:
    - It's possible if all other players die to earn negative bonus health, which does reduce your health
    - Two sets of two paris had the lower pair win
]]