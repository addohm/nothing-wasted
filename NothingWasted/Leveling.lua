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

-- Counts spells in the spellbook the character could train now. Forever lists future spells in the
-- spellbook; if it doesn't, this finds none and the trainer visit fills it in instead.
local function CountTrainable(c)
    if not C_SpellBook or not C_SpellBook.GetNumSpellBookSkillLines then return end
    local bank = Enum.SpellBookSpellBank.Player
    local level = UnitLevel("player")
    local names = {}
    for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
        local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
        if info and not info.offSpecID then
            for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
                local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
                if item and item.itemType == Enum.SpellBookItemType.FutureSpell then
                    local learnedAt = C_SpellBook.GetSpellBookItemLevelLearned(slot, bank)
                    if learnedAt and learnedAt > 0 and learnedAt <= level then
                        names[#names + 1] = item.name
                    end
                end
            end
        end
    end
    c.trainable = names
end

-- At a class trainer the game says exactly what's available.
local function ReadTrainer(c)
    if IsTradeskillTrainer and IsTradeskillTrainer() then return end
    local names = {}
    for i = 1, GetNumTrainerServices() or 0 do
        local name, kind = GetTrainerServiceInfo(i)
        if kind == "available" and name then names[#names + 1] = name end
    end
    c.trainable = names
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
    if reason == "login" then
        CountTrainable(c)
        ReadSleepingBag(c)
    end
end)

ns.On("NW_INIT", function()
    local level = ns.db.maxLevel
    if GameRulesUtil and GameRulesUtil.GetEffectiveMaxLevelForPlayer then
        level = GameRulesUtil.GetEffectiveMaxLevelForPlayer()
    end
    ns.db.maxLevel = level or 60
end)

local pending
local function TrainableSoon()
    if pending then return end
    pending = true
    C_Timer.After(2, function()
        pending = false
        local c = ns.Me()
        if c then CountTrainable(c) end
    end)
end
ns.On("NW_LEVEL_UP", function(c, level)
    TrainableSoon()
    C_Timer.After(3, function()
        local me = ns.Me()
        if me and me.trainable and #me.trainable > 0 then
            ns.Print(format(L["%s reached level %d and has %d spell(s) to train."], ns.ColoredName(me), level, #me.trainable))
        end
    end)
end)
ns.On("LEARNED_SPELL_IN_SKILL_LINE", TrainableSoon)
ns.On("TRAINER_SHOW", function() local c = ns.Me() if c then ReadTrainer(c) end end)
ns.On("TRAINER_UPDATE", function() local c = ns.Me() if c then ReadTrainer(c) end end)
ns.On("QUEST_TURNED_IN", function()
    C_Timer.After(1, function() local c = ns.Me() if c then ReadSleepingBag(c) end end)
end)
