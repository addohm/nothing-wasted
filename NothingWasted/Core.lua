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

eventFrame:SetScript("OnEvent", function(_, event, ...) ns.Fire(event, ...) end)

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
    InitDB()
    ns.Fire("NW_INIT")
    if firstRun then
        ns.Print(L["type /nw or click the minimap button to see your characters."])
    end
end)
