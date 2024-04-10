AddCSLuaFile()

if SERVER then
    util.AddNetworkString("TTTCrackerOpen")
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
SWEP.Kind = 31135
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"
SWEP.UseHands = false
SWEP.OpenedLongModel = "models/ttt_randomat_jingle_jam_2023/cracker/cracker_cracked_long.mdl"
SWEP.OpenedShortModel = "models/ttt_randomat_jingle_jam_2023/cracker/cracker_cracked_short.mdl"
SWEP.WorldModel = "models/ttt_randomat_jingle_jam_2023/cracker/cracker.mdl"
SWEP.ViewModel = "models/ttt_randomat_jingle_jam_2023/cracker/cracker.mdl"
-- How far away in source units you can try to get someone to open a cracker
SWEP.Range = 200
-- How forgiving to the user to find a player they are trying to click on
-- (Higher number = more lag compensation, but less accuracy, might find the wrong player if another player is near)
SWEP.PartnerSearchHitBoxSize = 10

-- Colours the paper hat can be
SWEP.HatColours = {COLOR_WHITE, COLOR_BLACK, COLOR_GREEN, COLOR_RED, COLOR_YELLOW, COLOR_BLUE, COLOR_PINK, COLOR_ORANGE}

-- How long players have to hold left-click and move backwards to open the cracker in seconds
SWEP.OpeningDelay = 1
-- How many seconds to give up on opening the cracker if either player isn't trying to open it
SWEP.OpeningResetCooldown = 1
-- How many times someone can try to open the cracker before it just auto-opens
SWEP.OpenTriesLimit = 10

-- Jokes displayed after winning a cracker
local jokes = {
    {"What do Santa's elves learn in school?", "The elf-abet!"},
    {"What kind of photos do Santa's elves take?", "Elfies!"},
    {"How do the elves clean Santa's sleigh on the day after Christmas?", "They use Santa-tizer!"},
    {"Why did Santa get a parking ticket on Christmas?", "He left his sleigh in a snow parking zone"},
    {"What is a Christmas tree's favourite candy?", "Orna-mints!"},
    {"What did the sea say to Santa?", "Nothing, it just waved!"},
    {"Why is Santa so good at karate?", "Because he has a black belt!"},
    {"Did Rudolph go to school?", "No. He was Elf-taught!"},
    {"Why are Comet, Cupid, and Donner, and always wet?", "Because they are rain deer"},
    {"Where does Mistletoe go to become famous?", "Holly-wood!"},
    {"What do reindeer hang on their Christmas trees?", "Horn-aments!"},
    {"Why did the Christmas tree go to the dentist?", "It needed a root canal"},
    {"What did the stamp say to the Christmas card?", "Stick with me and we'll go places!"},
    {"Why does Santa go down the chimney?", "Because it soots him!"},
    {"What did one Christmas tree say to another?", "Lighten up!"},
    {"What do you call Santa on the beach? ", "Sandy Clause!"},
    {"What do snowmen have for breakfast?", "Snowflakes!"},
    {"Why are Christmas trees bad at knitting?", "Because they always drop their needles"},
    {"Why couldn't the skeleton go to the Christmas party?", "He had no body to go with"},
    {"What do you sing a snowman's birthday party?", "Freeze a jolly good fellow!"},
    {"What is the best Christmas present?", "A broken drum - you can't beat it!"}
}

local itemBlocklist = {}
local hooksAdded = false

function SWEP:Initialize()
    -- Don't add these hooks every time a cracker is created. Just once per round when someone gets a cracker
    if hooksAdded then return end

    -- Slow the players down when opening the cracker
    hook.Add("TTTSpeedMultiplier", "TTTCrackerSlowdown", function(ply, mults, sprinting)
        if IsValid(ply:GetNWEntity("TTTCrackerPartner")) then
            table.insert(mults, 0.2)
        end
    end)

    -- Removing all cracker hooks
    hook.Add("TTTPrepareRound", "TTTCrackerReset", function()
        hook.Remove("TTTSpeedMultiplier", "TTTCrackerSlowdown")
        hook.Remove("TTTPrepareRound", "TTTCrackerReset")
        hooksAdded = false
    end)

    hooksAdded = true

    if SERVER then
        -- Populate shop item-giving blocklist
        table.Empty(itemBlocklist)

        for classname in string.gmatch(GetConVar("randomat_crackers_item_blocklist"):GetString(), "([^,]+)") do
            table.insert(itemBlocklist, classname:Trim())
        end
    end
