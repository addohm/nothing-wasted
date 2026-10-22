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
            update(row, item)
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
function UI.TextRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row.left = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.left:SetPoint("LEFT", 4, 0)
    row.left:SetJustifyH("LEFT")
    row.right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.right:SetPoint("RIGHT", -4, 0)
    row.right:SetJustifyH("RIGHT")
    row.left:SetPoint("RIGHT", row.right, "LEFT", -8, 0)
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

function UI.UpdateTextRow(row, item)
    row.left:SetText(item.left or "")
    row.right:SetText(item.right or "")
    if item.header then
        row.left:SetFontObject("GameFontNormal")
    else
        row.left:SetFontObject("GameFontHighlight")
    end
end

-- A simple list of text rows: items are { left, right, header, tooltip, onClick }.
function UI.TextList(parent)
    return UI.List(parent, 18, UI.TextRow, UI.UpdateTextRow)
end

-- A small text header line above a list.
function UI.Header(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetText(text)
    return fs
end

function UI.Checkbox(parent, label, get, set)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cb.label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    cb.label:SetText(label)
    cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
    cb.Sync = function(self) self:SetChecked(get()) end
    return cb
end

function UI.Button(parent, label, width, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width or 100, 22)
    b:SetText(label)
    b:SetScript("OnClick", onClick)
    return b
end

-- A clickable text that cycles through choices: values is a list of { value, label }.
function UI.Cycle(parent, label, values, get, set)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(320, 24)
    holder.label = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    holder.label:SetPoint("LEFT")
    holder.label:SetText(label)
    local b = UI.Button(holder, "", 140, function()
        local cur = get()
        local idx = 1
        for i, v in ipairs(values) do
            if v[1] == cur then idx = i end
        end
        local nextValue = values[idx % #values + 1]
        set(nextValue[1])
        holder:Sync()
    end)
    b:SetPoint("LEFT", holder.label, "RIGHT", 8, 0)
    holder.button = b
    function holder:Sync()
        local cur = get()
        for _, v in ipairs(values) do
            if v[1] == cur then b:SetText(v[2]) end
        end
    end
    return holder
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
