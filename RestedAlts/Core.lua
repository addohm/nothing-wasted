-- Rested Alts: data, rested XP estimates, events and slash commands.
local addonName, ns = ...

local GetMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
ns.version = GetMetadata(addonName, "Version") or "?"

-- Rested XP rules: 5% of a level per 8 hours while resting (inn or city),
-- a quarter of that anywhere else, capped at 1.5 levels.
ns.MAX_RESTED_LEVELS = 1.5
ns.INN_RATE = 0.05 / (8 * 60 * 60)
ns.WORLD_RATE = ns.INN_RATE / 4

local SAVE_EVENTS = {
    "PLAYER_ENTERING_WORLD",
    "PLAYER_XP_UPDATE",
    "PLAYER_LEVEL_UP",
    "PLAYER_UPDATE_RESTING",
    "UPDATE_EXHAUSTION",
    "ZONE_CHANGED_NEW_AREA",
    "PLAYER_LOGOUT",
}

local DEFAULT_SETTINGS = {
    sort = "rested",
    thisRealmOnly = false,
    hideMaxLevel = false,
    minimap = { angle = 200, hide = false },
}

local function ApplyDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            ApplyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

function ns.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffRested Alts|r: " .. msg)
end

function ns.PlayerKey()
    return UnitName("player") .. "-" .. GetRealmName()
end

-- Records the logged-in character. Updates its entry in place.
function ns.SaveCurrent()
    local level = UnitLevel("player")
    if not level or level <= 0 then return end -- not ready during loading screens

    local key = ns.PlayerKey()
    local c = ns.db.chars[key]
    if not c then
        c = {}
        ns.db.chars[key] = c
    end

    c.className, c.class = UnitClass("player")
    c.name = UnitName("player")
    c.realm = GetRealmName()
    c.level = level
    c.isMax = level >= GetMaxPlayerLevel()
    c.xp = UnitXP("player")
    c.xpMax = UnitXPMax("player")
    c.rested = GetXPExhaustion() or 0
    c.resting = IsResting() and true or false
    c.zone = GetRealZoneText()
    c.savedAt = time()
end

-- Returns estimated rested XP, the rested cap, and seconds until the cap is reached.
function ns.Estimate(c, now)
    if c.isMax or not c.xpMax or c.xpMax <= 0 then return 0, 0, 0 end
    local cap = c.xpMax * ns.MAX_RESTED_LEVELS
    local perSecond = c.xpMax * (c.resting and ns.INN_RATE or ns.WORLD_RATE)
    local elapsed = math.max(0, now - (c.savedAt or now))
    local rested = math.min(cap, (c.rested or 0) + perSecond * elapsed)
    return rested, cap, (cap - rested) / perSecond
end

function ns.Forget(key)
    ns.db.chars[key] = nil
    if key == ns.PlayerKey() then ns.SaveCurrent() end
    ns.RefreshUI()
end

function ns.ForgetAll()
    wipe(ns.db.chars)
    ns.SaveCurrent()
    ns.RefreshUI()
end

-- One-time copy of characters recorded by the older RestedRoster addon, if it is enabled.
local function ImportRestedRoster()
    if ns.db.importedRestedRoster or type(RestedRosterDB) ~= "table" then return end
    local count = 0
    for key, old in pairs(RestedRosterDB) do
        if type(old) == "table" and old.name and old.savedAt and (old.xpMax or 0) > 0 and not ns.db.chars[key] then
            ns.db.chars[key] = {
                name = old.name,
                realm = old.realm,
                class = old.class,
                level = old.level or 0,
                isMax = (old.level or 0) >= GetMaxPlayerLevel(),
                xp = old.xp or 0,
                xpMax = old.xpMax or 0,
                rested = old.rested or 0,
                resting = old.resting and true or false,
                savedAt = old.savedAt,
            }
            count = count + 1
        end
    end
    ns.db.importedRestedRoster = true
    if count > 0 then
        ns.Print(format("imported %d character(s) from RestedRoster. You can disable that addon now.", count))
    end
end

function ns.FormatDuration(seconds)
    seconds = math.floor(seconds)
    if seconds < 60 then return "<1m" end
    local d = math.floor(seconds / 86400)
    local h = math.floor(seconds % 86400 / 3600)
    local m = math.floor(seconds % 3600 / 60)
    if d > 0 then return format("%dd %dh", d, h) end
    if h > 0 then return format("%dh %dm", h, m) end
    return format("%dm", m)
end

function ns.FormatNumber(n)
    local s = tostring(math.floor(n))
    local formatted
    repeat
        s, formatted = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
    until formatted == 0
    return s
end

StaticPopupDialogs["RESTEDALTS_FORGET"] = {
    text = "Forget %s?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(_, key) ns.Forget(key) end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["RESTEDALTS_FORGET_ALL"] = {
    text = "Forget every recorded character? The one you are playing is added back.",
    button1 = YES,
    button2 = NO,
    OnAccept = function() ns.ForgetAll() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= addonName then return end
        self:UnregisterEvent("ADDON_LOADED")

        local firstRun = RestedAltsDB == nil
        RestedAltsDB = RestedAltsDB or {}
        ns.db = RestedAltsDB
        ns.db.chars = ns.db.chars or {}
        ns.db.settings = ns.db.settings or {}
        ApplyDefaults(ns.db.settings, DEFAULT_SETTINGS)

        for _, e in ipairs(SAVE_EVENTS) do self:RegisterEvent(e) end
        ns.InitUI()
        ns.InitMinimap()
        if firstRun then
            ns.Print("type /alts or click the minimap button to see your characters' rested XP.")
        end
        return
    end

    if event == "PLAYER_LOGIN" then
        ImportRestedRoster()
    end
    ns.SaveCurrent()
    ns.RefreshUI()
end)

SLASH_RESTEDALTS1 = "/alts"
SLASH_RESTEDALTS2 = "/restedalts"
SlashCmdList.RESTEDALTS = function(msg)
    msg = msg:lower():match("^%s*(.-)%s*$")
    if msg == "" then
        ns.ToggleUI()
    elseif msg == "minimap" then
        ns.SetMinimapShown(ns.db.settings.minimap.hide)
    elseif msg == "reset" then
        StaticPopup_Show("RESTEDALTS_FORGET_ALL")
    else
        ns.Print("v" .. ns.version .. " commands:")
        ns.Print("  /alts - show or hide the window")
        ns.Print("  /alts minimap - show or hide the minimap button")
        ns.Print("  /alts reset - forget every recorded character")
    end
end
