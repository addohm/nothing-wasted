-- Rested Alts: the roster window.
local _, ns = ...

local WIDTH, HEIGHT = 380, 360
local LIST_WIDTH = WIDTH - 42 -- room for the scroll bar
local ROW_HEIGHT = 36
local BAR_WIDTH = 120
local REFRESH_SECONDS = 10

local WHITE = "Interface\\Buttons\\WHITE8X8"
local REST_ICON = "Interface\\CharacterFrame\\UI-StateIcon"
local COLOR_FILLING = { 0.25, 0.5, 1 }
local COLOR_FULL = { 0.2, 0.8, 0.4 }

local SORT_ORDER = { "rested", "level", "name", "seen" }
local SORT_LABELS = { rested = "Rested", level = "Level", name = "Name", seen = "Last seen" }

local function ByName(a, b)
    if a.c.name ~= b.c.name then return a.c.name < b.c.name end
    return (a.c.realm or "") < (b.c.realm or "")
end

local SORTS = {
    rested = function(a, b)
        if a.c.isMax ~= b.c.isMax then return not a.c.isMax end
        if a.pct ~= b.pct then return a.pct > b.pct end
        return ByName(a, b)
    end,
    level = function(a, b)
        if a.c.level ~= b.c.level then return a.c.level > b.c.level end
        return ByName(a, b)
    end,
    name = ByName,
    seen = function(a, b)
        if a.current ~= b.current then return a.current end
        if a.c.savedAt ~= b.c.savedAt then return a.c.savedAt > b.c.savedAt end
        return ByName(a, b)
    end,
}

local frame, content, emptyText, summaryText, sortButton, ticker
local rows = {}

local function ClassColor(c)
    local color = c.class and RAID_CLASS_COLORS[c.class]
    if color then return color.r, color.g, color.b end
    return 1, 1, 1
end

local function BuildList()
    local settings = ns.db.settings
    local realm, me, now = GetRealmName(), ns.PlayerKey(), time()
    local list, total, full = {}, 0, 0
    for key, c in pairs(ns.db.chars) do
        total = total + 1
        local rested, cap, toFull = ns.Estimate(c, now)
        if not c.isMax and rested >= cap then full = full + 1 end
        if (not settings.thisRealmOnly or c.realm == realm) and not (settings.hideMaxLevel and c.isMax) then
            list[#list + 1] = {
                key = key,
                c = c,
                current = key == me,
                rested = rested,
                cap = cap,
                toFull = toFull,
                pct = c.isMax and 0 or rested / c.xpMax * 100,
                now = now,
            }
        end
    end
    table.sort(list, SORTS[settings.sort] or SORTS.rested)
    return list, total, full
end

local function ShowRowTooltip(row)
    local e = row.entry
    local c = e.c
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:AddLine(c.name, ClassColor(c))
    GameTooltip:AddLine(format("Level %d%s - %s", c.level, c.className and (" " .. c.className) or "", c.realm or "?"), 1, 1, 1)

    if c.isMax then
        GameTooltip:AddLine("Max level: no rested XP to earn.", 0.7, 0.7, 0.7)
    else
        GameTooltip:AddDoubleLine("XP", format("%s / %s (%.0f%%)",
            ns.FormatNumber(c.xp), ns.FormatNumber(c.xpMax), c.xp / c.xpMax * 100), nil, nil, nil, 1, 1, 1)
        GameTooltip:AddDoubleLine("Rested", format("%s (%.0f%% of a level)",
            ns.FormatNumber(e.rested), e.pct), nil, nil, nil, 1, 1, 1)
        GameTooltip:AddDoubleLine("Rested cap", format("%s (%.0f%%)",
            ns.FormatNumber(e.cap), ns.MAX_RESTED_LEVELS * 100), nil, nil, nil, 1, 1, 1)
        if e.toFull > 0 then
            GameTooltip:AddDoubleLine("Full in", ns.FormatDuration(e.toFull), nil, nil, nil, 1, 1, 1)
        end
        GameTooltip:AddLine(c.resting
            and "Resting (inn or city): full rate."
            or "Not resting: earns at a quarter of the inn rate.", 0.7, 0.7, 0.7, true)
        if not e.current then
            GameTooltip:AddLine("Estimated from when this character was last played.", 0.7, 0.7, 0.7, true)
        end
    end

    if e.current then
        GameTooltip:AddDoubleLine("Last seen", "playing now", nil, nil, nil, 0.4, 1, 0.4)
    else
        local seen = ns.FormatDuration(e.now - c.savedAt) .. " ago"
        if c.zone and c.zone ~= "" then seen = seen .. " in " .. c.zone end
        GameTooltip:AddDoubleLine("Last seen", seen, nil, nil, nil, 1, 1, 1)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Right-click to forget this character.", 0.5, 0.5, 0.5)
    GameTooltip:Show()
