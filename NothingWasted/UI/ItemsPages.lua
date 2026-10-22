-- Nothing Wasted: the Mail and items pages. Item search across every character, uncollected mail
-- (including mail sent but not yet seen), and bag space.
local _, ns = ...
local L = ns.L


local function Chars()
    local list = {}
    for _, c in pairs(ns.db.chars) do list[#list + 1] = c end
    table.sort(list, function(a, b) return (a.name or "") < (b.name or "") end)
    return list
end

local function Where(h)
    local parts = {}
    if h.bags > 0 then parts[#parts + 1] = format(L["bags %d"], h.bags) end
    if h.bank > 0 then parts[#parts + 1] = format(L["bank %d"], h.bank) end
    if h.mailbox > 0 then parts[#parts + 1] = format(L["mailbox %d"], h.mailbox) end
    if h.transit > 0 then parts[#parts + 1] = format(L["sent %d"], h.transit) end
    return table.concat(parts, ", ")
end

local function SearchItems(query)
    local items = {}
    if not query or query == "" then
        items[#items + 1] = { left = "|cff999999" .. L["Type part of an item name above, or use /nw [item link]."] .. "|r" }
        return items
    end
    local results = ns.Inventory.Search(query)
    local shown = 0
    for _, r in ipairs(results) do
        if r.total > 0 then
            shown = shown + 1
            items[#items + 1] = {
                left = r.link or r.name, right = format(L["%d total"], r.total), header = true,
                tooltip = r.link and function(tip) tip:SetHyperlink(r.link) end or nil,
            }
            for _, h in ipairs(r.holders) do
                items[#items + 1] = { left = "   " .. ns.ColoredName(h.c), right = Where(h) }
            end
        end
        if shown >= 30 then break end
    end
    if shown == 0 then items[#items + 1] = { left = "|cff999999" .. L["None of your characters has that."] .. "|r" } end
    return items
end

local function MailItems()
    local now = ns.Now()
    local items = {}
    for _, c in ipairs(Chars()) do
        local list = ns.Mail.Pending(c)
        if #list > 0 then
            local seen = c.mail and c.mail.inboxAt
            items[#items + 1] = {
                left = ns.ColoredName(c), header = true,
                right = seen and ("|cff999999" .. format(L["mailbox checked %s ago"], ns.FormatDuration(now - seen)) .. "|r") or "",
            }
            for _, m in ipairs(list) do
                local what = {}
                local count = 0
                for _, n in pairs(m.items or {}) do count = count + n end
                if count > 0 then what[#what + 1] = format(L["%d item(s)"], count) end
                if m.money then what[#what + 1] = ns.FormatMoney(m.money) end
                if m.cod then what[#what + 1] = L["COD"] .. " " .. ns.FormatMoney(m.cod) end
                local left = m.expiresAt and (m.expiresAt - now) or nil
                local expiry = left and (left < 3 * 86400 and "|cffff4040" or "") .. format(L["expires in %s"], ns.FormatDuration(left)) .. "|r" or ""
                items[#items + 1] = {
                    left = format("   %s%s  |cff999999%s|r", m.sentAt and (L["(sent)"] .. " ") or "", m.sender or "?", table.concat(what, ", ")),
                    right = expiry,
                    tooltip = function(tip)
                        tip:AddLine(m.subject ~= "" and m.subject or L["(no subject)"])
                        tip:AddLine(format(L["From %s"], m.sender or "?"), 1, 1, 1)
                        for itemID, n in pairs(m.items or {}) do
                            local item = ns.db.items and ns.db.items[itemID]
                            tip:AddLine(format("%dx %s", n, item and item.name or ("item:" .. itemID)), 1, 1, 1)
                        end
                    end,
                }
            end
        end
    end
    if #items == 0 then items[#items + 1] = { left = "|cff999999" .. L["No uncollected mail."] .. "|r" } end
    return items
end

local function BagItems()
    local now = ns.Now()
    local items = {}
    for _, c in ipairs(Chars()) do
        if c.bagSlots then
            local full = (c.bagFree or 0) == 0
            items[#items + 1] = {
                left = ns.ColoredName(c) .. (c.bankAt and ("  |cff999999" .. format(L["bank seen %s ago"], ns.FormatDuration(now - c.bankAt)) .. "|r") or ""),
                right = (full and "|cffff4040" or "") .. format(L["%d / %d free"], c.bagFree or 0, c.bagSlots),
            }
        end
    end
    return items
end

ns.Window.AddPage({
    id = "search",
    group = "items",
    label = L["Item search"],
    order = 1,
    build = function(panel)
        local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", 4, -6)
        label:SetText(L["Find an item:"])

        local box = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
        box:SetSize(240, 22)
        box:SetPoint("LEFT", label, "RIGHT", 14, 0)
        box:SetAutoFocus(false)
        box:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
            ns.Inventory.ShowSearch(self:GetText())
        end)
        box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        box:SetScript("OnTextChanged", function(self, userInput)
            if userInput then
                ns.Inventory.lastQuery = self:GetText()
                ns.Window.Refresh()
            end
        end)
        panel.box = box

        local body = CreateFrame("Frame", nil, panel)
        body:SetPoint("TOPLEFT", 0, -34)
        body:SetPoint("BOTTOMRIGHT")
        panel.list = ns.UI.TextList(body)

        ns.On("NW_SEARCH", function(query)
            box:SetText(query or "")
            ns.Window.Refresh()
        end)
    end,
    refresh = function(panel)
        panel.list:SetItems(SearchItems(ns.Inventory.lastQuery))
    end,
})

local function ListPage(id, label, order, source)
    ns.Window.AddPage({
        id = id,
        group = "items",
        label = label,
        order = order,
        build = function(panel) panel.list = ns.UI.TextList(panel) end,
        refresh = function(panel) panel.list:SetItems(source()) end,
    })
end

ListPage("mail", L["Mail"], 2, MailItems)
ListPage("bags", L["Bag space"], 3, BagItems)
