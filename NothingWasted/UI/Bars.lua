-- Nothing Wasted: the rested bars, shared by the Rested tab and the small bars window.
-- One bar per character with its name and time to the rested cap; everything else is in the
-- bar's tooltip.
local _, ns = ...
local L = ns.L

local Bars = {}
ns.Bars = Bars

local COLOR_FILLING = { 0.25, 0.5, 1 }
local COLOR_CAPPED = { 0.85, 0.15, 0.15 }
local COLOR_IDLE = { 0.4, 0.4, 0.4 }

-- Every saved character, capped first, then soonest to cap, then those that can't rest. Only
-- max-level characters can be hidden (by the option); everyone else always gets a bar.
function Bars.Items()
    local now, me = ns.Now(), ns.PlayerKey()
    local showMax = ns.db.settings.bars.showMax
    local items = {}
    for key, c in pairs(ns.db.chars) do
        local idle = ns.Rested.IsIdle(c)
        if showMax or not c.isMax then
            local rested, cap, toCap = ns.Rested.Estimate(c, now)
            items[#items + 1] = {
                key = key,
                c = c,
                isMe = key == me,
                idle = idle,
                fraction = cap > 0 and rested / cap or 0,
                toCap = toCap,
                rested = rested,
                cap = cap,
            }
        end
    end
    -- Capped first (they're wasting time), then soonest to cap, then characters that can't rest.
    table.sort(items, function(a, b)
        if a.idle ~= b.idle then return not a.idle end
        if a.toCap ~= b.toCap then return a.toCap < b.toCap end
        return (a.c.name or "") < (b.c.name or "")
    end)
    return items
end

-- `font` is optional; the small bars window uses a smaller one.
function Bars.CreateRow(parent, font)
    local row = CreateFrame("Button", nil, parent)

    local bar = CreateFrame("StatusBar", nil, row)
    bar:SetPoint("TOPLEFT", 1, -1)
    bar:SetPoint("BOTTOMRIGHT", -1, 1)
    bar:SetStatusBarTexture(ns.UI.BAR_TEXTURE)
    bar:SetMinMaxValues(0, 1)
    bar:EnableMouse(false)
    row.bar = bar

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.5)

    row.name = bar:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    row.name:SetPoint("LEFT", 6, 0)
    row.time = bar:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    row.time:SetPoint("RIGHT", -6, 0)

    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row:SetScript("OnEnter", function(self)
        if self.item then ns.Tooltip.ShowCharacter(self, self.item.c, self.item.isMe) end
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    -- Right-click to forget a character.
    row:RegisterForClicks("RightButtonUp")
    row:SetScript("OnClick", function(self)
        local c = self.item and self.item.c
        if c then StaticPopup_Show("NOTHINGWASTED_FORGET", (c.name or "?") .. "-" .. (c.realm or "?"), nil, self.item.key) end
    end)
    return row
end

-- What the right-hand text of a bar can show (settings.meter.text), in the order offered.
Bars.TEXT_CHOICES = {
    { "toCap", L["Time to cap"] },
    { "rested", L["Rested XP"] },
    { "levelPct", L["Rested % of a level"] },
    { "capPct", L["Rested % of the cap"] },
    { "carries", L["Level rested XP reaches"] },
}

local function ValueText(item, mode)
    local c = item.c
    if mode == "rested" then
        return ns.FormatNumber(item.rested)
    elseif mode == "levelPct" then
        return format("%d%%", math.floor(item.rested / c.xpMax * 100 + 0.5))
    elseif mode == "capPct" then
        return format("%d%%", math.floor(item.fraction * 100 + 0.5))
    elseif mode == "carries" then
        local level = ns.Leveling.RestedCarriesTo(c, ns.Now())
        return level and format(L["to %.1f"], level) or ""
    end
    return ns.FormatDuration(item.toCap)
end

function Bars.UpdateRow(row, item)
    local c = item.c
    row.name:SetText(ns.ColoredName(c) .. (item.isMe and (" |cff999999" .. L["(you)"] .. "|r") or ""))
    row.bar:SetValue(item.fraction)
    local color
    if item.idle then
        color = COLOR_IDLE
        if c.isMax then
            row.time:SetText(L["Max level"])
        elseif c.xpDisabled then
            row.time:SetText(L["XP turned off"])
        else
            row.time:SetText(L["log in to update"])
        end
    else
        local mode = ns.db.settings.meter.text
        if item.toCap <= 0 then
            color = COLOR_CAPPED
            -- At the cap, time to cap becomes "At cap!"; the other values just turn red.
            row.time:SetText("|cffff4040" .. (mode == "toCap" and L["At cap!"] or ValueText(item, mode)) .. "|r")
        else
            color = COLOR_FILLING
            row.time:SetText(ValueText(item, mode))
        end
    end
    row.bar:SetStatusBarColor(color[1], color[2], color[3])
end
