-- Nothing Wasted: the full window. Tabs across the top; a tab with more than one view shows them as
-- a row of links under the tabs. Options open from the gear button in the title bar.
--
-- Pages register themselves with Window.AddPage. The window opens only when asked for; the small
-- bars window (Meter.lua) is the one that pops up in inns and cities.
local _, ns = ...
local L = ns.L

local Window = {}
ns.Window = Window

local WIDTH, HEIGHT = 620, 460
local TABS_Y = -36       -- top of the tab row
local TAB_HEIGHT = 24
local LINKS_Y = -66      -- top of the row of view links
local LINK_HEIGHT = 18
local REFRESH_SECONDS = 5
local GOLD = { 1, 0.82, 0 }
local GREY = { 0.62, 0.62, 0.62 }
local RULE = { 0.6, 0.45, 0.15, 0.6 }

-- The tabs, in order. Options isn't a tab: the gear button opens it.
local TABS = {
    { id = "rested", label = L["Rested"] },
    { id = "leveling", label = L["Leveling"] },
    { id = "cooldowns", label = L["Cooldowns"] },
    { id = "professions", label = L["Professions"] },
    { id = "items", label = L["Items"] },
    { id = "legacy", label = L["Legacy"] },
}

-- Group names open their tab; older page names still work.
local ALIASES = { characters = "rested", options = "alerts" }

local frame, ticker, content, linkBar, defaultsButton
local tabButtons = {}
local tabWidgets = {} -- list of { group, page (optional), build = function(parent), frame }
local pages, pageOrder = {}, {}
local current

