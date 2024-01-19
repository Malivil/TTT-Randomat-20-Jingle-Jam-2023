--// Logan Christianson

local LoganPanel = {}
LoganPanel.Font = "Trebuchet22"

function LoganPanel:SetFont(newFont)
    self.Font = newFont
end

-- Don't register this, it's used as a base for other vgui elements

local LoganButton = table.Copy(LoganPanel)
LoganButton.IsHover = false
LoganButton.Disabled = false
LoganButton.CustomDoClick = function() end

function LoganButton:SetDisabled(newDisabled)
    self.Disabled = newDisabled
end

function LoganButton:SetHover(newHover)
    self.IsHover = newHover
end

function LoganButton:OnCursorEntered()
    if not self.Disabled then
        self.IsHover = true
    end
end

function LoganButton:OnCursorExited()
    self.IsHover = false
end

function LoganButton:SetDoClick(doClickFunc)
    this.CustomDoClick = doClickFunc
end

function LoganButton:DoClick()
    if not self.Disabled then
        self:CustomDoClick()
    end
end

-- Don't register this, it's used as a base for other vgui elements

local PlayerCard = table.Copy(LoganPanel)
PlayerCard.Player = nil
PlayerCard.Action = ""
PlayerCard.Bet = 0
PlayerCard.NameWidth = 0
PlayerCard.NameHeight = 0
PlayerCard.ActionWidth = 0
PlayerCard.ActionHeight = 0
PlayerCard.IsFolded = false

function PlayerCard:SetFont(newfont)
    self.Font = newFont

    if self.Player then
        self:CalculateNameSize()
    end
end

function PlayerCard:SetPlayer(ply)
    self.Player = ply

    self:CalculateNameSize()
end

function PlayerCard:CalculateNameSize()
    surface.SetFont(self.Font)

    self.NameWidth, self.NameHeight = surface.GetTextSize(self.Player:GetName()) -- TODO this will likely need to be cut off after enough characters
end

function PlayerCard:SetBet(newBet)
    self.Bet = newBet
end

function PlayerCard:SetAction(newAction)
    self.Action = newAction

    self:CalculateActionSize()
end

function PlayerCard:CalculateActionSize()
    surface.SetFont(self.Font)

    self.ActionWidth, self.ActionHeight = surface.GetTextSize(self.Action)
end

function PlayerCard:SetFolded()
    self.IsFolded = true
end

function PlayerCard:Paint()
    if !self then return end

    if self.IsFolded or not self.Player then
        -- Draw a gray overlay, does this need to occur at the end?
        -- If we move to bottom, how to check player is valid and return early?
    end

    -- surface.SetDrawColor(0, 0, 0)
    surface.SetDrawColor(255, 255, 255)
    surface.SetFont(self.Font)
    surface.SetTextPos(self:GetWide() * 0.5 - (self.NameWidth * 0.5), 10)
    surface.DrawText(self.Player:GetName())
    surface.DrawLine(self:GetWide() * 0.5 - (self.NameWidth * 0.5), 10 + self.NameHeight + 2)

    -- Draw current bet here
    --surface.something, text or an image?

    -- Draw action here
    surface.SetTextPos(self:GetWide() * 0.5 - (self.ActionWdith * 0.5), self:GetTall() - self.ActionHeight - 10)
    surface.DrawText(self.Action)
end

vgui.Register("Poker_PlayerPanel", PlayerCard, "DPanel")

local OtherPlayers = table.Copy(LoganPanel)
OtherPlayers.PlayersTable = []
OtherPlayers.PlayerCards = []

function OtherPlayers:SetPlayers(playersTable)
    self.PlayersTable = playersTable

    for _, ply in ipairs(self.PlayersTable) do
        if ply ~= LocalPlayer() then
            local newCard = vgui.Create("Poker_PlayerCard", self)
            newCard:SetPlayer(ply)

            self.PlayerCards[ply] = newCard
        end
    end
end

function OtherPlayers:SetPlayerAction(ply, action)
    local card = self.PlayerCards[ply]

    if card then
        card:SetAction(action)
    end
end

function OtherPlayers:SetBet(ply, bet)
    local card = self.PlayerCards[ply]

    if card then
        card:SetBet(bet)
    end
end

vgui.Register("Poker_AllPlayerPanels", OtherPlayers, "DPanel")

local Card = table.Copy(LoganButton)
Card.CanDraw = false
Card.SelectedForDiscard = false
Card.CanSelectForDiscard = false
Card.Rank = Cards.NONE
Card.Suit = Suits.NONE
Card.Graphics = [
    Suits.SAPDES = [],
    Suits.HEARTS = [],
    Suits.DIAMONDS = [],
    Suits.CLUBS = []
]

function Card:SetRank(newRank)
    self.Rank = newRank

    self:UpdateCanDraw()
end

function Card:SetSuit(newSuit)
    self.Suit = newSuit

    self:UpdateCanDraw()
end

function Card:UpdateCanDraw()
    if self.Rank > Cards.NONE and self.Suit > Suit.NONE then
        self.CanDraw = true
    end
end

function Card:SetCanSelectForDiscard(canDiscard)
    self.CanSelectForDiscard = canDiscard
end

function Card:CustomDoClick()
    if self.CanSelectForDiscard then
        self.SelectedForDiscard = not self.SelectedForDiscard
    end
end

function Card:Paint()
    if not self.CanDraw then return end

    --set material, draw card png

    if self.SelectedForDiscard then
        -- Card has been selected for discard
    elseif self.CanSelectForDiscard then
        -- (All) cards can be selected for discard
    elseif self.Disabled then
        -- Card has been disabled, gray overlay?
    end
end

vgui.Register("Poker_Card", Card, "DButton")

local Hand = {}
Hand.Cards = []
Hand.CardsToDiscard = []
Hand.CanDiscard = false

function Hand:

function Hand:SetHand(newHand)
    if #self.Cards > 0 then
        -- For each card no longer in hand, discard
    end

    self.Cards = newHand

    for _, card in ipairs(newHand) do
        local newCard = vgui.Create("Poker_Card", self)
        newCard:SetRank(card.Rank)
        newCard:SetSuit(card.Suit)

        table.insert(self.Cards, newCard)

        -- do some animation?
    end
end

function Hand:SetCanDiscard(canDiscard)
    self.CanDiscard = canDiscard

    for _, cardPanel in ipairs(self.Cards) do
        cardPanel:SetCanSelectForDiscard(canDisard)
    end
end

vgui.Register("Poker_Hand", Hand, "DPanel")