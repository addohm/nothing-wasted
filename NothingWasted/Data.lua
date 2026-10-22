-- Nothing Wasted: game data for WoW: Forever. IDs were checked against Wowhead's Forever tooltips
-- (build 1.60.1) unless a comment says otherwise.
local _, ns = ...

local Data = {}
ns.Data = Data

Data.rested = {
    innPerEightHours = 0.05, -- 5% of a level per 8 hours in an inn or city
    worldFactor = 0.25,      -- a quarter of that elsewhere (Classic rule, not yet confirmed for Forever)
    capLevels = 1.5,         -- capped at 150% of a level
    -- Well Rested (spell 1225478): each rank makes rested XP build 4% faster and raises the cap 4%.
    wellRestedRatePerRank = 0.04,
    wellRestedCapPerRank = 0.04,
    wellRestedMaxRank = 5,
}

-- Legacy perks to track, found in the Legacy trees by spell ID (or by English name as a fallback).
Data.perks = {
    wellRested = { spellIDs = { 1225478 }, name = "Well Rested" },
    dedicatedStudy = { spellIDs = { 1225469 }, name = "Dedicated Study" },
}

-- Cooldowns shown for every character. `alert = false` for short ones that would be noise.
-- spellIDs lists spells that share one cooldown; the first one the character knows is used.
local L = ns.L
Data.cooldowns = {
    { id = "dedicatedStudy", name = L["Dedicated Study"], spellID = 1225469 },          -- 23 h
    { id = "mooncloth", name = L["Mooncloth"], spellID = 18560 },                       -- 95 h
    { id = "arcanite", name = L["Transmute: Arcanite"], spellID = 17187 },              -- 47 h
    { id = "essence", name = L["Transmute: elemental essence"],                         -- 23 h
      spellIDs = { 17559, 17560, 17561, 17562, 17563, 17564, 17565, 17566 } },
    { id = "saltShaker", name = L["Salt Shaker"], itemID = 15846 },                     -- 71 h
    { id = "campTent", name = L["Camp Tent"], itemID = 279978, auraSpellID = 1229451, alert = false }, -- 1 h
    { id = "sleepingBag", name = L["Cozy Sleeping Bag"], itemID = 211527, alert = false }, -- 1 h
    { id = "hearthstone", name = L["Hearthstone"], itemID = 6948, alert = false },     -- 1 h
}

-- The Cozy Sleeping Bag quest chain. The first quest has one ID per faction (which is which isn't
-- confirmed, so either counts).
Data.sleepingBag = {
    itemID = 211527,
    level = 14,
    chain = { { 79007, 79008 }, { 79192 }, { 79980 }, { 79974 }, { 79975 }, { 79976 } },
}

-- First mount: level 40, 100g in total (confirmed in game, 2026-10-22).
Data.mount = { level = 40, cost = 100 * 10000 }
Data.RIDING_SKILL_LINE = 762

-- Forever's trade economy.
Data.merchantsFavor = { id = 3402 }
Data.tradeFactions = {
    { key = "commerce", id = 2586, name = "Azeroth Commerce Authority" },    -- Alliance
    { key = "supply", id = 2587, name = "Durotar Supply and Logistics" },    -- Horde
}

-- Trainer ranks for primary and secondary professions (Classic).
Data.professionRanks = {
    { name = L["Journeyman"], max = 150, skill = 50, level = 10 },
    { name = L["Expert"], max = 225, skill = 125, level = 20 },
    { name = L["Artisan"], max = 300, skill = 200, level = 35 },
}

-- Recipe item subclass -> profession skill line.
Data.recipeSubclassSkillLine = {
    [1] = 165, -- Leatherworking
    [2] = 197, -- Tailoring
    [3] = 202, -- Engineering
    [4] = 164, -- Blacksmithing
    [5] = 185, -- Cooking
    [6] = 171, -- Alchemy
    [7] = 129, -- First Aid
    [8] = 333, -- Enchanting
    [9] = 356, -- Fishing
}
