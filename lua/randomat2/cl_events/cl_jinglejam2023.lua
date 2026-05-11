util.PrecacheSound("radar_jammed.mp3")

local EVENT = {}
EVENT.id = "jinglejam2023"

local oldRadarEndTime = nil
local function RestartRadar()
    if not oldRadarEndTime then return end

    RADAR.enable = true
    RADAR.endtime = CurTime() + RADAR.duration
end

function EVENT:End()
    hook.Remove("HUDPaint", "RdmtJingleJam2023HUDPaint")
    timer.Remove("RdmtJingleJam2023RadarDisable")

    -- If we don't have a client it's because we're not loaded yet
    -- This can happen because the Randomat "ends" all events during the Prep phase so if
    -- a player is still loading at that point then `LocalPlayer` would return a NULL Entity
    if not Randomat.Client or not IsPlayer(Randomat.Client) or not Randomat.Client.HasEquipmentItem then return end

    if Randomat.Client:HasEquipmentItem(EQUIP_RADAR) then
        RestartRadar()
    end
end

Randomat:register(EVENT)

net.Receive("RdmtJingleJam2023Begin", function()
    surface.PlaySound("radar_jammed.mp3")

    local time = net.ReadUInt(8)
    local targetall = net.ReadBool()

    local function IsTarget()
        if not Randomat.Client:Alive() or Randomat.Client:IsSpec() then return false end
        if targetall then return true end
        if Randomat:IsInnocentTeam(Randomat.Client) then return false end
        return true
    end
    if not IsTarget() then return end

    local endTime = CurTime() + time

    local minWidth = 15
    local maxWidth = 30
    local screenWidth = ScrW()
    local screenHeight = ScrH()

    local lines = {}
    local isLine = true
    local pos = 0
    while true do
        local width = math.random(minWidth, maxWidth)
        local done = false
        -- Don't let the width of the line exceed the screen width
        if (pos + width) > screenWidth then
            width = screenWidth - pos
            done = true
        end

        -- Alternate gaps
        if isLine then
            table.insert(lines, {pos = pos, width = width, height = 0, started = false})
        end
        isLine = not isLine

        pos = pos + width
        if done then
            break
        end
    end

    hook.Add("HUDPaint", "RdmtJingleJam2023HUDPaint", function()
        if CurTime() >= endTime then return end
        if not Randomat.Client:Alive() or Randomat.Client:IsSpec() then return end

        surface.SetDrawColor(95, 9, 9, 225)

        for idx, line in ipairs(lines) do
            -- Check if we should start this line
            if not line.started then
                line.started = math.random(0, 75) == 1
            end

            -- If this line hasn't been started, skip it
            if not line.started then continue end

            -- Increase the line height each tick unless we've already covered the screen
            if line.height < screenHeight then
                line.height = line.height + 1
                lines[idx].height = line.height
            end

            surface.DrawRect(line.pos, 0, line.width, line.height)
        end
    end)

    -- Block radar from working while jammed
    timer.Create("RdmtJingleJam2023RadarDisable", 0.25, 0, function()
        if not Randomat.Client:Alive() or Randomat.Client:IsSpec() then return end
        if not Randomat.Client:HasEquipmentItem(EQUIP_RADAR) then return end

        if CurTime() >= endTime then
            RestartRadar()
            timer.Remove("RdmtJingleJam2023RadarDisable")
        else
            oldRadarEndTime = RADAR.endtime
            RADAR:Clear()
        end
    end)
end)