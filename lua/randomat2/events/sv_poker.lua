--// Logan Christianson

util.AddNetworkString("StartPokerRandomat")
util.AddNetworkString("StartPokerRandomatCallback")
util.AddNetworkString("NotifyBlinds")
util.AddNetworkString("DealCards")
util.AddNetworkString("StartBetting")
util.AddNetworkString("MakeBet")
util.AddNetworkString("PlayerFolded")
util.AddNetworkString("PlayerChecked")
util.AddNetworkString("PlayerCalled")
util.AddNetworkString("PlayerRaised")
util.AddNetworkString("StartDiscard")
util.AddNetworkString("PlayersFinishedBetting")
util.AddNetworkString("MakeDiscard")
util.AddNetworkString("RevealHands")
util.AddNetworkString("DeclareWinner")
util.AddNetworkString("ClosePokerWindow")

-- Probably needs to be moved to a shared context - scratch that, definitely needs to
local BettingStatus = {
    NONE = 0,
    FOLD = 1,
    CHECK = 2,
    CALL = 3,
    RAISE = 4,
    ALL_IN = 5
}
local Bets = {
    NONE = 0,
    QUARTER = 1,
    HALF = 2,
    THREEQ = 3,
    ALL = 4
}
local Hands = {
    NONE = 0,
    HIGH_CARD = 1,
    PAIR = 2,
    TWO_PAIR = 3,
    THREE_KIND = 4,
    STRAIGHT = 5,
    FLUSH = 6,
    FULL_HOUSE = 7,
    FOUR_KIND = 8,
    STRAIGHT_FLUSH = 9,
    ROYAL_FLUSH = 10,
    NINE_OF_DIAMONDS = 11
}
local Cards = {
    NONE = 0,
    ACE = 1,
    TWO = 2,
    THREE = 3,
    FOUR = 4,
    FIVE = 5,
    SIX = 6,
    SEVEN = 7,
    EIGHT = 8
    NINE = 9,
    TEN = 10,
    JACK = 11,
    QUEEN = 12,
    KING = 13
}
local Suits = {
    NONE = 0,
    SPADES = 1,
    HEARTS = 2,
    DIAMONDS = 3,
    CLUBS = 4
}

--// EVENT Properties

local EVENT = {}

EVENT.Title = "A Round Of Yogscast Poker"
EVENT.Description = "Only if the 9 of Diamonds touch!"
EVENT.ExtDescription = "A round of 5-Card Draw Poker, bet with your health. Up to 7 may play. Any pair, three, or four of a kind containing the 9 of Diamonds instantly wins."
EVENT.id = "poker"
EVENT.MinPlayers = 2
EVENT.Type = EVENT_TYPE_DEFAULT
EVENT.Categories = {"gamemode", "largeimpact", "fun"}

--// My properties

EVENT.MaxPlayers = 7
-- EVENT.BaseBlind = BETS.QUARTER
EVENT.MinPlayers = 2
EVENT.Started = false
EVENT.Players = {}
EVENT.Deck = {}
-- EVENT.Pot = 0
EVENT.PlayerBets = {}

--// EVENT Functions

