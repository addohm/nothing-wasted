-- Nothing Wasted: the leveling pages. Who to play next, leveling pace, spells to train and mount gold.
local _, ns = ...
local L = ns.L

local SOON = 24 * 3600 -- "caps in" is highlighted when it's within a day
local GREY = "|cff999999"

local function Chars()
    local list = {}
    for key, c in pairs(ns.db.chars) do list[#list + 1] = { key = key, c = c } end
    table.sort(list, function(a, b) return (a.c.name or "") < (b.c.name or "") end)
    return list
end

local function WhoToPlay()
    local now = ns.Now()
    local items = {}
    for i, e in ipairs(ns.Leveling.WhoToPlay(now)) do
        local why
        if e.toCap <= 0 then
            why = "|cffff4040" .. L["at cap, rested XP is going to waste"] .. "|r"
        else
            why = format(L["caps in %s"], ns.FormatDuration(e.toCap))
            if e.toCap <= SOON then why = "|cffffd100" .. why .. "|r" end
        end
        items[#items + 1] = {
            left = format("%d. %s  %s", i, ns.ColoredName(e.c), why),
            right = e.carries and format(L["rested to %.1f"], e.carries) or "",
            tooltip = function(tip) ns.Tooltip.Fill(tip, e.c, now, false) end,
        }
    end
    return items, L["No alts that can gain rested XP yet."]
end

local function Pace()
    local items = {}
    for _, e in ipairs(Chars()) do
        local c = e.c
        if not c.isMax then
            local rate = ns.Leveling.XPPerHour(c)
            local hoursLeft = ns.Leveling.HoursToMax(c)
            items[#items + 1] = {
                left = format("%s  %s", ns.ColoredName(c), format(L["level %d"], c.level or 0)),
                right = rate and format(L["%s XP/h, %d in about %s"], ns.FormatNumber(rate), ns.db.maxLevel or 60, ns.FormatDuration(hoursLeft * 3600))
                    or (GREY .. L["needs more time online"] .. "|r"),
            }
        end
    end
    return items, L["No characters below max level yet."]
end

local function Train()
    local items = {}
    for _, e in ipairs(Chars()) do
        local names = ns.Leveling.Trainable(e.c)
        if #names > 0 then
            items[#items + 1] = {
                left = ns.ColoredName(e.c),
                right = format(L["%d spell(s)"], #names),
                tooltip = function(tip)
                    tip:AddLine(L["Spells to train"])
                    for _, n in ipairs(names) do tip:AddLine(n, 1, 1, 1) end
                end,
            }
        end
    end
    return items, L["No spells waiting at a trainer. Visit your class trainer once so the addon knows what's coming."]
end

local function Mount()
    local items = {}
    for _, e in ipairs(Chars()) do
        local have, need = ns.Leveling.MountGold(e.c)
        if have then
            local color = have >= need and "|cff40ff40" or ""
            items[#items + 1] = {
                left = format("%s  %s", ns.ColoredName(e.c), format(L["level %d"], e.c.level)),
                right = color .. ns.FormatMoney(have) .. " / " .. ns.FormatMoney(need),
            }
        end
    end
    return items, format(L["No characters close to level %d without a mount."], ns.Data.mount.level)
end

local function ListPage(id, label, order, source)
    ns.Window.AddPage({
        id = id,
        group = "leveling",
        label = label,
        order = order,
        build = function(panel) panel.list = ns.UI.TextList(panel) end,
        refresh = function(panel) panel.list:SetItems(source()) end,
    })
end

ListPage("whoplay", L["Who to play next"], 1, WhoToPlay)
ListPage("pace", L["Pace"], 2, Pace)
ListPage("train", L["Spells to train"], 3, Train)
ListPage("mount", format(L["Gold for the level %d mount"], ns.Data.mount.level), 4, Mount)
