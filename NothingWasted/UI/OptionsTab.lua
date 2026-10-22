-- Nothing Wasted: the Options tab.
local _, ns = ...
local L = ns.L

local SOUNDS = {
    { "RAID_WARNING", L["Raid warning"] },
    { "READY_CHECK", L["Ready check"] },
    { "RAID_BOSS_EMOTE_WARNING", L["Boss emote"] },
    { "UI_RAID_BOSS_WHISPER_WARNING", L["Boss whisper"] },
    { "ALARM_CLOCK_WARNING_3", L["Alarm clock"] },
    { "TELL_MESSAGE", L["Whisper"] },
    { "MAP_PING", L["Map ping"] },
}

local EARLY = {
    { 30, L["30 minutes"] }, { 60, L["1 hour"] }, { 120, L["2 hours"] }, { 240, L["4 hours"] },
    { 480, L["8 hours"] }, { 1440, L["1 day"] },
}

local MAIL_DAYS = { { 1, L["1 day"] }, { 3, L["3 days"] }, { 7, L["7 days"] } }

local function Setting(group, key)
    return function() return ns.db.settings[group][key] end,
        function(v)
            ns.db.settings[group][key] = v
            ns.Fire("NW_REFRESH")
        end
end

ns.Window.AddTab({
    id = "options",
    label = L["Options"],
    order = 7,
    build = function(panel)
        local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT")
        scroll:SetPoint("BOTTOMRIGHT", -24, 0)
        local content = CreateFrame("Frame", nil, scroll)
        content:SetSize(480, 1)
        scroll:SetScrollChild(content)

        local widgets = {}
        local y = 0
        local function Place(w, indent, height)
            w:SetPoint("TOPLEFT", indent or 0, -y)
            y = y + (height or 26)
            widgets[#widgets + 1] = w
        end
        local function Header(text)
            local fs = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fs:SetText(text)
            fs:SetPoint("TOPLEFT", 0, -(y + 6))
            y = y + 26
        end
        local function Check(label, group, key)
            Place(ns.UI.Checkbox(content, label, Setting(group, key)), 8)
        end
        local function Cycle(label, values, group, key)
            Place(ns.UI.Cycle(content, label, values, Setting(group, key)), 12, 28)
        end

        Header(L["Alerts"])
        Check(L["Alert when a character reaches the rested XP cap"], "alerts", "cap")
        Check(L["Only alert once per cap (otherwise again at every login until you play it)"], "alerts", "once")
        Check(L["Red screen-edge glow with the cap alert"], "alerts", "glow")
        Check(L["Early warning before a character caps"], "alerts", "early")
        Cycle(L["Warn this long before:"], EARLY, "alerts", "earlyMinutes")
        Check(L["Alert when a cooldown is ready"], "alerts", "cooldowns")
        Check(L["Warn before mail expires"], "alerts", "mail")
        Cycle(L["Warn this long before:"], MAIL_DAYS, "alerts", "mailDays")
        Check(L["Warn when logging out somewhere that isn't resting"], "alerts", "logout")
        Cycle(L["Alert sound:"], SOUNDS, "alerts", "sound")
        local test = ns.UI.Button(content, L["Test alert"], 120, function()
            ns.Alerts.PlaySound()
            if ns.db.settings.alerts.glow then ns.Glow.Pulse() end
        end)
        Place(test, 12, 30)

        Header(L["Window"])
        Check(L["Show the window in inns and cities, hide it when leaving"], "bars", "autoShow")
        Check(L["Keep the window open when leaving if I opened it myself"], "bars", "manualStays")
        Check(L["Show max-level characters"], "bars", "showMax")

        Header(L["Tooltip details"])
        for _, def in ipairs(ns.Tooltip.Sections()) do
            Check(def.label, "tooltip", def.id)
        end

        Header(L["Minimap"])
        local minimap = ns.UI.Checkbox(content, L["Show the minimap button"],
            function() return not ns.db.settings.minimap.hide end,
            function(v) ns.Minimap.SetShown(v) end)
        Place(minimap, 8)

        content:SetHeight(y + 10)
        panel.widgets = widgets
    end,
    refresh = function(panel)
        for _, w in ipairs(panel.widgets) do
            if w.Sync then w:Sync() end
        end
    end,
})
