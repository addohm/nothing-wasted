-- Nothing Wasted: records the character being played.
--
-- The entry is saved at login, whenever XP, rested state, level, zone or money change, and at
-- logout. Hardcore characters aren't tracked while they're hardcore.
local _, ns = ...

local Character = {}
ns.Character = Character

local function IsHardcore()
    return C_GameRules and C_GameRules.IsHardcoreActive and C_GameRules.IsHardcoreActive() or false
end

-- The same rule Blizzard's XP bar uses: the lower of the expansion's and the player's max level.
local function MaxLevel()
    if GameRulesUtil and GameRulesUtil.GetEffectiveMaxLevelForPlayer then
        return GameRulesUtil.GetEffectiveMaxLevelForPlayer()
    end
    return GetMaxPlayerLevel()
end

-- Sets a field only to a real value. While the character leaves the world (at logout) the game can
-- report empty values, which must not overwrite good ones.
local function Set(c, field, value)
    if value ~= nil and value ~= "" then c[field] = value end
end

-- Saves the live values. `reason` is passed on to NW_CHARACTER_SAVED listeners: "login", "logout"
-- or nil for updates during play. Returns the entry, or nil if nothing was saved.
function Character.Save(reason)
    if not ns.db then return end
    local key = ns.PlayerKey()
    if IsHardcore() then
        ns.db.chars[key] = nil
        return
    end
    local level = UnitLevel("player")
    if not level or level <= 0 then return end -- not ready during loading screens

    local c = ns.db.chars[key]
    if not c then
        c = {}
        ns.db.chars[key] = c
    end

    local className, class = UnitClass("player")
    Set(c, "className", className)
    Set(c, "class", class)
    -- On Forever, UnitName's second value is the surname (Blizzard's Camelot NameUtil.lua).
    local name, surname = UnitName("player")
    Set(c, "name", name)
    if type(surname) == "string" and not (issecretvalue and issecretvalue(surname)) then
        Set(c, "surname", surname)
    end
    Set(c, "realm", GetRealmName())
    Set(c, "faction", UnitFactionGroup("player"))
    if c.level and level > c.level then ns.Fire("NW_LEVEL_UP", c, level) end
    c.level = level
    c.isMax = level >= MaxLevel()
    c.xpDisabled = IsXPUserDisabled and IsXPUserDisabled() or false

    -- XP, rested XP, resting and the save time go together: the estimate starts from this snapshot.
    -- If the game has no XP data right now (max XP of 0), keep the last good snapshot.
    local xpMax = UnitXPMax("player")
    if c.isMax or (xpMax and xpMax > 0) then
        c.xp = UnitXP("player")
        c.xpMax = xpMax
        c.rested = GetXPExhaustion() or 0
        c.resting = IsResting() and true or false
        c.savedAt = ns.Now()
    end
    Set(c, "zone", GetRealZoneText())
    c.subzone = GetSubZoneText() -- may be empty: not every spot has a subzone
    Set(c, "bind", GetBindLocation())
    Set(c, "money", GetMoney())
    c.seenAt = ns.Now()

    -- Learn how much XP each level takes, for "how far rested XP carries you".
    if c.xpMax and c.xpMax > 0 then
        ns.db.xpPerLevel = ns.db.xpPerLevel or {}
        ns.db.xpPerLevel[level] = c.xpMax
    end

    ns.Fire("NW_CHARACTER_SAVED", c, reason)
    return c
end

local pending
local function SaveSoon()
    if pending then return end
    pending = true
    C_Timer.After(0.5, function()
        pending = false
        Character.Save()
        ns.Fire("NW_REFRESH")
    end)
end

ns.On("PLAYER_ENTERING_WORLD", function(isInitialLogin, isReload)
    local c = Character.Save((isInitialLogin or isReload) and "login" or nil)
    if c and (isInitialLogin or isReload) then c.lastLogin = ns.Now() end
    ns.Fire("NW_REFRESH")
end)

ns.On("PLAYER_LOGOUT", function()
    Character.Save("logout")
end)

for _, event in ipairs({ "PLAYER_XP_UPDATE", "UPDATE_EXHAUSTION", "PLAYER_UPDATE_RESTING", "PLAYER_LEVEL_UP",
    "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "PLAYER_MONEY", "ENABLE_XP_GAIN", "DISABLE_XP_GAIN" }) do
    ns.On(event, SaveSoon)
end

-- Removes a character from the saved data. Logging in to it adds it back.
function Character.Forget(key)
    ns.db.chars[key] = nil
    if key == ns.PlayerKey() then Character.Save() end
    ns.Fire("NW_REFRESH")
end

-- Tracks a character again, or stops tracking it: an untracked character is still saved but left
-- out of every list, alert and tooltip (see ns.Chars).
function Character.SetTracked(key, tracked)
    local c = ns.db.chars[key]
    if not c then return end
    c.untracked = not tracked or nil
    ns.Fire("NW_REFRESH")
end
