-- Nothing Wasted: Legacy perks, points and challenges.
--
-- Perks are nodes in the Legacy talent trees. A perk's rank is read from its node, found once by
-- the spell IDs in Data.lua (or by name as a fallback) and remembered. Ranks are read at login,
-- whenever the trees change, and at logout, so a point spent mid-session is never missed.
--
-- Challenges are achievements. Legacy counts one as complete for a character only if that character
-- earned it (wasEarnedByMe); `completed` alone is account-wide.
local _, ns = ...
local L = ns.L

local Legacy = {}
ns.Legacy = Legacy

local CURRENCY_ID = 4225
local TREES = { 1187, 1188, 1189 } -- Professions, Adventure, Progression
local REWARD_FACTION_ID = 2802     -- renown level = Legacy points earned by the account
local TOP_LEVEL_CATEGORY = -1

local function Consts()
    return Constants and Constants.LegacyConsts
end

local function TreeIDs()
    local c = Consts()
    if c then
        return { c.LEGACY_TREE_PROFESSIONS_ID, c.LEGACY_TREE_ADVENTURE_ID, c.LEGACY_TREE_PROGRESSION_ID }
    end
    return TREES
end

-- Perks --------------------------------------------------------------------------------------------

local function NodeSpell(configID, nodeInfo)
    local entryID = (nodeInfo.activeEntry and nodeInfo.activeEntry.entryID) or (nodeInfo.entryIDs and nodeInfo.entryIDs[1])
    if not entryID then return end
    local entry = C_Traits.GetEntryInfo(configID, entryID)
    if not entry or not entry.definitionID then return end
    local def = C_Traits.GetDefinitionInfo(entry.definitionID)
    if not def then return end
    local name = def.overrideName
    if (not name or name == "") and def.spellID then name = C_Spell.GetSpellName(def.spellID) end
    return def.spellID, name
end

local function MatchPerk(spellID, name)
    for perkID, perk in pairs(ns.Data.perks) do
        for _, id in ipairs(perk.spellIDs) do
            if id == spellID then return perkID end
        end
        if name and perk.name and name == perk.name then return perkID end
    end
end

-- Walks the Legacy trees once to find the node of each tracked perk. Returns false if the trees
-- aren't available yet.
local function FindPerkNodes()
    local nodes = ns.db.perkNodes or {}
    ns.db.perkNodes = nodes
    local found = false
    for _, treeID in ipairs(TreeIDs()) do
        local configID = C_Traits.GetConfigIDByTreeID(treeID)
        if configID then
            found = true
            for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID) or {}) do
                local info = C_Traits.GetNodeInfo(configID, nodeID)
                if info then
                    local spellID, name = NodeSpell(configID, info)
                    local perkID = MatchPerk(spellID, name)
                    if perkID then nodes[perkID] = { treeID = treeID, nodeID = nodeID } end
                end
            end
        end
    end
    return found
end

local function PerkRank(perkID)
    local where = ns.db.perkNodes and ns.db.perkNodes[perkID]
    if not where then return 0 end
    local configID = C_Traits.GetConfigIDByTreeID(where.treeID)
    if not configID then return nil end
    local info = C_Traits.GetNodeInfo(configID, where.nodeID)
    return info and info.activeRank or 0
end

-- Reads the current character's perk ranks and Legacy points. Returns true if the data was there.
-- At logout the game can report empty values, so then only a higher Well Rested rank is taken
-- (refunds are caught live by the trait events) and the points aren't touched.
function Legacy.ReadCharacter(c, atLogout)
    if not C_Traits or not C_Traits.GetConfigIDByTreeID then return false end
    local missing = false
    for perkID in pairs(ns.Data.perks) do
        if not (ns.db.perkNodes and ns.db.perkNodes[perkID]) then missing = true end
    end
    if missing and not FindPerkNodes() then return false end

    local wellRested = PerkRank("wellRested")
    if wellRested == nil then return false end
    if atLogout then
        if wellRested > (c.wellRested or 0) then c.wellRested = wellRested end
        return true
    end
    c.wellRested = wellRested
    c.dedicatedStudy = PerkRank("dedicatedStudy") or 0

    local treeID = TreeIDs()[1]
    local configID = C_Traits.GetConfigIDByTreeID(treeID)
    local info = configID and C_Traits.GetTreeCurrencyInfo(configID, treeID, false)
    info = info and info[1]
    if info then
        c.legacyPoints = { unspent = info.quantity or 0, spent = info.spent or 0, cap = info.maxQuantity }
    end

    if C_MajorFactions and C_MajorFactions.GetCurrentRenownLevel then
        ns.db.legacy = ns.db.legacy or {}
        ns.db.legacy.earned = C_MajorFactions.GetCurrentRenownLevel(REWARD_FACTION_ID) or 0
        ns.db.legacy.max = C_Traits.GetMaxAvailableTraitCurrency(CURRENCY_ID, false)
    end
    return true
end

-- Challenges ---------------------------------------------------------------------------------------

