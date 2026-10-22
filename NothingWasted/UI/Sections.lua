-- Nothing Wasted: the sections of the character tooltip. Each can be turned off in the options.
local _, ns = ...
local L = ns.L

local function Line(tip, left, right)
    tip:AddDoubleLine(left, right, 1, 0.82, 0, 1, 1, 1)
end

ns.Tooltip.AddSection({
    id = "rested",
    label = L["Rested XP and time to cap"],
    order = 10,
    add = function(tip, c, now, isMe)
        if ns.Rested.IsIdle(c) then return end
        local rested, cap, toCap = ns.Rested.Estimate(c, now)
        Line(tip, L["Rested XP"], format("%s / %s (%d%%)", ns.FormatNumber(rested), ns.FormatNumber(cap),
            math.floor(rested / c.xpMax * 100 + 0.5)))
        Line(tip, L["Time to cap"], toCap <= 0 and ("|cffff4040" .. L["At cap!"] .. "|r") or ns.FormatDuration(toCap))
        if not isMe then
            Line(tip, L["Logged out"], c.resting and L["resting (full rate)"] or ("|cffff8040" .. L["not resting (quarter rate)"] .. "|r"))
        end
        if (c.wellRested or 0) > 0 then
            Line(tip, L["Well Rested"], format(L["rank %d"], c.wellRested))
        end
        local carries = ns.Leveling.RestedCarriesTo(c, now)
        if carries then Line(tip, L["Rested XP carries to"], format(L["level %.1f"], carries)) end
    end,
})

ns.Tooltip.AddSection({
    id = "level",
    label = L["Level and XP"],
    order = 20,
    add = function(tip, c)
        local text = format(L["Level %d %s"], c.level or 0, c.className or "")
        if not c.isMax and c.xpMax and c.xpMax > 0 then
            text = text .. format("  (%d%%)", math.floor((c.xp or 0) / c.xpMax * 100))
        end
        tip:AddLine(text, 1, 1, 1)
        local hours = ns.Leveling.HoursToMax(c)
        if hours then Line(tip, format(L["Level %d in"], ns.db.maxLevel or 60), format(L["about %s played"], ns.FormatDuration(hours * 3600))) end
        if c.trainable and #c.trainable > 0 then
            Line(tip, L["Spells to train"], tostring(#c.trainable))
        end
    end,
})

ns.Tooltip.AddSection({
    id = "professions",
    label = L["Professions"],
    order = 30,
    add = function(tip, c)
        if not c.professions or #c.professions == 0 then return end
        for _, p in ipairs(c.professions) do
            local right = format("%d / %d", p.rank, p.max)
            local nextName, skill, level, stuck = ns.Professions.NextRank(p, c.level)
            if stuck then right = right .. "  |cffff8040" .. format(L["train %s"], nextName) .. "|r" end
            tip:AddDoubleLine((p.icon and ("|T" .. p.icon .. ":0|t ") or "") .. p.name, right, 1, 0.82, 0, 1, 1, 1)
        end
    end,
})

ns.Tooltip.AddSection({
    id = "cooldowns",
    label = L["Cooldowns"],
    order = 40,
    add = function(tip, c, now)
        for _, cd in ipairs(ns.Cooldowns.List(c, now)) do
            Line(tip, cd.name, cd.left <= 0 and ("|cff40ff40" .. L["Ready"] .. "|r") or ns.FormatDuration(cd.left))
        end
    end,
})

ns.Tooltip.AddSection({
    id = "legacy",
    label = L["Legacy goals"],
    order = 50,
    add = function(tip, c)
        if c.legacyPoints then
            Line(tip, L["Legacy points spent"], tostring(c.legacyPoints.spent) .. (c.legacyPoints.cap and (" / " .. c.legacyPoints.cap) or ""))
        end
        for _, g in pairs(c.legacyProgress or {}) do
            Line(tip, g.name or "?", g.req and g.req > 1 and format("%s / %s", ns.FormatNumber(g.q), ns.FormatNumber(g.req)) or "")
        end
    end,
})

ns.Tooltip.AddSection({
    id = "gold",
    label = L["Gold"],
    order = 60,
    add = function(tip, c)
        if c.money then Line(tip, L["Gold"], ns.FormatMoney(c.money)) end
        local have, need = ns.Leveling.MountGold(c)
        if have then Line(tip, format(L["Mount at %d"], ns.Data.mount.level), format("%s / %s", ns.FormatMoney(have), ns.FormatMoney(need))) end
    end,
})

ns.Tooltip.AddSection({
    id = "location",
    label = L["Where they logged out"],
    order = 70,
    add = function(tip, c, now, isMe)
        local where = c.zone or "?"
        if c.subzone and c.subzone ~= "" and c.subzone ~= c.zone then where = c.subzone .. ", " .. where end
        Line(tip, isMe and L["Location"] or L["Logged out in"], where)
        local seen = c.seenAt or c.savedAt
        if not isMe and seen then Line(tip, L["Last played"], format(L["%s ago"], ns.FormatDuration(now - seen))) end
    end,
})

ns.Tooltip.AddSection({
    id = "bind",
    label = L["Hearthstone"],
    order = 75,
    add = function(tip, c)
        if c.bind and c.bind ~= "" then Line(tip, L["Hearthstone"], c.bind) end
    end,
})

ns.Tooltip.AddSection({
    id = "played",
    label = L["Time online"],
    order = 90,
    add = function(tip, c)
        if c.online and c.online >= 60 then
            Line(tip, L["Time online (tracked)"], ns.FormatDuration(c.online))
        end
    end,
})
