AddCSLuaFile()

SWEP.HoldType = "pistol"

if CLIENT then
    SWEP.PrintName = "Club"
    SWEP.Slot = 0

    SWEP.DrawCrosshair = false
    SWEP.ViewModelFlip = false
end

SWEP.Base                   = "weapon_tttbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE

SWEP.AutoSpawnable          = false

SWEP.ViewModel              = Model("models/weapons/v_stunbaton.mdl")
SWEP.WorldModel             = Model("models/weapons/w_stunbaton.mdl")

SWEP.Primary.Damage         = 50
SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = true
SWEP.Primary.Ammo           = "none"
SWEP.Primary.Delay          = 0.5

SWEP.Secondary.Damage       = 0
SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = true
SWEP.Secondary.Ammo         = "none"
SWEP.Secondary.Delay        = 1

SWEP.Kind                   = WEAPON_MELEE

SWEP.AllowDelete            = false
SWEP.AllowDrop              = false
SWEP.NoSights               = true

local sound_single = Sound("Weapon_Crowbar.Single")

function SWEP:Initialize()
    if CLIENT then
        self:AddHUDHelp("yeticlub_help_pri", "yeticlub_help_sec", true)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if owner.LagCompensation then -- for some reason not always true
        owner:LagCompensation(true)
    end

    local spos = owner:GetShootPos()
    local sdest = spos + (owner:GetAimVector() * 140)
    local kmins = Vector(1,1,1) * -10
    local kmaxs = Vector(1,1,1) * 10

    local tr_main = util.TraceHull({start=spos, endpos=sdest, filter=owner, mask=MASK_SHOT_HULL, mins=kmins, maxs=kmaxs})
    local hitEnt = tr_main.Entity

    self:EmitSound(sound_single)

    if IsValid(hitEnt) or tr_main.HitWorld then
        self:SendWeaponAnim(ACT_VM_HITCENTER)

        if not (CLIENT and (not IsFirstTimePredicted())) then
            local edata = EffectData()
            edata:SetStart(spos)
            edata:SetOrigin(tr_main.HitPos)
            edata:SetNormal(tr_main.Normal)
            edata:SetSurfaceProp(tr_main.SurfaceProps)
            edata:SetHitBox(tr_main.HitBox)
            edata:SetDamageType(DMG_CLUB)
            edata:SetEntity(hitEnt)

            if hitEnt:IsPlayer() or hitEnt:GetClass() == "prop_ragdoll" then
                util.Effect("BloodImpact", edata)

                -- do a bullet just to make blood decals work sanely
                -- need to disable lagcomp because firebullets does its own
                owner:LagCompensation(false)
                owner:FireBullets({ Num = 1, Src = spos, Dir = owner:GetAimVector(), Spread = Vector(0, 0, 0), Tracer = 0, Force = 1, Damage = 0 })
            else
                util.Effect("Impact", edata)
            end
        end
    else
        self:SendWeaponAnim(ACT_VM_MISSCENTER)
    end

    if SERVER then
        owner:SetAnimation(PLAYER_ATTACK1)

        if IsValid(hitEnt) then
            local aimVector = owner:GetAimVector()
            local dmg = DamageInfo()
            dmg:SetDamage(self.Primary.Damage)
            dmg:SetAttacker(owner)
            dmg:SetInflictor(self)
            dmg:SetDamageForce(aimVector * 1500)
            dmg:SetDamagePosition(owner:GetPos())
            dmg:SetDamageType(DMG_CLUB)

            hitEnt:DispatchTraceAttack(dmg, spos + (aimVector * 3), sdest)

            -- Knock the target back if they aren't frozen
            local isPlayer = hitEnt:IsPlayer()
            if not isPlayer or not hitEnt:IsFrozen() then
                hitEnt:SetVelocity(aimVector * 1500)
                if isPlayer then
                    hitEnt.was_pushed = { att = owner, t = CurTime(), wep = self:GetClass() } --, infl=self}
                end
            end
        end
    end

    if owner.LagCompensation then
        owner:LagCompensation(false)
    end
end

function SWEP:SecondaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if owner.LagCompensation then -- for some reason not always true
        owner:LagCompensation(true)
    end

    self:SendWeaponAnim(ACT_VM_HITCENTER)
    if SERVER then
        owner:SetAnimation(PLAYER_ATTACK1)

        local ent = ents.Create("yeti_club_proj")
        local ang = owner:GetAimVector():Angle()

        ent:SetPos(owner:GetShootPos())
        ent:SetOwner(owner)
        ent:SetAngles(ang)
        ent:Spawn()

        local dir = ang:Forward()
        -- Projectile velocity
        dir:Mul(1000)
        ent:SetVelocity(dir)

        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetVelocity(dir)
        end

        ent:SetOwner(owner)
    end

    if owner.LagCompensation then
        owner:LagCompensation(false)
    end
end

function SWEP:OnDrop()
    self:Remove()
end