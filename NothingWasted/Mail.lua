-- Nothing Wasted: mail.
--
-- Mail you send to your own characters is recorded when it's sent, so their mailbox is known before
-- you log them in. A character's inbox is read whenever its mailbox is open.
local _, ns = ...
local L = ns.L

local Mail = {}
ns.Mail = Mail

local DAY = 86400
local KEEP_DAYS = 30   -- mail is returned or deleted after this
local COD_DAYS = 3     -- cash-on-delivery mail is returned sooner

local function MailOf(c)
    c.mail = c.mail or {}
    c.mail.inbox = c.mail.inbox or {}
    c.mail.incoming = c.mail.incoming or {}
    return c.mail
end

-- The saved character a mail recipient refers to ("Name" or "Name-Realm"), if it's one of ours.
local function FindRecipient(recipient)
    if not recipient or recipient == "" then return end
    local name, realm = recipient:match("^([^%-]+)%-?(.*)$")
    if not name then return end
    if realm == "" then realm = GetRealmName() end
    local lname, lrealm = name:lower(), realm:gsub("%s", ""):lower()
    for key, c in pairs(ns.db.chars) do
        if c.name and c.name:lower() == lname and (c.realm or ""):gsub("%s", ""):lower() == lrealm then
            return key, c
        end
    end
end

-- Sending ------------------------------------------------------------------------------------------

local pending -- the mail being sent, until the game confirms it

local function CaptureSend(recipient, subject)
    local key, c = FindRecipient(recipient)
    if not key then
        pending = nil
        return
    end
    local items = {}
    local any = false
    for i = 1, ATTACHMENTS_MAX_SEND or 12 do
        local name, itemID, _, count = GetSendMailItem(i)
        if itemID then
            items[itemID] = (items[itemID] or 0) + (count or 1)
            ns.Inventory.RememberItem(itemID, name, GetSendMailItemLink and GetSendMailItemLink(i))
            any = true
        end
    end
    local money = GetSendMailMoney() or 0
    local cod = GetSendMailCOD() or 0
    pending = {
        key = key,
        mail = {
            sender = UnitName("player"),
            subject = subject,
            items = any and items or nil,
            money = money > 0 and money or nil,
            cod = cod > 0 and cod or nil,
        },
    }
end

hooksecurefunc("SendMail", CaptureSend)

ns.On("MAIL_SEND_SUCCESS", function()
    if not pending then return end
    local c = ns.db.chars[pending.key]
    if c then
        local m = pending.mail
        local now = ns.Now()
        m.sentAt = now
        m.expiresAt = now + (m.cod and COD_DAYS or KEEP_DAYS) * DAY
        m.id = format("%s:%d", pending.key, now)
        table.insert(MailOf(c).incoming, m)
        ns.Fire("NW_REFRESH")
    end
    pending = nil
end)

ns.On("MAIL_FAILED", function() pending = nil end)

-- Inbox --------------------------------------------------------------------------------------------

local mailboxOpen = false

function Mail.ReadInbox(c)
    if not mailboxOpen then return end
    local now = ns.Now()
    local inbox = {}
    local count = GetInboxNumItems() or 0
    for i = 1, count do
        local _, _, sender, subject, money, cod, daysLeft, itemCount, _, wasReturned = GetInboxHeaderInfo(i)
        local m = {
            sender = sender,
            subject = subject,
            money = (money or 0) > 0 and money or nil,
            cod = (cod or 0) > 0 and cod or nil,
            returned = wasReturned or nil,
            expiresAt = daysLeft and math.floor(now + daysLeft * DAY) or nil,
        }
        if (itemCount or 0) > 0 then
            m.items = {}
            for a = 1, ATTACHMENTS_MAX_RECEIVE or 16 do
                local name, itemID, _, n = GetInboxItem(i, a)
                if itemID then
                    m.items[itemID] = (m.items[itemID] or 0) + (n or 1)
                    ns.Inventory.RememberItem(itemID, name, GetInboxItemLink(i, a))
                end
            end
        end
        -- An ID that stays the same between reads, so expiry warnings fire once per mail.
        m.id = format("%s|%s|%d", sender or "?", subject or "", math.floor((m.expiresAt or 0) / 3600))
        inbox[#inbox + 1] = m
    end
    local mail = MailOf(c)
    mail.inbox = inbox
    mail.inboxAt = now
    -- Mail we recorded as sent has arrived by now (sending to your own characters is instant).
    mail.incoming = {}
end

-- Colour for time left before mail expires: red within 3 days, yellow within 7, none otherwise.
local RED, YELLOW = "|cffff4040", "|cffffd100"
function Mail.ExpiryColor(left)
    if not left then return "" end
    if left <= 3 * DAY then return RED end
    if left <= 7 * DAY then return YELLOW end
    return ""
end

-- Mail of one character that hasn't been collected: inbox and sent-but-not-seen, soonest to expire first.
function Mail.Pending(c)
    local list = {}
    if not c.mail then return list end
    for _, m in ipairs(c.mail.inbox or {}) do list[#list + 1] = m end
    for _, m in ipairs(c.mail.incoming or {}) do list[#list + 1] = m end
    table.sort(list, function(a, b) return (a.expiresAt or math.huge) < (b.expiresAt or math.huge) end)
    return list
end

-- At login: every character with mail expiring within 7 days.
local SOON = 7 * DAY
ns.On("PLAYER_ENTERING_WORLD", function(isInitialLogin)
    if not isInitialLogin then return end
    C_Timer.After(7, function()
        if not ns.db.settings.alerts.mailLogin then return end
        local now = ns.Now()
        local lines = {}
        for _, c in pairs(ns.db.chars) do
            local count, soonest = 0, nil
            for _, m in ipairs(Mail.Pending(c)) do
                if m.expiresAt and m.expiresAt > now and m.expiresAt - now <= SOON then
                    count = count + 1
                    if not soonest or m.expiresAt < soonest then soonest = m.expiresAt end
                end
            end
            if count > 0 then lines[#lines + 1] = { c = c, count = count, left = soonest - now } end
        end
        if #lines == 0 then return end
        table.sort(lines, function(a, b) return a.left < b.left end)
        ns.Print(L["Mail expiring within 7 days:"])
        for _, e in ipairs(lines) do
            ns.Print(format("  %s: %s%s|r", ns.ColoredName(e.c), Mail.ExpiryColor(e.left),
                format(L["%d mail(s), first in %s"], e.count, ns.FormatDuration(e.left))))
        end
    end)
end)

local readPending
local function ReadSoon()
    if readPending then return end
    readPending = true
    C_Timer.After(0.5, function()
        readPending = false
        local c = ns.Me()
        if c then
            Mail.ReadInbox(c)
            ns.Fire("NW_REFRESH")
        end
    end)
end

ns.On("MAIL_SHOW", function()
    mailboxOpen = true
    ReadSoon()
end)
ns.On("MAIL_INBOX_UPDATE", ReadSoon)
ns.On("MAIL_CLOSED", function() mailboxOpen = false end)

-- Tooltip section: uncollected mail.
ns.Tooltip.AddSection({
    id = "mail",
    label = L["Mail"],
    order = 85,
    add = function(tip, c, now)
        local list = Mail.Pending(c)
        if #list == 0 then return end
        local soonest = list[1].expiresAt
        local text = format(L["%d waiting"], #list)
        if soonest then text = text .. format(L[", first expires in %s"], ns.FormatDuration(soonest - now)) end
        tip:AddDoubleLine(L["Mail"], text, 1, 0.82, 0, 1, 1, 1)
    end,
})
