-- Nothing Wasted: the Leveling tab. Who to play next, leveling pace, spells to train and mount gold.
local _, ns = ...
local L = ns.L


local function ByName(a, b) return (a.c.name or "") < (b.c.name or "") end

local function Chars()
    local list = {}
    for key, c in pairs(ns.db.chars) do list[#list + 1] = { key = key, c = c } end
    table.sort(list, ByName)
    return list
end

local SOON = 24 * 3600 -- "caps in" is highlighted when it's within a day

local function Items()
    local now = ns.Now()
    local items = {}

    items[#items + 1] = { left = L["Who to play next"], header = true }
    local ranked = ns.Leveling.WhoToPlay(now)
    if #ranked == 0 then items[#items + 1] = { left = "   " .. L["No alts that can gain rested XP yet."] } end
    for i, e in ipairs(ranked) do
        local why
        if e.toCap <= 0 then
            why = "|cffff4040" .. L["at cap, rested XP is going to waste"] .. "|r"
        else
            why = format(L["caps in %s"], ns.FormatDuration(e.toCap))
            if e.toCap <= SOON then why = "|cffffd100" .. why .. "|r" end
        end
        items[#items + 1] = {
            left = format("   %d. %s  %s", i, ns.ColoredName(e.c), why),
            right = e.carries and format(L["rested to %.1f"], e.carries) or "",
        }
        if i >= 5 then break end
    end

    items[#items + 1] = { left = L["Pace"], header = true }
    for _, e in ipairs(Chars()) do
        local c = e.c
        if not c.isMax then
            local rate = ns.Leveling.XPPerHour(c)
            local hoursLeft = ns.Leveling.HoursToMax(c)
            items[#items + 1] = {
                left = format("   %s  %s", ns.ColoredName(c), format(L["level %d"], c.level or 0)),
                right = rate and format(L["%s XP/h, %d in about %s"], ns.FormatNumber(rate), ns.db.maxLevel or 60, ns.FormatDuration(hoursLeft * 3600))
                    or ("|cff999999" .. L["needs more time online"] .. "|r"),
            }
        end
    end

    local train = {}
    for _, e in ipairs(Chars()) do
        if e.c.trainable and #e.c.trainable > 0 then train[#train + 1] = e end
    end
    if #train > 0 then
        items[#items + 1] = { left = L["Spells to train"], header = true }
        for _, e in ipairs(train) do
            local names = e.c.trainable
            items[#items + 1] = {
                left = "   " .. ns.ColoredName(e.c),
                right = format(L["%d spell(s)"], #names),
                tooltip = function(tip)
                    tip:AddLine(L["Spells to train"])
                    for _, n in ipairs(names) do tip:AddLine(n, 1, 1, 1) end
                end,
            }
        end
    end

    local mount = {}
    for _, e in ipairs(Chars()) do
        local have, need = ns.Leveling.MountGold(e.c)
        if have then mount[#mount + 1] = { c = e.c, have = have, need = need } end
    end
    if #mount > 0 then
        items[#items + 1] = { left = format(L["Gold for the level %d mount"], ns.Data.mount.level), header = true }
        for _, m in ipairs(mount) do
            local color = m.have >= m.need and "|cff40ff40" or ""
            items[#items + 1] = {
                left = format("   %s  %s", ns.ColoredName(m.c), format(L["level %d"], m.c.level)),
                right = color .. ns.FormatMoney(m.have) .. " / " .. ns.FormatMoney(m.need),
            }
        end
    end
    return items
end

ns.Window.AddTab({
    id = "leveling",
    label = L["Leveling"],
    order = 3,
    build = function(panel)
        panel.list = ns.UI.TextList(panel)
    end,
    refresh = function(panel)
        panel.list:SetItems(Items())
    end,
})
