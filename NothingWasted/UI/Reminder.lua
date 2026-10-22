-- Nothing Wasted: the reminder card. When you leave an inn or city with a leveling buff missing, it
-- takes the place of the bars window and looks just like it, except its bars are yellow and flash:
-- one per missing buff, with its icon. A bar goes away when you get that buff; the card hides when
-- none are left, when you close it, or when you're back in a rested area.
local _, ns = ...
local L = ns.L

local Reminder = {}
ns.Reminder = Reminder

-- Same size and look as the bars window (Meter.lua), with the bars filled yellow and flashing.
local WIDTH = 220
local TITLE_HEIGHT = 18
local ROW_HEIGHT = 16
local YELLOW = { 1, 0.82, 0 }
local DARK = { 0.12, 0.09, 0 }

local frame
local rows = {}
local shown = {} -- list of row kinds currently on the card

local function SpellIcon(spellID)
    local info = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
    return info and info.iconID or "Interface\\Icons\\INV_Misc_Food_15"
end

local function ItemIcon(itemID)
    return C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID) or "Interface\\Icons\\INV_Misc_Bag_08"
end

-- The kinds of row the card can show: icon, name, the bonus on the right, and a hint on hover.
local KINDS = {
    wellFed = function()
        return { icon = SpellIcon(ns.Data.wellFedXPSpellID), name = L["Not Well Fed"],
            bonus = L["+5% kill XP"], hint = L["Eat cooked food: Well Fed gives +5% XP from kills."] }
    end,
    bag = function()
        return { icon = ItemIcon(ns.Data.sleepingBag.itemID), name = L["Sleeping bag ready"],
            bonus = L["+3% XP"], hint = L["Rest in your Cozy Sleeping Bag for up to +3% XP."] }
    end,
    bagLogout = function()
        return { icon = ItemIcon(ns.Data.sleepingBag.itemID), name = L["Use your sleeping bag"],
            bonus = L["+3% XP"], hint = L["Rest in your Cozy Sleeping Bag before logging out to keep up to +3% XP for your next session."] }
    end,
}

local function Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(WIDTH, TITLE_HEIGHT + ROW_HEIGHT + 2)
    frame:SetFrameStrata("MEDIUM")
    frame:Hide()

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.55)

    local titleBg = frame:CreateTexture(nil, "BORDER")
    titleBg:SetPoint("TOPLEFT")
    titleBg:SetPoint("TOPRIGHT")
    titleBg:SetHeight(TITLE_HEIGHT)
    titleBg:SetColorTexture(0.1, 0.1, 0.15, 0.9)
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", 6, -3)
    title:SetText("Nothing Wasted")

    local close = CreateFrame("Button", nil, frame)
    close:SetSize(TITLE_HEIGHT, TITLE_HEIGHT)
    close:SetPoint("TOPRIGHT")
    local x = close:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    x:SetPoint("CENTER")
    x:SetText("x")
    close:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
    close:SetScript("OnClick", function() Reminder.Hide() end)
end

-- Places the card where the bars window is (or would be).
local function Place()
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", ns.Meter.GetFrame(), "TOPLEFT", 0, 0)
end

local function CreateRow(i)
    local row = CreateFrame("Button", nil, frame)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 2, -(TITLE_HEIGHT + (i - 1) * ROW_HEIGHT))
    row:SetPoint("RIGHT", frame, "RIGHT", -2, 0)

    local bar = CreateFrame("StatusBar", nil, row)
    bar:SetPoint("TOPLEFT", 1, -1)
    bar:SetPoint("BOTTOMRIGHT", -1, 1)
    bar:SetStatusBarTexture(ns.UI.BAR_TEXTURE)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    bar:SetStatusBarColor(YELLOW[1], YELLOW[2], YELLOW[3])
    bar:EnableMouse(false)
    row.bar = bar

    -- The flashing: the yellow bar pulses between bright and dim.
    row.flash = bar:CreateAnimationGroup()
    local a = row.flash:CreateAnimation("Alpha")
    a:SetFromAlpha(1)
    a:SetToAlpha(0.45)
    a:SetDuration(0.6)
    row.flash:SetLooping("BOUNCE")

    row.icon = bar:CreateTexture(nil, "OVERLAY")
    row.icon:SetSize(ROW_HEIGHT - 4, ROW_HEIGHT - 4)
    row.icon:SetPoint("LEFT", 3, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.name = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.name:SetTextColor(DARK[1], DARK[2], DARK[3])
    row.bonus = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.bonus:SetPoint("RIGHT", -6, 0)
    row.bonus:SetTextColor(DARK[1], DARK[2], DARK[3])

    row:SetScript("OnEnter", function(self)
        if not self.hint then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(self.hint, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    return row
end

local function Layout()
    for i, kind in ipairs(shown) do
        local row = rows[i] or CreateRow(i)
        rows[i] = row
        local def = KINDS[kind]()
        row.kind = kind
        row.hint = def.hint
        row.icon:SetTexture(def.icon)
        row.name:SetText(def.name)
        row.bonus:SetText(def.bonus)
        row:Show()
        -- Restart every row's flash together, so they pulse in step.
        row.flash:Stop()
        row.flash:Play()
    end
    for i = #shown + 1, #rows do
        rows[i].kind = nil
        rows[i].flash:Stop()
        rows[i]:Hide()
    end
    frame:SetHeight(TITLE_HEIGHT + #shown * ROW_HEIGHT + 2)
end

-- Shows the card with these kinds of row ("wellFed", "bag", "bagLogout").
function Reminder.Show(kinds)
    if #kinds == 0 then return end
    if not frame then Build() end
    shown = {}
    for _, k in ipairs(kinds) do shown[#shown + 1] = k end
    Place()
    frame:Show()
    Layout()
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
        for _, row in ipairs(rows) do row.flash:Stop() end
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
