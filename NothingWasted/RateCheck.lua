-- Nothing Wasted: checking the rested XP rates against the game.
--
-- Two ways, both shown by /nw rate:
--   * A manual measurement: /nw rate sets a mark (saved, so it works across a logout); the next
--     /nw rate shows the rested XP gained since, as % of a level per 8 hours, next to the expected rate.
--   * Login checks: when a character logs in, its real rested XP is compared with what the addon
--     estimated from its last logout, before the login save replaces it.
--
-- This file loads before Character.lua, so its login handler sees the old saved values.
local _, ns = ...
local L = ns.L

local RateCheck = {}
ns.RateCheck = RateCheck

local EIGHT_HOURS = 8 * 3600
local MIN_SAMPLE = 1800 -- login checks need at least half an hour logged out
local KEEP_SAMPLES = 20

-- Rested XP gain as % of a level per 8 hours.
local function PerEightHours(gain, xpMax, seconds)
    if not xpMax or xpMax <= 0 or seconds <= 0 then return 0 end
    return gain / xpMax * 100 * EIGHT_HOURS / seconds
end

-- The expected rate (% of a level per 8 hours) for a character's Well Rested rank and resting state.
local function ExpectedPerEightHours(rank, resting)
    local perSecond = ns.Rested.Rules(rank, resting)
    return perSecond * 100 * EIGHT_HOURS
end

local function Live()
    return {
        xp = UnitXP("player"), xpMax = UnitXPMax("player"), level = UnitLevel("player"),
        rested = GetXPExhaustion() or 0, resting = IsResting() and true or false,
    }
end

-- Login checks -----------------------------------------------------------------------------------

local function Sample(c, now)
    if not c or not c.savedAt or ns.Rested.IsIdle(c) then return end
    local live = Live()
    local away = now - c.savedAt
    -- Only clean samples: the same level and max XP, long enough away, and not stopped by the cap.
    if away < MIN_SAMPLE or live.level ~= c.level or live.xpMax ~= c.xpMax then return end
    local estimate, cap = ns.Rested.Estimate(c, now)
    if estimate >= cap or live.rested >= cap then return end
    local gain = live.rested - (c.rested or 0)
    local samples = ns.db.rateSamples or {}
    ns.db.rateSamples = samples
    table.insert(samples, 1, {
        name = c.name, at = now, away = away, resting = c.resting, rank = c.wellRested or 0,
        gain = gain, expectedGain = estimate - (c.rested or 0),
        rate = PerEightHours(gain, c.xpMax, away),
        expectedRate = ExpectedPerEightHours(c.wellRested, c.resting),
    })
    while #samples > KEEP_SAMPLES do table.remove(samples) end
end

ns.On("PLAYER_ENTERING_WORLD", function(isInitialLogin)
    if not isInitialLogin or not ns.db then return end
    Sample(ns.db.chars[ns.PlayerKey()], ns.Now())
end)

-- /nw rate ---------------------------------------------------------------------------------------

local function Pct(v) return format("%.2f%%", v) end

function RateCheck.Run(arg)
    local c = ns.Me()
    if not c then return end
    local now = ns.Now()
    local live = Live()
    local rank = c.wellRested or 0

    ns.Print(format(L["%s: XP %s / %s (%.1f%%), rested %s (%.1f%% of a level), %s, Well Rested rank %d"],
        ns.ColoredName(c), ns.FormatNumber(live.xp), ns.FormatNumber(live.xpMax), live.xp / math.max(1, live.xpMax) * 100,
        ns.FormatNumber(live.rested), live.rested / math.max(1, live.xpMax) * 100,
        live.resting and L["resting"] or L["not resting"], rank))
    if c.isMax then
        ns.Print(L["At max level there's no rested XP to measure."])
    else
        local inn, away = ExpectedPerEightHours(rank, true), ExpectedPerEightHours(rank, false)
        ns.Print(format(L["Expected: %s of a level per 8h resting (+%s per hour), %s elsewhere (+%s per hour)."],
            Pct(inn), ns.FormatNumber(live.xpMax * inn / 100 / 8), Pct(away), ns.FormatNumber(live.xpMax * away / 100 / 8)))
    end

    local mark = c.rateMark
    if arg == "reset" or not mark then
        c.rateMark = { at = now, rested = live.rested, xp = live.xp, level = live.level, xpMax = live.xpMax,
            resting = live.resting, rank = rank }
        ns.Print(format(L["Mark set at %s with rested %s. Run /nw rate again later; you can log out in between (log out where you want to measure)."],
            date("%H:%M:%S", now), ns.FormatNumber(live.rested)))
    else
        local seconds = now - mark.at
        local gain = live.rested - mark.rested
        ns.Print(format(L["Since the mark at %s (%s ago, rested %s then): rested +%s = %s of a level per 8h (expected %s, %s at the mark)."],
            date("%H:%M:%S", mark.at), ns.FormatDuration(seconds), ns.FormatNumber(mark.rested), ns.FormatNumber(gain),
            Pct(PerEightHours(gain, mark.xpMax, seconds)), Pct(ExpectedPerEightHours(mark.rank, mark.resting)),
            mark.resting and L["resting"] or L["not resting"]))
        if live.level ~= mark.level or live.xp ~= mark.xp then
            ns.Print(L["XP changed since the mark, which uses up rested XP, so this isn't a clean measurement. /nw rate reset starts over."])
        elseif live.rested >= live.xpMax * select(2, ns.Rested.Rules(rank, true)) then
            ns.Print(L["Rested XP is at the cap, so the rate can't be measured past it."])
        end
    end

    local samples = ns.db.rateSamples or {}
    if #samples > 0 then
        ns.Print(L["Checks at login (newest first):"])
        for i = 1, math.min(5, #samples) do
            local s = samples[i]
            ns.Print(format(L["  %s, %s logged out %s: +%s rested (expected +%s) = %s per 8h (expected %s)"],
                s.name or "?", ns.FormatDuration(s.away), s.resting and L["resting"] or L["not resting"],
                ns.FormatNumber(s.gain), ns.FormatNumber(s.expectedGain), Pct(s.rate), Pct(s.expectedRate)))
        end
    end
end
