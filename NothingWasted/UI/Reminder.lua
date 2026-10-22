-- Nothing Wasted: the buff reminder. When you leave an inn or city with a leveling buff missing, the
-- missing buffs' icons appear where the bars window was, large, with a pulsing yellow glow and a
-- small label under each. Hover one for the details; right-click to dismiss. An icon goes away when
-- you get that buff; they all go when none are left or when you're back in a rested area.
local _, ns = ...
local L = ns.L

local Reminder = {}
ns.Reminder = Reminder

local SIZE = 38       -- icon size
local GAP = 14        -- space between one icon's label and the next
local LABEL_SPACE = 16 -- room under the icons for their labels
local YELLOW = { 1, 0.82, 0 }
local GLOW = "Interface\\Buttons\\UI-ActionButton-Border" -- the game's yellow button highlight

local frame
local buttons = {}
local shown = {} -- the kinds currently shown

local function SpellIcon(spellID)
    local info = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
    return info and info.iconID or "Interface\\Icons\\INV_Misc_Food_15"
end

local function ItemIcon(itemID)
    return C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID) or "Interface\\Icons\\INV_Misc_Bag_08"
end

-- The kinds of reminder: icon, short label, and the details shown on hover.
local KINDS = {
    wellFed = function()
        return { icon = SpellIcon(ns.Data.wellFedXPSpellID), label = L["Well Fed"],
            title = L["Not Well Fed"], hint = L["Eat cooked food: Well Fed gives +5% XP from kills."] }
    end,
    bag = function()
        return { icon = ItemIcon(ns.Data.sleepingBag.itemID), label = L["Sleeping bag"],
            title = L["Sleeping bag ready"], hint = L["Rest in your Cozy Sleeping Bag for up to +3% XP."] }
    end,
    bagLogout = function()
        return { icon = ItemIcon(ns.Data.sleepingBag.itemID), label = L["Sleeping bag"],
            title = L["Use your sleeping bag"], hint = L["Rest in your Cozy Sleeping Bag before logging out to keep up to +3% XP for your next session."] }
    end,
}

local function Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(SIZE, SIZE + LABEL_SPACE)
    frame:SetFrameStrata("MEDIUM")
    frame:Hide()
end

-- Centers the icons (with their labels) on the bars window, wherever it is and however big.
local function Place()
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", ns.Meter.GetFrame(), "CENTER", 0, 0)
end

local function CreateButton(i)
    local b = CreateFrame("Button", nil, frame)
    b:SetSize(SIZE, SIZE)
    b:RegisterForClicks("RightButtonUp")

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- The glow sits on its own frame so it can pulse.
    b.glow = CreateFrame("Frame", nil, b)
    b.glow:SetPoint("CENTER")
    b.glow:SetSize(SIZE * 1.8, SIZE * 1.8)
    local tex = b.glow:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    tex:SetTexture(GLOW)
    tex:SetBlendMode("ADD")
    tex:SetVertexColor(YELLOW[1], YELLOW[2], YELLOW[3])
    b.pulse = b.glow:CreateAnimationGroup()
    local a = b.pulse:CreateAnimation("Alpha")
    a:SetFromAlpha(1)
    a:SetToAlpha(0.25)
    a:SetDuration(0.6)
    b.pulse:SetLooping("BOUNCE")

    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.label:SetPoint("TOP", b, "BOTTOM", 0, -3)

    b:SetScript("OnEnter", function(self)
        if not self.def then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.def.title, YELLOW[1], YELLOW[2], YELLOW[3])
        GameTooltip:AddLine(self.def.hint, 1, 1, 1, true)
        GameTooltip:AddLine(L["Right-click to dismiss."], 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    b:SetScript("OnClick", function() Reminder.Hide() end)
    return b
end

local function Layout()
    local x = 0
    for i, kind in ipairs(shown) do
        local b = buttons[i] or CreateButton(i)
        buttons[i] = b
        b.buffKind = kind
        b.def = KINDS[kind]()
        b.icon:SetTexture(b.def.icon)
        b.label:SetText(b.def.label)
        -- Each icon gets a slot as wide as its label (or the icon, if wider), so labels never overlap.
        local slot = math.max(SIZE, math.ceil(b.label:GetStringWidth() or SIZE))
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", x + (slot - SIZE) / 2, 0)
        x = x + slot + GAP
        b:Show()
        -- Restart every glow together, so they pulse in step.
        b.pulse:Stop()
        b.pulse:Play()
    end
    for i = #shown + 1, #buttons do
        buttons[i].buffKind = nil
        buttons[i].pulse:Stop()
        buttons[i]:Hide()
    end
    frame:SetWidth(math.max(SIZE, x - GAP))
end

-- Shows the icons for these kinds ("wellFed", "bag", "bagLogout").
function Reminder.Show(kinds)
    if #kinds == 0 then return end
    if not frame then Build() end
    shown = {}
    for _, k in ipairs(kinds) do shown[#shown + 1] = k end
    Place()
    frame:Show()
    Layout()
end

-- Keeps only the icons still missing; hides when none are left.
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
        for _, b in ipairs(buttons) do b.pulse:Stop() end
        frame:Hide()
    end
end

function Reminder.IsShown()
    return frame and frame:IsShown() or false
end

-- The kinds currently shown (for the tests).
function Reminder.Kinds()
    return shown
end
