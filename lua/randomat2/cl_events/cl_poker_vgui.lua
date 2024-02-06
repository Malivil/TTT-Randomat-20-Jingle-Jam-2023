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

-- function LoganButton:SetText(text)
-- end

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

function LoganButton:CustomDoClick()
end

function LoganButton:DoClick()
    if not self.Disabled then
        self:CustomDoClick()
    end
end

vgui.Register("Poker_Button", LoganButton, "DButton")

local PlayerCard = table.Copy(LoganPanel)
PlayerCard.BetIcon = Material("a")
PlayerCard.Player = nil
PlayerCard.NoPlayerName = "No Player!"
PlayerCard.ActionText = ""
PlayerCard.BetText = ""
PlayerCard.BlindStatus = ""
PlayerCard.Action = 0
PlayerCard.Bet = 0
PlayerCard.NameWidth = 0
PlayerCard.NameHeight = 0
PlayerCard.ActionWidth = 0
PlayerCard.ActionHeight = 0
PlayerCard.BetWidth = 0
PlayerCard.BetHeight = 0
PlayerCard.IsFolded = false
PlayerCard.IsBetting = false

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

function PlayerCard:SetBlindStatus(text)
    self.BlindStatus = text
end

function PlayerCard:CalculateNameSize()
    surface.SetFont(self.Font)

    if self.Player then
        self.NameWidth, self.NameHeight = surface.GetTextSize(self.Player:GetName()) -- TODO this will likely need to be cut off after enough characters
    else
        self.NameWidth, self.NameHeight = surface.GetTextSize(self.NoPlayerName)
    end
end

function PlayerCard:SetBet(newBet)
    self.Bet = newBet
    self.BetText = BetToString(self.Bet)

    self:CalculateBetSize()
end

function PlayerCard:CalculateBetSize()
    surface.SetFont(self.Font)

    self.BetWidth, self.BetHeight = surface.GetTextSize(self.BetText)
end

function PlayerCard:SetAction(newAction)
    self.Action = newAction
    self.ActionText = BetStatusToString(self.Action)

    self:CalculateActionSize()
end

function PlayerCard:CalculateActionSize()
    surface.SetFont(self.Font)

    self.ActionWidth, self.ActionHeight = surface.GetTextSize(self.ActionText)
end

function PlayerCard:SetFolded()
    self.IsFolded = true
end

function PlayerCard:SetIsBetting(isBetting)
    self.IsBetting = isBetting
end

function PlayerCard:Paint()
    if !self then return end
    surface.SetFont(self.Font)

    surface.SetDrawColor(0, 0, 0)
    surface.DrawOutlinedRect(1, 1, self:GetWide() - 2, self:GetTall() - 2, 2)

    if not self.Player then
        surface.SetDrawColor(0, 0, 0, 120)
        surface.DrawRect(1, 1, self:GetWide() - 2, self:GetTall() - 2)
        
        surface.SetTextColor(255, 255, 255)
        surface.SetTextPos(self:GetWide() * 0.5 - (self.NameWidth * 0.5), self:GetTall() * 0.5 - (self.NameHeight * 0.5))
        surface.DrawText(self.NoPlayerName)

        return
    end    

    surface.SetFont("Trebuchet18")
    surface.SetTextColor(255, 255, 255)
    surface.SetTextPos(6, 3)
    surface.DrawText(self.BlindStatus)

    -- Name
    surface.SetFont(self.Font)
    surface.SetTextColor(255, 255, 255)
    surface.SetTextPos(self:GetWide() * 0.5 - (self.NameWidth * 0.5), 10)
    surface.DrawText(self.Player:GetName())
    surface.SetDrawColor(255, 255, 255)
    surface.DrawLine(self:GetWide() * 0.5 - (self.NameWidth * 0.5), 10 + self.NameHeight, self:GetWide() * 0.5 + (self.NameWidth * 0.5), 10 + self.NameHeight)

    -- Bet amount
    surface.SetTextPos(self:GetWide() * 0.5 - (self.BetWidth * 0.5), self:GetTall() * 0.5 - (self.BetHeight * 0.5))
    surface.DrawText(self.BetText)

    -- Recent Action
    surface.SetTextPos(self:GetWide() * 0.5 - (self.ActionWidth * 0.5), self:GetTall() - 10 - self.ActionHeight)
    surface.DrawText(self.ActionText)

    if self.IsBetting then
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(self.BetIcon)
        surface.DrawTexturedRect(self:GetWide() * 0.5 + (self.NameWidth * 0.5) + 2, 10, 24, 24)

        surface.SetDrawColor(255, 215, 0, 140)
        surface.DrawOutlinedRect(4, 4, self:GetWide() - 8, self:GetTall() - 8, 4)
    end

    if self.IsFolded then
        surface.SetDrawColor(0, 0, 0, 220)
        surface.DrawRect(1, 1, self:GetWide() - 2, self:GetTall() - 2)

        surface.SetTextColor(255, 255, 255)
        surface.SetTextPos(self:GetWide() * 0.5 - 25, self:GetTall() * 0.5 - 5)
        surface.DrawText("Folded!")
    end
