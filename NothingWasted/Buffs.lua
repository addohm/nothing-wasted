-- Nothing Wasted: reminders for the leveling buffs, below max level.
--
-- Well Fed XP Boost (+5% kill XP from cooked food) and the Cozy Sleeping Bag's Well-Rested (up to
-- +3% XP). A missing buff is mentioned once after login and again each time it wears off, as a
-- chat line. At logout, a ready sleeping bag is pointed out: resting in it first carries the buff
-- into the next session.
local _, ns = ...
local L = ns.L

local Buffs = {}
ns.Buffs = Buffs

local function HasAura(spellID)
    return C_UnitAuras.GetPlayerAuraBySpellID(spellID) ~= nil
end

-- True if the character carries the sleeping bag and it's off cooldown.
function Buffs.BagReady()
    local itemID = ns.Data.sleepingBag.itemID
    if (C_Item.GetItemCount(itemID) or 0) == 0 then return false end
    local start, duration = C_Container.GetItemCooldown(itemID)
    if not start or start == 0 or not duration or duration == 0 then return true end
    return start + duration - GetTime() <= 0
end

local function BelowMax()
    local c = ns.Me()
    return c and not c.isMax and not c.xpDisabled
end

-- State between checks: whether each buff was on last time, and the once-after-login reminders.
local hadWellFed, hadBagBuff
local loginWellFed, loginBag = false, false

function Buffs.Check()
    -- Auras can be secret in combat; the check runs again when combat ends.
    if InCombatLockdown() or not BelowMax() then return end
    local settings = ns.db.settings.alerts

    local wellFed = HasAura(ns.Data.wellFedXPSpellID)
    if not wellFed and settings.wellFed and (loginWellFed or hadWellFed) then
        ns.Print(L["Not Well Fed: eat cooked food for +5% XP from kills."])
    end
    loginWellFed = false
    hadWellFed = wellFed

    local bagBuff = HasAura(ns.Data.sleepingBag.buffSpellID)
    -- The bag can't be used in inns and cities, so the login reminder waits until you're out.
    local usable = Buffs.BagReady() and not IsResting()
    if not bagBuff and usable and settings.bagBuff and (loginBag or hadBagBuff) then
        ns.Print(L["Your Cozy Sleeping Bag is ready: rest in it for up to +3% XP."])
    end
    if bagBuff or usable then loginBag = false end
    hadBagBuff = bagBuff
end

local pending
local function CheckSoon()
    if pending then return end
    pending = true
    C_Timer.After(1, function()
        pending = false
        Buffs.Check()
    end)
end

ns.On("PLAYER_ENTERING_WORLD", function(isInitialLogin, isReload)
    if not isInitialLogin and not isReload then return end
    loginWellFed, loginBag = true, true
    hadWellFed, hadBagBuff = nil, nil
    -- After the login chat settles, like the other alerts.
    C_Timer.After(10, Buffs.Check)
end)
ns.On("UNIT_AURA", function(unit) if unit == "player" then CheckSoon() end end)
ns.On("PLAYER_REGEN_ENABLED", CheckSoon)
ns.On("PLAYER_UPDATE_RESTING", CheckSoon)

-- Logging out with a ready sleeping bag and no Well-Rested buff.
ns.On("PLAYER_CAMPING", function()
    if not ns.db.settings.alerts.bagLogout or not BelowMax() or IsResting() then return end
    if Buffs.BagReady() and not HasAura(ns.Data.sleepingBag.buffSpellID) then
        ns.Print(L["Your Cozy Sleeping Bag is ready: rest in it before logging out to keep up to +3% XP for your next session."])
    end
end)
