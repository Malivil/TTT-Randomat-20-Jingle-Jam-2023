--// Logan Christianson

local EVENT = {}

EVENT.Title = "A Round Of Yogscast Poker"
EVENT.Description = "Only if the 9 of Diamonds touch!"
EVENT.ExtDescription = "A round of 5-Card Draw Poker, bet with your health. Up to 7 may play. Any pair, three, or four of a kind containing the 9 of Diamonds instantly wins."
EVENT.id = "poker"
EVENT.MinPlayers = 2
EVENT.Type = EVENT_TYPE_DEFAULT
EVENT.Categories = {"gamemode", "largeimpact", "fun"} -- Add more?

-- Called when an event is started. Must be defined to for an event to work.
function EVENT:Begin()
    local maxPlayers = 7 -- Max amount of players allowed in the game
    local baseBlind = 5 -- The base blind amount (big blind is double this)
    local livingPlayers = self:GetAlivePlayers(true)

    local numPlayersOverMax = #livingPlayers - maxPlayers
    while numPlayersOverMax > 0 do
        table.remove(livingPlayers)
        numPlayersOverMax = numPlayersOverMax - 1
    end

    local bigBlind = livingPlayers[1]
    local littleBlind = livingPlayers[2]
end

-- Called when an event is stopped. Used to do manual cleanup of processes started in the event.
function EVENT:End()
end

-- Gets tables of the convars defined for an event. Used primarily by the Randomat 2.0 ULX module to dynamically create configuration pages for each event.
function EVENT:GetConVars()
end

net.Receive("")

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
    - StartDiscardCallback(x) cl -> sv, notifies server of x player's discards
    - Repeat DealCards to any remaining players
    - Repeat StartBetting(x) to any remaining players
    - Calculate winner -
    - RevealHands sv -> cl, reveals all hands still in at the end of the round to all player
    - DeclareWinner sv -> cl, declares the winner
]]