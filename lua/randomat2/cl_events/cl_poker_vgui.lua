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
        surface.PlaySound("ui/buttonclick.wav")
    end
end

vgui.Register("Poker_Button", LoganButton, "DButton")

local PlayerCard = table.Copy(LoganPanel)
PlayerCard.BetIcon = Material("vgui/ttt/randomats/poker/poker_hand.png")
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
    if not self then return end
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
    surface.SetTextPos(6, 1)
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
Card.AvailableForDiscard = false
Card.IsBeingDiscarded = false
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

        self.Graphic = Material(self.GraphicsDir[self.Suit] .. CardRankToFileName(self.Rank) .. ".png", "noclamp")
    end
end

function Card:SetCanSelectForDiscard(canDiscard)
    self.AvailableForDiscard = canDiscard
end

function Card:SetBeingDiscarded(isDiscarded)
    self.IsBeingDiscarded = isDiscarded
end

function Card:CustomDoClick()
    if self.AvailableForDiscard and not self.Disabled then
        self.SelectedForDiscard = not self.SelectedForDiscard
    end
end

function Card:Paint()
    if not self.CanDraw then return end

    surface.SetMaterial(self.Graphic)
    surface.SetDrawColor(255, 255, 255)
    surface.DrawTexturedRect(0, 0, self:GetWide(), self:GetTall())
    draw.NoTexture()

    surface.SetDrawColor(0, 0, 0)
    surface.DrawOutlinedRect(0, 0, self:GetWide(), self:GetTall(), 2)

    if self.Disabled then
        surface.SetDrawColor(170, 170, 170, 150)
        surface.DrawRect(0, 0, self:GetWide(), self:GetTall())
    elseif self.AvailableForDiscard and self:IsHovered() then
        surface.SetDrawColor(180, 255, 180, 255)
        surface.DrawOutlinedRect(0, 0, self:GetWide(), self:GetTall(), 4)
    elseif self.IsBeingDiscarded then
        surface.SetDrawColor(130, 130, 130, 200)
        surface.DrawRect(0, 0, self:GetWide(), self:GetTall())
    elseif self.SelectedForDiscard then
        surface.SetDrawColor(255, 60, 60, 255)
        surface.DrawOutlinedRect(0, 0, self:GetWide(), self:GetTall(), 4)
    end
end

vgui.Register("Poker_Card", Card, "DButton")

local Hand = table.Copy(LoganPanel)
Hand.Cards = {}
Hand.CardsToDiscard = {}
Hand.CanDiscard = false
Hand.CardWide = 180
Hand.NumSelectCards = 0
Hand.CardTall = math.Round(Hand.CardWide * 1.4)

function Hand:SetCardWidth(newWidth)
    self.CardWide = newWidth
    self.CardTall = math.Round(Hand.CardWide * 1.4)
end

function Hand:SetHand(newHand)
    for i, card in ipairs(self.Cards) do
        card:Remove()
    end
    table.Empty(self.Cards)

    local margin = 20
    local divisableArea = (self:GetWide() - (margin * 2) - self.CardWide) * 0.25

    for index, card in ipairs(newHand) do
        local newCard = vgui.Create("Poker_Card", self)
        newCard:SetSize(self.CardWide, self.CardTall)
        newCard:SetPos(margin + ((index - 1) * divisableArea), self:GetTall() * 0.25)
        newCard:SetText("")
        newCard:SetRank(card.Rank)
        newCard:SetSuit(card.Suit)
        newCard:SetCanSelectForDiscard(false)
        newCard:SetBeingDiscarded(false)

        table.insert(self.Cards, newCard)
    end
end