end

local function CreateRow(index)
    local row = CreateFrame("Button", nil, content)
    row:SetSize(LIST_WIDTH, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    row:RegisterForClicks("RightButtonUp")

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetTexture(WHITE)

    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture(WHITE)
    highlight:SetVertexColor(1, 1, 1, 0.08)

    row.name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    row.name:SetPoint("TOPLEFT", 8, -5)
    row.name:SetJustifyH("LEFT")

    row.info = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    row.info:SetPoint("BOTTOMLEFT", 8, 5)
    row.info:SetJustifyH("LEFT")

    row.bar = CreateFrame("StatusBar", nil, row)
    row.bar:SetSize(BAR_WIDTH, 12)
    row.bar:SetPoint("TOPRIGHT", -8, -5)
    row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    row.bar:SetMinMaxValues(0, ns.MAX_RESTED_LEVELS * 100)

    local barBg = row.bar:CreateTexture(nil, "BACKGROUND")
    barBg:SetAllPoints()
    barBg:SetTexture(WHITE)
    barBg:SetVertexColor(0, 0, 0, 0.5)

    -- Marks one full level of rested XP on the bar.
    local tick = row.bar:CreateTexture(nil, "OVERLAY")
    tick:SetTexture(WHITE)
    tick:SetVertexColor(1, 1, 1, 0.35)
    tick:SetSize(1, 12)
    tick:SetPoint("LEFT", BAR_WIDTH / ns.MAX_RESTED_LEVELS, 0)

    row.barText = row.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.barText:SetPoint("CENTER", 0, 1)

    row.status = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    row.status:SetPoint("BOTTOMRIGHT", -8, 5)
    row.status:SetJustifyH("RIGHT")

    row.restIcon = row:CreateTexture(nil, "ARTWORK")
    row.restIcon:SetSize(18, 18)
    row.restIcon:SetPoint("RIGHT", row.bar, "LEFT", -6, -6)
    row.restIcon:SetTexture(REST_ICON)
    row.restIcon:SetTexCoord(0, 0.5, 0, 0.421875)

    row:SetScript("OnEnter", ShowRowTooltip)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnClick", function(self)
        local c = self.entry.c
        StaticPopup_Show("RESTEDALTS_FORGET", c.name .. "-" .. (c.realm or "?"), nil, self.entry.key)
    end)

    rows[index] = row
    return row
end

local function UpdateRow(row, index, e)
    local c = e.c
    row.entry = e
    row.bg:SetVertexColor(1, 1, 1, e.current and 0.07 or (index % 2 == 0 and 0.03 or 0))

    row.name:SetText(c.name)
    row.name:SetTextColor(ClassColor(c))

    local info = "Level " .. c.level
    if c.realm ~= GetRealmName() then info = info .. "  |  " .. (c.realm or "?") end
    if e.current then
        info = info .. "  |  |cff66ff66online|r"
    else
        info = info .. "  |  " .. ns.FormatDuration(e.now - c.savedAt) .. " ago"
    end
    row.info:SetText(info)

    if c.isMax then
        row.bar:Hide()
        row.restIcon:Hide()
        row.status:SetText("Max level")
    else
        local full = e.rested >= e.cap
        local color = full and COLOR_FULL or COLOR_FILLING
        row.bar:Show()
        row.bar:SetValue(e.pct)
        row.bar:SetStatusBarColor(color[1], color[2], color[3])
        row.barText:SetFormattedText("%.0f%%", e.pct)
        row.restIcon:SetShown(c.resting)
        row.status:SetText(full and "|cff33cc66Fully rested|r" or ("full in " .. ns.FormatDuration(e.toFull)))
    end
    row:Show()
