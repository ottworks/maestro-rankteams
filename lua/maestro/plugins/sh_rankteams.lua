local rankteams = {}
local teams = {}
if SERVER then
    util.AddNetworkString("maestro_rankteams")
    maestro.load("rankteams", function(tab, newfile)
        rankteams = tab
        if newfile then
            rankteams.admin = HSVToColor(80, 0.9, 1)
            rankteams.superadmin = HSVToColor(300, 0.9, 1)
            rankteams.root = HSVToColor(0, 0.9, 1)
            maestro.save("rankteams", rankteams)
        end
        local i = 0
        repeat
            i = i + 1
        until not team.Valid(i)
        for rank, color in pairs(rankteams) do
            print(rank, i)
            team.SetUp(i, rank, color, false)
            teams[rank] = i
            i = i + 1
        end
    end)
    net.Receive("maestro_rankteams", function(len, ply)
        for rank, color in pairs(rankteams) do
            net.Start("maestro_rankteams")
                net.WriteUInt(teams[rank], 16)
                net.WriteString(rank)
                net.WriteTable(rankteams[rank])
            net.Send(ply)
        end
    end)
    maestro.hook("PlayerInitialSpawn", "rankteams", function(ply)
        timer.Simple(1, function()
            local rank = maestro.userrank(ply)
            if not teams[rank] then return end
            ply:SetTeam(teams[rank])
        end)
    end)
end

if CLIENT then
    timer.Create("maestro_rankteams", 1, 0, function()
        if IsValid(LocalPlayer()) then
            net.Start("maestro_rankteams")
            net.SendToServer()
            timer.Remove("maestro_rankteams")
        end
    end)

    net.Receive("maestro_rankteams", function()
        local i = net.ReadUInt(16)
        local rank = net.ReadString()
        local color = net.ReadTable()
        print(i, rank, color)
        team.SetUp(i, rank, color, false)
        team.SetColor(i, color)
    end)
end

maestro.command("rankcolor", {"rank", "number:red", "number:green", "number:blue"}, function(caller, rank, r, g, b)
    local col = Color(r, g, b)
    rankteams[rank] = col
    maestro.save("rankteams", rankteams)
    team.SetColor(teams[rank], col)
    net.Start("maestro_rankteams")
        net.WriteUInt(teams[rank], 16)
        net.WriteString(rank)
        net.WriteTable(col)
    net.Broadcast()
    return false, "set the color of rank %1 to (%2, %3, %4)"
end)