function Hand:SetCanDiscard(canDiscard)
    self.CanDiscard = canDiscard

    for _, cardPanel in ipairs(self.Cards) do
        cardPanel:SetCanSelectForDiscard(canDisard)
    end

    local function ClosePanels()
        if self.DiscardButton then
            self.DiscardButton:Remove()
            self.DiscardButton = nil

            self.DiscardButtonBackground:Remove()
            self.DiscardButtonBackground = nil
        end
    end

    if canDiscard then
        self.DiscardButtonBackground = vgui.Create("DPanel", self)
        self.DiscardButtonBackground:SetPos(0, self:GetTall() * 0.7 - 4)
        self.DiscardButtonBackground:SetSize(self:GetWide(), 42)
        self.DiscardButtonBackground.Paint = function()
            surface.SetDrawColor(0, 0, 0)
            surface.DrawRect(0, 0, self:GetWide(), self:GetTall())
        end

        self.DiscardButton = vgui.Create("Control_Button", self)
        self.DiscardButton:SetSize(self:GetWide() * 0.5 - 65, 34)
        self.DiscardButton:SetPos(self:GetWide() * 0.5 - (self.DiscardButton:GetWide() * 0.5), self:GetTall() * 0.7)
        self.DiscardButton:SetText("DISCARD")
        self.DiscardButton.CustomDoClick = function()
            self:Discard()
            ClosePanels()
        end
    else
        ClosePanels()
    end
end

function Hand:Discard()
    if not self.CanDiscard then return end

    net.Start("MakeDiscard")
        net.WriteUInt(self.NumSelectCards, 2)
        for _, cardPanel in ipairs(self.CardsToDiscard) do
            net.WriteUInt(cardPanel.Rank, 5)
            net.WriteUInt(cardPanel.Suit, 3)
        end
    net.SendToServer()

    self.CanDiscard = false

    for _, cardPanel in ipairs(self.Cards) do
        cardPanel:SetCanSelectForDiscard(false)

        if table.HasValue(self.CardsToDiscard, cardPanel) then
            cardPanel:SetBeingDiscarded(true)
        end
    end
end

