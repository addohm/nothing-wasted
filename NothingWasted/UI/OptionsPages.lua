-- Nothing Wasted: the Options pages (Alerts, Bars window, Tooltip, Minimap, Characters).
local _, ns = ...
local L = ns.L
local UI = ns.UI

local SOUNDS = {
    { "RAID_WARNING", L["Raid warning"] },
    { "READY_CHECK", L["Ready check"] },
    { "RAID_BOSS_EMOTE_WARNING", L["Boss emote"] },
    { "UI_RAID_BOSS_WHISPER_WARNING", L["Boss whisper"] },
    { "ALARM_CLOCK_WARNING_3", L["Alarm clock"] },
    { "TELL_MESSAGE", L["Whisper"] },
    { "MAP_PING", L["Map ping"] },
    { "FAREWELL", L["Farewell (\"See ya later\", random)"] },
}

local CUSTOM = { "CUSTOM", L["Custom (enter an ID below)"] }
local ALERT_SOUNDS, BUFF_SOUNDS = {}, { { "SAME", L["Same as the alert sound"] } }
for _, v in ipairs(SOUNDS) do
    ALERT_SOUNDS[#ALERT_SOUNDS + 1] = v
    BUFF_SOUNDS[#BUFF_SOUNDS + 1] = v
end
ALERT_SOUNDS[#ALERT_SOUNDS + 1] = CUSTOM
BUFF_SOUNDS[#BUFF_SOUNDS + 1] = CUSTOM

local EARLY = {
    { 30, L["30 minutes"] }, { 60, L["1 hour"] }, { 120, L["2 hours"] }, { 240, L["4 hours"] },
    { 480, L["8 hours"] }, { 1440, L["1 day"] },
}

local BAR_COUNTS = { { 5, "5" }, { 10, "10" }, { 15, "15" }, { 20, "20" }, { 40, "40" } }

local MAIL_DAYS = { { 1, L["1 day"] }, { 3, L["3 days"] }, { 7, L["7 days"] } }

local function Setting(group, key)
    return function() return ns.db.settings[group][key] end,
        function(v)
            ns.db.settings[group][key] = v
            ns.Fire("NW_REFRESH")
        end
end

local function Check(stack, label, group, key)
    stack:Add(UI.OptionCheck(stack.inner, label, Setting(group, key)))
end

local function Select(stack, label, values, group, key)
    stack:Add(UI.OptionSelect(stack.inner, label, values, Setting(group, key)))
end

-- Resets a settings group to its defaults.
local function ResetGroup(group)
    return function()
        wipe(ns.db.settings[group])
        ns.ApplyDefaultSettings()
    end
end

local function Page(id, label, order, fill, defaults)
    ns.Window.AddPage({
        id = id,
        group = "options",
        label = label,
        order = order,
        build = function(panel)
            panel.stack = UI.Stack(panel)
            fill(panel.stack)
        end,
        refresh = function(panel) panel.stack:Sync() end,
        defaults = defaults,
    })
end

Page("alerts", L["Alerts"], 1, function(stack)
    Check(stack, L["Alert when a character reaches the rested XP cap"], "alerts", "cap")
    Check(stack, L["Only alert once per cap"], "alerts", "once")
    Check(stack, L["Red screen-edge glow with the cap alert"], "alerts", "glow")
    Select(stack, L["Alert sound"], ALERT_SOUNDS, "alerts", "sound")
    stack:Add(UI.OptionEdit(stack.inner, L["Custom sound ID (sound=ID or file:ID; commas for random)"], Setting("alerts", "customSound")))
    stack:Add(UI.OptionButton(stack.inner, L["Try the alert"], L["Test"], function()
        ns.Alerts.PlaySound()
        if ns.db.settings.alerts.glow then ns.Glow.Pulse() end
    end))
    stack:Add(UI.OptionHeading(stack.inner, L["Early warning"]))
    Check(stack, L["Warn before a character caps"], "alerts", "early")
    Select(stack, L["How long before"], EARLY, "alerts", "earlyMinutes")
    stack:Add(UI.OptionHeading(stack.inner, L["Other alerts"]))
    Check(stack, L["Alert when a cooldown is ready"], "alerts", "cooldowns")
    Check(stack, L["Warn before mail expires"], "alerts", "mail")
    Select(stack, L["How long before"], MAIL_DAYS, "alerts", "mailDays")
    Check(stack, L["At login, list mail expiring within 7 days"], "alerts", "mailLogin")
    Check(stack, L["Warn when logging out away from rest"], "alerts", "logout")
    stack:Add(UI.OptionHeading(stack.inner, L["Leveling buffs (below max level)"]))
    Check(stack, L["Remind me when Well Fed (+5% XP) is missing"], "alerts", "wellFed")
    Check(stack, L["Remind me when my sleeping bag is ready and unused"], "alerts", "bagBuff")
    Check(stack, L["Remind me at logout to use a ready sleeping bag"], "alerts", "bagLogout")
    Check(stack, L["Play a sound with these reminders"], "alerts", "buffSound")
    Select(stack, L["Reminder sound"], BUFF_SOUNDS, "alerts", "buffSoundName")
    stack:Add(UI.OptionEdit(stack.inner, L["Custom reminder sound ID"], Setting("alerts", "buffCustomSound")))
    stack:Add(UI.OptionButton(stack.inner, L["Try the reminder"], L["Test"], function()
        ns.Alerts.PlaySound("buff")
        if ns.db.settings.alerts.buffGlow then ns.Glow.Pulse() end
    end))
    Check(stack, L["Flash the screen edge with these reminders"], "alerts", "buffGlow")
    Check(stack, L["Also print these reminders in chat"], "alerts", "buffChat")
end, ResetGroup("alerts"))

Page("barsopt", L["Bars window"], 2, function(stack)
    Check(stack, L["Show in inns and cities, hide when leaving"], "bars", "autoShow")
    Check(stack, L["Stay open when leaving if I opened it"], "bars", "manualStays")
    Check(stack, L["Show max-level characters"], "bars", "showMax")
    Check(stack, L["Lock in place"], "meter", "locked")
    Select(stack, L["Bars shown"], BAR_COUNTS, "meter", "maxBars")
    Select(stack, L["Bar shows"], ns.Bars.TEXT_CHOICES, "meter", "text")
    stack:Add(UI.OptionButton(stack.inner, L["Bars window"], L["Show it now"], function() ns.Meter.Show() end))
end, function()
    ResetGroup("bars")()
    ResetGroup("meter")()
end)

Page("tooltip", L["Tooltip"], 3, function(stack)
    for _, def in ipairs(ns.Tooltip.Sections()) do
        Check(stack, def.label, "tooltip", def.id)
    end
end, ResetGroup("tooltip"))

Page("minimap", L["Minimap"], 4, function(stack)
    stack:Add(UI.OptionCheck(stack.inner, L["Show the minimap button"],
        function() return not ns.db.settings.minimap.hide end,
        function(v) ns.Minimap.SetShown(v) end))
end, function()
    ns.Minimap.SetShown(true)
end)

-- Characters: every saved character, tracked or not. Untick one to stop tracking it (a bank alt);
-- Forget removes one that's been deleted.

local CHAR_ROW_HEIGHT = 28

local function CharacterItems()
    local me = ns.PlayerKey()
    local items = {}
    for key, c in pairs(ns.db.chars) do items[#items + 1] = { key = key, c = c, isMe = key == me } end
    table.sort(items, function(a, b)
        if (a.c.name or "") ~= (b.c.name or "") then return (a.c.name or "") < (b.c.name or "") end
        return (a.c.realm or "") < (b.c.realm or "")
    end)
    return items
end

local function CharacterRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row:SetScript("OnEnter", function(self)
        if self.item then ns.Tooltip.ShowCharacter(self, self.item.c, self.item.isMe) end
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)

    row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    row.check:SetSize(26, 26)
    row.check:SetPoint("LEFT", 4, 0)
    row.check:SetScript("OnClick", function(self)
        if row.item then ns.Character.SetTracked(row.item.key, self:GetChecked() and true or false) end
    end)

    row.forget = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.forget:SetSize(80, 22)
    row.forget:SetPoint("RIGHT", -4, 0)
    row.forget:SetText(L["Forget"])
    row.forget:SetScript("OnClick", function()
        local item = row.item
        if item then StaticPopup_Show("NOTHINGWASTED_FORGET", item.name, nil, item.key) end
    end)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.name:SetPoint("LEFT", row.check, "RIGHT", 4, 0)
    row.info = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.info:SetPoint("RIGHT", row.forget, "LEFT", -10, 0)
    return row
end

local function UpdateCharacterRow(row, item)
    local c = item.c
    item.name = (c.name or "?") .. "-" .. (c.realm or "?")
    local tracked = ns.IsTracked(c)
    row.check:SetChecked(tracked)
    local name = ns.ColoredName(c) .. " |cff999999" .. (c.realm or "?") .. "|r"
    if item.isMe then name = name .. " |cff999999" .. L["(you)"] .. "|r" end
    row.name:SetText(name)
    local seen = item.isMe and L["playing now"]
        or (c.savedAt and format(L["saved %s ago"], ns.FormatDuration(ns.Now() - c.savedAt)) or L["never saved"])
    row.info:SetText(format("%s %d, %s", L["level"], c.level or 0, seen))
    -- Forgetting the character being played would only add it straight back.
    row.forget:SetShown(not item.isMe)
end

ns.Window.AddPage({
    id = "chars",
    group = "options",
    label = L["Characters"],
    order = 5,
    build = function(panel)
        local note = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        note:SetPoint("TOPLEFT", 4, -2)
        note:SetPoint("TOPRIGHT", -28, -2)
        note:SetJustifyH("LEFT")
        note:SetText(L["Untick a character to stop tracking it: it's still saved, but left out of every list, alert and tooltip. Forget removes a deleted character (logging in to it adds it back)."])
        local holder = CreateFrame("Frame", nil, panel)
        holder:SetPoint("TOPLEFT", 0, -36)
        holder:SetPoint("BOTTOMRIGHT")
        panel.list = UI.List(holder, CHAR_ROW_HEIGHT, CharacterRow, UpdateCharacterRow)
    end,
    refresh = function(panel)
        panel.list:SetItems(CharacterItems(), L["Log in to each character once to add it."])
    end,
})
