local addonName = ...
local PREFIX = "|cff66ccffRested Roster|r"
local MAX_RESTED_LEVELS = 1.5
local INN_RATE_PER_SECOND = 0.05 / (8 * 60 * 60) -- 5% of a level per 8 hours
local WORLD_RATE_PER_SECOND = INN_RATE_PER_SECOND / 4

local function Key()
    local name = UnitName("player") or "Unknown"
    local realm = GetRealmName and GetRealmName() or "Unknown"
    return name .. "-" .. realm
end

local function IsRestingSafe()
    return IsResting and IsResting() or false
end

local function SaveCurrent()
    if not RestedRosterDB then RestedRosterDB = {} end
    if UnitLevel("player") <= 0 then return end

    local xpMax = UnitXPMax("player") or 0
    local rested = GetXPExhaustion and GetXPExhaustion() or 0
    local _, class = UnitClass("player")

    RestedRosterDB[Key()] = {
        name = UnitName("player") or "Unknown",
        realm = GetRealmName and GetRealmName() or "Unknown",
        class = class,
        level = UnitLevel("player") or 0,
        xp = UnitXP("player") or 0,
        xpMax = xpMax,
        rested = rested,
        savedAt = time(),
        resting = IsRestingSafe(),
    }
end

local function Estimate(entry)
    if not entry or not entry.xpMax or entry.xpMax <= 0 then return 0, false end
    local exact = entry.rested or 0
    local elapsed = math.max(0, time() - (entry.savedAt or time()))
    local rate = entry.resting and INN_RATE_PER_SECOND or WORLD_RATE_PER_SECOND
    local gained = entry.xpMax * rate * elapsed
    local cap = entry.xpMax * MAX_RESTED_LEVELS
    return math.min(cap, exact + gained), elapsed > 0
end

local function PrintRoster()
    if not RestedRosterDB or not next(RestedRosterDB) then
        DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. ": no characters recorded yet.")
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. " by KYOL")
    local rows = {}
    for _, entry in pairs(RestedRosterDB) do
        rows[#rows+1] = entry
    end
    table.sort(rows, function(a, b)
        if (a.realm or "") == (b.realm or "") then
            return (a.name or "") < (b.name or "")
        end
        return (a.realm or "") < (b.realm or "")
    end)

    for _, entry in ipairs(rows) do
        local rested, estimated = Estimate(entry)
        local pct = entry.xpMax and entry.xpMax > 0 and (rested / entry.xpMax * 100) or 0
        local tag = estimated and "estimated" or "exact"
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s - Lv %d - %.1f%% of a level rested (%s)", entry.name or "?", entry.level or 0, pct, tag))
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_XP_UPDATE")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("PLAYER_UPDATE_RESTING")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            if not RestedRosterDB then RestedRosterDB = {} end
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. " 0.1.2 by KYOL loaded. Type /rr to view your roster.")
            end
        end
        return
    end
    SaveCurrent()
end)

SLASH_RESTEDROSTER1 = "/rr"
SLASH_RESTEDROSTER2 = "/restedroster"
SlashCmdList.RESTEDROSTER = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "clear" then
        RestedRosterDB = {}
        SaveCurrent()
        DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. ": roster cleared; current character re-added.")
    else
        SaveCurrent()
        PrintRoster()
    end
end
