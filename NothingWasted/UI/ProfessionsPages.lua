-- Nothing Wasted: the Professions pages. Skill levels, trainer ranks and the trade economy for every
-- character, and what each can craft from what all your characters hold.
local _, ns = ...
local L = ns.L

local CRAFTS_PER_PROFESSION = 10

local function Chars()
    local list = {}
    for _, c in pairs(ns.db.chars) do list[#list + 1] = c end
    table.sort(list, function(a, b) return (a.name or "") < (b.name or "") end)
    return list
end

local function SkillItems()
    local items = {}
    for _, c in ipairs(Chars()) do
        local hasAny = c.professions and #c.professions > 0
        local trade = c.trade or {}
        if hasAny or trade.favor then
            items[#items + 1] = { left = ns.ColoredName(c), header = true }
            for _, p in ipairs(c.professions or {}) do
                local nextName, skill, level, stuck = ns.Professions.NextRank(p, c.level)
                local note = ""
                if stuck then
                    note = "  |cffff8040" .. format(L["stuck: train %s"], nextName) .. "|r"
                elseif nextName and p.rank >= p.max and (c.level or 0) < level then
                    note = "  |cffffd100" .. format(L["%s needs level %d"], nextName, level) .. "|r"
                elseif nextName then
                    note = "  |cff999999" .. format(L["%s at %d"], nextName, skill) .. "|r"
                end
                items[#items + 1] = {
                    indent = 1,
                    left = (p.icon and ("|T" .. p.icon .. ":0|t ") or "") .. p.name .. note,
                    right = format("%d / %d", p.rank, p.max),
                }
            end
            if trade.favor then
                items[#items + 1] = { indent = 1, left = (trade.favor.icon and ("|T" .. trade.favor.icon .. ":0|t ") or "") .. trade.favor.name, right = ns.FormatNumber(trade.favor.quantity) }
            end
            for _, f in ipairs(ns.Data.tradeFactions) do
                local rep = trade[f.key]
                if rep then
                    items[#items + 1] = { indent = 1, left = rep.name, right = format("%s  %d / %d", rep.standing or "", rep.value, rep.max) }
                end
            end
        end
    end
    return items
end

local craftsOpen = {} -- headers toggled on the Crafts view: characters start open, professions closed

local function CraftItems()
    local items = {}
    for _, c in ipairs(Chars()) do
        -- Gather this character's crafts first, so its header can show how many there are.
        local byProfession, total = {}, 0
        for profession, set in pairs(c.recipes or {}) do
            local crafts = {}
            for id in pairs(set) do
                local n = ns.Professions.CraftableFromAlts(id)
                if n > 0 then crafts[#crafts + 1] = { id = id, n = n } end
            end
            table.sort(crafts, function(a, b) return a.n > b.n end)
            if #crafts > 0 then
                byProfession[#byProfession + 1] = { name = profession, crafts = crafts }
                total = total + #crafts
            end
        end
        table.sort(byProfession, function(a, b) return a.name < b.name end)
        local key = (c.name or "?") .. "-" .. (c.realm or "?")
        if total > 0 then
            items[#items + 1] = ns.UI.CollapsibleHeader(craftsOpen, key, ns.ColoredName(c),
                format(L["%d recipe(s)"], total), true)
        end
        local charOpen = ns.UI.IsOpen(craftsOpen, key, true)
        for _, group in ipairs(charOpen and byProfession or {}) do
            local profession, crafts = group.name, group.crafts
            local profKey = key .. "|" .. profession
            items[#items + 1] = ns.UI.CollapsibleHeader(craftsOpen, profKey, profession,
                format(L["%d recipe(s)"], #crafts), false, 1)
            for i = 1, ns.UI.IsOpen(craftsOpen, profKey) and math.min(#crafts, CRAFTS_PER_PROFESSION) or 0 do
                local r = ns.db.recipes[crafts[i].id]
                items[#items + 1] = {
                    indent = 2,
                    left = (r.icon and ("|T" .. r.icon .. ":0|t ") or "") .. (r.name or "?"),
                    right = format(L["can make %d"], crafts[i].n),
                    tooltip = function(tip)
                        tip:AddLine(r.name or "?")
                        for _, reagent in ipairs(r.reagents or {}) do
                            local item = ns.db.items and ns.db.items[reagent.itemID]
                            tip:AddDoubleLine(format("%dx %s", reagent.count, item and item.name or ("item:" .. reagent.itemID)),
                                format(L["%d on your characters"], ns.Inventory.TotalCount(reagent.itemID)), 1, 1, 1, 1, 1, 1)
                        end
                    end,
                }
            end
        end
    end
    if #items == 0 then
        items[#items + 1] = { left = "|cff999999" .. L["Open each profession window once so its recipes are recorded."] .. "|r" }
    end
    return items
end

local function ListPage(id, label, order, source)
    ns.Window.AddPage({
        id = id,
        group = "professions",
        label = label,
        order = order,
        build = function(panel) panel.list = ns.UI.TextList(panel) end,
        refresh = function(panel) panel.list:SetItems(source()) end,
    })
end

ListPage("skills", L["Skills"], 1, SkillItems)
ListPage("crafts", L["Crafts from your alts' items"], 2, CraftItems)
