-- Nothing Wasted: the small bars window, like a damage meter. It pops up when you enter an inn or
-- city and hides when you leave; a bars window you open yourself stays open unless the option says
-- otherwise. Click the title to open the full window.
local _, ns = ...
local L = ns.L

local Meter = {}
ns.Meter = Meter

local WIDTH = 220
local TITLE_HEIGHT = 18
local ROW_HEIGHT = 16
local REFRESH_SECONDS = 5

local frame, ticker, empty
local rows = {}
local openedBy -- "auto" when it popped up for resting, "user" otherwise

local function SavePosition()
    local point, _, relPoint, x, y = frame:GetPoint()
    ns.db.settings.meter.pos = { point, relPoint, x, y }
end

function Meter.Refresh()
    if not frame or not frame:IsShown() then return end
    local items = ns.Bars.Items()
    local count = math.min(#items, ns.db.settings.meter.maxBars)
    for i = 1, count do
        local row = rows[i]
        if not row then
            row = ns.Bars.CreateRow(frame, "GameFontHighlightSmall")
            row:SetHeight(ROW_HEIGHT)
            row:SetPoint("TOPLEFT", 2, -(TITLE_HEIGHT + (i - 1) * ROW_HEIGHT))
            row:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
            rows[i] = row
        end
        row.item = items[i]
        ns.Bars.UpdateRow(row, items[i])
        row:Show()
    end
    for i = count + 1, #rows do
        rows[i].item = nil
        rows[i]:Hide()
    end
    empty:SetShown(count == 0)
    frame:SetHeight(TITLE_HEIGHT + math.max(count, 1) * ROW_HEIGHT + 2)
end

local function Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(WIDTH, TITLE_HEIGHT + ROW_HEIGHT + 2)
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    local pos = ns.db.settings.meter.pos
    if pos then
        frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        frame:SetPoint("RIGHT", UIParent, "RIGHT", -40, 120)
    end
    frame:Hide()

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.55)

    -- Title strip: drag to move, click to open the full window.
    local title = CreateFrame("Button", nil, frame)
    title:SetPoint("TOPLEFT")
    title:SetPoint("TOPRIGHT", -TITLE_HEIGHT, 0)
    title:SetHeight(TITLE_HEIGHT)
    title:RegisterForClicks("LeftButtonUp")
    title:RegisterForDrag("LeftButton")
    local titleBg = title:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetColorTexture(0.1, 0.1, 0.15, 0.9)
    local text = title:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", 6, 0)
    text:SetText("Nothing Wasted")
    title:SetScript("OnClick", function() ns.Window.Show("rested") end)
    title:SetScript("OnDragStart", function()
        if not ns.db.settings.meter.locked then frame:StartMoving() end
    end)
    title:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        SavePosition()
    end)
    title:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Nothing Wasted")
        GameTooltip:AddLine(L["Click to open the full window."], 1, 1, 1)
        if not ns.db.settings.meter.locked then GameTooltip:AddLine(L["Drag to move."], 0.7, 0.7, 0.7) end
        GameTooltip:Show()
    end)
    title:SetScript("OnLeave", GameTooltip_Hide)

    local close = CreateFrame("Button", nil, frame)
    close:SetSize(TITLE_HEIGHT, TITLE_HEIGHT)
    close:SetPoint("TOPRIGHT")
    local closeBg = close:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    closeBg:SetColorTexture(0.1, 0.1, 0.15, 0.9)
    local x = close:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    x:SetPoint("CENTER")
    x:SetText("x")
    close:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
    close:SetScript("OnClick", function() Meter.Hide() end)

    empty = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    empty:SetPoint("TOPLEFT", 6, -(TITLE_HEIGHT + 2))
    empty:SetText(L["Log in to each character once to add it."])

    frame:SetScript("OnShow", function()
        Meter.Refresh()
        if not ticker then ticker = C_Timer.NewTicker(REFRESH_SECONDS, Meter.Refresh) end
    end)
    frame:SetScript("OnHide", function()
        openedBy = nil
        if ticker then
            ticker:Cancel()
            ticker = nil
        end
    end)
end

function Meter.Show(by)
    if not frame then Build() end
    openedBy = by or "user"
    frame:Show()
    Meter.Refresh()
end

function Meter.Hide()
    if frame then frame:Hide() end
end

function Meter.IsShown()
    return frame and frame:IsShown() or false
end

function Meter.Toggle()
    if Meter.IsShown() then Meter.Hide() else Meter.Show("user") end
end

-- For the tests.
function Meter.Frame() return frame end

-- Pop up while resting -----------------------------------------------------------------------------

local wasResting

local function UpdateResting()
    local resting = IsResting() and true or false
    if resting == wasResting then return end
    wasResting = resting
    local settings = ns.db.settings.bars
    if not settings.autoShow then return end
    if resting then
        if not Meter.IsShown() then Meter.Show("auto") end
    elseif Meter.IsShown() and (openedBy == "auto" or not settings.manualStays) then
        Meter.Hide()
    end
end

ns.On("PLAYER_UPDATE_RESTING", UpdateResting)
ns.On("PLAYER_ENTERING_WORLD", function()
    C_Timer.After(2, UpdateResting)
end)

ns.On("NW_REFRESH", Meter.Refresh)
