-- Glicko system in lua based on the paper by Dr. Mark E. Glickman 
-- https://www.glicko.net/glicko/glicko.pdf
-- to do: 
-- explain everything
-- add back notation comments
-- rewrite it to not be weird arrays? 
local pi = math.pi -- To clutter notation less
--[[------------------
    Constants
--------------------]]
local StartingRating = 1500
local StartingRD = 350
local c = 63.2 -- Used by the paper. I do not have the data to determine a different c for my case. 
-- "I would therefore recommend that an RD never drop below a threshold value,
-- such as 30, so that ratings can change appreciably even in a relatively short time."
-- RDThreshold isn't used currently, will probably use it later.
local RDThreshold = 30
--[[------------------
    Glicko calculations
--------------------]]
Glickos = {}
local function GetGlicko(ply, category) -- Step 1
    Glickos[ply] = Glickos[ply] or {}
    Glickos[ply][(category or "") .. "Rating"] = Glickos[ply][(category or "") .. "Rating"] or StartingRating -- set the rating to 1500 
    Glickos[ply][(category or "") .. "RD"] = Glickos[ply][(category or "") .. "RD"] or StartingRD -- and the RD to 350."
    return Glickos[ply][(category or "") .. "RD"], Glickos[ply][(category or "") .. "Rating"]
end

local function CalculateNewGlicko(ply, matches, category, constant)
    local OpponentRatings = {}
    local OpponentRDs = {}
    local MatchOutcomes = {}
    for _, data in pairs(matches) do
        if data.Winner ~= ply then
            OpponentRatings[#OpponentRatings + 1] = select(2, GetGlicko(data.Winner, category, constant))
            OpponentRDs[#OpponentRDs + 1] = select(1, GetGlicko(data.Winner, category, constant))
        end

        if data.Loser ~= ply then
            OpponentRatings[#OpponentRatings + 1] = select(2, GetGlicko(data.Loser, category, constant))
            OpponentRDs[#OpponentRDs + 1] = select(1, GetGlicko(data.Loser, category, constant))
        end

        MatchOutcomes[#MatchOutcomes + 1] = (data.Winner == ply and 1) or ((data.WinnerScore == data.LoserScore) and 0.5) or 0
    end

    --[[--------
        Step 1
    ----------]]
    -- "If the player is unrated set the rating to 1500 and the RD to 350.""
    -- "Otherwise, use the player’s rating from the last period, and calculate the new RD
    -- from the RD at the last period (RD_old) by the formula
    -- RD = min(sqrt(RD^2_old + c^2, 350))
    -- where c is a constant that governs the increase in uncertainty between rating periods"
    local PlayerRD, PlayerRating = GetGlicko(ply, category, constant)
    PlayerRD = math.min(math.sqrt(Glickos[ply][(category or "") .. "RD"] ^ 2 + (constant or c) ^ 2), StartingRD)
    Glickos[ply][(category or "") .. "RD"] = PlayerRD
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

return CalculateNewGlicko