end

vgui.Register("Poker_PlayerPanel", PlayerCard, "DPanel")

local OtherPlayers = table.Copy(LoganPanel)
OtherPlayers.PlayersTable = {}
OtherPlayers.PlayerPanels = {}

function OtherPlayers:SetPlayers(playersTable)
    self.PlayersTable = playersTable
    table.RemoveByValue(self.PlayersTable, LocalPlayer())

    for i = 1, 6 do
        local ply = self.PlayersTable[i]
        local row2 = 0

        if i > 3 then row2 = 1 end

        local newPanel = vgui.Create("Poker_PlayerPanel", self)
        newPanel:SetPlayer(ply)
        newPanel:SetSize(self:GetWide() * 0.33, self:GetTall() * 0.5)
        newPanel:SetPos(newPanel:GetWide() * ((i - 1) % 3), newPanel:GetTall() * row2)

        if ply then
            self.PlayerPanels[ply] = newPanel
        else
            self.PlayerPanels[i] = newPanel
        end
    end
end

function OtherPlayers:SetBlinds(littleBlind, bigBlind)
    local littleBlindPanel = self.PlayerPanels[littleBlind]
    local bigBlindPanel = self.PlayerPanels[bigBlind]
    
    if littleBlindPanel then
        littleBlindPanel:SetBlindStatus("LB")
    end

    if bigBlindPanel then
        bigBlindPanel:SetBlindStatus("BB")
    end
end

function OtherPlayers:SetPlayerAction(ply, action)
    local card = self.PlayerPanels[ply]

    if card then
        card:SetAction(action)
    end
end

function OtherPlayers:SetPlayerBet(ply, betType, bet)
    local card = self.PlayerPanels[ply]

    if card then
        if betType == BettingStatus.FOLD then
            card:SetFolded()
        elseif betType == BettingStatus.CHECK then
            -- Do nothing? Set message?
        elseif betType == BettingStatus.CALL then
            card:SetBet(bet)
        elseif betType == BettingStatus.RAISE then
            card:SetBet(bet)
        end
    end
end

function OtherPlayers:SetPlayerAsBetting(ply)
    for _, plyLoop in ipairs(self.PlayersTable) do
        local card = self.PlayerPanels[plyLoop]

        if not card then continue end

        if ply == plyLoop then
            card:SetIsBetting(true)
        else
            card:SetIsBetting(false)
        end
    end
end

function OtherPlayers:Paint()
end

vgui.Register("Poker_AllPlayerPanels", OtherPlayers, "DPanel")

local Card = table.Copy(LoganButton)
Card.CanDraw = false
Card.SelectedForDiscard = false
Card.CanSelectForDiscard = false
Card.Rank = 0
Card.Suit = 0
Card.Graphic = nil
Card.GraphicsDir = {"vgui/ttt/randomats/poker/cards/spades/", "vgui/ttt/randomats/poker/cards/hearts/", "vgui/ttt/randomats/poker/cards/diamonds/", "vgui/ttt/randomats/poker/cards/clubs/"}

function Card:SetRank(newRank)
    self.Rank = newRank

    self:UpdateCanDraw()
end

function Card:SetSuit(newSuit)
    self.Suit = newSuit

    self:UpdateCanDraw()
end

