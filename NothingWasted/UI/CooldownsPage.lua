-- Nothing Wasted: the Cooldowns page. Every tracked cooldown on every character, ready ones first.
local _, ns = ...
local L = ns.L

local function Items()
    local now = ns.Now()
    local rows = {}
    for _, c in pairs(ns.db.chars) do
        for _, cd in ipairs(ns.Cooldowns.List(c, now)) do
            rows[#rows + 1] = { c = c, cd = cd }
        end
        local bag = c.sleepingBag
        if bag and not bag.has and (c.level or 0) >= ns.Data.sleepingBag.level and bag.steps then
            rows[#rows + 1] = { c = c, quest = bag }
        end
    end
    table.sort(rows, function(a, b)
        local al, bl = a.cd and a.cd.left or math.huge, b.cd and b.cd.left or math.huge
        if al ~= bl then return al < bl end
        return (a.c.name or "") < (b.c.name or "")
    end)

    local items = {}
    local ready = 0
    for _, r in ipairs(rows) do
        if r.cd then
            if r.cd.left <= 0 then ready = ready + 1 end
            items[#items + 1] = {
                left = ns.ColoredName(r.c) .. "  " .. r.cd.name,
                right = r.cd.left <= 0 and ("|cff40ff40" .. L["Ready"] .. "|r") or ns.FormatDuration(r.cd.left),
            }
        else
            items[#items + 1] = {
                left = ns.ColoredName(r.c) .. "  " .. L["Cozy Sleeping Bag quest chain"],
                right = format(L["%d / %d quests"], r.quest.done, r.quest.steps),
                tooltip = function(tip)
                    tip:AddLine(L["Cozy Sleeping Bag"])
                    tip:AddLine(L["A quest chain from level 14 that starts at the Alexston Farmstead in Westfall (Alliance) or near Camp Taurajo in the Barrens (Horde). The bag gives bonus XP and works away from inns."], 1, 1, 1, true)
                end,
            }
        end
    end
    if ready > 0 then
        table.insert(items, 1, { left = format(L["%d ready now"], ready), header = true })
    end
    return items
end

ns.Window.AddPage({
    id = "cooldowns",
    group = "characters",
    label = L["Cooldowns"],
    order = 3,
    build = function(panel)
        panel.list = ns.UI.TextList(panel)
    end,
    refresh = function(panel)
        panel.list:SetItems(Items(), L["No cooldowns yet. Log in to characters with professions or camping items."])
    end,
})
