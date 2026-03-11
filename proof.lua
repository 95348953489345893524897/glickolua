local CalculateNewGlicko = include("glicko.lua")
--[[----------------------------------------------------------------------
    Tests 
    (examples used from section of the paper titled "Example calculation")
------------------------------------------------------------------------]]
Glickos["76561198000000001"] = {
    ["DuelRD"] = 200,
    ["DuelRating"] = 1500
}

local Match1 = {
    Winner = "76561198000000001",
    WinnerScore = 1,
    Loser = "76561198000000002",
    LoserScore = 0,
}

local Match2 = {
    Winner = "76561198000000003",
    WinnerScore = 1,
    Loser = "76561198000000001",
    LoserScore = 0,
}

local Match3 = {
    Winner = "76561198000000004",
    WinnerScore = 1,
    Loser = "76561198000000001",
    LoserScore = 0,
}

Glickos["76561198000000002"] = {
    ["DuelRD"] = 30,
    ["DuelRating"] = 1400
}

Glickos["76561198000000003"] = {
    ["DuelRD"] = 100,
    ["DuelRating"] = 1550
}

Glickos["76561198000000004"] = {
    ["DuelRD"] = 300,
    ["DuelRating"] = 1700
}

print(CalculateNewGlicko("76561198000000001", {Match1, Match2, Match3}, "Duel", 0))
-- Output: 1464.1064627569	151.39890244797
