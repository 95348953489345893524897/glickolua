-- Glicko system in lua based on the paper by Dr. Mark E. Glickman 
-- https://www.glicko.net/glicko/glicko.pdf
local StartingRating = 1500
local StartingRD = 350
-- I would therefore recommend that an RD never drop below a threshold value,
-- such as 30, so that ratings can change appreciably even in a relatively short time.
-- RDThreshold isn't used currently, will probably use it later.
local RDThreshold = 30
for _, ply in player.Iterator() do -- delete this for loop later
    ply.Glickos = {
        -- Make these able to have different category strings later. 
        -- There should not be only 1 universal category for all glickos. 
        -- Maybe servers have different gamemodes that need different glickos.
        ["RD"] = nil,
        ["Rating"] = nil
    }
end

--[[
local function SUM(equation, iterations) -- Instead of writing a for loop every time for my mathematical notation I use this. It looks better.
    local sum = 0
    for j = 1, iterations do
        sum = equation
    end
end
--]]
local function GetPlayerRD(ply) -- Get the old RD, for use in step 2
    return ply.Glickos["RD"] or StartingRD
end

local function GetPlayerRating(ply) -- Get the old Rating, for use in step 2
    return ply.Glickos["Rating"] or StartingRating
end

local function GetGlicko(ply, category) -- Step 1
    if not ply.Glickos then
        -- If the player is unrated
        ply.Glickos["Rating"] = StartingRating -- set the rating to 1500 
        ply.Glickos["RD"] = StartingRD -- and the RD to 350. 
    else -- Otherwise,
        -- use the player’s rating from the last period, and calculate the new RD
        -- from the RD at the last period (RDold) by the formula
        -- RD = min(sqrt(RD^2_old + c^2, 350))
        -- where c is a constant that governs the increase in uncertainty between rating periods
        --local c = 63.2 -- Used by the paper. I do not have the data to determine a different c for my case. 
        local c = 0
        ply.Glickos["RD"] = math.min(math.sqrt(ply.Glickos["RD"] ^ 2 + c ^ 2), StartingRD)
    end
end

local function CalculateNewGlicko(ply, matches, category)
    GetGlicko(ply)
    -- Step 2
    -- Assume that the player’s pre-period rating is r
    local r = ply.Glickos["Rating"]
    --and the ratings deviation is RD 
    -- determined from Step 1
    local RD = ply.Glickos["RD"]
    -- Let m be the number of opponents
    local m = #matches
    local OpponentStats = {}
    for i = 1, m do
        local Opp = matches[i]
        GetGlicko(Opp)
        OpponentStats[i] = {GetPlayerRD(Opp), GetPlayerRating(Opp), Opp.Result}
    end

    -- Let the pre-period ratings of the m opponents (again from Step 1) 
    -- be r_1, r_2, . . . , r_m 
    local r_ = OpponentStats -- r_[j][2]
    -- and the ratings deviations be RD_1, RD_2, . . . , RD_m. 
    local RD_ = OpponentStats -- RD_[j][1]
    -- Also let s_1, . . . , s_m be the outcome against each opponent, 
    -- with an outcome being either 1, 1/2, or 0 for a win, draw and loss.
    local s_ = OpponentStats -- s_[j][3]
    -- Where q = ln(10) / 400 = 0.0057565
    local q = math.log(10) / 400

    -- Declare pi for less clutter in notation below
    local pi = math.pi
    local function g(RD_J) -- Where g(RD) = 1 / sqrt(1 + 3q^2(rd^2) / pi^2)
        return 1 / math.sqrt(1 + 3 * q ^ 2 * (RD_J ^ 2) / pi ^ 2)
    end

    local rPrime = nil
    local RDPrime = nil
    for i = 1, #matches do -- Carry out the following updating calculations for each player separately
        -- ∑ g(RD_j)(s_j - E(s|r, r_j, RD_j)
        -- Where E(s|r, r_j, RD_j) = 1 / (1 + 10 ^ (-g(RD_j)(r-r_j) / 400)
        local function E(_, r_j, RD_j)
            return 1 / (1 + 10 ^ (-g(RD_j) * (r - r_j) / 400))
        end

        -- Calculate what's inside Sigma before-hand 
        local ESUM = 0
        ESUM = ESUM + g(RD_[i][1]) * s_[i][3] - E(_, r_[i][2], RD_[i][1])
        -- Calculate the d^2 Sigma beforehand
        -- Where d^2 = (q^2 * ∑ (g(RD_j))^2 * E(s|r, r_j, RD_j) * (1 - E(s|r, r_j, RD_j))) ^ -1
        local dSquared = 0
        for j = 1, m do
            dSquared = dSquared + (g(RD_[j][1]) ^ 2 * E(_, r_[j][2], RD_[j][1]) * (1 - E(_, r_[j][2], RD_[j][1])))
        end

        -- Multiply dSquared by the q^2 that was outside of Sigma
        dSquared = (q ^ 2 * dSquared) ^ -1
        rPrime = r + q / (1 / RD ^ 2 + 1 / dSquared) * ESUM
        matches[i].Glickos["Rating"] = rPrime
        RDPrime = math.sqrt((1 / RD ^ 2 + 1 / dSquared) ^ -1)
        matches[i].Glickos["RD"] = RDPrime
        -- Note that multiple games against the same opponent are treated
        -- as games against multiple opponents with the same rating and RD
    end
    return rPrime, RDPrime
end

--[[-----------------------
    Tests 
    (examples used from section of the paper titled "Example calculation")
-------------------------]]
local ExamplePlayer = {
    Glickos = {
        ["RD"] = 200,
        ["Rating"] = 1500
    }
}

local Match1 = {
    Glickos = {
        ["RD"] = 30,
        ["Rating"] = 1400
    },
    Result = 1
}

local Match2 = {
    Glickos = {
        ["RD"] = 100,
        ["Rating"] = 1550
    },
    Result = 0
}

local Match3 = {
    Glickos = {
        ["RD"] = 300,
        ["Rating"] = 1700
    },
    Result = 0
}

print(CalculateNewGlicko(ExamplePlayer, {Match1, Match2, Match3}))
-- Output: 1460.0409247964	151.39890244797
-- Now calculate it manually to be absolutely sure (the paper uses rounding, I don't, this makes my numbers seem off.): 
-- Opponent Ratings: 1400, 1550, 1700
-- Opponent RDs:     30,   100,  300
-- Player Rating: 1500 (standard) 
-- Player RD:     200
-- RD = min(sqrt(RD^2_old) + c ^ 2, 350)
-- Where c = 0 (example calculation does not use c)
-- PlayerRD = min(sqrt(200^2) + 0 ^ 2, 350) = 200
-- r' = r + q / ((1 / RD^2) + (1 / d^2))
--
