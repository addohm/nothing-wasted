-- Nothing Wasted: the Legacy pages. Goals for each character, choosing goals, and an account planner
-- that shows which challenges the account still lacks.
local _, ns = ...
local L = ns.L

local GREY = "|cff999999"
local GREEN = "|cff40ff40"


local function Pct(q, req)
    if not req or req <= 0 then return "" end
    return format("%s / %s", ns.FormatNumber(q), ns.FormatNumber(req))
end

local function SummaryItems(items)
    local acc = ns.db.legacy
    local me = ns.Me()
    if acc and acc.earned then
        items[#items + 1] = { left = L["Legacy points earned by the account"], right = acc.max and format("%d / %d", acc.earned, acc.max) or tostring(acc.earned) }
    end
    if me and me.legacyPoints then
        local p = me.legacyPoints
        items[#items + 1] = { left = format(L["%s: spent / unspent"], ns.ColoredName(me)), right = format("%d / %d", p.spent, p.unspent) .. (p.cap and format(GREY .. "  (" .. L["cap %d"] .. ")|r", p.cap) or "") }
    end
end

local function GoalItems()
    local items = {}
    SummaryItems(items)
    local list = {}
    for key, c in pairs(ns.db.chars) do list[#list + 1] = { key = key, c = c } end
    table.sort(list, function(a, b) return (a.c.name or "") < (b.c.name or "") end)
    local any = false
    for _, e in ipairs(list) do
        local goals = e.c.legacyProgress
        if goals and next(goals) then
            any = true
            items[#items + 1] = { left = ns.ColoredName(e.c), header = true }
            for _, g in pairs(goals) do
                items[#items + 1] = { left = "   " .. (g.name or "?"), right = Pct(g.q, g.req) }
            end
        end
    end
    if not any then
        items[#items + 1] = { left = GREY .. L["No goals yet. Use \"Choose goals\" to pick challenges for this character."] .. "|r" }
    end
    return items
end

local function ChooseItems()
    local items = {}
    local me = ns.Me()
    if not me then return items end
    items[#items + 1] = { left = format(L["Click a challenge to make it a goal for %s."], ns.ColoredName(me)) }
    local goals = me.legacyGoals or {}
    for _, cat in ipairs(ns.Legacy.Catalog()) do
        local header = false
        for _, ch in ipairs(cat.challenges) do
            if not ch.earnedByMe then -- completed challenges are hidden
                if not header then
                    items[#items + 1] = { left = cat.name, header = true }
                    header = true
                end
                local isGoal = goals[ch.id]
                items[#items + 1] = {
                    left = (isGoal and (GREEN .. "[x]|r ") or "[  ] ") .. ch.name,
                    right = ch.points > 0 and format(L["%d pts"], ch.points) or "",
                    onClick = function() ns.Legacy.SetGoal(ch.id, not isGoal) end,
                    tooltip = function(tip)
                        tip:AddLine(ch.name)
                        local done, q, req, text = ns.Legacy.Progress(ch.id)
                        if text then tip:AddLine(text, 1, 1, 1, true) end
                        if not done and req > 1 then tip:AddLine(Pct(q, req), 1, 1, 1) end
                        if ch.completed then tip:AddLine(L["Another character has completed this."], 0.6, 0.6, 0.6, true) end
                    end,
                }
            end
        end
    end
    return items
end

local function PlannerItems()
    local items = {}
    SummaryItems(items)
    items[#items + 1] = { left = L["Challenges no character on the account has completed yet:"] }
    local any = false
    for _, cat in ipairs(ns.Legacy.Catalog()) do
        local open = {}
        for _, ch in ipairs(cat.challenges) do
            if not ch.completed then open[#open + 1] = ch end
        end
        if #open > 0 then
            any = true
            items[#items + 1] = { left = cat.name, header = true, right = format(L["%d left"], #open) }
            for _, ch in ipairs(open) do
                items[#items + 1] = { left = "   " .. ch.name, right = ch.points > 0 and format(L["%d pts"], ch.points) or "" }
            end
        end
    end
    if not any then items[#items + 1] = { left = GREEN .. L["Every challenge is complete."] .. "|r" } end
    return items
end

local function ListPage(id, label, order, source)
    ns.Window.AddPage({
        id = id,
        group = "legacy",
        label = label,
        order = order,
        build = function(panel) panel.list = ns.UI.TextList(panel) end,
        refresh = function(panel) panel.list:SetItems(source()) end,
    })
end

ListPage("goals", L["Goals"], 1, GoalItems)
ListPage("choose", L["Choose goals"], 2, ChooseItems)
ListPage("planner", L["Account planner"], 3, PlannerItems)