function EVENT:GeneratePlayers()
    local randomizedLivingPlayers = self:GetAlivePlayers(true)
    local numPlayersOverMax = #randomizedLivingPlayers - maxPlayers

    while numPlayersOverMax > 0 do
        table.remove(randomizedLivingPlayers)
        numPlayersOverMax = numPlayersOverMax - 1
    end

    for i = 1, #randomizedLivingPlayers do
        local nextPlayerIndex = (i % #randomizedLivingPlayers) + 1
        randomizedLivingPlayers[i].NextPlayer = randomizedLivingPlayers[nextPlayerIndex]
        randomizedLivingPlayers[i].Status = BettingStatus.NONE
    end

    self.Players = randomizedLivingPlayers
end

-- Called when an event is started. Must be defined for an event to work.
function EVENT:Begin()
    self.Started = true

    self:GeneratePlayers()

    net.Start("StartPokerRandomat") -- Should players not in this list be notified they were passed over and for what reason?
        net.WriteUInt(#self.Players, 3)
        for _, ply in ipairs(self.Players) do
            net.WriteEntity(ply)
        end
    net.Broadcast()
end

-- Called once all the players' clients have responded to the initial net message starting the randomat
function EVENT:StartGame()
    if not self.Started then
        self:End()
        return
    end

    local smallBlind = self.Players[1]
    local bigBlind = self.Players[2]

    self.PlayerBets[smallBlind] = BETS.QUARTER
    self.PlayerBets[bigBlind] = BETS.HALF

    net.Start("NotifyBlinds")
        net.WriteEntity(smallBlind)
        net.WriteEntity(bigBlind)
    net.Broadcast()

    self:GenerateDeck()
    self:DealDeck()

    timer.Simple(5, function()
        self:BeginBetting()
    end)
end

-- Called to generate a deck of cards and shuffle them
function EVENT:GenerateDeck()
    if not self.Started then
        self:End()
        return
    end

    self.Deck = {}

    for rank = Cards.ACE, Cards.KING do
        for suit = Suits.SPADES, Suits.CLUBS do
            table.insert(self.Deck, {
                rank = rank,
                suit = suit
            })
        end
    end

    table.Shuffle(self.Deck)
end

-- Called to deal a generated deck of cards out to all participating players
function EVENT:DealDeck()
    if not self.Started then
        self:End()
        return
    end

    for _, ply in ipairs(self.Players) do
        if self.Players.Status == BettingStatus.FOLD then
            return
        end

        local deckLength = #self.Deck
        ply.Cards = ply.Cards or {}

        net.Start("DealCards")
            for i = #ply.Cards; 5 do
                local card = table.remove(self.Deck, deckLength + 1 - i)

                ply.Cards[i + 1] = card

                net.WriteUInt(card.rank, 5)
                net.WriteUInt(card.suit, 3)
            end
        net.Send(ply)
    end
end

local function GetNextValidPlayer(ply)
    local startingPlayer = self.Players[2]
    local toCheck = self.Players[2]
    local nextPlayer = nil

    while nextPlayer == nil do
        if toCheck.status ~= BettingStatus.FOLD then
            nextPlayer = toCheck
        elseif toCheck == startingPlayer then
            -- Error state, we've looped through the entire chain of nextPlayers and everyone is folded
        else
            toCheck = toCheck.NextPlayer
        end
    end
end

-- Called to mark a player as starting their turn to bet
function EVENT:BeginBetting(optionalPlayer)
    if not self.Started then
        self:End()
        return
    end

    self.ExpectantBetter = nil

    if optionalPlayer and optionalPlayer.Status ~= BettingStatus.FOLD then
        self.ExpectantBetter = optionalPlayer
    elseif self.Players[2].Status ~= BettingStatus.FOLD then
        self.ExpectantBetter = self.Players[2]
    else
        self.ExpectantBetter = GetNextValidPlayer(optionalPlayer or self.Player[2])
    end

    net.Start("StartBetting")
        net.WriteEntity(self.ExpectantBetter)
    net.Broadcast()

    timer.Create("WaitingOnPlayerBet", 30, 1, function() -- TODO Make this into a ConVar
        -- Player did not reply in time, player checks if possible, otherwise folds
        EVENT:RegisterPlayerBet(EVENT.ExpectantBetter, EVENT.PlayerBets[EVENT.ExpectantBetter] or 0)
    end)
end

local function AllPlayersMatchingBets()
    local betToCompare = 0

    for _, ply in ipairs(EVENT.Players) do
        if ply.Status == BettingStatus.NONE then
            return false
        end

        if ply.Status > BettingStatus.FOLD then
            if betToCompare == 0 then -- First bet we run across
                betToCompare = EVENT.PlayerBets[ply]
            elseif betToCompare ~= EVENT.PlayerBets[ply] -- If there's differences in bet amounts in non-folded players
                return false
            end
        end
    end

    return true
end

local function IsBetRaise(ply, bet)
    local highestBet = 0

    for _, comparePly in ipairs(EVENT.Players) do
        if comparePly ~= ply then
            local newBet = EVENT.PlayerBets[comparePly]

            if newBet > highestBet then
                highestBet = newBet
            end
        end
    end

    return bet > highestBet
end

-- Called to register a player's bet (or lack thereof) - Bet is assumed to be the truth, determines if a bet was a fold, check, call, or raise
function EVENT:RegisterPlayerBet(ply, bet)
    if not self.Started then
        self:End()
        return
    end

    -- If we receive a bet when we're not expecting (and it isn't a fold), ignore it
    if not self.ExpectantBetter and not bet == 0 then
        return
    end

    -- If we somehow get a check/raise/call that is late or out of order, ignore it outright (we've already assumed a check if possible)
    if ply == self.ExpectantBetter then
        if timer.Exists("WaitingOnPlayerBet") then
            timer.Remove("WaitingOnPlayerBet")
        end

        local playersPreviousBet = self.PlayerBets[ply] or 0

        if bet == 0 or bet < playersPreviousBet then
            ply.Status = BettingStatus.FOLD

            net.Start("PlayerFolded")
                net.WriteEntity(ply)
            net.Broadcast()
        elseif bet == playersPreviousBet then
            -- TODO this does not check if they're expected to be calling and instead they're somehow checking
            ply.Status = BettingStatus.CHECK

            net.Start("PlayerChecked")
                net.WriteEntity(ply)
            net.Broadcast()
        elseif bet > playersPreviousBet then
            self.PlayerBets[ply] = bet

            if IsBetRaise(ply, bet) then
                ply.Status = BettingStatus.RAISE -- I'm still not certain why I necessarily care about assigning any status beyond "is folded or not"

                net.Start("PlayerRaised")
                    net.WriteEntity(ply)
                    net.WriteUInt(bet, 3)
                net.Broadcast()
            else
                ply.Status = BettingStatus.CALL

                net.Start("PlayerCalled")
                    net.WriteEntity(ply)
                net.Broadcast()
            end
        end

        if AllPlayersMatchingBets() then
            net.Start("PlayersFinishedBetting")
            net.Broadcast()

            timer.Simple(5, function()
                if not self.HaveDiscarded then
                    self:BeginDiscarding()
                else
                    self:CalculateWinner()
                end
            end)
        else
            self:BeginBetting(GetNextValidPlayer(ply))
        end
    elseif bet == 0 then
        -- Out of sync player fold, used primarily for player disconnecting/death
        ply.Status = BettingStatus.FOLD

        net.Start("PlayerFolded")
            net.WriteEntity(ply)
        net.Broadcast()
    end
end

function EVENT:BeginDiscarding()
    if not self.Started then
        self:End()
        return
    end

    net.Start("StartDiscard")
        net.WriteUInt(30, 6) -- TODO Turn 30 into a ConVar
    net.Broadcast()

    self.AcceptingDiscards = true

    timer.Create("AcceptDiscards", 30, 1, function()
        self.AcceptingDiscards = false
        self:DealDeck()

        timer.Simple(5, function()
            self:BeginBetting()
        end)
    end)
end

local function AllPlayersDiscarded()
    for _, ply in ipairs(EVENT.Players) do
        if not ply.HasDiscarded then
            return false
        end
    end

    return true
end

function EVENT:RegisterPlayerDiscard(ply, discardsTable)
    if not self.Started then
        self:End()
        return
    end

    if not self.AcceptingDiscards then return end

    for _, tbl in ipairs(discardsTable) do
        if not table.RemoveByValue(ply.Cards, tbl) then
            -- Error state, we should never receive a card that the player doesn't have in their hand
        end
    end

    self.Players[ply].HasDiscarded = true

    if AllPlayersDiscarded() then
        timer.Remove("AcceptDiscards")
        self.AcceptingDiscards = false
        self.HaveDiscarded = true
        
        self:DealDeck()

        timer.Simple(5, function()
            self:BeginBetting()
        end)
    end
end

function EVENT:CalculateWinner()
    if not self.Started then
        self:End()
        return
    end

    local winner = self:GetWinningPlayer()

    net.Start("DeclareWinner")
        net.WriteEntity(winner)
        --Should we also send ALL card info here? You get to see your opponent's hands normally
    net.Broadcast()

    self:ApplyRewards(winner)

    timer.Simple(5, function()
        self:End()
    end)
end

-- This is gonna get fuckinnnnnnnnn messy
local function GetHandRank(ply)
    local hand = ply.Cards

    -- Check for flush
    local isFlush = true
    local suit = Suits.NONE

    for _, card in ipairs(hand) do
        if suit == 0 then
            suit = card.suit
        elseif suit ~= card.suit then
            isFlush = false

            break
        end
    end

    -- Check for straights
    local isStraight = true
    local prevNum = Cards.NONE
    local handCopyAsc = table.Copy(hand)

    table.sort(handCopyAsc, function(cardOne, cardTwo)
        return cardOne.rank < cardTwo.rank
    end)

    for _, card in ipairs(handCopyAsc) do
        if prevNum == 0 then
            prevNum = card.rank
        elseif not card.rank == prevNum + 1 or (prevNum == 1 and card.rank ~= Cards.TEN) then
            isStraight = false

            break
        else
            prevNum = card.rank
        end
    end

    -- Check for kinds
    local suitsByRank = {[], [], [], [], [], [], [], [], [], [], [], [], []}
    local hasThree = false
    local hasThreeRank = Cards.NONE
    local hasPair = false
    local hasTwoPair = false
    local hasPairsRank = CARDS.NONE

    for _, card in ipairs(hand) do
        table.insert(suitsByRank[card.rank], card.suit)
    end

    for rank, tbl in ipairs(suitsByRank) do
        local count = #tbl

        if count == 2 then
            if hasPair then
                hasTwoPair = true

                if rank > hasPairsRank then
                    hasPairsRank = rank
                end
            else
                endhasPair = true
                hasPairsRank = rank
            end
        elseif count == 3 then
            hasThree = true
            hasThreeRank = rank
        end
    end

    -- Get highest card rank
    local highestRank = Cards.NONE
    
    if handCopyAsc[1].rank == Cards.ACE then
        highestRank = Cards.ACE
    else
        highestRank = handCopyAsc[5].rank
    end

    -- Get table of ranks (used specifically for comparing hands when winning hands are matching pairs or high cards)
    local rankTable = []

    for _, card in ipairs(handCopyAsc) do
        table.insert(rankTable, card.rank)
    end

    -- Check possible hands in descending order --

    -- Any pair+ featuring a nine of diamonds
    if suitsByRank[Cards.NINE] and #suitsByRank[Cards.NINE] > 1 and table.HasValue(suitsByRank[card.rank], Suits.DIAMONDS) then
        return Hands.NINE_OF_DIAMONDS
    end

    -- Royal flush/straight flush check
    if isFlush and isStraight then
        if handCopyAsc[1].rank == Cards.ACE then
            return Hands.ROYAL_FLUSH
        else
            return Hands.STRAIGHT_FLUSH, highestRank
        end
    end

    -- Four of a kind
    for rank, suit in pairs(suitsByRank) do
        if #suit == 4 then
            return Hands.FOUR_KIND, rank
        end
    end

    -- Full house
    if hasPair and hasThree then
        return Hands.FULL_HOUSE, hasThreeRank
    end

    -- Flush
    if isFlush then
        return Hands.FLUSH, highestRank
    end

    -- Straight
    if isStraight then
        return Hands.STRAIGHT, highestRank
    end

    -- Three of a kind
    if hasThree then
        return Hands.THREE_KIND, hasThreeRank
    end

    -- Two pair
    if hasTwoPair then
        return Hands.TWO_PAIR, hasPairsRank
    end

    -- Pair
    if hasPair then
        return Hands.PAIR, hasPairsRank, highestRank, rankTable
    end

    -- High Card
    return Hands.HIGH_CARD, highestRank, rankTable
end

function EVENT:GetWinningPlayer()
    if not self.Started then
        self:End()
        return
    end

    local winningHandRank = Hands.NONE
    local winningPlayer = nil
    local winningHighestCardRank = Cards.NONE
    local winningRanksTbl = nil

    for _, ply in ipairs(self.Players) do
        if ply.Status == BettingStatus.FOLD then
            continue
        end

        local newHandRank, newHighestCardRank, newRanksTbl = GetHandRank(ply)

        local function AssignNewWinner()
            winningHandRank = newHandRank
            winningPlayer = ply
            winningHighestCardRank = newHighestCardRank
            winningRanksTbl = newRanksTbl
        end

        if newHandRank == Hands.NINE_OF_DIAMONDS then
            return ply
        elseif newHandRank > winningHandRank then
            AssignNewWinner()
        elseif newHandRank == winningHandRank then
            if newHighestCardRank > winningHighestCardRank then
                AssignNewWinner()
            elseif newestHighestCardRank == winningHighestCardRank then
                for i = 4, 1, -1 do
                    if winningRanksTbl[i] > newRanksTbl[i] then
                        break
                    elseif winningRanksTbl[i] < newRanksTbl[i] then
                        AssignNewWinner()
                    end
                end
            end
        end
    end

    if winningHandRank == 0 or winningPlayer = nil then
        -- Error state, should always be able to calc a winner
    end

    return winningPlayer
end

function EVENT:ApplyRewards(winner)
    if not self.Started then
        self:End()
        return
    end

    local runningHealth = 0

    for _, ply in ipairs(self.Players) do
        if ply == winner then
            continue
        end

        local bet = self.PlayerBets[ply]
        local betPercent = bet * 0.25
        local health = ply:Health()
        local healthToLose = math.Round(health * betPercent)

        runningHealth = runningHealth + healthToLose

        if bet == Bets.ALL then
            ply:Kill()
        else
            ply:SetHealth(ply:GetHealth - healthToLose)
        end

        ply:SetMaxHealth(ply:GetMaxHealth() - healthToLose)
    end

    winner:SetMaxHealth(winner:GetMaxHealth() + runningHealth)
    winner:SetHealth(winner:Health() + runningHealth)
end

-- Called when an event is stopped. Used to do manual cleanup of processes started in the event.
function EVENT:End()
    self.Started = false
    self.AcceptingDiscards = false

    net.Start("ClosePokerWindow")
    net.Broadcast()
end

-- Gets tables of the convars defined for an event. Used primarily by the Randomat 2.0 ULX module to dynamically create configuration pages for each event.
function EVENT:GetConVars()
end

--// Net Receives

local function AllPlayersReady(playerTable)
    for _, ply in ipairs(playerTable) do
        if ply.Ready == nil || not ply.Ready then
            return false
        end
    end

    return true
end

-- TODO Logic should get shifted into an EVENT:function
net.Receive("StartPokerRandomatCallback", function(len, ply)
    if not EVENT.Started then return end

    if not timer.Exists("PokerStartTimeout") then
        timer.Create("PokerStartTimeout", 5, 1, function() -- TODO Turn the 5 into a ConVar
            -- For each player in the player table that hasn't been verified, drop them from game
            -- Then, resend new list of players
            -- Then, start game
        end)
    end

    -- TODO check if player we're receiving is supposed to be play the game
    EVENT.Players[ply].Ready = true

    if AllPlayersReady(EVENT.Players) then
        EVENT:StartGame()
    end
end)

net.Receive("MakeBet", function(len, ply)
    if not EVENT.Started then return end

    local healthBeingBet = net.ReadUInt(7)

    EVENT:RegisterPlayerBet(ply, healthBeingBet)
end)

net.Receive("MakeDiscard", function(len, ply)
    if not EVENT.Started or not EVENT.AcceptingDiscards then return end

    local cardsBeingDiscarded = []
    local numCards = net.ReadUInt(2)

    for i = 1, numCards do
        table.insert(cardsBeingDiscarded, {
            rank = net.ReadUInt(5),
            suit = net.ReadUInt(3)
        })
    end

    EVENT:RegisterPlayerDiscard(ply, cardsBeingDiscarded)
end)

--// Hooks

hook.Add("PlayerDisconnected", "Alter Poker Randomat If Player Leaves", function(ply)
    if EVENT.Started and EVENT.Players[ply] then
        -- Remove player from table
        -- If player count is now below minimum, end game
        -- Otherwise, notify other players of the drop (if it was their turn, they auto-fold)
    end
end)

Randomat:register(EVENT)

--[[
    Breakdown of all networking calls
    - StartPokerRandomat sv -> cl, sets up game (sends the list of all the players)
    - StartPokerRandomatCallback cl -> sv, verifies all clients ready, sent after all screen components are drawn on client (if a client times out, remove them from the game)
        - If player is removed, re-send list of players in new net message
    - NotifyBlinds sv -> cl, notifies all players who the blinds are
    - DealCards sv -> cl, notifies the players of the 5 cards they've been dealt
    - StartBetting(x) sv -> cl, notifies all players it's x player's turn to bet
        - Continue repeatedly until all players fold/match the last raise
    - MakeBet(x) cl -> sv, notifies server if x player is checking, matching, raising, or folding (if player timeout, default check if available, fold otherwise)
        - If everyone folds except big blind, game ends and they gain little blind's hp
    - StartDiscard sv -> cl, notifies players they can start discarding up to 3 cards, starts discard timer
    - MakeDiscard(x) cl -> sv, notifies server of x player's discards
    - Repeat DealCards to any remaining players
    - Repeat StartBetting(x) to any remaining players
    Calculate winner -
    - RevealHands sv -> cl, reveals all hands still in at the end of the round to all player
    - DeclareWinner sv -> cl, declares the winner
    Misc calls -
    - ClosePokerWindow sv -> cl, forces closed the window
    - Player Folds
    - Player Checks
    - Player Raises
    - Player Calls
]]