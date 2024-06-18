-- Logan Christianson

PokerConVars = PokerConVars or {}
PokerConVars.ManualRoundStateTimes = PokerConVars.ManualRoundStateTimes or CreateConVar("randomat_poker_manual_round_state_times", "0", FCVAR_REPLICATED, "Enables use of the various 'RoundState*' PokerConVars")
PokerConVars.RoundStateStart = PokerConVars.RoundStateStart or CreateConVar("randomat_poker_round_state_start", "5", FCVAR_REPLICATED, "Manually overrides how long clients have to repond to the initial game start", 1, 10)
PokerConVars.RoundStateBetting = PokerConVars.RoundStateBetting or CreateConVar("randomat_poker_round_state_betting", "30", FCVAR_REPLICATED, "Manually overrides how long the 'betting' phase of the round lasts", 5, 60)
PokerConVars.RoundStateDiscarding = PokerConVars.RoundStateDiscarding or CreateConVar("randomat_poker_round_state_discarding", "30", FCVAR_REPLICATED, "Manually overrides how long the 'discarding' phase of the round lasts", 5, 60)
PokerConVars.RoundStateMessage = PokerConVars.RoundStateMessage or CreateConVar("randomat_poker_round_state_message", "5", FCVAR_REPLICATED, "Manually overrides how long the round state messages should appear for", 1, 10)
PokerConVars.RoundStateEnd = PokerConVars.RoundStateEnd or CreateConVar("randomat_poker_round_state_end", "5", FCVAR_REPLICATED, "Manually overrides how long the game outcome message lasts for (as well as how long to wait"
    .. " before starting a new round if continuous play is enabled)", 1, 60)
PokerConVars.EnableYogsification = PokerConVars.EnableYogsification or CreateConVar("randomat_poker_enable_yogsification", "1", FCVAR_REPLICATED, "Enables the Yogscast sfx")
PokerConVars.EnableRoundStateAudioCues = PokerConVars.EnableRoundStateAudioCues or CreateConVar("randomat_poker_enable_audio_cues", "1", FCVAR_REPLICATED, "Enables the round state audio cues")
PokerConVars.EnableContinuousPlay = PokerConVars.EnableContinuousPlay or CreateConVar("randomat_poker_enable_continuous_play", "0", FCVAR_REPLICATED, "Enables continuous play, event repeats until TTT game ends")
PokerConVars.EnableSmallerBets = PokerConVars.EnableSmallerBets or CreateConVar("randomat_poker_enable_smaller_bets", "0", FCVAR_REPLICATED, "Enables smaller bet increments (default: 25-50-75-100, alt: 10-20-30-...-100)")
PokerConVars.EnableNineDiamondsGag = PokerConVars.EnableNineDiamondsGag or CreateConVar("randomat_poker_enable_nine_diamonds", "1", FCVAR_REPLICATED, "Enables the 9 of Diamonds win condition gag")

PokerConVars.EnableRandomCollusions = PokerConVars.EnableRandomCollusions or CreateConVar("randomat_poker_colluding_enable_random_collusions", "1", FCVAR_REPLICATED, "Enables whether your colluding partner should be randomized or ordered")
PokerConVars.AnonymizeCollusions = PokerConVars.AnonymizeCollusions or CreateConVar("randomat_poker_colluding_anonymized_collusions", "1", FCVAR_REPLICATED, "Enables whether the colluding partner's name should be hidden")

DynamicTimerPlayerCount = 0
function GetDynamicRoundTimerValue(conVar)
    if PokerConVars.ManualRoundStateTimes:GetBool() then
        return PokerConVars[conVar]:GetInt()
    elseif ({RoundStateMessage = true, RoundStateStart = true, RoundStateEnd = true})[conVar] then
        return 5
    else
        local window = 30

        if DynamicTimerPlayerCount >= 5 then
            window = 20
        end

        return window
    end
end


BettingStatus = {
    NONE = 0,
    FOLD = 1,
    CHECK = 2,
    CALL = 3,
    RAISE = 4,
    ALL_IN = 5
}

Bets = {
    NONE = 0,
    QUARTER = 1,
    HALF = 2,
    THREEQ = 3,
    ALL = 4
}

Bets_Alt = {
    NONE = 0,
    TEN = 1,
    TWENTY = 2,
    THIRTY = 3,
    FOURTY = 4,
    FIFTY = 5,
    SIXTY = 6,
    SEVENTY = 7,
    EIGHTY = 8,
    NINETY = 9,
    ALL = 10
}

