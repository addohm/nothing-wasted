-- Nothing Wasted: rested XP estimates.
--
-- A character builds rested XP only while logged out, from the moment it logged out:
-- 5% of a level per 8 hours when it logged out resting (inn or city), a quarter of that anywhere
-- else, up to a cap of 1.5 levels. Each rank of the Legacy perk Well Rested raises the rate and the
-- cap by 4% (values in Data.lua).
local _, ns = ...

local Rested = {}
ns.Rested = Rested

local EIGHT_HOURS = 8 * 60 * 60

-- Returns the rested XP gained per second (as a fraction of a level) and the cap (in levels).
function Rested.Rules(wellRestedRank, resting)
    local d = ns.Data.rested
    local rank = math.max(0, math.min(wellRestedRank or 0, d.wellRestedMaxRank))
    local perEightHours = d.innPerEightHours * (1 + d.wellRestedRatePerRank * rank)
    if not resting then perEightHours = perEightHours * d.worldFactor end
    return perEightHours / EIGHT_HOURS, d.capLevels * (1 + d.wellRestedCapPerRank * rank)
end

-- True when a character can't gain rested XP: max level, XP turned off, or no data yet.
function Rested.IsIdle(c)
    return c.isMax or c.xpDisabled or not c.xpMax or c.xpMax <= 0
end

-- Estimated rested XP for a saved character at time `now`.
-- Returns rested, cap, secondsToCap and the time the cap is (or was) reached.
--
-- Rested XP only builds while a character is logged out (confirmed in game: nothing builds while
-- logged in, even in an inn). So the character being played keeps its live value, and its time to
-- cap means "if you log out here now".
function Rested.Estimate(c, now)
    if Rested.IsIdle(c) then return 0, 0, 0, nil end
    local rate, capLevels = Rested.Rules(c.wellRested, c.resting)
    local perSecond = c.xpMax * rate
    local cap = c.xpMax * capLevels
    local start = math.min(c.rested or 0, cap)
    local from = c.savedAt or now
    if ns.db and c == ns.db.chars[ns.PlayerKey()] then from = now end
    local cappedAt = from + (cap - start) / perSecond
    local elapsed = math.max(0, now - from)
    local rested = math.min(cap, start + perSecond * elapsed)
    return rested, cap, math.max(0, cappedAt - now), cappedAt
end

-- Rested XP as a fraction of the cap, 0 to 1.
function Rested.Fraction(c, now)
    local rested, cap = Rested.Estimate(c, now)
    if cap <= 0 then return 0 end
    return rested / cap
end

-- The level the character would reach if it used all its rested XP (rested XP doubles kill XP,
-- so each point of rested XP is one bonus point on top of one earned point).
function Rested.CarriesTo(c, now)
    if Rested.IsIdle(c) then return c.level end
    local rested = Rested.Estimate(c, now)
    local levels = (c.xp + 2 * rested) / c.xpMax
    return c.level + levels
end
