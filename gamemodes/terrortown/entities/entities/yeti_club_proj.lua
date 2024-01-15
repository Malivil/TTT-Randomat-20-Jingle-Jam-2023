if SERVER then
    AddCSLuaFile()
end

ENT.Type = "anim"
ENT.PrintName = "Yeti Club Freeze"
ENT.Author = "Malivil (based on work by TFA, Tanki Flo, and Raven)"
ENT.Contact = ""
ENT.Purpose = ""
ENT.Instructions = ""
ENT.DoNotDuplicate = true
ENT.DisableDuplicator = true

ENT.Damage = 0
ENT.Delay = 1
ENT.Radius = 10
ENT.Color = COLOR_WHITE
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.Sprite = Material("particle/wisp")
ENT.Beam = Material("cable/smoke")

if SERVER then
    function ENT:Initialize()
        local mdl = self:GetModel()
        if mdl == "" or mdl == "models/error.mdl" then
            self:SetModel("models/weapons/w_eq_fraggrenade.mdl")
        end

        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:PhysicsInitSphere(self.Radius, "default_silent")
        local phys = self:GetPhysicsObject()

        if phys:IsValid() then
            phys:Wake()
            phys:EnableDrag(false)
            phys:EnableGravity(false)
            phys:SetMass(1)
        end

        self.DieTime = CurTime() + self.Delay
        self:DrawShadow(false)
    end

    function ENT:Think()
        if CurTime() > self.DieTime then
            self:Remove()
            return false
        end
        self:NextThink(CurTime())
        return true
    end

    function ENT:PhysicsCollide(colData, collider)
        timer.Simple(0, function()
            if IsValid(self) then
                self:Remove()
            end
        end)

        local owner = self:GetOwner()
        local target = colData.HitEntity
        if IsValid(owner) and IsPlayer(target) then
            local dmgInfo = DamageInfo()
            dmgInfo:SetAttacker(owner)

            local inf = owner
            if owner.GetActiveWeapon and IsValid(owner:GetActiveWeapon()) then
                inf = owner:GetActiveWeapon()
            end

            dmgInfo:SetInflictor(inf)
            dmgInfo:SetDamage(0)
            colData.Normal = colData.OurOldVelocity
            colData.Normal:Normalize()
            dmgInfo:SetDamageForce(Vector(0,0,0))
            dmgInfo:SetDamageType(DMG_GENERIC)
            dmgInfo:SetDamagePosition(colData.HitPos)

            target:DispatchTraceAttack(dmgInfo, util.QuickTrace(colData.HitPos, -colData.HitNormal * 32, self), colData.Normal)
            target:SetMaterial("effects/freeze_overlayeffect01")
            target:Freeze(true)

            local freeze_time = GetConVar("randomat_yeti_freeze_time"):GetInt()
            timer.Create("RdmtYetiClubFreeze_" .. self:EntIndex() .. "_" .. target:SteamID64(), freeze_time, 1, function()
                if not IsPlayer(target) then return end
                if not target:IsFrozen() then return end
                target:Freeze(false)
                target:SetMaterial("")
            end)
        end
    end
end

if CLIENT then
    function ENT:Draw()
    end

    function ENT:DrawTranslucent()
        if not self.StartTime then
            self.StartTime = CurTime()
        end

        if self.StartTime + 0.05 > CurTime() then return end
        render.SetMaterial(self.Sprite)
        render.DrawQuadEasy(self:GetPos(), -EyeAngles():Forward(), self.Radius * 2, self.Radius * 2, self.Color, 0)
        render.SetMaterial(self.Beam)
        render.StartBeam(2)
        render.AddBeam(self:GetPos(), self.Radius, 0, self.Color)
        render.AddBeam(self:GetPos() - self:GetVelocity() / 15, 0, 1, self.Color)
        render.EndBeam()
    end
end