Hands = {
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

Cards = {
    NONE = 0,
    ACE = 1,
    TWO = 2,
    THREE = 3,
    FOUR = 4,
    FIVE = 5,
    SIX = 6,
    SEVEN = 7,
    EIGHT = 8,
    NINE = 9,
    TEN = 10,
    JACK = 11,
    QUEEN = 12,
    KING = 13,
    ACE_HIGH = 14
}

Suits = {
    NONE = 0,
    SPADES = 1,
    HEARTS = 2,
    DIAMONDS = 3,
    CLUBS = 4
}

function CardRankToFileName(rank)
    if rank == Cards.NONE then
        return ""
    elseif rank == Cards.ACE then
        return "ace"
    elseif rank == Cards.JACK then
        return "jack"
    elseif rank == Cards.QUEEN then
        return "queen"
    elseif rank == Cards.KING then
        return "king"
    else
        return tostring(rank)
    end
end

function CardRankToName(rank)
    if rank == Cards.NONE then
        return ""
    elseif rank == Cards.ACE then
        return "Ace"
    elseif rank == Cards.JACK then
        return "Jack"
    elseif rank == Cards.QUEEN then
        return "Queen"
    elseif rank == Cards.KING then
        return "King"
    elseif rank == Cards.TWO then
        return "Two"
    elseif rank == Cards.THREE then
        return "Three"
    elseif rank == Cards.FOUR then
        return "Four"
    elseif rank == Cards.FIVE then
        return "Five"
    elseif rank == Cards.SIX then
        return "Six"
    elseif rank == Cards.SEVEN then
        return "Seven"
    elseif rank == Cards.EIGHT then
        return "Eight"
    elseif rank == Cards.NINE then
        return "Nine"
    elseif rank == Cards.TEN then
        return "Ten"
    else
        return tostring(rank)
    end
end

function CardSuitToName(suit)
    if suit == Suits.NONE then
        return ""
    elseif suit == Suits.SPADES then
        return "Spades"
    elseif suit == Suits.HEARTS then
        return "Hearts"
    elseif suit == Suits.DIAMONDS then
        return "Diamonds"
    elseif suit == Suits.CLUBS then
        return "Clubs"
    else
        return tostring(suit)
    end
end

local function RegularBetToString(bet)
    if bet == Bets.NONE then
        return "NONE"
    elseif bet == Bets.QUARTER then
        return "QUARTER"
    elseif bet == Bets.HALF then
        return "HALF"
    elseif bet == Bets.THREEQ then
        return "3/4"
    elseif bet == Bets.ALL then
        return "ALL-IN"
    else
        return ""
    end
end

local function AltBetToString(bet)
    if bet == Bets_Alt.NONE then
        return "NONE"
    elseif bet == Bets_Alt.ALL then
        return "ALL-IN"
    else
        return bet .. "0%"
    end
end

function BetToString(bet)
    if PokerConVars.EnableSmallerBets:GetBool() then
        return AltBetToString(bet)
    else
        return RegularBetToString(bet)
    end
end

function BetStatusToString(bettingStatus)
    if bettingStatus == BettingStatus.NONE then
        return "NO BET"
    elseif bettingStatus == BettingStatus.FOLD then
        return "FOLD"
    elseif bettingStatus == BettingStatus.CHECK then
        return "CHECK"
    elseif bettingStatus == BettingStatus.CALL then
        return "CALL"
    elseif bettingStatus == BettingStatus.RAISE then
        return "RAISE"
    elseif bettingStatus == BettingStatus.ALL_IN then
        return "ALL IN"
    else
        return ""
    end
end

function GetLittleBlindBet()
    if PokerConVars.EnableSmallerBets:GetBool() then
        return Bets_Alt.TEN
    else
        return Bets.QUARTER
    end
end

function GetBigBlindBet()
    if PokerConVars.EnableSmallerBets:GetBool() then
        return Bets_Alt.TWENTY
    else
        return Bets.HALF
    end
end

function IsAllIn(bet)
    if PokerConVars.EnableSmallerBets:GetBool() then
        return bet == Bets_Alt.ALL
    else
        return bet == Bets.ALL
    end
end

function PrintHand(hand, shouldTab)
    for i, card in pairs(hand) do
        local toPrint = ""
        if shouldTab then toPrint = "\t" end
        print(toPrint .. CardRankToName(card.Rank) .. "(" .. card.Rank .. ") of " .. CardSuitToName(card.Suit) .. "(" .. card.Suit .. ")")
    end
end