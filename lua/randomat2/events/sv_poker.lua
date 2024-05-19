--// Logan Christianson

util.AddNetworkString("StartPokerRandomat")
util.AddNetworkString("StartPokerRandomatCallback")
util.AddNetworkString("BeginPokerRandomat")
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
util.AddNetworkString("DeclareNoWinner")
util.AddNetworkString("DeclareWinner")
util.AddNetworkString("ClosePokerWindow")

--// EVENT Properties

local EVENT = {}

EVENT.Title = "A Round Of Yogscast Poker"
EVENT.Description = "Only if the 9 of Diamonds touch!"
EVENT.ExtDescription = "A round of 5-Card Draw Poker (no Texas Hold 'Em, for my sake), bet with your health. Up to 7 may play. Any pair, three, or four of a kind containing the 9 of Diamonds instantly wins."
EVENT.id = "poker"
EVENT.MinPlayers = 2
EVENT.Type = EVENT_TYPE_DEFAULT
EVENT.Categories = {"gamemode", "largeimpact", "fun"}

--// My properties

EVENT.MaxPlayers = 7
EVENT.MinPlayers = 2
EVENT.Started = false
EVENT.Running = false
EVENT.Players = {}
EVENT.Deck = {}
EVENT.PlayerBets = {}

--// EVENT Functions

