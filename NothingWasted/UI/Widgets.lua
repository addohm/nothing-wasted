-- Nothing Wasted: small building blocks shared by the tabs.
local _, ns = ...

local UI = {}
ns.UI = UI

UI.BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
UI.WHITE = "Interface\\Buttons\\WHITE8X8"

-- A scrolling list of pooled rows.
-- createRow(parent) builds a row frame; update(row, item) fills it. Call list:SetItems(items).
function UI.List(parent, rowHeight, createRow, update)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT")
    scroll:SetPoint("BOTTOMRIGHT", -24, 0)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    -- Follow the window's width when it's resized.
    scroll:SetScript("OnSizeChanged", function(_, width) content:SetWidth(width) end)

    local list = { scroll = scroll, content = content, rows = {} }

    local empty = parent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("CENTER")
    empty:Hide()
    list.empty = empty

    function list:SetItems(items, emptyText)
        local width = scroll:GetWidth()
        content:SetWidth(width > 0 and width or parent:GetWidth() - 24)
        for i, item in ipairs(items) do
            local row = self.rows[i]
            if not row then
                row = createRow(content)
                row:SetHeight(rowHeight)
                row:SetPoint("TOPLEFT", 0, -(i - 1) * rowHeight)
                row:SetPoint("RIGHT", content, "RIGHT")
                self.rows[i] = row
            end
            row.item = item
            update(row, item, i)
            row:Show()
        end
        for i = #items + 1, #self.rows do
            self.rows[i].item = nil
            self.rows[i]:Hide()
        end
        content:SetHeight(math.max(1, #items * rowHeight))
        empty:SetText(emptyText or "")
        empty:SetShown(#items == 0 and emptyText ~= nil)
    end

    return list
end

-- A row with a left and a right text, for simple lists. Rows with a tooltip function get one.
-- Every other plain row gets a faint stripe; headers get a thin gold rule under them.
local INDENT = 16

function UI.TextRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row.stripe = row:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints()
    row.stripe:SetColorTexture(1, 1, 1, 0.04)
    row.rule = row:CreateTexture(nil, "BORDER")
    row.rule:SetPoint("BOTTOMLEFT", 4, 1)
    row.rule:SetPoint("BOTTOMRIGHT", -4, 1)
    row.rule:SetHeight(1)
    row.rule:SetColorTexture(0.6, 0.45, 0.15, 0.5)
    row.left = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.left:SetJustifyH("LEFT")
    row.right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.right:SetPoint("RIGHT", -6, 0)
    row.right:SetJustifyH("RIGHT")
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row:SetScript("OnEnter", function(self)
        if self.item and self.item.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            self.item.tooltip(GameTooltip)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnClick", function(self, button)
        if self.item and self.item.onClick then self.item.onClick(button) end
    end)
    return row
end

function UI.UpdateTextRow(row, item, index)
    row.left:ClearAllPoints()
    row.left:SetPoint("LEFT", 6 + (item.indent or 0) * INDENT, 0)
    row.left:SetPoint("RIGHT", row.right, "LEFT", -10, 0)
    row.left:SetText(item.left or "")
    row.right:SetText(item.right or "")
    row.left:SetFontObject(item.header and "GameFontNormal" or "GameFontHighlight")
    row.right:SetFontObject(item.header and "GameFontNormalSmall" or "GameFontHighlight")
    row.rule:SetShown(item.header and true or false)
    row.stripe:SetShown(not item.header and index % 2 == 0)
end

-- A header row that expands or collapses the rows under it. `state` holds the keys toggled away
-- from the default (collapsed unless `defaultOpen`); clicking toggles the key and refreshes the
-- window. UI.IsOpen tells whether a header is open.
local PLUS = "|TInterface\\Buttons\\UI-PlusButton-Up:14:14|t "
local MINUS = "|TInterface\\Buttons\\UI-MinusButton-Up:14:14|t "

function UI.IsOpen(state, key, defaultOpen)
    if defaultOpen then return not state[key] end
    return state[key] and true or false
end

function UI.CollapsibleHeader(state, key, left, right, defaultOpen, indent)
    return {
        header = true,
        indent = indent,
        left = (UI.IsOpen(state, key, defaultOpen) and MINUS or PLUS) .. left,
        right = right,
        onClick = function()
            state[key] = not state[key] or nil
            ns.Window.Refresh()
        end,
    }
end

-- A simple list of text rows: items are { left, right, header, indent, tooltip, onClick }.
function UI.TextList(parent)
    return UI.List(parent, 20, UI.TextRow, UI.UpdateTextRow)
end

-- A small text header line above a list.
function UI.Header(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetText(text)
    return fs
end

-- Options rows, laid out like the game's Settings: the label on the left, the control on the right.
-- Each row has :Sync() to show the current value. Place rows top to bottom with UI.Stack.

local LABEL_X, CONTROL_X, ROW_HEIGHT = 16, 330, 34

local function OptionRow(parent, label)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.label:SetPoint("LEFT", LABEL_X, 0)
    row.label:SetWidth(CONTROL_X - LABEL_X - 12)
    row.label:SetJustifyH("LEFT")
    row.label:SetText(label)
    row.Sync = function() end
    return row
end

function UI.OptionCheck(parent, label, get, set)
    local row = OptionRow(parent, label)
    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cb:SetSize(30, 30)
    cb:SetPoint("LEFT", CONTROL_X, 0)
    cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
    row.check = cb
    row.Sync = function() cb:SetChecked(get()) end
    return row
end

-- A value picker with arrows on each side: values is a list of { value, label }.
function UI.OptionSelect(parent, label, values, get, set)
    local row = OptionRow(parent, label)
    local function Step(dir)
        local cur, idx = get(), 1
        for i, v in ipairs(values) do
            if v[1] == cur then idx = i end
        end
        idx = (idx - 1 + dir) % #values + 1
        set(values[idx][1])
        row.Sync()
    end
    local function Arrow(dir, x)
        local b = CreateFrame("Button", nil, row)
        b:SetSize(26, 26)
        b:SetPoint("LEFT", x, 0)
        local base = dir < 0 and "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-" or "Interface\\Buttons\\UI-SpellbookIcon-NextPage-"
        b:SetNormalTexture(base .. "Up")
        b:SetPushedTexture(base .. "Down")
        b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        b:SetScript("OnClick", function() Step(dir) end)
        return b
    end
    row.prev = Arrow(-1, CONTROL_X)
    local box = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    box:SetSize(170, 24)
    box:SetPoint("LEFT", CONTROL_X + 30, 0)
    box:SetScript("OnClick", function() Step(1) end)
    row.box = box
    row.next = Arrow(1, CONTROL_X + 204)
    row.Sync = function()
        local cur = get()
        local text = tostring(cur)
        for _, v in ipairs(values) do
            if v[1] == cur then text = v[2] end
        end
        box:SetText(text)
    end
    return row
end

-- A text box; the value is saved when you press Enter or click away.
function UI.OptionEdit(parent, label, get, set)
    local row = OptionRow(parent, label)
    local box = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    box:SetSize(164, 22)
    box:SetPoint("LEFT", CONTROL_X + 36, 0)
    box:SetAutoFocus(false)
    local function Save(self)
        set(self:GetText() or "")
        self:ClearFocus()
    end
    box:SetScript("OnEnterPressed", Save)
    box:HookScript("OnEditFocusLost", function(self) set(self:GetText() or "") end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    row.box = box
    row.Sync = function()
        if not box:HasFocus() then box:SetText(get() or "") end
    end
    return row
end

function UI.OptionButton(parent, label, buttonText, onClick)
    local row = OptionRow(parent, label)
    local b = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    b:SetSize(170, 24)
    b:SetPoint("LEFT", CONTROL_X + 30, 0)
    b:SetText(buttonText)
    b:SetScript("OnClick", onClick)
    row.button = b
    return row
end

-- A section heading inside a page, like "Mouse" in the game's Settings.
function UI.OptionHeading(parent, text)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT + 4)
    local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    fs:SetPoint("BOTTOMLEFT", 4, 6)
    fs:SetText(text)
    row.Sync = function() end
    return row
end

-- A scrolling column of rows. Returns the stack; call stack:Add(row) for each row in order.
function UI.Stack(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT")
    scroll:SetPoint("BOTTOMRIGHT", -24, 0)
    local inner = CreateFrame("Frame", nil, scroll)
    inner:SetSize(520, 1)
    scroll:SetScrollChild(inner)
    scroll:SetScript("OnSizeChanged", function(_, width) inner:SetWidth(width) end)
    local stack = { rows = {}, inner = inner, height = 0 }
    function stack:Add(row)
        row:SetParent(inner)
        row:SetPoint("TOPLEFT", 0, -self.height)
        row:SetPoint("RIGHT", inner, "RIGHT")
        self.height = self.height + row:GetHeight()
        inner:SetHeight(self.height)
        self.rows[#self.rows + 1] = row
        return row
    end
    function stack:Sync()
        for _, row in ipairs(self.rows) do row:Sync() end
    end
    return stack
end

-- Adds the lines of a tooltip section: lines is a list of { left, right } or a string.
function UI.AddLines(tooltip, lines)
    for _, line in ipairs(lines) do
        if type(line) == "string" then
            tooltip:AddLine(line, 1, 1, 1, true)
        else
            tooltip:AddDoubleLine(line[1], line[2], 1, 0.82, 0, 1, 1, 1)
        end
    end
end