end

function ns.RefreshUI()
    if not frame or not frame:IsShown() then return end
    ns.SaveCurrent()

    local list, total, full = BuildList()
    for i, e in ipairs(list) do
        UpdateRow(rows[i] or CreateRow(i), i, e)
    end
    for i = #list + 1, #rows do rows[i]:Hide() end
    content:SetHeight(math.max(1, #list * ROW_HEIGHT))

    emptyText:SetShown(#list == 0)
    sortButton:SetText("Sort: " .. SORT_LABELS[ns.db.settings.sort])
    summaryText:SetText(format("%d character%s  |  %d fully rested", total, total == 1 and "" or "s", full))

    -- Keep the tooltip's numbers live while hovering.
    local owner = GameTooltip:GetOwner()
    if owner and owner.entry and owner:IsShown() and owner:IsMouseOver() then ShowRowTooltip(owner) end
end

local function CreateCheckbox(label, settingKey, anchor, x)
    local check = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    check:SetSize(24, 24)
    check:SetPoint("LEFT", anchor, "RIGHT", x, 0)
    check:SetChecked(ns.db.settings[settingKey])
    check:SetScript("OnClick", function(self)
        ns.db.settings[settingKey] = self:GetChecked() and true or false
        ns.RefreshUI()
    end)

    local text = check:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    text:SetPoint("LEFT", check, "RIGHT", 0, 1)
    text:SetText(label)
    return check, text
end

local function SavePosition()
    local point, _, relPoint, x, y = frame:GetPoint()
    ns.db.settings.window = { point = point, relPoint = relPoint, x = x, y = y }
end

function ns.InitUI()
    frame = CreateFrame("Frame", "RestedAltsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)
    frame:SetBackdrop({
        bgFile = WHITE,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.06, 0.06, 0.08, 0.94)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.45)
    frame:Hide()

    local pos = ns.db.settings.window
    if pos then
        frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        frame:SetPoint("CENTER")
    end
    tinsert(UISpecialFrames, "RestedAltsFrame") -- Escape closes the window

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("Rested Alts")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    sortButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    sortButton:SetSize(116, 22)
    sortButton:SetPoint("TOPLEFT", 12, -38)
    sortButton:SetScript("OnClick", function()
        local settings = ns.db.settings
        for i, key in ipairs(SORT_ORDER) do
            if key == settings.sort then
                settings.sort = SORT_ORDER[i % #SORT_ORDER + 1]
                break
            end
        end
        if not SORT_LABELS[settings.sort] then settings.sort = SORT_ORDER[1] end
        ns.RefreshUI()
    end)

    local _, realmLabel = CreateCheckbox("This realm", "thisRealmOnly", sortButton, 10)
    CreateCheckbox("Hide max level", "hideMaxLevel", realmLabel, 8)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -68)
    scroll:SetPoint("BOTTOMRIGHT", -32, 30)

    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(LIST_WIDTH, 1)
    scroll:SetScrollChild(content)

    emptyText = frame:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    emptyText:SetPoint("CENTER", scroll, "CENTER")
    emptyText:SetText("No characters match these filters.")

    summaryText = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    summaryText:SetPoint("BOTTOMLEFT", 14, 11)

    local hint = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMRIGHT", -14, 11)
    hint:SetText("Hover for details")

    frame:SetScript("OnShow", function()
        ns.RefreshUI()
        ticker = C_Timer.NewTicker(REFRESH_SECONDS, ns.RefreshUI)
    end)
    frame:SetScript("OnHide", function()
        if ticker then ticker:Cancel() end
        ticker = nil
    end)
end

function ns.ToggleUI()
    frame:SetShown(not frame:IsShown())
end