-- Used to populate EVENT.Players with living players, up to the max amount
function EVENT:GeneratePlayers()
    local removedPlayers = {}
    local randomizedLivingPlayers = self:GetAlivePlayers(true)
    table.Shuffle(randomizedLivingPlayers)
    local numPlayersOverMax = #randomizedLivingPlayers - self.MaxPlayers

    while numPlayersOverMax > 0 do
        local removedPlayer = table.remove(randomizedLivingPlayers)
        table.insert(removedPlayers, removedPlayer)
        numPlayersOverMax = numPlayersOverMax - 1
    end

    for i = 1, #randomizedLivingPlayers do
        local nextPlayerIndex = (i % #randomizedLivingPlayers) + 1 -- Makes it so final player's 'next player' wraps around to [1]
        randomizedLivingPlayers[i].NextPlayer = randomizedLivingPlayers[nextPlayerIndex]
        randomizedLivingPlayers[i].Status = BettingStatus.NONE
    end

    for _, ply in ipairs(removedPlayers) do
        ply:ChatPrint("Sorry " .. ply:Nick() .. ", the maximum number of players was exceeded, and you drew the short stick! The event currently supports up to " .. self.MaxPlayers .. " players.")
    end

    self.Players = randomizedLivingPlayers
end

-- Called when an event is started. Must be defined for an event to work.
function EVENT:Begin()
    self.Started = true

    self:GeneratePlayers()

    for _, ply in ipairs(self.Players) do
        ply.Status = BettingStatus.NONE
    end

    net.Start("StartPokerRandomat")
        net.WriteUInt(#self.Players, 3)
        for _, ply in ipairs(self.Players) do
            net.WriteEntity(ply)
        end
    net.Broadcast()
end

-- Called after all players responded to the initial net message and any who haven't are removed
function EVENT:RefreshPlayers()
    if not self.Started then self:End() return end

    net.Start("BeginPokerRandomat")
        net.WriteUInt(#self.Players, 3)
        for _, ply in ipairs(self.Players) do
            net.WriteEntity(ply)
        end
    net.Broadcast()
end

-- Called once all the validated players' clients have responded to BeginPokerRandomat net message
function EVENT:StartGame()
    if not self.Started then self:End() return end

    self:RefreshPlayers()
    self.Running = true

    local smallBlind = self.Players[1]
    local bigBlind = self.Players[2]

    self:RegisterPlayerBet(smallBlind, BettingStatus.RAISE, Bets.QUARTER, true)
    self:RegisterPlayerBet(bigBlind, BettingStatus.RAISE, Bets.HALF, true)

    net.Start("NotifyBlinds")
        net.WriteEntity(smallBlind)
        net.WriteEntity(bigBlind)
    net.Broadcast()

    self:GenerateDeck()
    self:DealDeck()

    timer.Simple(5, function()
        self:BeginBetting(bigBlind.NextPlayer)
    end)
end

-- Called to generate a deck of cards and shuffle them
function EVENT:GenerateDeck()
    if not self.Started then self:End() return end

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
function EVENT:DealDeck(isSecondDeal)
    if not self.Started then self:End() return end

    for _, ply in ipairs(self.Players) do
        if ply.Status == BettingStatus.FOLD then
            continue
        end

        local deckLength = #self.Deck
        ply.Cards = ply.Cards or {}
        local cardCount = #ply.Cards

        net.Start("DealCards")
            net.WriteUInt(5, 3)
            for i = 1, 5 do
                local card
                if i > cardCount then
                    card = table.remove(self.Deck)
                    ply.Cards[i] = card
                else
                    card = ply.Cards[i]
                end
                net.WriteUInt(card.rank, 5)
                net.WriteUInt(card.suit, 3)
            end
            net.WriteBool(isSecondDeal or false)
        net.Send(ply)
    end
end

local function GetNextValidPlayer(ply)
    local startingPlayer = ply
    local toCheck = ply.NextPlayer
    local nextPlayer = nil

    while nextPlayer == nil do
        if toCheck.Status ~= BettingStatus.FOLD then
            nextPlayer = toCheck
        elseif toCheck == startingPlayer then
            return
        else
            toCheck = toCheck.NextPlayer
        end
    end

    return nextPlayer
end

-- Called to mark a player as starting their turn to bet
function EVENT:BeginBetting(optionalPlayer)
    if not self.Started then self:End() return end

    self.ExpectantBetter = nil

    if optionalPlayer and optionalPlayer.Status ~= BettingStatus.FOLD then
        self.ExpectantBetter = optionalPlayer
    elseif self.Players[2].NextPlayer.Status ~= BettingStatus.FOLD then
        self.ExpectantBetter = self.Players[2].NextPlayer
    else
        self.ExpectantBetter = GetNextValidPlayer(optionalPlayer or self.Players[2].NextPlayer)
    end

    if not self.ExpectantBetter then
        self:EndBetting()
    end

    net.Start("StartBetting")
        net.WriteEntity(self.ExpectantBetter)
    net.Broadcast()

    timer.Create("WaitingOnPlayerBet", 30, 1, function() -- TODO Make this into a ConVar
        EVENT:RegisterPlayerBet(EVENT.ExpectantBetter, BettingStatus.CHECK, EVENT.PlayerBets[EVENT.ExpectantBetter] or 0)
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
            elseif betToCompare ~= EVENT.PlayerBets[ply] then -- If there's differences in bet amounts in non-folded players
                return false
            end
        end
    end

    return true
end

local function GetHighestBet()
    local highestBet = 0

    for _, ply in ipairs(EVENT.Players) do
        local newBet = EVENT.PlayerBets[ply]

        if newBet and newBet > highestBet then
            highestBet = newBet
        end
    end

    return highestBet
end

local function ResetOtherPlayersBetStatus(ply)
    for _, other in ipairs(EVENT.Players) do
        if other ~= ply and other.Status ~= BettingStatus.FOLD then
            other.Status = BettingStatus.NONE
        end
    end
end

local function PlayerFolds(ply)
    ply.Status = BettingStatus.FOLD

    net.Start("PlayerFolded")
        net.WriteEntity(ply)
    net.Broadcast()
end

local function PlayerChecks(ply)
    ply.Status = BettingStatus.CHECK
    EVENT.PlayerBets[ply] = GetHighestBet()

    net.Start("PlayerChecked")
        net.WriteEntity(ply)
    net.Broadcast()
end

local function PlayerCalls(ply)
    ply.Status = BettingStatus.CALL
    EVENT.PlayerBets[ply] = GetHighestBet()

    net.Start("PlayerCalled")
        net.WriteEntity(ply)
        --net.WriteUInt(bet, 3) -- TODO I don't even think this is necessary...
    net.Broadcast()
end

local function PlayerRaises(ply, raise)
    ply.Status = BettingStatus.RAISE
    ResetOtherPlayersBetStatus(ply)
    EVENT.PlayerBets[ply] = raise

    net.Start("PlayerRaised")
        net.WriteEntity(ply)
        net.WriteUInt(raise, 3)
    net.Broadcast()
end

local function EnoughPlayersRemaining()
    local atLeastOne = false
    for _, ply in ipairs(EVENT.Players) do
        if ply.Status ~= BettingStatus.FOLD then
            if atLeastOne then
                return true
            else
                atLeastOne = true
            end
        end
    end

    return false
end

local function CanDispenseWinnings()
    local onePlayerStillAliveWithBets = false

    for _, ply in ipairs(EVENT.Players) do
        if ply:Alive() and EVENT.PlayerBets[ply] then
            if onePlayerStillAliveWithBets then
                return true
            else
                onePlayerStillAliveWithBets = true
            end
        end
    end

    return false
end

-- Called to register a player's bet (or lack thereof)
function EVENT:RegisterPlayerBet(ply, bet, betAmount, forceBet)
    if not self.Started then self:End() return end

    -- If we receive a bet when we're not expecting (and it isn't a fold), ignore it
    if not self.ExpectantBetter and bet > 1 and not forceBet then
        return
    end

    if ply == self.ExpectantBetter or forceBet then
        if ply == self.ExpectantBetter and timer.Exists("WaitingOnPlayerBet") then
            timer.Remove("WaitingOnPlayerBet")
        end

        local highestBet = GetHighestBet()

        if bet < BettingStatus.CHECK then
            PlayerFolds(ply)
        elseif bet == BettingStatus.CHECK then
            if highestBet > betAmount then
                PlayerFolds(ply)
            else
                PlayerChecks(ply)
            end
        elseif bet == BettingStatus.CALL then
            PlayerCalls(ply)
        elseif bet == BettingStatus.RAISE then
            if betAmount <= highestBet then
                PlayerCalls(ply)
            else
                PlayerRaises(ply, betAmount)
            end
        else
            error(ply:Nick() .. " is sending net messages manually...")
        end

        if not forceBet then
            print("\tChecking if all players have matching bets or are folded...")
            if AllPlayersMatchingBets() then
                net.Start("PlayersFinishedBetting")
                net.Broadcast()

                self:EndBetting()
            else
                local nextPly = GetNextValidPlayer(ply)
                
                self:BeginBetting(nextPly)
            end
        end
    elseif bet < BettingStatus.CHECK then
        -- Out of sync player fold, used primarily for player disconnecting/death
        ply.Status = BettingStatus.FOLD

        net.Start("PlayerFolded")
            net.WriteEntity(ply)
        net.Broadcast()

        if not EnoughPlayersRemaining() then
            if CanDispenseWinnings() then
                self:CalculateWinner()
            else
                net.Start("DeclareNoWinner")
                net.Broadcast()

                timer.Simple(5, function()
                    self:End()
                end)
            end
        end
    end
end

function EVENT:EndBetting()
    timer.Simple(5, function()
        local epr = EnoughPlayersRemaining() -- Needs to be ran BEFORE changing player's Status prop

        for _, ply in ipairs(self.Players) do
            if ply.Status ~= BettingStatus.FOLD then
                ply.Status = BettingStatus.NONE
            end
        end

        if self.HaveDiscarded or not epr then
            self:CalculateWinner()
        else
            self:BeginDiscarding()
        end
    end)
end

function EVENT:BeginDiscarding()
    if not self.Started then self:End() return end

    net.Start("StartDiscard")
    net.Broadcast()

    self.AcceptingDiscards = true

    timer.Create("AcceptDiscards", 30, 1, function()
        self.AcceptingDiscards = false
        self.HaveDiscarded = true
        self:DealDeck(true)

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
    if not self.Started then self:End() return end

    if not self.AcceptingDiscards then return end

    for _, cardToRemove in ipairs(discardsTable) do
        local toBeRemoved
        for index, cardInHand in ipairs(ply.Cards) do
            if cardToRemove.rank == cardInHand.rank and cardToRemove.suit == cardInHand.suit then
                toBeRemoved = index
                -- break
            end
        end

        if toBeRemoved then
            table.remove(ply.Cards, toBeRemoved)
        end
    end

    self.Players[table.KeyFromValue(self.Players, ply)].HasDiscarded = true
    if AllPlayersDiscarded() then
        timer.Remove("AcceptDiscards")
        self.AcceptingDiscards = false
        self.HaveDiscarded = true

        self:DealDeck(true)

        timer.Simple(5, function()
            self:BeginBetting()
        end)
    end
end

function EVENT:CalculateWinner()
    print("EVENT:CalculateWinner called")
    if not self.Started then self:End() return end

    local winner, hand = self:GetWinningPlayer()

    if winner == nil then
        -- Everyone died! Cancel the game
        net.Start("DeclareNoWinner")
        net.Broadcast()
    else
        net.Start("DeclareWinner")
            net.WriteEntity(winner)
            net.WriteString(hand)
        net.Broadcast()

        self:ApplyRewards(winner)
    end

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
    local suitsByRank = {{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}}
    local hasThree = false
    local hasThreeRank = Cards.NONE
    local hasPair = false
    local hasTwoPair = false
    local hasPairsRank = Cards.NONE

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
    local rankTable = {}

    for _, card in ipairs(handCopyAsc) do
        table.insert(rankTable, card.rank)
    end

    -- Check possible hands in descending order --

    -- Any pair+ featuring a nine of diamonds
    if suitsByRank[Cards.NINE] and #suitsByRank[Cards.NINE] > 1 and table.HasValue(suitsByRank[card.rank], Suits.DIAMONDS) then -- TO FIX "card" here is nil
        return Hands.NINE_OF_DIAMONDS, 0, 0, {}, "Two+ of a kind with a 9 of diamonds"
    end

    -- Royal flush/straight flush check
    if isFlush and isStraight then
        if handCopyAsc[1].rank == Cards.ACE then
            return Hands.ROYAL_FLUSH, 0, 0, {}, "Royal flush"
        else
            return Hands.STRAIGHT_FLUSH, highestRank, 0, {}, "Straight flush"
        end
    end

    -- Four of a kind
    for rank, suits in pairs(suitsByRank) do
        if #suits == 4 then
            return Hands.FOUR_KIND, rank, 0, {}, "Four of a kind"
        end
    end

    -- Full house
    if hasPair and hasThree then
        return Hands.FULL_HOUSE, hasThreeRank, 0, {}, "Full house"
    end

    -- Flush
    if isFlush then
        return Hands.FLUSH, highestRank, 0, {}, "Flush"
    end

    -- Straight
    if isStraight then
        return Hands.STRAIGHT, highestRank, 0, {}, "Straight"
    end

    -- Three of a kind
    if hasThree then
        return Hands.THREE_KIND, hasThreeRank, 0, {}, "Three of a kind"
    end

    -- Two pair
    if hasTwoPair then
        return Hands.TWO_PAIR, hasPairsRank, 0, {}, "Two pair"
    end

    -- Pair
    if hasPair then
        return Hands.PAIR, hasPairsRank, highestRank, rankTable, "Pair"
    end

    -- High Card
    return Hands.HIGH_CARD, highestRank, 0, rankTable, "High card"
end

function EVENT:GetWinningPlayer()
    print("EVENT:GetWinningPlayer called")
    if not self.Started then self:End() return end

    local winningHandRank = Hands.NONE
    local winningPlayer = nil
    local winningHighestCardRank = Cards.NONE
    local winningAltHighestCardRank = Cards.NONE
    local winningRanksTbl = {}
    local winningStr = ""

    local function AssignNewWinner(ply, newHandRank, newHighestCardRank, newAltHighestCardRank, newRanksTbl, newStr)
        print("\tAssignNewWinner called with args:", ply, newHandRank, newHighestCardRank, newAltHighestCardRank, newRanksTbl, newStr)
        winningHandRank = newHandRank
        winningPlayer = ply
        winningHighestCardRank = newHighestCardRank
        winningAltHighestCardRank = newAltHighestCardRank
        winningRanksTbl = newRanksTbl
        winningStr = newStr
    end

    for _, ply in ipairs(self.Players) do
        if ply.Status == BettingStatus.FOLD then
            continue
        end

        local newHandRank, newHighestCardRank, newAltHighestCardRank, newRanksTbl, str = GetHandRank(ply)

        if newHandRank == Hands.NINE_OF_DIAMONDS then
            return ply, str
        elseif newHandRank > winningHandRank then
            AssignNewWinner(ply, newHandRank, newHighestCardRank, newAltHighestCardRank, newRanksTbl, str)
        elseif newHandRank == winningHandRank then
            if newHighestCardRank > winningHighestCardRank then
                AssignNewWinner(ply, newHandRank, newHighestCardRank, newAltHighestCardRank, newRanksTbl, str)
            elseif newHighestCardRank == winningHighestCardRank then
                if newAltHighestCardRank > winningAltHighestCardRank then
                    AssignNewWinner(ply, newHandRank, newHighestCardRank, newAltHighestCardRank, newRanksTbl, str)
                elseif newAltHighestCardRank == winningAltHighestCardRank then
                    for i = 4, 1, -1 do -- Cards should be in ascending order
                        if winningRanksTbl[i] > newRanksTbl[i] then
                            break
                        elseif winningRanksTbl[i] < newRanksTbl[i] then
                            AssignNewWinner(ply, newHandRank, newHighestCardRank, newAltHighestCardRank, newRanksTbl, str)
                        end
                    end
                end
            end
        end
    end

    return winningPlayer, winningStr
end

function EVENT:ApplyRewards(winner)
    print("EVENT:ApplyRewards called", winner)
    if not self.Started then self:End() return end

    local runningHealth = 0
    for _, ply in ipairs(self.Players) do
        if ply == winner then
            continue
        end

        local bet = self.PlayerBets[ply] or 0
        local betPercent = bet * 0.25
        local health = ply:Health()
        local healthToLose = math.Round(health * betPercent)

        runningHealth = runningHealth + healthToLose

        if bet == Bets.ALL then
            ply:Kill()
        else
            ply:SetHealth(math.max(1, ply:Health() - healthToLose))
            ply:SetMaxHealth(math.max(1, ply:GetMaxHealth() - healthToLose))
        end
    end

    for _, ply in ipairs(player.GetAll()) do
        ply:ChatPrint(winner:Nick() .. " wins the Poker hand and gained " .. runningHealth .. " health from all the schmucks who lost!")
    end

    winner:SetMaxHealth(winner:GetMaxHealth() + runningHealth)
    winner:SetHealth(winner:Health() + runningHealth)
end

-- Called when an event is stopped. Used to do manual cleanup of processes started in the event.
function EVENT:End()
    -- ErrorNoHaltWithStack("Event End called")
    self.Started = false
    self.AcceptingDiscards = false
    self.HaveDiscarded = false
    self.Running = false
    self.Players = {}
    self.Deck = {}
    self.PlayerBets = {}

    for _, ply in ipairs(player.GetAll()) do
        ply.Cards = {}
    end

    net.Start("ClosePokerWindow")
    net.Broadcast()
end

-- Gets tables of the convars defined for an event. Used primarily by the Randomat 2.0 ULX module to dynamically create configuration pages for each event.
function EVENT:GetConVars()
end

function EVENT:RemovePlayer(ply)
    table.remove(self.Players, table.KeyFromValue(self.Players, ply) or 0)
    self.PlayerBets[ply] = nil

    if #self.Players < self.MinPlayers then
        self:End()
        -- TODO leave comment stating too few players are alive+playing to continue the round of poker
    end
end

--// Net Receives

local function AllPlayersReady(playerTable)
    for _, ply in ipairs(playerTable) do
        if not ply:IsBot() and (ply.Ready == nil or not ply.Ready) then
            return false
        end
    end

    return true
end

net.Receive("StartPokerRandomatCallback", function(len, ply)
    if not EVENT.Started then return end

    if not timer.Exists("PokerStartTimeout") then
        timer.Create("PokerStartTimeout", 5, 1, function() -- TODO Turn the 5 into a ConVar - TODO need to check if we haven't already started the game before running this
            if EVENT.Running then return end

            for index, unreadyPly in ipairs(EVENT.Players) do
                if not unreadyPly.Ready then
                    EVENT:RemovePlayer(unreadyPly)
                end
            end

            EVENT:StartGame()
        end)
    end

    ply.Ready = true

    if AllPlayersReady(EVENT.Players) then
        EVENT:StartGame()
    end
end)

net.Receive("MakeBet", function(len, ply)
    if not EVENT.Started then return end

    local betAmt = net.ReadUInt(3)
    local bet = net.ReadUInt(3)

    EVENT:RegisterPlayerBet(ply, bet, betAmt)
end)

net.Receive("MakeDiscard", function(len, ply)
    if not EVENT.Started or not EVENT.AcceptingDiscards then return end

    local cardsBeingDiscarded = {}
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
    if EVENT.Started and table.HasValue(EVENT.Players, ply) then
        EVENT:RegisterPlayerBet(ply, BettingStatus.FOLD, Bets.NONE)
        EVENT:RemovePlayer(ply)
    end
end)

hook.Add("PlayerDeath", "Player Death Folds In Poker", function(ply)
    if EVENT.Started and table.HasValue(EVENT.Players, ply) then
        EVENT:RegisterPlayerBet(ply, BettingStatus.FOLD, Bets.NONE)
        EVENT:RemovePlayer(ply)
    end
end)

hook.Add("PlayerSilentDeath", "Silent Player Death Folds In Poker", function(ply)
    if EVENT.Started and table.HasValue(EVENT.Players, ply) then
        EVENT:RegisterPlayerBet(ply, BettingStatus.FOLD, Bets.NONE)
        EVENT:RemovePlayer(ply)
    end
end)

Randomat:register(EVENT)