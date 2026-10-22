-- Nothing Wasted: leveling pace, who to play next, spells to train, mount gold and the Cozy
-- Sleeping Bag quest chain.
--
-- Pace comes from the addon's own record of time online and XP earned per character, so it needs
-- no /played requests.
local _, ns = ...
local L = ns.L

local Leveling = {}
ns.Leveling = Leveling

-- Time online and XP earned --------------------------------------------------------------------------

local sessionMark   -- GetTime() when online time was last added
local lastXP, lastXPMax, lastLevel

local function AddOnlineTime(c)
    local t = GetTime()
    if sessionMark then c.online = (c.online or 0) + (t - sessionMark) end
    sessionMark = t
end

local function TrackXP(c)
    local xp, xpMax, level = UnitXP("player"), UnitXPMax("player"), UnitLevel("player")
    if lastXP and lastLevel then
        local gained
        if level == lastLevel then
            gained = xp - lastXP
        elseif level > lastLevel then
            gained = (lastXPMax - lastXP) + xp -- rough when several levels pass at once
        end
        if gained and gained > 0 then c.xpEarned = (c.xpEarned or 0) + gained end
    end
    lastXP, lastXPMax, lastLevel = xp, xpMax, level
end

-- XP per hour online, or nil if there isn't enough data yet (half an hour online).
function Leveling.XPPerHour(c)
    if not c.online or c.online < 1800 or not c.xpEarned or c.xpEarned <= 0 then return end
    return c.xpEarned / (c.online / 3600)
end

-- XP still needed to reach the max level, using the XP per level the addon has seen.
local function XPToMax(c)
    if c.isMax or not c.xpMax then return 0 end
    local maxLevel = ns.db.maxLevel or 60
    local need = c.xpMax - (c.xp or 0)
    local known = ns.db.xpPerLevel or {}
    local last = c.xpMax
    for level = c.level + 1, maxLevel - 1 do
        last = known[level] or last
        need = need + last
    end
    return need
end

-- Hours online until the max level at the current pace, or nil.
function Leveling.HoursToMax(c)
    local rate = Leveling.XPPerHour(c)
    if not rate then return end
    return XPToMax(c) / rate
end

-- How far rested XP carries a character: the level it reaches using all of it. Rested XP doubles
-- kill XP, so each point of rested XP is worth two points of progress.
function Leveling.RestedCarriesTo(c, now)
    if ns.Rested.IsIdle(c) then return end
    local rested = ns.Rested.Estimate(c, now)
    local remaining = (c.xp or 0) + 2 * rested
    local level = c.level
    local known = ns.db.xpPerLevel or {}
    local maxLevel = ns.db.maxLevel or 60
    while level < maxLevel do
        local need = known[level] or c.xpMax
        if remaining < need then return level + remaining / need end
        remaining = remaining - need
        level = level + 1
    end
    return level
end

-- Who to play next: capped characters first (their rested XP is being wasted), then those that
-- will cap soonest.
function Leveling.WhoToPlay(now)
    local me = ns.PlayerKey()
    local list = {}
    for key, c in pairs(ns.db.chars) do
        if not ns.Rested.IsIdle(c) and key ~= me then
            local rested, cap, toCap = ns.Rested.Estimate(c, now)
            list[#list + 1] = {
                key = key, c = c, rested = rested, cap = cap, toCap = toCap,
                carries = Leveling.RestedCarriesTo(c, now),
            }
        end
    end
    table.sort(list, function(a, b)
        if a.toCap ~= b.toCap then return a.toCap < b.toCap end
        return (a.c.name or "") < (b.c.name or "")
    end)
    return list
end

-- Spells to train --------------------------------------------------------------------------------

-- Forever doesn't list untrained spells in the spellbook; only the trainer shows them. So a trainer
-- visit saves every spell it lists that isn't learned yet, with the level it needs. Between visits,
-- a saved spell counts as trainable once the character reaches its level.
local function ReadTrainer(c)
    if IsTradeskillTrainer and IsTradeskillTrainer() then return end
    local spells = {}
    for i = 1, GetNumTrainerServices() or 0 do
        local name, kind, _, reqLevel = GetTrainerServiceInfo(i)
        if name and (kind == "available" or kind == "unavailable") then
            -- "unavailable" can also mean a missing earlier rank; those get a level of at least now+1.
            local level = reqLevel or 0
            if kind == "unavailable" and level <= (c.level or 0) then level = (c.level or 0) + 1 end
            spells[#spells + 1] = { name = name, level = level }
        end
    end
    c.trainerSpells = spells
    c.trainerAt = ns.Now()
    c.trainable = nil -- from older builds
end

-- Names of the spells the character can train at its current level, from its last trainer visit.
function Leveling.Trainable(c)
    local names = {}
    for _, s in ipairs(c.trainerSpells or {}) do
        if s.level <= (c.level or 0) then names[#names + 1] = s.name end
    end
    return names
end

-- Cozy Sleeping Bag --------------------------------------------------------------------------------

local function ReadSleepingBag(c)
    local d = ns.Data.sleepingBag
    local done = 0
    for _, step in ipairs(d.chain) do
        local stepDone = false
        for _, questID in ipairs(step) do
            if C_QuestLog.IsQuestFlaggedCompleted(questID) then stepDone = true end
        end
        if stepDone then done = done + 1 end
    end
    c.sleepingBag = {
        done = done,
        steps = #d.chain,
        has = (C_Item.GetItemCount(d.itemID, true) or 0) > 0,
    }
end

-- Mount gold: returns gold saved and gold needed, or nil when it doesn't apply.
function Leveling.MountGold(c)
    local d = ns.Data.mount
    if (c.riding or 0) > 0 or not c.level or c.level < d.level - 10 then return end
    return c.money or 0, d.cost
end

-- Events -----------------------------------------------------------------------------------------

ns.On("NW_CHARACTER_SAVED", function(c, reason)
    AddOnlineTime(c)
    TrackXP(c)
    if reason == "login" then ReadSleepingBag(c) end
end)

ns.On("NW_INIT", function()
    local level = ns.db.maxLevel
    if GameRulesUtil and GameRulesUtil.GetEffectiveMaxLevelForPlayer then
        level = GameRulesUtil.GetEffectiveMaxLevelForPlayer()
    end
    ns.db.maxLevel = level or 60
end)

ns.On("NW_LEVEL_UP", function(c, level)
    C_Timer.After(3, function()
        local me = ns.Me()
        local n = me and #Leveling.Trainable(me) or 0
        if n > 0 then
            ns.Print(format(L["%s reached level %d and has %d spell(s) to train."], ns.ColoredName(me), level, n))
        end
    end)
end)
ns.On("TRAINER_SHOW", function() local c = ns.Me() if c then ReadTrainer(c) end end)
ns.On("TRAINER_UPDATE", function() local c = ns.Me() if c then ReadTrainer(c) end end)
ns.On("QUEST_TURNED_IN", function()
    C_Timer.After(1, function() local c = ns.Me() if c then ReadSleepingBag(c) end end)
end)