end

SWEP.OpenTries = 0

function SWEP:PrimaryAttack()
    -- Find the player someone is trying to open a cracker with
    if CLIENT or self.Opened then return end
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    local partner = self:GetTraceEntity()

    -- If they're clicking nothing, show a message to find another player
    if not IsPlayer(partner) then
        if not self.ShownPrimaryAttackMessage then
            self:ResetCrackerPartner()
            owner:PrintMessage(HUD_PRINTCENTER, "Find a player to open this with!")
            self.ShownPrimaryAttackMessage = true
        end
    else
        -- If someone tries too many times to open their cracker, then just open it for them
        self.OpenTries = self.OpenTries + 1

        if self.OpenTries >= self.OpenTriesLimit then
            self:OpenCracker()
        end
    end
end

function SWEP:SecondaryAttack()
    self:PrimaryAttack()
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

    SWEP.GiveJokeAttempts = 0

    -- Gives the player a random joke displayed in the centre of the screen
    function SWEP:GiveJoke(ply)
        -- Try and give a joke to the player
        for _, joke in RandomPairs(jokes) do
            if not joke.used then
                -- Delay giving the joke by 5 seconds
                timer.Simple(5, function()
                    if not IsValid(ply) then return end
                    ply:ChatPrint(joke[1])

                    -- Delay giving the punchline by 5 seconds after that
                    timer.Simple(5, function()
                        if not IsValid(ply) then return end
                        ply:ChatPrint(joke[2])
                    end)
                end)

                joke.used = true
                self.GiveJokeAttempts = 0

                return
            end
        end

        -- If all jokes are used, reset their flags and try again
        for _, joke in ipairs(jokes) do
            joke.used = false
        end

        -- Just in case this function gets stuck in an infinite loop...
        self.GiveJokeAttempts = self.GiveJokeAttempts + 1

        if self.GiveJokeAttempts < 4 then
            self:GiveJoke(ply)
        end
    end

    -- Gives the player a random shop item
    function SWEP:GiveShopItem(ply)
        ply.TTTCrackerShopItemTries = 0

        Randomat:GiveRandomShopItem(ply, Randomat:GetShopRoles(), itemBlocklist, false, function() return ply.TTTCrackerShopItemTries end, function(value)
            ply.TTTCrackerShopItemTries = value
        end, function(isequip, id)
            Randomat:CallShopHooks(isequip, id, ply)
        end)
    end

    -- Returns an entity the owner is looking at, with a tolerance of a bounding box to search for a player in
    function SWEP:GetTraceEntity()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local startPos = owner:GetShootPos()
        local endPos = startPos + (owner:GetAimVector() * self.Range)
        local lowerBoxBound = Vector(-1, -1, -1) * self.PartnerSearchHitBoxSize
        local upperBoxBound = Vector(1, 1, 1) * self.PartnerSearchHitBoxSize

        local traceResult = util.TraceHull({
            start = startPos,
            endpos = endPos,
            filter = owner,
            mask = MASK_SHOT_HULL,
            mins = lowerBoxBound,
            maxs = upperBoxBound
        })

        return traceResult.Entity
    end

    -- Frees players from trying to open the cracker
    function SWEP:ResetCrackerPartner()
        local own = self:GetOwner()
        if not IsValid(own) then return end
        if timer.Exists("TTTCrackerResetCooldown" .. own:SteamID64()) then return end

        timer.Create("TTTCrackerResetCooldown" .. own:SteamID64(), self.OpeningResetCooldown, 1, function()
            if not IsValid(self) then return end
            self.CrackerOpenDelay = nil
            local owner = self:GetOwner()
            if not IsValid(owner) then return end
            local partner = owner:GetNWEntity("TTTCrackerPartner")

            if IsValid(partner) then
                partner:SetNWEntity("TTTCrackerPartner", nil)
            end

            owner:SetNWEntity("TTTCrackerPartner", nil)
        end)
    end

    -- Opens the cracker and randomly chooses a winner, biased towards players that have lost more cracker-openings (gambler's fallacy)
    function SWEP:OpenCracker()
        -- Get the cracker owner and partner
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local partner = owner:GetNWEntity("TTTCrackerPartner")
        -- Set this flag to prevent the cracker from being opened a second time (Prevents the think hook from running)
        self.Opened = true
        local winner
        local loser
        owner.TTTCrackerWins = owner.TTTCrackerWins or 0
        partner.TTTCrackerWins = partner.TTTCrackerWins or 0

        -- Picking a player to win the cracker
        -- Automatically picking the owner if their partner isn't valid for any reason
        -- Always picking the player that has won less times
        -- Picking randomly on a tie
        if not IsValid(partner) or partner.TTTCrackerWins > owner.TTTCrackerWins or (partner.TTTCrackerWins == owner.TTTCrackerWins and math.random() < 0.5) then
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

        net.Start("TTTCrackerOpen")
        net.WritePlayer(winner)
        net.Broadcast()
        winner:ChatPrint("You won the cracker! You got a toy, hat and a joke!")

        if IsValid(loser) then
            loser:ChatPrint("You didn't win the cracker, try opening another one!")
        end

        -- Rewards
        self:GiveHat(winner)
        self:GiveJoke(winner)
        self:GiveShopItem(winner)
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

            -- If the player already has a cracker partner, then don't try to partner with them
            local partnerPartner = partner:GetNWEntity("TTTCrackerPartner")

            if IsValid(partnerPartner) and partnerPartner ~= owner then
                self:ResetCrackerPartner()

                return
            end

            -- Set flags on the cracker-opening partners, this slows their movement speed down
            if not IsValid(owner:GetNWEntity("TTTCrackerPartner")) then
                owner:SetNWEntity("TTTCrackerPartner", partner)
                partner:SetNWEntity("TTTCrackerPartner", owner)
                -- Make the partner face the player
                local partnerAim = owner:GetAimVector()
                partnerAim.x = -partnerAim.x
                partnerAim.y = -partnerAim.y
                partnerAim = partnerAim:Angle()
                partner:SetEyeAngles(partnerAim)
                -- Message both players what they have to do
                local message = "Opening a cracker! Hold left-click and walk backwards!"
                owner:PrintMessage(HUD_PRINTCENTER, message)
                partner:PrintMessage(HUD_PRINTCENTER, message)
            end

            -- Make it so either player can hold left-click and walk backwards to open the cracker, to avoid trolling from the cracker-using player
            -- (The owner holding left-click has already been checked above)
            if owner:KeyDown(IN_BACK) or (partner:KeyDown(IN_ATTACK) and partner:KeyDown(IN_BACK)) then
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
    net.Receive("TTTCrackerOpen", function()
        local winner = net.ReadPlayer()
        winner:Celebrate("crackers/cracker_open.mp3", true)
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
    -- A hacked-in draw animation (Animation that plays when you swap to the cracker)
    SWEP.ViewmodelDrawAnimModifier = 1

    function SWEP:Deploy()
        self.ViewmodelDrawAnimModifier = 0

        timer.Create("TTTCrackerDrawAnimation", 0.01, 25, function()
            self.ViewmodelDrawAnimModifier = self.ViewmodelDrawAnimModifier + 0.04
        end)

        return true
    end

    -- First-person viewmodel
    function SWEP:GetViewModelPosition(eyePos, eyeAng)
        eyeAng:RotateAroundAxis(eyeAng:Right(), self.ViewModelAng.x)
        eyeAng:RotateAroundAxis(eyeAng:Up(), self.ViewModelAng.y)
        eyeAng:RotateAroundAxis(eyeAng:Forward(), self.ViewModelAng.z)
        local Right = eyeAng:Right()
        local Up = eyeAng:Up()
        local Forward = eyeAng:Forward()
        eyePos = eyePos + self.ViewModelPos.x * Right
        eyePos = eyePos + self.ViewModelPos.y * Forward * self.ViewmodelDrawAnimModifier
        eyePos = eyePos + self.ViewModelPos.z * Up

        return eyePos, eyeAng
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
        else
            self.ClientWorldModel:SetModel(self.ViewModel)
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