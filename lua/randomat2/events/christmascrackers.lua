local EVENT = {}
EVENT.Title = "Christmas Crackers"
EVENT.Description = "Open your crackers and spread some Christmas cheer!"
EVENT.id = "christmascrackers"

EVENT.Categories = {"item", "largeimpact"}

util.AddNetworkString("RandomatChristmasCrackersBegin")
util.AddNetworkString("RandomatChristmasCrackersEnd")
local crackerClass = "weapon_ttt_christmas_cracker"

function EVENT:Begin()
    net.Start("RandomatChristmasCrackersBegin")
    net.Broadcast()

    for _, ply in player.Iterator() do
        ply:Give(crackerClass)
        ply:SelectWeapon(crackerClass)
    end
end

function EVENT:End()
    net.Start("RandomatChristmasCrackersEnd")
    net.Broadcast()
end

Randomat:register(EVENT)