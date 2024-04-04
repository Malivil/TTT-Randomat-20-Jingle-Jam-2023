AddCSLuaFile()

if SERVER then
    util.AddNetworkString("TTTChristmasCrackerOpen")
end

if CLIENT then
    SWEP.EquipMenuData = {
        type = "Item",
        desc = "A christmas cracker filled with goodies!"
    }

    SWEP.Icon = "vgui/ttt/icon_christmas_cracker"
    SWEP.Slot = 7
    SWEP.PrintName = "Christmas Cracker"
end

SWEP.Base = "weapon_tttbase"
SWEP.AutoSpawnable = false
SWEP.AllowDrop = true
SWEP.CanBuy = nil
-- Arbitrary weapon kind to not conflict with any other weapon
local lastKind = 31135
SWEP.Kind = lastKind
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"
SWEP.UseHands = false
SWEP.OpenedLongModel = "models/ttt_randomat_jingle_jam_2023/cracker/cracker_cracked_long.mdl"
SWEP.OpenedShortModel = "models/ttt_randomat_jingle_jam_2023/cracker/cracker_cracked_short.mdl"
SWEP.WorldModel = "models/ttt_randomat_jingle_jam_2023/cracker/cracker.mdl"
SWEP.ViewModel = "models/ttt_randomat_jingle_jam_2023/cracker/cracker.mdl"
-- How far away in source units you can try to get someone to 
SWEP.Range = 100
-- How forgiving to the user to find a player they are trying to click on
-- (Higher number = more lag compensation, but less accuracy, might find the wrong player if another player is near)
SWEP.PartnerSearchHitBoxSize = 10

-- Colours the paper hat can be
SWEP.HatColours = {COLOR_WHITE, COLOR_BLACK, COLOR_GREEN, COLOR_RED, COLOR_YELLOW, COLOR_BLUE, COLOR_PINK, COLOR_ORANGE}

-- How long players have to hold left-click and move backwards to open the cracker in seconds
SWEP.OpeningDelay = 2
-- How many seconds to give up on opening the cracker if either player isn't trying to open it
SWEP.OpeningResetCooldown = 1
local hooksAdded = false

function SWEP:Initialize()
    -- Don't add these hooks every time a cracker is created. Just once per round when someone gets a cracker
    if hooksAdded then return end

    -- Slow the players down when opening the cracker
    hook.Add("TTTSpeedMultiplier", "TTTChristmasCrackerSlowdown", function(ply, mults, sprinting)
        if IsValid(ply:GetNWEntity("TTTChristmasCrackerPartner")) then
            table.insert(mults, 0.2)
        end
    end)

    -- Removing all cracker hooks
    hook.Add("TTTPrepareRound", "TTTChristmasCrackerReset", function()
        hook.Remove("TTTSpeedMultiplier", "TTTChristmasCrackerSlowdown")
        hook.Remove("TTTPrepareRound", "TTTChristmasCrackerReset")
        hooksAdded = false
    end)
end

function SWEP:PrimaryAttack()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if not self.ShownPrimaryAttackMessage then
        owner:PrintMessage(HUD_PRINTCENTER, "Find a player to open this with!")
        self.ShownPrimaryAttackMessage = true
    end
end

function SWEP:SecondaryAttack()
    self:PrimaryAttack()
end

function SWEP:Reload()
end