function Hand:Think()
    if not self.CanDiscard then return end

    local selectedCards = {}
    local unselectedCards = {}

    for _, cardPanel in ipairs(self.Cards) do
        if cardPanel.SelectedForDiscard then
            table.insert(selectedCards, cardPanel)
        else
            table.insert(unselectedCards, cardPanel)
        end
    end

    self.CardsToDiscard = selectedCards
    self.NumSelectCards = math.min(#selectedCards, 3)

    for _, cardPanel in ipairs(unselectedCards) do
        cardPanel:SetCanSelectForDiscard(self.NumSelectCards < 3)
        cardPanel:SetDisabled(self.NumSelectCards == 3)
    end

    if self.DiscardButton then
        self.DiscardButton:SetDisabled(self.NumSelectCards < 1)
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
Controls.EnableTimer = false
Controls.CurrentRaise = 2
Controls.CurrentBet = 0

function Controls:SetCurrentBet(amount)
    self.CurrentBet = amount

    self:SetCurrentRaise(amount)
end

function Controls:SetCurrentRaise(amount)
    self.CurrentRaise = amount

    self:ResetRaiseOptions(self.CurrentRaise)
end

function Controls:Setup()
    -- Set up vgui buttons for fold, check, call, raise
    local margin = 10
    local leftOverSpace = self:GetWide() - (margin * 5)
    local buttonWidth = leftOverSpace * 0.20
    local buttonHeight = margin * 3

    self.Fold = vgui.Create("Control_Button", self, "Fold Button")
    self.Fold:SetPos(margin, self:GetTall() - buttonHeight - margin)
    self.Fold:SetSize(buttonWidth, buttonHeight)
    self.Fold:SetText(BetStatusToString(BettingStatus.FOLD))
    self.Fold:SetEnabled(false)
    self.Fold.CustomDoClick = function()
        net.Start("MakeBet")
            net.WriteUInt(BettingStatus.FOLD, 3)
            net.WriteUInt(0, 3)
        net.SendToServer()

        self:DisableBetting()
    end

    self.Check = vgui.Create("Control_Button", self, "Check Button")
    self.Check:SetPos(margin * 2 + buttonWidth, self:GetTall() - buttonHeight - margin)
    self.Check:SetSize(buttonWidth, buttonHeight)
    self.Check:SetText(BetStatusToString(BettingStatus.CHECK))
    self.Check:SetEnabled(false)
    self.Check.CustomDoClick = function()
        net.Start("MakeBet")
            net.WriteUInt(BettingStatus.CHECK, 3)
            net.WriteUInt(self.CurrentBet, 3)
        net.SendToServer()

        self:DisableBetting()
    end

    self.Call = vgui.Create("Control_Button", self, "Call Button")
    self.Call:SetPos(margin * 3 + buttonWidth * 2, self:GetTall() - buttonHeight - margin)
    self.Call:SetSize(buttonWidth, buttonHeight)
    self.Call:SetText(BetStatusToString(BettingStatus.CALL))
    self.Call:SetEnabled(false)
    self.Call.CustomDoClick = function()
        net.Start("MakeBet")
            net.WriteUInt(BettingStatus.CALL, 3)
            net.WriteUInt(self.CurrentRaise, 3)
        net.SendToServer()

        self:DisableBetting()
    end

    self.Raise = vgui.Create("Control_Button", self, "Raise Button")
    self.Raise:SetPos(margin * 4 + buttonWidth * 3, self:GetTall() - buttonHeight - margin)
    self.Raise:SetSize(buttonWidth, buttonHeight)
    self.Raise:SetText(BetStatusToString(BettingStatus.RAISE))
    self.Raise:SetEnabled(false)
    self.Raise.CustomDoClick = function()
        local _, val = self.RaiseOpt:GetSelected()

        if val then
            net.Start("MakeBet")
                net.WriteUInt(BettingStatus.RAISE, 3)
                net.WriteUInt(val, 3)
            net.SendToServer()

            self:DisableBetting()
        end
    end

    -- I'm *not* making this a custom component because this is used only here and I'm sick of working on custom vgui elements
    -- Most of this is ripped from the specific component's github page and then changed with styling to match everything else
    self.RaiseOpt = vgui.Create("DComboBox", self)
    self.RaiseOpt:SetPos(margin * 4 + buttonWidth * 4 + 2, self:GetTall() - buttonHeight - margin)
    self.RaiseOpt:SetSize(buttonWidth, buttonHeight)
    self.RaiseOpt:SetSortItems(false)
    self.RaiseOpt:AddSpacer()
    self.RaiseOpt:SetEnabled(false)
    self.RaiseOpt.OnSelect = function(raiseOptSelf, index, value, data)
    end
    -- Just minimize this function and pretend it's all a bad dream
    self.RaiseOpt.OpenMenu = function(pnl)
        pnl:CloseMenu()
        local parent = pnl
        while ( IsValid( parent ) && !parent:IsModal() ) do
            parent = parent:GetParent()
        end
        if ( !IsValid( parent ) ) then parent = pnl end

        CloseDermaMenus()
        pnl.Menu = vgui.Create( "DMenu", parent )
        pnl.Menu.Paint = function(menuPnl)
            surface.SetDrawColor(255, 255, 255)
            surface.DrawRect(0, 0, pnl:GetWide(), pnl:GetTall())

            surface.SetDrawColor(0, 0, 0)
            surface.DrawOutlinedRect(0, 0, pnl:GetWide(), pnl:GetTall(), 1)
        end
        pnl.Menu.AddOption = function( menuPnl, strText, funcFunction )
            local pnl = vgui.Create( "DMenuOption", menuPnl )
            pnl:SetMenu( menuPnl )
            pnl:SetText( strText )
            pnl.OnCursorEntered = function()
                pnl.IsHover = true
            end
            pnl.OnCursorExited = function()
                pnl.IsHover = false
            end
            pnl.Paint = function()
                surface.SetFont("Trebuchet22")
                local textWide, textTall = surface.GetTextSize(pnl:GetText())
                if pnl.IsHover then
                    surface.SetDrawColor(180, 255, 180)
                else
                    surface.SetDrawColor(255, 255, 255)
                end

                surface.DrawRect(0, 0, pnl:GetWide(), pnl:GetTall())

                surface.SetTextColor(0, 0, 0)
                surface.SetTextPos(pnl:GetWide() * 0.5 - (textWide * 0.5), pnl:GetTall() * 0.5 - (textTall * 0.5))
                surface.DrawText(pnl:GetText())

                surface.SetDrawColor(0, 0, 0)
                surface.DrawLine(0, pnl:GetTall() - 1, pnl:GetWide(), pnl:GetTall() - 1)

                return true
            end
            if ( funcFunction ) then pnl.DoClick = funcFunction end
        
            menuPnl:AddPanel( pnl )
        
            return pnl
        end

        for k, v in pairs( pnl.Choices ) do
			local option = pnl.Menu:AddOption( v, function() pnl:ChooseOption( v, k ) end )
			if ( pnl.Spacers[ k ] ) then
				pnl.Menu:AddSpacer()
			end
		end

        local x, y = pnl:LocalToScreen( 0, pnl:GetTall() )
        pnl.Menu:SetMinimumWidth( pnl:GetWide() )
        pnl.Menu:Open( x, y, false, pnl )

        pnl:OnMenuOpened( pnl.Menu )
    end
    self.RaiseOpt.OnCursorEntered = function(pnl)
        pnl.IsHover = true
    end
    self.RaiseOpt.OnCursorExited = function(pnl)
        pnl.IsHover = false
    end
    self.RaiseOpt.Paint = function(pnl)
        surface.SetFont("Trebuchet22")
        local textWide, textTall = surface.GetTextSize(pnl:GetText())
        if not pnl:GetDisabled() and pnl.IsHover then
            surface.SetDrawColor(180, 255, 180)
        else
            surface.SetDrawColor(255, 255, 255)
        end

        surface.DrawRect(0, 0, pnl:GetWide(), pnl:GetTall())

        surface.SetDrawColor(0, 0, 0)
        surface.DrawOutlinedRect(0, 0, pnl:GetWide(), pnl:GetTall(), 1)

        surface.SetTextColor(0, 0, 0)
        surface.SetTextPos(8, pnl:GetTall() * 0.5 - (textTall * 0.5))
        surface.DrawText(pnl:GetText())
        
        if pnl:GetDisabled() then
            surface.SetDrawColor(0, 0, 0, 180)
            surface.DrawRect(0, 0, pnl:GetWide(), pnl:GetTall())
        end

        return true
    end

    self:ResetRaiseOptions(self.CurrentRaise)
end

function Controls:ResetRaiseOptions(baselineBet)
    self.RaiseOpt:Clear()
    self.RaiseOpt:SetValue("BET")

    baselineBet = baselineBet or 0

    if baselineBet <= Bets.HALF then
        self.RaiseOpt:AddChoice("3/4", Bets.THREEQ)
    end

    if baselineBet <= Bets.THREEQ then
        self.RaiseOpt:AddChoice(BetToString(Bets.ALL), Bets.ALL)
    end

    if baselineBet >= Bets.ALL then
        self.Raise:SetEnabled(false)
        self.RaiseOpt:SetValue("NONE")
    end
end

function Controls:EnableBetting()
    if self.CurrentBet == self.CurrentRaise then
        self.Check:SetEnabled(true)
    else
        self.Call:SetEnabled(true)
    end

    self.Fold:SetEnabled(true)
    self.Raise:SetEnabled(true)
    self.RaiseOpt:SetEnabled(true)
end

function Controls:DisableBetting()
    self.Fold:SetEnabled(false)
    self.Check:SetEnabled(false)
    self.Call:SetEnabled(false)
    self.Raise:SetEnabled(false)
    self.RaiseOpt:SetEnabled(false)
end

function Controls:Paint()
    surface.SetDrawColor(0, 0, 0)
    surface.DrawOutlinedRect(1, 1, self:GetWide() - 2, self:GetTall() + 4, 2)
    surface.DrawRect(self:GetWide() * 0.5 - 45, 1, 90, 34)

    surface.SetFont(self.Font)
    surface.SetTextColor(255, 255, 255)
    surface.SetTextPos(self:GetWide() * 0.5 - 32, 5)
    surface.DrawText("Controls")

    surface.SetFont("Trebuchet18")
    surface.DrawRect(8, 1, 80, 34)
    surface.SetTextPos(18, 4)
    surface.DrawText("Your Bet:")
    surface.SetTextPos(20, 18)
    surface.DrawText(BetToString(self.CurrentBet))

    surface.DrawRect(self:GetWide() - 80, 1, 72, 34)
    surface.SetTextPos(self:GetWide() - 74, 4)
    surface.DrawText("To Match:")
    surface.SetTextPos(self:GetWide() - 72, 18)
    surface.DrawText(BetToString(self.CurrentRaise))
end

vgui.Register("Poker_Controls", Controls, "DPanel")

local ControlButton = table.Copy(LoganButton)

function ControlButton:Paint()
    local text = self:GetText()
    surface.SetFont(self.Font)
    local textWide, textTall = surface.GetTextSize(text)
    if not self.Disabled and self.IsHover then
        surface.SetDrawColor(180, 255, 180)
    else
        surface.SetDrawColor(255, 255, 255)
    end

    surface.DrawRect(0, 0, self:GetWide(), self:GetTall())

    surface.SetDrawColor(0, 0, 0)
    surface.DrawOutlinedRect(0, 0, self:GetWide(), self:GetTall(), 1)

    surface.SetTextColor(0, 0, 0)
    surface.SetTextPos(self:GetWide() * 0.5 - (textWide * 0.5), self:GetTall() * 0.5 - (textTall * 0.5))
    surface.DrawText(text)
    
    if self.Disabled then
        surface.SetDrawColor(0, 0, 0, 180)
        surface.DrawRect(0, 0, self:GetWide(), self:GetTall())
    end

    return true
end

vgui.Register("Control_Button", ControlButton, "DButton")

local Main = table.Copy(LoganPanel)
Main.BackgroundMat = Material("vgui/ttt/randomats/poker/poker_table.jpg")
Main.DisplayMessageTime = 0
Main.TimeRemaining = 0
Main.DisplayTemporaryMessage = false
Main.Folded = false

function Main:Init()
    self:ShowCloseButton(false)
    self:SetTitle("")
end

function Main:TemporaryMessage(message, optionalTime)
    self.DisplayMessageTime = CurTime() + (optionalTime or 5) -- TODO turn into convar
    self.DisplayTemporaryMessage = true
    self.DisplayMessage = message
end

function Main:PermanentMessage(message)
    self.DisplayMessageTime = 0
    self.DisplayTemporaryMessage = true
    self.DisplayMessage = message
end

function Main:SetSelfFolded()
    self.Folded = true
end

function Main:SetTimer(time)
    if time == 0 then
        self.ShowTimer = false
        timer.Remove("PokerMainTimer")
        return
    end

    local width = self:GetWide()

    self.PolyHeader = {
        {x = width * 0.5 + 100, y = 1},
        {x = width * 0.5 + 80, y = 24},
        {x = width * 0.5 - 80, y = 24},
        {x = width * 0.5 - 100, y = 1},
    }

    self.ShowTimer = true
    self.TimeRemaining = time or 0
    if not timer.Exists("PokerMainTimer") then
        timer.Create("PokerMainTimer", 1, 0, function()
            if not self or not IsValid(self) then
                self.ShowTimer = false
                timer.Remove("PokerMainTimer")

                return
            end

            if self.TimeRemaining == 0 or self.TimeRemaining == nil then
                self.ShowTimer = false
                timer.Remove("PokerMainTimer")

                return
            end

            self.TimeRemaining = self.TimeRemaining - 1
        end)
    end
end

function Main:Think()
    if self.DisplayMessageTime > 0 and CurTime() > self.DisplayMessageTime and not self.Folded then
        self.DisplayTemporaryMessage = false
        self.DisplayMessageTime = 0
    end
end

function Main:Paint()
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(self.BackgroundMat)
    surface.DrawTexturedRect(0, 0, self:GetWide(), self:GetTall())
    draw.NoTexture()
end

function Main:PaintOver()
    draw.NoTexture()

    if self.Folded then
        surface.SetDrawColor(0, 0, 0, 240)
        surface.DrawRect(0, 0, self:GetWide(), self:GetTall())

        draw.DrawText("Folded!", self.Font, self:GetWide() * 0.5, self:GetTall() * 0.5, Color(255, 255, 255), TEXT_ALIGN_CENTER)
    else
        if self.ShowTimer then
            surface.SetDrawColor(0, 0, 0)
            surface.DrawPoly(self.PolyHeader)

            draw.SimpleText("Time Remaining: " .. self.TimeRemaining, self.Font, self:GetWide() * 0.5, 1, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end
        
        if self.DisplayTemporaryMessage then
            surface.SetDrawColor(0, 0, 0, 240)
            surface.DrawRect(0, 0, self:GetWide(), self:GetTall())

            draw.DrawText(self.DisplayMessage, self.Font, self:GetWide() * 0.5, self:GetTall() * 0.5 - 30, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        end
    end
end

vgui.Register("Poker_Frame", Main, "DFrame")