-- Nothing Wasted: the full window, laid out like the game's Settings: a sidebar of sections and
-- pages on the left, the selected page on the right.
--
-- Pages register themselves with Window.AddPage. The window opens only when asked for; the small
-- bars window (Meter.lua) is the one that pops up in inns and cities.
local _, ns = ...
local L = ns.L

local Window = {}
ns.Window = Window

local WIDTH, HEIGHT = 780, 580
local NAV_WIDTH = 210
local HEADER_HEIGHT = 26
local ITEM_HEIGHT = 20
local REFRESH_SECONDS = 5
local GOLD = { 1, 0.82, 0 }

local GROUPS = {
    { id = "characters", label = L["Characters"] },
    { id = "professions", label = L["Professions"] },
    { id = "items", label = L["Mail and items"] },
    { id = "legacy", label = L["Legacy"] },
    { id = "options", label = L["Options"] },
}

-- Older names for pages, still used by slash commands and buttons.
local ALIASES = {
    options = "alerts", items = "search", legacy = "goals", leveling = "whoplay", professions = "skills",
}

local frame, ticker, title, defaultsButton, content
local pages, pageOrder = {}, {}
local current

-- def: { id, group, label, order, title (optional), build(panel), refresh(panel), defaults() (optional) }
function Window.AddPage(def)
    pages[def.id] = def
    pageOrder[#pageOrder + 1] = def
end

function Window.PageIDs()
    local ids = {}
    for _, group in ipairs(GROUPS) do
        for _, def in ipairs(pageOrder) do
            if def.group == group.id then ids[#ids + 1] = def.id end
        end
    end
    return ids
end

local function GroupPages(groupID)
    local list = {}
    for _, def in ipairs(pageOrder) do
        if def.group == groupID then list[#list + 1] = def end
    end
    table.sort(list, function(a, b) return a.order < b.order end)
    return list
end

-- Pages -------------------------------------------------------------------------------------------

function Window.Select(id)
    id = ALIASES[id] or id
    if not pages[id] then id = "rested" end
    current = id
    ns.db.settings.window.tab = id
    for _, def in ipairs(pageOrder) do
        local selected = def.id == id
        if def.navButton then def.navButton.selected:SetShown(selected) end
        if def.panel then
            if selected then
                if not def.panel.built then
                    def.build(def.panel)
                    def.panel.built = true
                end
                def.panel:Show()
            else
                def.panel:Hide()
            end
        end
    end
    local def = pages[id]
    title:SetText(def.title or def.label)
    defaultsButton:SetShown(def.defaults ~= nil)
    Window.Refresh()
end

function Window.Refresh()
    if not frame or not frame:IsShown() or not current then return end
    local def = pages[current]
    if def and def.refresh and def.panel.built then def.refresh(def.panel) end
end

-- The panel of the page being shown (used by the tests).
function Window.CurrentPanel()
    return current and pages[current] and pages[current].panel
end

-- Frame --------------------------------------------------------------------------------------------

local function SavePosition()
    local point, _, relPoint, x, y = frame:GetPoint()
    ns.db.settings.window.pos = { point, relPoint, x, y }
end

local function NavHeader(parent, text, y)
    local h = CreateFrame("Frame", nil, parent)
    h:SetPoint("TOPLEFT", 0, -y)
    h:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    h:SetHeight(HEADER_HEIGHT)
    local bg = h:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.12, 0.09, 0.05, 0.95)
    local top = h:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")
    top:SetHeight(1)
    top:SetColorTexture(0.6, 0.45, 0.15, 0.9)
    local bottom = h:CreateTexture(nil, "BORDER")
    bottom:SetPoint("BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT")
    bottom:SetHeight(1)
    bottom:SetColorTexture(0.6, 0.45, 0.15, 0.9)
    local fs = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    fs:SetPoint("LEFT", 12, 0)
    fs:SetText(text)
    return h
end

local function NavItem(parent, def, y)
    local b = CreateFrame("Button", nil, parent)
    b:SetPoint("TOPLEFT", 0, -y)
    b:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    b:SetHeight(ITEM_HEIGHT)
    -- The selected page gets a gold band fading out to the right, like the game's Settings.
    local selected = b:CreateTexture(nil, "BACKGROUND")
    selected:SetAllPoints()
    selected:SetTexture(ns.UI.WHITE)
    selected:SetGradient("HORIZONTAL", CreateColor(1, 0.82, 0, 0.35), CreateColor(1, 0.82, 0, 0))
    selected:Hide()
    b.selected = selected
    b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("LEFT", 28, 0)
    fs:SetText(def.label)
    b:SetScript("OnClick", function() Window.Select(def.id) end)
    return b
end

local function Build()
    frame = CreateFrame("Frame", "NothingWastedFrame", UIParent, "BackdropTemplate")
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("HIGH")
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.05, 0.06, 0.09, 0.92)
    frame:SetBackdropBorderColor(0.6, 0.45, 0.15, 1)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)
    local pos = ns.db.settings.window.pos
    if pos then
        frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        frame:SetPoint("CENTER")
    end
    frame:Hide()
    tinsert(UISpecialFrames, "NothingWastedFrame") -- Escape closes the window

    -- Sidebar
    local nav = CreateFrame("Frame", nil, frame)
    nav:SetPoint("TOPLEFT", 6, -6)
    nav:SetPoint("BOTTOMLEFT", 6, 6)
    nav:SetWidth(NAV_WIDTH)
    local divider = frame:CreateTexture(nil, "BORDER")
    divider:SetPoint("TOPLEFT", nav, "TOPRIGHT", 2, 0)
    divider:SetPoint("BOTTOMLEFT", nav, "BOTTOMRIGHT", 2, 0)
    divider:SetWidth(1)
    divider:SetColorTexture(0.6, 0.45, 0.15, 0.6)

    local y = 0
    for _, group in ipairs(GROUPS) do
        local list = GroupPages(group.id)
        if #list > 0 then
            NavHeader(nav, group.label, y)
            y = y + HEADER_HEIGHT + 4
            for _, def in ipairs(list) do
                def.navButton = NavItem(nav, def, y)
                y = y + ITEM_HEIGHT
            end
            y = y + 10
        end
    end

    -- Content
    title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
    title:SetPoint("TOPLEFT", nav, "TOPRIGHT", 24, -10)

    defaultsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    defaultsButton:SetSize(110, 24)
    defaultsButton:SetPoint("TOPRIGHT", -16, -12)
    defaultsButton:SetText(L["Defaults"])
    defaultsButton:SetScript("OnClick", function()
        local def = pages[current]
        if def and def.defaults then
            def.defaults()
            ns.Fire("NW_REFRESH")
        end
    end)

    local rule = frame:CreateTexture(nil, "BORDER")
    rule:SetPoint("TOPLEFT", nav, "TOPRIGHT", 16, -44)
    rule:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
    rule:SetHeight(1)
    rule:SetColorTexture(0.6, 0.45, 0.15, 0.6)

    local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    close:SetSize(110, 24)
    close:SetPoint("BOTTOMRIGHT", -12, 10)
    close:SetText(CLOSE or L["Close"])
    close:SetScript("OnClick", function() frame:Hide() end)

    content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", nav, "TOPRIGHT", 16, -54)
    content:SetPoint("BOTTOMRIGHT", -16, 42)

    for _, def in ipairs(pageOrder) do
        local panel = CreateFrame("Frame", nil, content)
        panel:SetAllPoints()
        panel:Hide()
        def.panel = panel
    end

    frame:SetScript("OnShow", function()
        Window.Select(current or ns.db.settings.window.tab)
        if not ticker then ticker = C_Timer.NewTicker(REFRESH_SECONDS, Window.Refresh) end
    end)
    frame:SetScript("OnHide", function()
        if ticker then
            ticker:Cancel()
            ticker = nil
        end
    end)
end

function Window.Show(page)
    if not frame then Build() end
    frame:Show()
    if page then Window.Select(page) end
end

function Window.Hide()
    if frame then frame:Hide() end
end

function Window.IsShown()
    return frame and frame:IsShown()
end

function Window.Toggle(page)
    local target = page and (ALIASES[page] or page)
    if Window.IsShown() and (not target or target == current) then
        Window.Hide()
    else
        Window.Show(page)
    end
end

ns.On("NW_REFRESH", Window.Refresh)
