-- Nothing Wasted: slash commands. /nw, with /nothingwasted in case another addon uses /nw.
local _, ns = ...
local L = ns.L

local function Help()
    ns.Print(format(L["v%s commands:"], ns.version))
    ns.Print(L["  /nw - show or hide the window"])
    ns.Print(L["  /nw [item] - find an item on all your characters"])
    ns.Print(L["  /nw options - open the options"])
    ns.Print(L["  /nw minimap - show or hide the minimap button"])
    ns.Print(L["  /nw reset - forget every character"])
end

SLASH_NOTHINGWASTED1 = "/nw"
SLASH_NOTHINGWASTED2 = "/nothingwasted"
SlashCmdList.NOTHINGWASTED = function(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$")
    local cmd = msg:lower()
    if cmd == "" then
        ns.Window.Toggle()
    elseif cmd == "options" or cmd == "config" then
        ns.Window.Show("options")
    elseif cmd == "minimap" then
        local hidden = ns.db.settings.minimap.hide
        ns.Minimap.SetShown(hidden)
        ns.Print(hidden and L["minimap button shown."] or L["minimap button hidden. Type /nw minimap to bring it back."])
    elseif cmd == "reset" then
        StaticPopup_Show("NOTHINGWASTED_FORGET_ALL")
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
