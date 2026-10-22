-- Nothing Wasted: slash commands. /nw, with /nothingwasted in case another addon uses /nw.
local _, ns = ...
local L = ns.L

local function Help()
    local version = ns.version .. (ns.build and (" build " .. ns.build) or "")
    ns.Print(format(L["v%s commands:"], version))
    ns.Print(L["  /nw - show or hide the window"])
    ns.Print(L["  /nw bars - show or hide the small bars window"])
    ns.Print(L["  /nw [item] - find an item on all your characters"])
    ns.Print(L["  /nw options - open the options"])
    ns.Print(L["  /nw minimap - show or hide the minimap button"])
    ns.Print(L["  /nw chars - list every saved character"])
    ns.Print(L["  /nw reset - forget every character"])
end

-- Lists every saved character and what its bar shows: /nw chars
local function ListCharacters()
    local now = ns.Now()
    local keys = {}
    for key in pairs(ns.db.chars) do keys[#keys + 1] = key end
    table.sort(keys)
    ns.Print(format(L["%d saved character(s):"], #keys))
    for _, key in ipairs(keys) do
        local c = ns.db.chars[key]
        local status
        if c.isMax then
            status = ns.db.settings.bars.showMax and L["max level"] or L["max level (hidden by the option)"]
        elseif ns.Rested.IsIdle(c) then
            status = c.xpDisabled and L["XP turned off"] or L["no XP data yet"]
        else
            local _, _, toCap = ns.Rested.Estimate(c, now)
            status = toCap <= 0 and L["at the rested cap"] or format(L["caps in %s"], ns.FormatDuration(toCap))
        end
        ns.Print(format("  %s  %s %d, %s, %s", key, L["level"], c.level or 0,
            c.savedAt and format(L["saved %s ago"], ns.FormatDuration(now - c.savedAt)) or L["never saved"], status))
    end
end

SLASH_NOTHINGWASTED1 = "/nw"
SLASH_NOTHINGWASTED2 = "/nothingwasted"
SlashCmdList.NOTHINGWASTED = function(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$")
    local cmd = msg:lower()
    if cmd == "" then
        ns.Window.Toggle()
    elseif cmd == "bars" then
        ns.Meter.Toggle()
    elseif cmd == "options" or cmd == "config" then
        ns.Window.Show("options")
    elseif cmd == "minimap" then
        local hidden = ns.db.settings.minimap.hide
        ns.Minimap.SetShown(hidden)
        ns.Print(hidden and L["minimap button shown."] or L["minimap button hidden. Type /nw minimap to bring it back."])
    elseif cmd == "reset" then
        StaticPopup_Show("NOTHINGWASTED_FORGET_ALL")
    elseif cmd == "chars" then
        ListCharacters()
    elseif cmd == "perks" then
        ns.Legacy.DumpPerks()
    elseif cmd == "help" or cmd == "?" then
        Help()
    else
        -- Anything else is an item search: an item link or part of a name.
        ns.Window.Show("items")
        ns.Inventory.ShowSearch(msg)
    end
end

StaticPopupDialogs["NOTHINGWASTED_FORGET"] = {
    text = L["Forget %s?"],
    button1 = YES,
    button2 = NO,
    OnAccept = function(_, key) ns.Character.Forget(key) end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["NOTHINGWASTED_FORGET_ALL"] = {
    text = L["Forget every character? The one you're playing is added back."],
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        wipe(ns.db.chars)
        ns.Character.Save()
        ns.Fire("NW_REFRESH")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
