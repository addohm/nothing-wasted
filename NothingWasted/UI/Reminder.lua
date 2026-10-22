-- Nothing Wasted: the reminder card. When you leave an inn or city with a leveling buff missing, it
-- takes the place of the bars window: one row per missing buff, with its icon, under a softly
-- pulsing gold border. A row goes away when you get that buff; the card hides when none are left,
-- when you close it, or when you're back in a rested area.
local _, ns = ...
local L = ns.L

local Reminder = {}
ns.Reminder = Reminder

local WIDTH = 220
local TITLE_HEIGHT = 18
local ROW_HEIGHT = 34
local GOLD = { 1, 0.82, 0 }

local frame, border, pulse
local rows = {}
local shown = {} -- list of row definitions currently on the card

local function SpellIcon(spellID)
    local info = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
    return info and info.iconID or "Interface\\Icons\\INV_Misc_Food_15"
end

local function ItemIcon(itemID)
    return C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID) or "Interface\\Icons\\INV_Misc_Bag_08"
end

-- The kinds of row the card can show.
local KINDS = {
    wellFed = function()
        return { icon = SpellIcon(ns.Data.wellFedXPSpellID), title = L["Not Well Fed"],
            text = L["Eat cooked food: +5% XP from kills"] }
    end,
    bag = function()
        return { icon = ItemIcon(ns.Data.sleepingBag.itemID), title = L["Sleeping bag ready"],
            text = L["Rest in it: up to +3% XP"] }
    end,
    bagLogout = function()
        return { icon = ItemIcon(ns.Data.sleepingBag.itemID), title = L["Sleeping bag ready"],
            text = L["Rest in it before logging out"] }
    end,
}

local function Build()
    frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(WIDTH, TITLE_HEIGHT + ROW_HEIGHT)
    frame:SetFrameStrata("MEDIUM")
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.05, 0.05, 0.08, 0.9)
    frame:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 1)
    frame:Hide()

    -- A gold glow around the edge that pulses gently, to stand out without getting in the way.
    border = frame:CreateTexture(nil, "BACKGROUND")
    border:SetPoint("TOPLEFT", -6, 6)
    border:SetPoint("BOTTOMRIGHT", 6, -6)
    border:SetTexture("Interface\\Buttons\\WHITE8X8")
    border:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.35)
    pulse = frame:CreateAnimationGroup()
    local a = pulse:CreateAnimation("Alpha")
    a:SetFromAlpha(1)
    a:SetToAlpha(0.35)
    a:SetDuration(0.9)
    pulse:SetLooping("BOUNCE")

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", 8, -5)
    title:SetText("Nothing Wasted")

    local close = CreateFrame("Button", nil, frame)
    close:SetSize(TITLE_HEIGHT, TITLE_HEIGHT)
    close:SetPoint("TOPRIGHT", -2, -2)
    local x = close:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    x:SetPoint("CENTER")
    x:SetText("x")
    close:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
    close:SetScript("OnClick", function() Reminder.Hide() end)
end

-- Places the card where the bars window is (or would be).
local function Place()
    frame:ClearAllPoints()
    local meter = ns.Meter.GetFrame()
    frame:SetPoint("TOPLEFT", meter, "TOPLEFT", 0, 0)
end

local function Layout()
    for i, kind in ipairs(shown) do
        local row = rows[i]
        if not row then
            row = CreateFrame("Frame", nil, frame)
            row:SetSize(WIDTH - 12, ROW_HEIGHT)
            row:SetPoint("TOPLEFT", 6, -(TITLE_HEIGHT + (i - 1) * ROW_HEIGHT))
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(26, 26)
            row.icon:SetPoint("LEFT", 2, 0)
            row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.title:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, 1)
            row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.text:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 8, -1)
            rows[i] = row
        end
        local def = KINDS[kind]()
        row.kind = kind
        row.icon:SetTexture(def.icon)
        row.title:SetText(def.title)
        row.text:SetText(def.text)
        row:Show()
    end
    for i = #shown + 1, #rows do
        rows[i].kind = nil
        rows[i]:Hide()
    end
    frame:SetHeight(TITLE_HEIGHT + #shown * ROW_HEIGHT + 6)
end

-- Shows the card with these kinds of row ("wellFed", "bag", "bagLogout").
function Reminder.Show(kinds)
    if #kinds == 0 then return end
    if not frame then Build() end
    shown = {}
    for _, k in ipairs(kinds) do shown[#shown + 1] = k end
    Place()
    Layout()
    frame:Show()
    pulse:Play()
end

-- Keeps only the rows still missing; hides the card when none are left.
function Reminder.Keep(stillMissing)
    if not frame or not frame:IsShown() then return end
    local keep = {}
    for _, k in ipairs(shown) do
        if stillMissing[k] then keep[#keep + 1] = k end
    end
    if #keep == 0 then
        Reminder.Hide()
    elseif #keep ~= #shown then
        shown = keep
        Layout()
    end
end

function Reminder.Hide()
    shown = {}
    if frame then
        pulse:Stop()
        frame:Hide()
    end
end

function Reminder.IsShown()
    return frame and frame:IsShown() or false
end

-- The kinds of row on the card now (for the tests).
function Reminder.Kinds()
    return shown
end