if SERVER then
    -- Places a paper crown hat on someone's head
    function SWEP:GiveHat(ply)
        if not IsValid(ply) or IsValid(ply.hat) then return end
        local model = "models/ttt_randomat_jingle_jam_2023/paper_crown/paper_crown.mdl"
        local hat = ents.Create("ttt_hat_deerstalker")
        if not IsValid(hat) then return end
        local pos = ply:GetPos()
        hat:SetPos(pos)
        hat:SetAngles(ply:GetAngles())
        hat:SetParent(ply)

        -- Hat doesn't like being set a lot of the time, so attempt to create it twice
        timer.Simple(0, function()
            if IsValid(hat) then
                hat:SetModel(model)
            end
        end)

        timer.Simple(0.1, function()
            if not IsValid(hat) then
                hat = ents.Create("ttt_hat_deerstalker")
                hat:SetPos(pos)
                hat:SetAngles(ply:GetAngles())
                hat:SetParent(ply)
                hat:SetModel(model)
                hat:Spawn()
            else
                hat:SetModel(model)
            end
        end)

        ply.hat = hat
        hat:Spawn()
        hat:SetColor(self.HatColours[math.random(#self.HatColours)])
    end

    -- Returns an entity the owner is looking at, with a tolerance of a bounding box to search for a player in
    function SWEP:GetTraceEntity()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local startPos = owner:GetShootPos()
        local endPos = startPos + (owner:GetAimVector() * self.Range)
        local lowerBoxBound = Vector(-1, -1, -1) * self.PartnerSearchHitBoxSize
        local upperBoxBound = Vector(1, 1, 1) * self.PartnerSearchHitBoxSize

        local TraceResult = util.TraceHull({
            start = startPos,
            endpos = endPos,
            filter = owner,
            mask = MASK_SHOT_HULL,
            mins = lowerBoxBound,
            maxs = upperBoxBound
        })

        return TraceResult.Entity
    end

    -- Frees players from trying to open the cracker
    function SWEP:ResetCrackerPartner()
        local own = self:GetOwner()
        if not IsValid(own) then return end
        if timer.Exists("TTTChristmasCrackerResetCooldown" .. own:SteamID64()) then return end

        timer.Create("TTTChristmasCrackerResetCooldown" .. own:SteamID64(), self.OpeningResetCooldown, 1, function()
            if not IsValid(self) then return end
            self.CrackerOpenDelay = nil
            local owner = self:GetOwner()
            if not IsValid(owner) then return end
            local partner = owner:GetNWEntity("TTTChristmasCrackerPartner")

            if IsValid(partner) then
                partner:SetNWEntity("TTTChristmasCrackerPartner", nil)
            end

            owner:SetNWEntity("TTTChristmasCrackerPartner", nil)
        end)
    end

    -- Opens the cracker and randomly chooses a winner, biased towards players that have lost more cracker-openings (gambler's fallacy)
    function SWEP:OpenCracker()
        -- Get the cracker owner and partner
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local partner = owner:GetNWEntity("TTTChristmasCrackerPartner")
        -- Set this flag to prevent the cracker from being opened a second time (Prevents the think hook from running)
        self.Opened = true
        local winner
        local loser
        owner.TTTChristmasCrackerWins = owner.TTTChristmasCrackerWins or 0
        partner.TTTChristmasCrackerWins = partner.TTTChristmasCrackerWins or 0

        -- Picking a player to win the cracker
        -- Automatically picking the owner if their partner isn't valid for any reason
        -- Always picking the player that has won less times
        -- Picking randomly on a tie
        if not IsValid(partner) or partner.TTTChristmasCrackerWins > owner.TTTChristmasCrackerWins or (partner.TTTChristmasCrackerWins == owner.TTTChristmasCrackerWins and math.random() < 0.5) then
            self:SetNWBool("OpenedWon", true)
            winner = owner
            loser = partner
            self.WorldModel = self.OpenedLongModel
            self.ViewModel = self.OpenedLongModel
        else
            self:SetNWBool("OpenedLost", true)
            winner = partner
            loser = owner
            self.WorldModel = self.OpenedShortModel
            self.ViewModel = self.OpenedShortModel
        end

        net.Start("TTTChristmasCrackerOpen")
        net.WritePlayer(winner)
        net.Broadcast()
        winner:ChatPrint("You won the cracker! What's inside?")
        self:GiveHat(winner)

        if IsValid(loser) then
            loser:ChatPrint("You didn't win the cracker, try opening another one!")
        end

        self:ResetCrackerPartner()
    end

    -- Cracker-opening logic
    function SWEP:Think()
        if self.Opened then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        -- First check the player is looking at someone and is holding down the left mouse button
        if owner:KeyDown(IN_ATTACK) then
            local partner = self:GetTraceEntity()

            if not IsPlayer(partner) then
                self:ResetCrackerPartner()

                return
            end

            -- Set flags on the cracker-opening partners, this slows their movement speed down
            if not IsValid(owner:GetNWEntity("TTTChristmasCrackerPartner")) then
                owner:SetNWEntity("TTTChristmasCrackerPartner", partner)
                partner:SetNWEntity("TTTChristmasCrackerPartner", owner)
                -- Make the partner face the player
                local partnerAim = owner:GetAimVector()
                partnerAim.x = -partnerAim.x
                partnerAim.y = -partnerAim.y
                partnerAim = partnerAim:Angle()
                partner:SetEyeAngles(partnerAim)
                -- Message both players what they have to do
                owner:PrintMessage(HUD_PRINTCENTER, "Hold left-click and walk backwards!")
                partner:PrintMessage(HUD_PRINTCENTER, "Hold left-click and walk backwards!")
            end

            -- Make the other player have to start holding left-click to start opening the cracker
            if owner:KeyDown(IN_BACK) and partner:KeyDown(IN_ATTACK) and partner:KeyDown(IN_BACK) then
                if not self.CrackerOpenDelay then
                    self.CrackerOpenDelay = CurTime() + self.OpeningDelay
                    -- If they've held the left-click and move back buttons down long enough, the cracker opens!
                elseif CurTime() >= self.CrackerOpenDelay then
                    self:OpenCracker()
                end
            else
                self:ResetCrackerPartner()
            end
        else
            self:ResetCrackerPartner()
        end
    end
end

if CLIENT then
    -- Doing the jester win effect on a player winning the cracker
    net.Receive("TTTChristmasCrackerOpen", function()
        local winner = net.ReadPlayer()
        winner:Celebrate("birthday.wav", true)
    end)

    -- This hacks in a viewmodel for the SWEP using its worldmodel, instead of using a proper separate v_ or c_ model (Not enough tutorials for this online...)
    -- The worldmodel hook is for how others see the SWEP while it is held, or when on the ground
    -- Adjust these variables to move the viewmodel's position
    SWEP.ViewModelPos = Vector(10, -25, -25)
    SWEP.ViewModelAng = Vector(30, 180, -10)
    -- Adjust these variables to move the worldmodel's position
    SWEP.WorldModelPos = Vector(13, -2.7, -3.4)
    SWEP.WorldModelAng = Angle(180, 0, 0)
    -- Adjust size of worldmodel in player's hand (Another player looking at someone holding the SWEP)
    SWEP.ViewmodelScale = 0.5

    -- First-person viewmodel
    function SWEP:GetViewModelPosition(EyePos, EyeAng)
        local Mul = 1.0
        EyeAng = EyeAng * 1
        EyeAng:RotateAroundAxis(EyeAng:Right(), self.ViewModelAng.x * Mul)
        EyeAng:RotateAroundAxis(EyeAng:Up(), self.ViewModelAng.y * Mul)
        EyeAng:RotateAroundAxis(EyeAng:Forward(), self.ViewModelAng.z * Mul)
        local Right = EyeAng:Right()
        local Up = EyeAng:Up()
        local Forward = EyeAng:Forward()
        EyePos = EyePos + self.ViewModelPos.x * Right * Mul
        EyePos = EyePos + self.ViewModelPos.y * Forward * Mul
        EyePos = EyePos + self.ViewModelPos.z * Up * Mul

        return EyePos, EyeAng
    end

    function SWEP:PreDrawViewModel(vm, weapon, ply)
        if weapon:GetNWBool("OpenedLost") then
            vm:SetModel(weapon.OpenedShortModel)
        elseif weapon:GetNWBool("OpenedWon") then
            vm:SetModel(weapon.OpenedLongModel)
        end
    end

    -- Third-person worldmodel
    SWEP.ClientWorldModel = ClientsideModel(SWEP.WorldModel)
    SWEP.ClientWorldModel:SetSkin(1)
    -- Set no draw here because we are making our own model-drawing function, model will draw twice otherwise
    SWEP.ClientWorldModel:SetNoDraw(true)

    function SWEP:DrawWorldModel()
        if self:GetNWBool("OpenedLost") then
            self.ClientWorldModel:SetModel(self.OpenedShortModel)
        elseif self:GetNWBool("OpenedWon") then
            self.ClientWorldModel:SetModel(self.OpenedLongModel)
        end

        local owner = self:GetOwner()

        if IsValid(owner) then
            local boneID = owner:LookupBone("ValveBiped.Bip01_R_Hand")
            if not boneID then return end
            local matrix = owner:GetBoneMatrix(boneID)
            if not matrix then return end
            local newPos, newAng = LocalToWorld(self.WorldModelPos, self.WorldModelAng, matrix:GetTranslation(), matrix:GetAngles())
            self.ClientWorldModel:SetPos(newPos)
            self.ClientWorldModel:SetAngles(newAng)
            -- When the cracker is held, make it smaller else it looks weird
            -- (Typically when making a weapon model, you would just make the viewmodel smaller, we have to hack that in too)
            self.ClientWorldModel:SetModelScale(self.ViewmodelScale)
            self.ClientWorldModel:SetupBones()
        else
            -- If the weapon is on the ground, don't move its rendered position, and set it to regular size
            self.ClientWorldModel:SetPos(self:GetPos())
            self.ClientWorldModel:SetAngles(self:GetAngles())
            self.ClientWorldModel:SetModelScale(1)
        end

        self.ClientWorldModel:DrawModel()
    end
end