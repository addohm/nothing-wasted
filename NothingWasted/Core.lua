-- Nothing Wasted: saved data, the event bus and shared helpers.
local addonName, ns = ...
local L = ns.L

local GetMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
ns.version = GetMetadata(addonName, "Version") or "?"

local DB_VERSION = 1

local DEFAULT_SETTINGS = {
    alerts = {
        cap = true,           -- alert when a character reaches the rested cap
        once = false,         -- only alert once per cap, instead of at every login until played
        early = true,         -- warn before a character caps
        earlyMinutes = 120,
        cooldowns = true,     -- alert when a tracked cooldown is ready
        mail = true,          -- warn before mail expires
        mailDays = 3,
        logout = true,        -- chat line when logging out somewhere that isn't resting
        wellFed = true,       -- remind when the Well Fed XP buff is missing (below max level)
        bagBuff = true,       -- remind when the sleeping bag is ready and its buff is missing
        bagLogout = true,     -- remind at logout to use a ready sleeping bag first
        buffSound = true,     -- play the alert sound with the buff reminders
        mailLogin = true,     -- at login, list characters with mail expiring within 7 days
        glow = true,          -- red screen-edge glow on the rested cap alert
        sound = "RAID_WARNING",
    },
    bars = {
        autoShow = true,      -- show the bars window when entering an inn or city, hide when leaving
        manualStays = true,   -- a bars window opened by hand stays open when leaving
        showMax = false,      -- show max-level characters
    },
    tooltip = {
        level = true,
        rested = true,
        professions = true,
        gold = true,
        location = true,
        bind = true,
        legacy = true,
        cooldowns = true,
        bags = true,
        mail = true,
        played = true,
    },
    meter = {
        maxBars = 10,         -- bars shown in the small bars window
        locked = false,       -- stop the bars window from being dragged
        text = "toCap",       -- what a bar's right-hand text shows (see Bars.TEXT_CHOICES)
    },
    window = { tab = "rested" },
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

function ns.ApplyDefaultSettings()
    ApplyDefaults(ns.db.settings, DEFAULT_SETTINGS)
end

-- Event bus. Game events register on first use; names starting with "NW_" are internal messages.
local handlers = {}
local eventFrame = CreateFrame("Frame")

function ns.On(event, fn)
    if not handlers[event] then
        handlers[event] = {}
        if not event:find("^NW_") then eventFrame:RegisterEvent(event) end
    end
    local list = handlers[event]
    list[#list + 1] = fn
end

function ns.Fire(event, ...)
    local list = handlers[event]
    if not list then return end
    for i = 1, #list do
        local ok, err = pcall(list[i], ...)
        if not ok then geterrorhandler()(err) end
    end
end

-- Removes Midnight "secret" values from the saved data, since the game can't save them.
-- Returns how many were removed.
local function StripSecrets(t, seen)
    if not issecretvalue then return 0 end
    seen = seen or {}
    if seen[t] then return 0 end
    seen[t] = true
    local removed = 0
    for k, v in pairs(t) do
        if issecretvalue(k) or issecretvalue(v) then
            t[k] = nil
            removed = removed + 1
        elseif type(v) == "table" then
            removed = removed + StripSecrets(v, seen)
        end
    end
    return removed
end

-- Runs after every PLAYER_LOGOUT handler, right before the game writes the saved data.
local function FinishSave()
    if not ns.db then return end
    local ok, removed = pcall(StripSecrets, ns.db)
    ns.db.lastSave = { by = ns.PlayerKey(), at = time(), secretsRemoved = ok and removed or nil }
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    ns.Fire(event, ...)
    if event == "PLAYER_LOGOUT" then FinishSave() end
end)

-- Helpers

function ns.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffNothing Wasted|r: " .. msg)
end

function ns.Now()
    return time()
end

function ns.PlayerKey()
    return UnitName("player") .. "-" .. GetRealmName()
end

function ns.Me()
    return ns.db.chars[ns.PlayerKey()]
end

-- Characters other than the one being played, as key, entry pairs.
function ns.Alts()
    local me = ns.PlayerKey()
    local list = {}
    for key, c in pairs(ns.db.chars) do
        if key ~= me then list[#list + 1] = { key = key, c = c } end
    end
    return list
end

function ns.ClassColor(c)
    local color = c and c.class and RAID_CLASS_COLORS[c.class]
    if color then return color.r, color.g, color.b end
    return 1, 1, 1
end

function ns.ColoredName(c)
    local r, g, b = ns.ClassColor(c)
    return format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, c.name or "?")
end

function ns.FormatDuration(seconds)
    seconds = math.floor(seconds or 0)
    if seconds < 60 then return L["<1m"] end
    local d = math.floor(seconds / 86400)
    local h = math.floor(seconds % 86400 / 3600)
    local m = math.floor(seconds % 3600 / 60)
    if d > 0 then return format(L["%dd %dh"], d, h) end
    if h > 0 then return format(L["%dh %dm"], h, m) end
    return format(L["%dm"], m)
end

function ns.FormatNumber(n)
    local s = tostring(math.floor(n or 0))
    local count
    repeat
        s, count = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
    until count == 0
    return s
end

function ns.FormatMoney(copper)
    copper = math.floor(copper or 0)
    local g = math.floor(copper / 10000)
    local s = math.floor(copper % 10000 / 100)
    local c = copper % 100
    if g > 0 then return format("%s|cffffd700g|r %d|cffc7c7cfs|r", ns.FormatNumber(g), s) end
    if s > 0 then return format("%d|cffc7c7cfs|r %d|cffeda55fc|r", s, c) end
    return format("%d|cffeda55fc|r", c)
end

-- Startup

local function InitDB()
    NothingWastedDB = NothingWastedDB or {}
    local db = NothingWastedDB
    db.version = db.version or DB_VERSION
    db.chars = db.chars or {}
    db.settings = db.settings or {}
    ApplyDefaults(db.settings, DEFAULT_SETTINGS)
    ns.db = db
end

ns.On("ADDON_LOADED", function(name)
    if name ~= addonName then return end
    local firstRun = NothingWastedDB == nil
    ns.firstRun = firstRun
    InitDB()
    -- What the saved file said about the session that wrote it, for /nw chars.
    ns.loadedSave = ns.db.lastSave
    ns.Fire("NW_INIT")
    if firstRun then
        ns.Print(L["type /nw or click the minimap button to see your characters."])
    end
end)
