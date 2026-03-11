-- Glicko system in lua based on the paper by Dr. Mark E. Glickman 
-- https://www.glicko.net/glicko/glicko.pdf
local StartingRating = 1500
local StartingRD = 350
-- I would therefore recommend that an RD never drop below a threshold value,
-- such as 30, so that ratings can change appreciably even in a relatively short time.
-- RDThreshold isn't used currently, will probably use it later.
local RDThreshold = 30
--[[
for _, ply in player.Iterator() do -- delete this for loop later
    ply.Glickos = {
        -- Make these able to have different category strings later. 
        -- There should not be only 1 universal category for all glickos. 
        -- Maybe servers have different gamemodes that need different glickos.
        ["RD"] = nil,
        ["Rating"] = nil
    }
end
--]]
Glickos = {}
--[ply] = {["RD"] = 10, ["Rating"] = 1000}
--[[
local function SUM(equation, iterations) -- Instead of writing a for loop every time for my mathematical notation I use this. It looks better.
    local sum = 0
    for j = 1, iterations do
        sum = equation
    end
end
--]]
local pi = math.pi -- To clutter notation less
--[[
local function GetPlayerRD(ply) -- Get the old RD, for use in step 2
    return (Glickos[ply] and Glickos[ply]["RD"]) or StartingRD
end

local function GetPlayerRating(ply) -- Get the old Rating, for use in step 2
    return (Glickos[ply] and Glickos[ply]["Rating"]) or StartingRating
end
--]]
local function GetGlicko(ply, category) -- Step 1
    if not Glickos[ply] then
        -- If the player is unrated
        Glickos[ply] = {}
        Glickos[ply]["Rating"] = StartingRating -- set the rating to 1500 
        Glickos[ply]["RD"] = StartingRD -- and the RD to 350. 
    else -- Otherwise,
        -- use the player’s rating from the last period, and calculate the new RD
        -- from the RD at the last period (RDold) by the formula
        -- RD = min(sqrt(RD^2_old + c^2, 350))
        -- where c is a constant that governs the increase in uncertainty between rating periods
        --local c = 63.2 -- Used by the paper. I do not have the data to determine a different c for my case. 
        local c = 0
        Glickos[ply]["RD"] = math.min(math.sqrt(Glickos[ply]["RD"] ^ 2 + c ^ 2), StartingRD)
    end
    return Glickos[ply]["RD"], Glickos[ply]["Rating"]
end

local function CalculateNewGlicko(ply, matches, category)
    local OpponentRatings = {}
    local OpponentRDs = {}
    local MatchOutcomes = {}
    for _, data in pairs(matches) do
        if data.Winner ~= ply then
            OpponentRatings[#OpponentRatings + 1] = select(2, GetGlicko(data.Winner))
            OpponentRDs[#OpponentRDs + 1] = select(1, GetGlicko(data.Winner))
        end

        if data.Loser ~= ply then
            OpponentRatings[#OpponentRatings + 1] = select(2, GetGlicko(data.Loser))
            OpponentRDs[#OpponentRDs + 1] = select(1, GetGlicko(data.Loser))
        end

        MatchOutcomes[#MatchOutcomes + 1] = (data.Winner == ply and 1) or ((data.WinnerScore == data.LoserScore) and 0.5) or 0
    end

    --[[--------
        Step 1
    ----------]]
    local PlayerRD, PlayerRating = GetGlicko(ply)
    --[[--------
        Step 2
    ----------]]
    local r = PlayerRating
    local RD = PlayerRD
    q = math.log(10) / 400
    local function g(RD_num)
        return 1 / math.sqrt(1 + 3 * q ^ 2 * (RD_num ^ 2) / pi ^ 2)
    end

    local m = matches
    local function E(j)
        return 1 / (1 + 10 ^ (-g(OpponentRDs[j]) * (r - OpponentRatings[j]) / 400))
    end

    local dSquared = 0
    for j = 1, #m do
        dSquared = dSquared + g(OpponentRDs[j]) ^ 2 * E(j) * (1 - E(j))
    end

    dSquared = (q ^ 2 * dSquared) ^ -1
    local PrimeSum = 0
    for j = 1, #m do
        PrimeSum = PrimeSum + g(OpponentRDs[j]) * (MatchOutcomes[j] - E(j))
    end

    local rPrime = r + (q / (1 / RD ^ 2 + 1 / dSquared) * PrimeSum)
    local RDPrime = math.sqrt((1 / RD ^ 2 + 1 / dSquared) ^ -1)
    return rPrime, RDPrime
end

--[[-----------------------
    Tests 
    (examples used from section of the paper titled "Example calculation")
-------------------------]]
Glickos["76561198000000001"] = {
    ["RD"] = 200,
    ["Rating"] = 1500
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
    ["RD"] = 30,
    ["Rating"] = 1400
}

Glickos["76561198000000003"] = {
    ["RD"] = 100,
    ["Rating"] = 1550
}

Glickos["76561198000000004"] = {
    ["RD"] = 300,
    ["Rating"] = 1700
}

print(CalculateNewGlicko("76561198000000001", {Match1, Match2, Match3}))
-- Output: 1464.1064627569	151.39890244797
