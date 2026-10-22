-- Nothing Wasted: the main window and its tabs.
--
-- Tabs register themselves with Window.AddTab. It opens only when asked for; the small bars window
-- (Meter.lua) is the one that pops up in inns and cities.
local _, ns = ...
local L = ns.L

local Window = {}
ns.Window = Window

local WIDTH, HEIGHT = 560, 420
local TAB_HEIGHT = 24
local REFRESH_SECONDS = 5

local frame, ticker
local tabs, tabOrder = {}, {}
local current

-- Tabs ---------------------------------------------------------------------------------------------

-- def: { id, label, order, build(panel), refresh(panel) }
function Window.AddTab(def)
    tabs[def.id] = def
    tabOrder[#tabOrder + 1] = def
    table.sort(tabOrder, function(a, b) return a.order < b.order end)
end

local function StyleTab(button, selected)
    button.selected = selected
    button.bg:SetColorTexture(selected and 0.25 or 0.1, selected and 0.25 or 0.1, selected and 0.3 or 0.12, 0.9)
    button.text:SetTextColor(selected and 1 or 0.8, selected and 0.82 or 0.8, selected and 0 or 0.8)
end

function Window.Select(id)
    if not tabs[id] then id = "rested" end
    current = id
    ns.db.settings.window.tab = id
    for _, def in ipairs(tabOrder) do
        local selected = def.id == id
        StyleTab(def.button, selected)
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
    Window.Refresh()
end

function Window.Refresh()
    if not frame or not frame:IsShown() or not current then return end
    local def = tabs[current]
    if def and def.refresh and def.panel.built then def.refresh(def.panel) end
end

-- Frame --------------------------------------------------------------------------------------------

local function SavePosition()
    local point, _, relPoint, x, y = frame:GetPoint()
    ns.db.settings.window.pos = { point, relPoint, x, y }
end

local function Build()
    frame = CreateFrame("Frame", "NothingWastedFrame", UIParent, "BackdropTemplate")
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("HIGH")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
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

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -18)
    title:SetText("Nothing Wasted")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    -- Tab buttons in a row under the title.
    local tabWidth = (WIDTH - 40) / #tabOrder
    for i, def in ipairs(tabOrder) do
        local b = CreateFrame("Button", nil, frame)
        b:SetSize(tabWidth - 2, TAB_HEIGHT)
        b:SetPoint("TOPLEFT", 20 + (i - 1) * tabWidth, -44)
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints()
        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.text:SetPoint("CENTER")
        b.text:SetText(def.label)
        b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
        b:SetScript("OnClick", function() Window.Select(def.id) end)
        def.button = b

        local panel = CreateFrame("Frame", nil, frame)
        panel:SetPoint("TOPLEFT", 18, -44 - TAB_HEIGHT - 6)
        panel:SetPoint("BOTTOMRIGHT", -18, 16)
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

function Window.Show(tab)
    if not frame then Build() end
    frame:Show()
    if tab then Window.Select(tab) end
end

function Window.Hide()
    if frame then frame:Hide() end
end

function Window.IsShown()
    return frame and frame:IsShown()
end

function Window.Toggle(tab)
    if Window.IsShown() and (not tab or tab == current) then
        Window.Hide()
    else
        Window.Show(tab)
    end
end

ns.On("NW_REFRESH", Window.Refresh)
