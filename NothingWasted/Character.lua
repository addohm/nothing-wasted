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

    c.className, c.class = UnitClass("player")
    c.name = UnitName("player")
    c.realm = GetRealmName()
    c.faction = UnitFactionGroup("player")
    if c.level and level > c.level then ns.Fire("NW_LEVEL_UP", c, level) end
    c.level = level
    c.isMax = level >= MaxLevel()
    c.xpDisabled = IsXPUserDisabled and IsXPUserDisabled() or false
    c.xp = UnitXP("player")
    c.xpMax = UnitXPMax("player")
    c.rested = GetXPExhaustion() or 0
    c.resting = IsResting() and true or false
    c.zone = GetRealZoneText()
    c.subzone = GetSubZoneText()
    c.bind = GetBindLocation()
    c.money = GetMoney()
    c.savedAt = ns.Now()

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

-- Removes a character from the saved data.
function Character.Forget(key)
    ns.db.chars[key] = nil
    if key == ns.PlayerKey() then Character.Save() end
    ns.Fire("NW_REFRESH")
end
