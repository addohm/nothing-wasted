-- Nothing Wasted: the Rested tab. One bar per character with its name and time to the rested cap;
-- everything else is in the bar's tooltip.
local _, ns = ...
local L = ns.L

local ROW_HEIGHT = 26
local COLOR_FILLING = { 0.25, 0.5, 1 }
local COLOR_CAPPED = { 0.85, 0.15, 0.15 }
local COLOR_IDLE = { 0.4, 0.4, 0.4 }

local function BuildItems()
    local now, me = ns.Now(), ns.PlayerKey()
    local showMax = ns.db.settings.bars.showMax
    local items = {}
    for key, c in pairs(ns.db.chars) do
        local idle = ns.Rested.IsIdle(c)
        if not (idle and not showMax) then
            local rested, cap, toCap = ns.Rested.Estimate(c, now)
            items[#items + 1] = {
                key = key,
                c = c,
                isMe = key == me,
                idle = idle,
                fraction = cap > 0 and rested / cap or 0,
                toCap = toCap,
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

local function CreateRow(parent)
    local row = CreateFrame("Button", nil, parent)

    local bar = CreateFrame("StatusBar", nil, row)
    bar:SetPoint("TOPLEFT", 2, -2)
    bar:SetPoint("BOTTOMRIGHT", -2, 2)
    bar:SetStatusBarTexture(ns.UI.BAR_TEXTURE)
    bar:SetMinMaxValues(0, 1)
    bar:EnableMouse(false)
    row.bar = bar

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.5)

    row.name = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.name:SetPoint("LEFT", 6, 0)
    row.time = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
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

local function UpdateRow(row, item)
    local c = item.c
    row.name:SetText(ns.ColoredName(c) .. (item.isMe and (" |cff999999" .. L["(you)"] .. "|r") or ""))
    row.bar:SetValue(item.fraction)
    local color
    if item.idle then
        color = COLOR_IDLE
        row.time:SetText(c.isMax and L["Max level"] or "")
    elseif item.toCap <= 0 then
        color = COLOR_CAPPED
        row.time:SetText("|cffff4040" .. L["At cap!"] .. "|r")
    else
        color = COLOR_FILLING
        row.time:SetText(ns.FormatDuration(item.toCap))
    end
    row.bar:SetStatusBarColor(color[1], color[2], color[3])
end

ns.Window.AddTab({
    id = "rested",
    label = L["Rested"],
    order = 1,
    build = function(panel)
        panel.list = ns.UI.List(panel, ROW_HEIGHT, CreateRow, UpdateRow)
    end,
    refresh = function(panel)
        panel.list:SetItems(BuildItems(), L["Log in to each character once to add it."])
    end,
})