-- Progress of one achievement for the current character: done, quantity, required, text.
function Legacy.Progress(achievementID)
    local _, _, _, completed, _, _, _, _, _, _, _, _, earnedByMe = GetAchievementInfo(achievementID)
    local done = completed and earnedByMe or false
    local n = GetAchievementNumCriteria(achievementID) or 0
    if done then return true, 1, 1 end
    if n == 0 then return false, 0, 1 end
    if n == 1 then
        local text, _, critDone, quantity, req = GetAchievementCriteriaInfo(achievementID, 1)
        if req and req > 1 then return critDone or false, quantity or 0, req, text end
        return critDone or false, critDone and 1 or 0, 1, text
    end
    local count = 0
    for i = 1, n do
        local _, _, critDone = GetAchievementCriteriaInfo(achievementID, i)
        if critDone then count = count + 1 end
    end
    return false, count, n
end

-- All Legacy challenges, grouped by category: { { id, name, parent, challenges = { {id, name,
-- points, completed (account), earnedByMe} } } }. In Forever every achievement category is a
-- Legacy challenge category.
function Legacy.Catalog()
    local out = {}
    for _, categoryID in ipairs(GetCategoryList() or {}) do
        local catName, parentID = GetCategoryInfo(categoryID)
        local cat = { id = categoryID, name = catName, parent = parentID ~= TOP_LEVEL_CATEGORY and parentID or nil, challenges = {} }
        local total = GetCategoryNumAchievements(categoryID) or 0
        for i = 1, total do
            local id, name, _, completed, _, _, _, _, _, icon, _, _, earnedByMe = GetAchievementInfo(categoryID, i)
            if id then
                local points = C_Traits.GetTraitCurrencyForAchievement(CURRENCY_ID, id)
                cat.challenges[#cat.challenges + 1] = {
                    id = id, name = name, icon = icon, points = points or 0,
                    completed = completed or false, earnedByMe = earnedByMe or false,
                }
            end
        end
        if #cat.challenges > 0 then out[#out + 1] = cat end
    end
    return out
end

-- Refreshes the saved progress of the current character's goals, dropping goals it has finished.
function Legacy.UpdateGoals(c)
    c.legacyGoals = c.legacyGoals or {}
    c.legacyProgress = c.legacyProgress or {}
    -- Drop the progress of challenges that are no longer goals (unticked).
    for id in pairs(c.legacyProgress) do
        if not c.legacyGoals[id] then c.legacyProgress[id] = nil end
    end
    for id in pairs(c.legacyGoals) do
        local done, q, req, text = Legacy.Progress(id)
        if done then
            c.legacyGoals[id] = nil
            c.legacyProgress[id] = nil
            local _, name = GetAchievementInfo(id)
            ns.Print(format(L["Legacy goal complete: %s"], name or "?"))
        else
            local _, name = GetAchievementInfo(id)
            c.legacyProgress[id] = { name = name, q = q, req = req, text = text }
        end
    end
end

function Legacy.SetGoal(id, on)
    local c = ns.Me()
    if not c then return end
    c.legacyGoals = c.legacyGoals or {}
    c.legacyGoals[id] = on or nil
    Legacy.UpdateGoals(c)
    ns.Fire("NW_REFRESH")
end

-- Events -------------------------------------------------------------------------------------------

local function Refresh()
    local c = ns.Me()
    if not c then return end
    local before = c.wellRested
    if Legacy.ReadCharacter(c) and before ~= c.wellRested and ns.Character then
        -- The rested rate and cap changed: re-anchor the estimate on the live value.
        ns.Character.Save()
    end
    ns.Fire("NW_REFRESH")
end

local pending
local function RefreshSoon()
    if pending then return end
    pending = true
    C_Timer.After(1, function()
        pending = false
        Refresh()
    end)
end

ns.On("NW_CHARACTER_SAVED", function(c, reason)
    if reason == "login" then
        Legacy.ReadCharacter(c)
        Legacy.UpdateGoals(c)
    elseif reason == "logout" then
        Legacy.ReadCharacter(c, true)
    end
end)

for _, event in ipairs({ "TRAIT_CONFIG_UPDATED", "TRAIT_CONFIG_LIST_UPDATED", "TRAIT_TREE_CURRENCY_INFO_UPDATED",
    "TRAIT_NODE_CHANGED", "MAJOR_FACTION_RENOWN_LEVEL_CHANGED" }) do
    ns.On(event, RefreshSoon)
end

local criteriaPending
local function GoalsSoon()
    if criteriaPending then return end
    criteriaPending = true
    C_Timer.After(2, function()
        criteriaPending = false
        local c = ns.Me()
        if c then
            Legacy.UpdateGoals(c)
            ns.Fire("NW_REFRESH")
        end
    end)
end
ns.On("CRITERIA_UPDATE", GoalsSoon)
ns.On("ACHIEVEMENT_EARNED", GoalsSoon)

-- Lists every node in the Legacy trees, to find perk spell IDs in game: /nw perks
function Legacy.DumpPerks()
    for _, treeID in ipairs(TreeIDs()) do
        local configID = C_Traits.GetConfigIDByTreeID(treeID)
        if not configID then
            ns.Print(format("tree %d: not available", treeID))
        else
            for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID) or {}) do
                local info = C_Traits.GetNodeInfo(configID, nodeID)
                if info then
                    local spellID, name = NodeSpell(configID, info)
                    ns.Print(format("tree %d node %d spell %s: %s (rank %d/%d)", treeID, nodeID,
                        tostring(spellID), tostring(name), info.activeRank or 0, info.maxRanks or 0))
                end
            end
        end
    end
end
