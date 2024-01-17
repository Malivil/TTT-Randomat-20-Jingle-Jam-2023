--// Logan Christianson

local PlayerCard = {}
PlayerCard.Player = nil
PlayerCard.Action = ""
PlayerCard.Font = "Trebuchet22"
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

vgui.Register("Poker_PlayerCard", PlayerCard, "DPanel")

local OtherPlayers = {}
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

vgui.Register("Poker_AllPlayerCards", OtherPlayers, "DPanel")