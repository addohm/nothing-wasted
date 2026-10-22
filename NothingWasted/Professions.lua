-- Nothing Wasted: professions, skill levels, known recipes, trainer ranks and the Forever trade
-- economy (Merchant's Favor and the trade reputations).
--
-- Skill levels are read at login and whenever skills change. Recipes are read when a profession
-- window is open, since that's the only time the game lists them.
local _, ns = ...
local L = ns.L

local Professions = {}
ns.Professions = Professions

-- Skills ---------------------------------------------------------------------------------------------

function Professions.ReadSkills(c)
    local list = {}
    local indexes = { GetProfessions() }
    for slot = 1, select("#", GetProfessions()) do
        local index = indexes[slot]
        if index then
            local name, icon, rank, maxRank, _, _, skillLine = GetProfessionInfo(index)
            if name then
                list[#list + 1] = {
                    name = name, icon = icon, rank = rank or 0, max = maxRank or 0,
                    skillLine = skillLine, primary = slot <= 2,
                }
            end
        end
    end
    c.professions = list

    -- Riding is a skill line, not a profession.
    local riding = C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID and C_SkillInfo.GetSkillLineInfoByID(ns.Data.RIDING_SKILL_LINE)
    c.riding = riding and riding.rank or 0
end

-- The next trainer rank for a profession: returns name, skill needed, level needed, and whether
-- the character is stuck (at its cap and able to train now).
function Professions.NextRank(p, level)
    for _, tier in ipairs(ns.Data.professionRanks) do
        if p.max < tier.max then
            local stuck = p.rank >= p.max and p.rank >= tier.skill and (level or 0) >= tier.level
            return tier.name, tier.skill, tier.level, stuck
        end
    end
end

-- Recipes --------------------------------------------------------------------------------------------

local function ReadRecipes()
    if not C_TradeSkillUI or C_TradeSkillUI.IsDataSourceChanging() then return end
    local info = C_TradeSkillUI.GetBaseProfessionInfo()
    if not info or not info.professionName then return end
    local c = ns.Me()
    if not c then return end
    if C_TradeSkillUI.IsTradeSkillLinked and C_TradeSkillUI.IsTradeSkillLinked() then return end

    local recipes = {}
    local cache = ns.db.recipes or {}
    ns.db.recipes = cache
    for _, id in ipairs(C_TradeSkillUI.GetFilteredRecipeIDs() or {}) do
        local r = C_TradeSkillUI.GetRecipeInfo(id)
        if r and r.learned then
            recipes[id] = true
            local entry = cache[id] or {}
            entry.name = r.name
            entry.icon = r.icon
            entry.profession = info.professionName
            local schematic = C_TradeSkillUI.GetRecipeSchematic(id, false)
            if schematic then
                entry.output = schematic.outputItemID
                entry.reagents = {}
                for _, slot in ipairs(schematic.reagentSlotSchematics or {}) do
                    local reagent = slot.reagents and slot.reagents[1]
                    if reagent and reagent.itemID and slot.required ~= false then
                        entry.reagents[#entry.reagents + 1] = { itemID = reagent.itemID, count = slot.quantityRequired or 1 }
                    end
                end
            end
            cache[id] = entry
        end
    end
    c.recipes = c.recipes or {}
    c.recipes[info.professionName] = recipes
    ns.Fire("NW_REFRESH")
end

local recipePending
ns.On("TRADE_SKILL_LIST_UPDATE", function()
    if recipePending then return end
    recipePending = true
    C_Timer.After(1, function()
        recipePending = false
        ReadRecipes()
    end)
end)
ns.On("NEW_RECIPE_LEARNED", function() C_Timer.After(1, ReadRecipes) end)

-- Does a character know a recipe with this name?
function Professions.KnowsByName(c, recipeName)
    for _, set in pairs(c.recipes or {}) do
        for id in pairs(set) do
            local r = ns.db.recipes[id]
            if r and r.name == recipeName then return true end
        end
    end
    return false
end

-- How many times a recipe can be crafted with what all characters hold (bags, bank, mail).
function Professions.CraftableFromAlts(recipeID)
    local r = ns.db.recipes and ns.db.recipes[recipeID]
    if not r or not r.reagents or #r.reagents == 0 then return 0 end
    local best
    for _, reagent in ipairs(r.reagents) do
        local have = ns.Inventory.TotalCount(reagent.itemID)
        local n = math.floor(have / reagent.count)
        if not best or n < best then best = n end
    end
    return best or 0
end

-- Trade economy ----------------------------------------------------------------------------------------

local function FindFactionByName(name)
    if not C_Reputation or not C_Reputation.GetNumFactions then return end
    for i = 1, C_Reputation.GetNumFactions() do
        local data = C_Reputation.GetFactionDataByIndex(i)
        if data and data.name == name then return data.factionID end
    end
end

function Professions.ReadTrade(c)
    c.trade = c.trade or {}
    for _, f in ipairs(ns.Data.tradeFactions) do
        local id = f.id or FindFactionByName(f.name)
        local data = id and C_Reputation.GetFactionDataByID(id)
        if data then
            c.trade[f.key] = {
                name = data.name,
                standing = _G["FACTION_STANDING_LABEL" .. (data.reaction or 4)],
                value = (data.currentStanding or 0) - (data.currentReactionThreshold or 0),
                max = (data.nextReactionThreshold or 0) - (data.currentReactionThreshold or 0),
            }
        end
    end
    local favor = ns.Data.merchantsFavor
    if favor.id and C_CurrencyInfo then
        local info = C_CurrencyInfo.GetCurrencyInfo(favor.id)
        if info then c.trade.favor = { name = info.name, quantity = info.quantity or 0, icon = info.iconFileID } end
    end
end

-- Events -----------------------------------------------------------------------------------------------

ns.On("NW_CHARACTER_SAVED", function(c, reason)
    if reason then
        Professions.ReadSkills(c)
        Professions.ReadTrade(c)
    end
end)

local pending
local function ReadSoon()
    if pending then return end
    pending = true
    C_Timer.After(1, function()
        pending = false
        local c = ns.Me()
        if c then
            Professions.ReadSkills(c)
            Professions.ReadTrade(c)
            ns.Fire("NW_REFRESH")
        end
    end)
end
for _, event in ipairs({ "SKILL_LINES_CHANGED", "UPDATE_FACTION", "CURRENCY_DISPLAY_UPDATE" }) do
    ns.On(event, ReadSoon)
end

-- Recipe tooltips: which characters know a recipe, or when they can learn it ------------------------

local RECIPE_CLASS = 9 -- Enum.ItemClass.Recipe

local function RequiredSkill(data)
    for _, line in ipairs(data.lines or {}) do
        if line.type == Enum.TooltipDataLineType.UsageRequirement and line.leftText then
            local n = line.leftText:match("%((%d+)%)")
            if n then return tonumber(n) end
        end
    end
end

local function OnItemTooltip(tooltip, data)
    if not data or not data.id or not ns.db then return end
    local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(data.id)
    if classID ~= RECIPE_CLASS then return end
    local skillLine = ns.Data.recipeSubclassSkillLine[subclassID]
    if not skillLine then return end
    local itemName = C_Item.GetItemNameByID(data.id)
    local recipeName = itemName and (itemName:match("^[^:]+:%s*(.+)$") or itemName)
    local required = RequiredSkill(data)

    local lines = {}
    for _, c in pairs(ns.db.chars) do
        for _, p in ipairs(c.professions or {}) do
            if p.skillLine == skillLine then
                local text
                if recipeName and Professions.KnowsByName(c, recipeName) then
                    text = "|cff808080" .. L["knows it"] .. "|r"
                elseif not required or p.rank >= required then
                    text = "|cff40ff40" .. L["can learn it"] .. "|r"
                else
                    text = "|cffffd100" .. format(L["can learn at %d (now %d)"], required, p.rank) .. "|r"
                end
                lines[#lines + 1] = { ns.ColoredName(c), text }
            end
        end
    end
    if #lines == 0 then return end
    tooltip:AddLine(" ")
    tooltip:AddLine("Nothing Wasted", 0.4, 0.8, 1)
    for _, line in ipairs(lines) do tooltip:AddDoubleLine(line[1], line[2]) end
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
        if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
        OnItemTooltip(tooltip, data)
    end)
end