-- def: { id, group, label, order, build(panel), refresh(panel), defaults() (optional) }
function Window.AddPage(def)
    pages[def.id] = def
    pageOrder[#pageOrder + 1] = def
end

-- A widget shown at the right of the view links whenever a tab is selected (the Items search box),
-- or only on one page of it when `page` is given. build(parent) returns the widget's frame.
function Window.AddTabWidget(group, build, page)
    tabWidgets[#tabWidgets + 1] = { group = group, page = page, build = build }
end

local function GroupPages(group)
    local list = {}
    for _, def in ipairs(pageOrder) do
        if def.group == group then list[#list + 1] = def end
    end
    table.sort(list, function(a, b) return a.order < b.order end)
    return list
end

function Window.PageIDs()
    local ids = {}
    local groups = {}
    for _, tab in ipairs(TABS) do groups[#groups + 1] = tab.id end
    groups[#groups + 1] = "options"
    for _, group in ipairs(groups) do
        for _, def in ipairs(GroupPages(group)) do ids[#ids + 1] = def.id end
    end
    return ids
end

-- A page ID, or a tab/group name meaning the last page used in that tab.
local function Resolve(id)
    id = ALIASES[id] or id
    if pages[id] then return id end
    local list = GroupPages(id)
    if #list == 0 then return "rested" end
    local last = ns.db.settings.window.views and ns.db.settings.window.views[id]
    if last and pages[last] and pages[last].group == id then return last end
    return list[1].id
end

-- Tabs and view links --------------------------------------------------------------------------

local function StyleLink(b, selected)
    local color = selected and GOLD or GREY
    b.text:SetTextColor(color[1], color[2], color[3])
    b.underline:SetShown(selected)
end

local function TextButton(parent, label, font, height)
    local b = CreateFrame("Button", nil, parent)
    b.text = b:CreateFontString(nil, "OVERLAY", font)
    b.text:SetPoint("CENTER", 0, 1)
    b.text:SetText(label)
    b:SetSize(math.max(40, (b.text:GetStringWidth() or 60) + 24), height)
    b.underline = b:CreateTexture(nil, "ARTWORK")
    b.underline:SetPoint("BOTTOMLEFT", 8, 0)
    b.underline:SetPoint("BOTTOMRIGHT", -8, 0)
    b.underline:SetHeight(2)
    b.underline:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.9)
    b.underline:Hide()
    b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
    return b
end

-- Rebuilds the row of view links for the selected page's tab.
local linkButtons = {}
local function ShowLinks(def)
    for _, b in ipairs(linkButtons) do b:Hide() end
    local list = GroupPages(def.group)
    local x = 0
    if #list > 1 then
        for i, page in ipairs(list) do
            local b = linkButtons[i]
            if not b then
                b = TextButton(linkBar, "", "GameFontHighlightSmall", LINK_HEIGHT)
                linkButtons[i] = b
            end
            b.text:SetText(page.label)
            b:SetSize((b.text:GetStringWidth() or 60) + 20, LINK_HEIGHT)
            b:ClearAllPoints()
            b:SetPoint("LEFT", x, 0)
            b:SetScript("OnClick", function() Window.Select(page.id) end)
            StyleLink(b, page.id == def.id)
            b:Show()
            x = x + b:GetWidth() + 4
        end
    end
    local anyWidget = false
    for _, w in ipairs(tabWidgets) do
        local show = w.group == def.group and (not w.page or w.page == def.id)
        if show and not w.frame then
            w.frame = w.build(linkBar)
            w.frame:SetPoint("RIGHT", -2, 0)
        end
        if w.frame then w.frame:SetShown(show) end
        anyWidget = anyWidget or show
    end
    linkBar:SetShown(#list > 1 or def.defaults ~= nil or anyWidget)
    defaultsButton:SetShown(def.defaults ~= nil)
    content:ClearAllPoints()
    content:SetPoint("TOPLEFT", 14, linkBar:IsShown() and (LINKS_Y - LINK_HEIGHT - 8) or (TABS_Y - TAB_HEIGHT - 10))
    content:SetPoint("BOTTOMRIGHT", -14, 14)
end

-- Pages ------------------------------------------------------------------------------------------

function Window.Select(id)
    id = Resolve(id)
    current = id
    local def = pages[id]
    local settings = ns.db.settings.window
    settings.tab = id
    settings.views = settings.views or {}
    settings.views[def.group] = id
    for _, tab in ipairs(TABS) do
        if tabButtons[tab.id] then StyleLink(tabButtons[tab.id], tab.id == def.group) end
    end
    for _, page in ipairs(pageOrder) do
        if page.panel then
            if page.id == id then
                if not page.panel.built then
                    page.build(page.panel)
                    page.panel.built = true
                end
                page.panel:Show()
            else
                page.panel:Hide()
            end
        end
    end
    ShowLinks(def)
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

-- Frame ----------------------------------------------------------------------------------------

local function SavePosition()
    local point, _, relPoint, x, y = frame:GetPoint()
    ns.db.settings.window.pos = { point, relPoint, x, y }
end

local function Rule(y)
    local t = frame:CreateTexture(nil, "BORDER")
    t:SetPoint("TOPLEFT", 12, y)
    t:SetPoint("TOPRIGHT", -12, y)
    t:SetHeight(1)
    t:SetColorTexture(RULE[1], RULE[2], RULE[3], RULE[4])
    return t
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
    frame:SetBackdropColor(0.05, 0.06, 0.09, 0.94)
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

    -- Title bar: name, gear (options) and close.
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 16, -12)
    title:SetText("Nothing Wasted")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    local gear = CreateFrame("Button", nil, frame)
    gear:SetSize(18, 18)
    gear:SetPoint("RIGHT", close, "LEFT", -2, 0)
    local icon = gear:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\Icons\\Trade_Engineering")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    gear:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    gear:SetScript("OnClick", function() Window.Select("options") end)
    gear:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["Options"])
        GameTooltip:Show()
    end)
    gear:SetScript("OnLeave", GameTooltip_Hide)

    -- Tabs
    local x = 12
    for _, tab in ipairs(TABS) do
        if #GroupPages(tab.id) > 0 then
            local b = TextButton(frame, tab.label, "GameFontNormal", TAB_HEIGHT)
            b:SetPoint("TOPLEFT", x, TABS_Y)
            b:SetScript("OnClick", function() Window.Select(tab.id) end)
            tabButtons[tab.id] = b
            x = x + b:GetWidth() + 2
        end
    end
    Rule(TABS_Y - TAB_HEIGHT - 2)

    -- View links (and the Defaults button on options pages).
    linkBar = CreateFrame("Frame", nil, frame)
    linkBar:SetPoint("TOPLEFT", 14, LINKS_Y)
    linkBar:SetPoint("TOPRIGHT", -14, LINKS_Y)
    linkBar:SetHeight(LINK_HEIGHT)
    defaultsButton = CreateFrame("Button", nil, linkBar, "UIPanelButtonTemplate")
    defaultsButton:SetSize(90, 20)
    defaultsButton:SetPoint("RIGHT")
    defaultsButton:SetText(L["Defaults"])
    defaultsButton:SetScript("OnClick", function()
        local def = pages[current]
        if def and def.defaults then
            def.defaults()
            ns.Fire("NW_REFRESH")
        end
    end)

    content = CreateFrame("Frame", nil, frame)
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
    if Window.IsShown() and (not page or Resolve(page) == current) then
        Window.Hide()
    else
        Window.Show(page)
    end
end

ns.On("NW_REFRESH", Window.Refresh)