function Card:UpdateCanDraw()
    if self.Rank and self.Rank > Cards.NONE and self.Suit and self.Suit > Suits.NONE then
        self.CanDraw = true
        print("UpdateCanDraw called", self.Rank, self.Suit)

        self.Graphic = Material(self.GraphicsDir[self.Suit] .. CardRankToName(self.Rank) .. ".png", "noclamp")
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
    surface.SetMaterial(self.Graphic)
    surface.SetDrawColor(255, 255, 255)
    surface.DrawTexturedRect(0, 0, self:GetWide(), self:GetTall())
    draw.NoTexture()

    surface.SetDrawColor(0, 0, 0)
    surface.DrawOutlinedRect(0, 0, self:GetWide(), self:GetTall(), 2)
    
    if self.SelectedForDiscard then
        -- Card has been selected for discard
    elseif self.CanSelectForDiscard then
        -- (All) cards can be selected for discard
    elseif self.Disabled then
        -- Card has been disabled, gray overlay?
        surface.SetDrawColor(170, 170, 170, 150)
        surface.DrawRect(0, 0, self:GetWide(), self:GetTall())
    end
end

vgui.Register("Poker_Card", Card, "DButton")

local Hand = table.Copy(LoganPanel)
Hand.Cards = {}
Hand.CardsToDiscard = {}
Hand.CanDiscard = false
Hand.CardWide = 180
Hand.CardTall = math.Round(Hand.CardWide * 1.4)

function Hand:SetCardWidth(newWidth)
    self.CardWide = newWidth
    self.CardTall = math.Round(Hand.CardWide * 1.4)
end

function Hand:SetHand(newHand)
    if #self.Cards > 0 then
        -- For each card no longer in hand, discard
    end

    local margin = 20
    local divisableArea = (self:GetWide() - (margin * 2) - self.CardWide) * 0.25
    print("calculated values:", divisableArea * 4)
    for index, card in ipairs(newHand) do
        local newCard = vgui.Create("Poker_Card", self)
        newCard:SetSize(self.CardWide, self.CardTall)
        newCard:SetPos(margin + ((index - 1) * divisableArea), self:GetTall() * 0.25)
        newCard:SetText("")
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

function Hand:Paint()
    surface.SetDrawColor(0, 0, 0)
    surface.DrawOutlinedRect(1, 1, self:GetWide() - 2, self:GetTall() + 4, 2)
    surface.DrawRect(self:GetWide() * 0.5 - 45, 1, 90, 34)

    surface.SetFont(self.Font)
    surface.SetTextColor(255, 255, 255)
    surface.SetTextPos(self:GetWide() * 0.5 - 40, 5)
    surface.DrawText("Your Hand")
end

vgui.Register("Poker_Hand", Hand, "DPanel")

local Controls = table.Copy(LoganPanel)

