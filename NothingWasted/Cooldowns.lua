-- Nothing Wasted: cooldowns per character (profession cooldowns, Dedicated Study, Camp Tent, the
-- Cozy Sleeping Bag, the hearthstone).
--
-- Cooldowns are read for the character being played and saved as the time they're ready, so they
-- can be shown and alerted on for every character. The list is in Data.lua.
local _, ns = ...

local Cooldowns = {}
ns.Cooldowns = Cooldowns

-- Seconds until a spell or item is ready (0 if ready), or nil if the character doesn't have it.
local function Remaining(def)
    local start, duration
    if def.spellID then
        if not C_SpellBook.IsSpellKnown(def.spellID) then return nil end
        local info = C_Spell.GetSpellCooldown(def.spellID)
        if not info then return 0 end
        start, duration = info.startTime, info.duration
    elseif def.itemID then
        if (C_Item.GetItemCount(def.itemID, true) or 0) == 0 then return nil end
        start, duration = C_Container.GetItemCooldown(def.itemID)
    else
        return nil
    end
    if not start or not duration or start == 0 or duration == 0 then return 0 end
    -- Global cooldowns aren't real cooldowns.
    if duration <= 1.5 then return 0 end
    return math.max(0, start + duration - GetTime())
end

-- For cooldowns with several spells (transmutes share one cooldown): the first one the character knows.
local function Resolve(def)
    if not def.spellIDs then return def end
    for _, id in ipairs(def.spellIDs) do
        if C_SpellBook.IsSpellKnown(id) then return { spellID = id } end
    end
end

-- Seconds left on a lockout aura (the Camp Tent's Boosted Rest), or nil if it isn't on.
local function AuraRemaining(spellID)
    if not C_UnitAuras or not C_UnitAuras.GetPlayerAuraBySpellID then return end
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
    if aura and aura.expirationTime and aura.expirationTime > 0 then
        return math.max(0, aura.expirationTime - GetTime())
    end
end

function Cooldowns.Read(c)
    -- Cooldown times can be secret during combat; keep the saved values until it ends.
    if InCombatLockdown() then return end
    c.cooldowns = c.cooldowns or {}
    local now = ns.Now()
    for _, def in ipairs(ns.Data.cooldowns) do
        local source = Resolve(def)
        local left = source and Remaining(source)
        if def.auraSpellID then
            local aura = AuraRemaining(def.auraSpellID)
            if aura then left = math.max(left or 0, aura) end
        end
        if left == nil then
            c.cooldowns[def.id] = nil
        else
            local entry = c.cooldowns[def.id] or {}
            entry.name = def.name
            entry.readyAt = math.floor(now + left + 0.5)
            entry.alert = def.alert ~= false
            c.cooldowns[def.id] = entry
        end
    end
end

-- Cooldowns of one character as a sorted list of { id, name, readyAt, left }.
function Cooldowns.List(c, now)
    local list = {}
    for id, cd in pairs(c.cooldowns or {}) do
        list[#list + 1] = { id = id, name = cd.name, readyAt = cd.readyAt, left = math.max(0, cd.readyAt - now), alert = cd.alert }
    end
    table.sort(list, function(a, b)
        if a.left ~= b.left then return a.left < b.left end
        return a.name < b.name
    end)
    return list
end

local pending
local function ReadSoon()
    if pending then return end
    pending = true
    C_Timer.After(1, function()
        pending = false
        local c = ns.Me()
        if c then
            Cooldowns.Read(c)
            ns.Fire("NW_REFRESH")
        end
    end)
end

-- Read at login and as things change during play, not at logout: while the character leaves the
-- world the game can report nothing, which would wipe good data.
ns.On("NW_CHARACTER_SAVED", function(c, reason)
    if reason == "login" then Cooldowns.Read(c) end
end)
for _, event in ipairs({ "SPELL_UPDATE_COOLDOWN", "BAG_UPDATE_COOLDOWN", "PLAYER_REGEN_ENABLED",
    "LEARNED_SPELL_IN_SKILL_LINE", "BAG_UPDATE_DELAYED", "UNIT_AURA" }) do
    ns.On(event, ReadSoon)
end
