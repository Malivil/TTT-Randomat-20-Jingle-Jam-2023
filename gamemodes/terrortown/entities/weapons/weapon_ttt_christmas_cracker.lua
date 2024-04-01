AddCSLuaFile()

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
SWEP.Kind = 31135
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"
SWEP.UseHands = false
-- SWEP.WorldModel = "models/ttt_randomat_jingle_jam_2023/cracker/cracker_cracked_long.mdl"
-- SWEP.ViewModel = "models/ttt_randomat_jingle_jam_2023/cracker/cracker_cracked_long.mdl"
-- SWEP.WorldModel = "models/ttt_randomat_jingle_jam_2023/cracker/cracker_cracked_short.mdl"
-- SWEP.ViewModel = "models/ttt_randomat_jingle_jam_2023/cracker/cracker_cracked_short.mdl"
SWEP.WorldModel = "models/ttt_randomat_jingle_jam_2023/cracker/cracker.mdl"
SWEP.ViewModel = "models/ttt_randomat_jingle_jam_2023/cracker/cracker.mdl"

-- Places a paper crown hat on someone's head
local hatColours = {COLOR_WHITE, COLOR_BLACK, COLOR_BLUE, COLOR_RED, COLOR_GREEN}

function SWEP:GiveHat(ply)
    if CLIENT or not IsValid(ply) or IsValid(ply.hat) then return end
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
    hat:SetColor(hatColours[math.random(#hatColours)])
end

function SWEP:Initialize()
end

function SWEP:Deploy()
    self:GiveHat(self:GetOwner())

    return true
end

function SWEP:PrimaryAttack()
end

function SWEP:Holster()
    return true
end

-- This hacks in a viewmodel for the SWEP using its worldmodel, instead of using a proper separate v_ or c_ model (Not enough tutorials for this online...)
-- The worldmodel hook is for how others see the SWEP while it is held, or when on the ground
if CLIENT then
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

    -- Third-person worldmodel
    local WorldModel = ClientsideModel(SWEP.WorldModel)
    WorldModel:SetSkin(1)
    -- Set no draw here because we are making our own model-drawing function, model will draw twice otherwise
    WorldModel:SetNoDraw(true)

    function SWEP:DrawWorldModel()
        local owner = self:GetOwner()

        if IsValid(owner) then
            local boneID = owner:LookupBone("ValveBiped.Bip01_R_Hand")
            if not boneID then return end
            local matrix = owner:GetBoneMatrix(boneID)
            if not matrix then return end
            local newPos, newAng = LocalToWorld(self.WorldModelPos, self.WorldModelAng, matrix:GetTranslation(), matrix:GetAngles())
            WorldModel:SetPos(newPos)
            WorldModel:SetAngles(newAng)
            -- When the cracker is held, make it smaller else it looks weird
            -- (Typically when making a weapon model, you would just make the viewmodel smaller, we have to hack that in too)
            WorldModel:SetModelScale(self.ViewmodelScale)
            WorldModel:SetupBones()
        else
            -- If the weapon is on the ground, don't move its rendered position, and set it to regular size
            WorldModel:SetPos(self:GetPos())
            WorldModel:SetAngles(self:GetAngles())
            WorldModel:SetModelScale(1)
        end

        WorldModel:DrawModel()
    end
end