function Controls:Setup()
    -- Set up vgui buttons for fold, check, call, raise
    -- Can only raise above last (active) player's bet
    -- Also shows current bet
    local margin = 10
    local leftOverSpace = self:GetWide() - (margin * 5)
    local buttonWidth = leftOverSpace * 0.20
    local buttonHeight = margin * 3

    self.Fold = vgui.Create("Poker_Button", self)
    self.Fold:SetPos(margin, self:GetTall() - buttonHeight - margin)
    self.Fold:SetSize(buttonWidth, buttonHeight)
    self.Fold:SetText(BetStatusToString(BettingStatus.FOLD))
    self.Fold:SetDisabled(true)
    self.Fold.CustomDoClick = function()
        print("self.Fold DEBUG")
    end
    -- self.Fold.Paint = function()
    -- end

    self.Check = vgui.Create("Poker_Button", self)
    self.Check:SetPos(margin * 2 + buttonWidth, self:GetTall() - buttonHeight - margin)
    self.Check:SetSize(buttonWidth, buttonHeight)
    self.Check:SetText(BetStatusToString(BettingStatus.CHECK))
    self.Check:SetEnabled(false)
    self.Check.CustomDoClick = function()
        print("self.Check DEBUG")
    end
    -- self.Check.Paint = function()
    -- end

    self.Call = vgui.Create("Poker_Button", self)
    self.Call:SetPos(margin * 3 + buttonWidth * 2, self:GetTall() - buttonHeight - margin)
    self.Call:SetSize(buttonWidth, buttonHeight)
    self.Call:SetText(BetStatusToString(BettingStatus.CALL))
    self.Call.CustomDoClick = function()
    end
    -- self.Call.Paint = function()
    -- end

    self.Raise = vgui.Create("Poker_Button", self)
    self.Raise:SetPos(margin * 4 + buttonWidth * 3, self:GetTall() - buttonHeight - margin)
    self.Raise:SetSize(buttonWidth, buttonHeight)
    self.Raise:SetText(BetStatusToString(BettingStatus.RAISE))
    self.Raise.CustomDoClick = function()
    end
    -- self.Raise.Paint = function()
    -- end

    self.RaiseOpt = vgui.Create("DComboBox", self)
    self.RaiseOpt:SetPos(margin * 4 + buttonWidth * 4 + 2, self:GetTall() - buttonHeight - margin)
    self.RaiseOpt:SetSize(buttonWidth, buttonHeight)
    self.RaiseOpt:SetValue("Bet")
    self.RaiseOpt:AddChoice(BetToString(Bets.HALF), Bets.HALF)
    self.RaiseOpt:AddChoice(BetToString(Bets.THREEQ), Bets.THREEQ)
    self.RaiseOpt:AddChoice(BetToString(Bets.ALL), Bets.ALL)
    self.RaiseOpt.OnSelect = function(raiseOptSelf, index, value, data)
        
    end    
end

function Controls:EnableBetting(time)

end

function Controls:DisableBetting()

end

function Controls:EnableDiscarding(time)

end

function Controls:Paint()
    surface.SetDrawColor(0, 0, 0)
    surface.DrawOutlinedRect(1, 1, self:GetWide() - 2, self:GetTall() + 4, 2)
    surface.DrawRect(self:GetWide() * 0.5 - 45, 1, 90, 34)

    surface.SetFont(self.Font)
    surface.SetTextColor(255, 255, 255)
    surface.SetTextPos(self:GetWide() * 0.5 - 30, 5)
    surface.DrawText("Controls")
end

vgui.Register("Poker_Controls", Controls, "DPanel")

local Main = table.Copy(LoganPanel)
Main.BackgroundMat = Material("vgui/ttt/randomats/poker/poker_table.jpg")
Main.DisplayMessageTime = 0
Main.DisplayTemporaryMessage = false
Main.Folded = false

function Main:GetBackgroundColor(newColor)
    self.BackgroundColor = newColor
end

function Main:TemporaryMessage(message)
    self.DisplayMessageTime = CurTime() + 5
    self.DisplayTemporaryMessage = true
    self.DisplayMessage = message
end

function Main:SetSelfFolded()
    self.Folded = true
end

function Main:SetTitle()
    return ""
end

function Main:SetVisible()
    return true
end

function Main:SetDraggable()
    return false
end

function Main:ShowCloseButton()
    return false
end

function Main:Think()
    if self.DisplayMessageTime > 0 and CurTime() > self.DisplayMessageTime then
        self.DisplayTemporaryMessage = false
        self.DisplayMessageTime = 0
    end
end

function Main:Paint()
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(self.BackgroundMat)
    surface.DrawTexturedRect(0, 0, self:GetWide(), self:GetTall())
end

function Main:PaintOver(currentPanelWidth, currentPanelHeight)
    if self.Folded then
        surface.SetDrawColor(0, 0, 0, 220)
        surface.DrawRect(0, 0, currentPanelWidth, currentPanelHeight)

        draw.DrawText("Folded!", self.Font, currentPanelWidth * 0.5, currentPanelHeight * 0.5, Color(255, 255, 255), TEXT_ALIGN_CENTER)
    elseif self.DisplayTemporaryMessage then
        surface.SetDrawColor(0, 0, 0, 220)
        surface.DrawRect(0, 0, currentPanelWidth, currentPanelHeight)

        draw.DrawText(self.DisplayMessage, self.Font, currentPanelWidth * 0.5, currentPanelHeight * 0.5, Color(255, 255, 255), TEXT_ALIGN_CENTER)
    end
end

vgui.Register("Poker_Frame", Main, "DFrame")