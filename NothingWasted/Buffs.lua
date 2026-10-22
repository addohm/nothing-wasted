-- Nothing Wasted: reminders for the leveling buffs, below max level.
--
-- Well Fed XP Boost (+5% kill XP from cooked food) and the Cozy Sleeping Bag's Well-Rested (up to
-- +3% XP). A missing buff is mentioned as a chat line when you leave an inn or city, and when it
-- wears off while you're out in the world. At logout, a ready sleeping bag is pointed out: resting
-- in it first carries the buff into the next session.
local _, ns = ...
local L = ns.L

local Buffs = {}
ns.Buffs = Buffs

local function HasAura(spellID)
    return C_UnitAuras.GetPlayerAuraBySpellID(spellID) ~= nil
end

-- Where the sleeping bag is: count in bags, count in the bank, and whether it's a toy.
local function BagWhere()
    local itemID = ns.Data.sleepingBag.itemID
    local carried = C_Item.GetItemCount(itemID) or 0
    local total = C_Item.GetItemCount(itemID, true) or 0
    local toy = PlayerHasToy and PlayerHasToy(itemID) or false
    return carried, total - carried, toy
end

-- Seconds until the bag is off cooldown (0 when ready).
local function BagCooldown()
    local start, duration = C_Container.GetItemCooldown(ns.Data.sleepingBag.itemID)
    if not start or start == 0 or not duration or duration == 0 then return 0 end
    return math.max(0, start + duration - GetTime())
end

-- True if the bag can be used now: in your bags (or a toy) and off cooldown. A bag in the bank
-- can't be used.
function Buffs.BagReady()
    local carried, _, toy = BagWhere()
    return (carried > 0 or toy) and BagCooldown() == 0
end

local YELLOW = "|cffffd100"

-- Shows buff reminders on the reminder card (kinds: "wellFed", "bag", "bagLogout"), with one sound
-- and one screen-edge flash for the batch, and optionally as yellow chat lines too.
local CHAT = {
    wellFed = "Not Well Fed: eat cooked food for +5% XP from kills.",
    bag = "Your Cozy Sleeping Bag is ready: rest in it for up to +3% XP.",
    bagLogout = "Your Cozy Sleeping Bag is ready: rest in it before logging out to keep up to +3% XP for your next session.",
}
local function Remind(kinds)
    if #kinds == 0 then return end
    local settings = ns.db.settings.alerts
    ns.Reminder.Show(kinds)
    if settings.buffChat then
        for _, k in ipairs(kinds) do ns.Print(YELLOW .. L[CHAT[k]] .. "|r") end
    end
    if settings.buffSound then ns.Alerts.PlaySound("buff") end
    if settings.buffGlow then ns.Glow.Pulse() end
end

local function BelowMax()
    local c = ns.Me()
    return c and not c.isMax and not c.xpDisabled
end

-- State between checks. nil until the first check after login, which only records the baseline.
local wasResting, hadWellFed, hadBagBuff

function Buffs.Check()
    -- Auras can be secret in combat; the check runs again when combat ends, transitions intact.
    if InCombatLockdown() or not BelowMax() then return end
    local settings = ns.db.settings.alerts
    local resting = IsResting() and true or false
    local leftRest = wasResting == true and not resting
    local wellFed = HasAura(ns.Data.wellFedXPSpellID)
    local bagBuff = HasAura(ns.Data.sleepingBag.buffSpellID)

    -- What's missing right now, and what just became worth a reminder.
    local missing = {
        wellFed = not resting and settings.wellFed and not wellFed,
        bag = not resting and settings.bagBuff and not bagBuff and Buffs.BagReady(),
    }
    missing.bagLogout = missing.bag
    if resting then
        ns.Reminder.Hide()
    else
        ns.Reminder.Keep(missing)
        -- Leaving rest, or a buff wearing off, brings up the card with everything that's missing.
        local trigger = (missing.wellFed and (leftRest or hadWellFed)) or (missing.bag and (leftRest or hadBagBuff))
        if trigger then
            local kinds = {}
            if missing.wellFed then kinds[#kinds + 1] = "wellFed" end
            if missing.bag then kinds[#kinds + 1] = "bag" end
            Remind(kinds)
        end
    end
    wasResting, hadWellFed, hadBagBuff = resting, wellFed, bagBuff
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
    if isInitialLogin or isReload then
        wasResting, hadWellFed, hadBagBuff = nil, nil, nil
    end
    C_Timer.After(5, Buffs.Check)
end)
ns.On("UNIT_AURA", function(unit) if unit == "player" then CheckSoon() end end)
ns.On("PLAYER_REGEN_ENABLED", CheckSoon)
-- Leaving rest is checked right away, so the reminder appears as the bars window closes.
ns.On("PLAYER_UPDATE_RESTING", function() Buffs.Check() end)

-- Logging out with a ready sleeping bag and no Well-Rested buff.
ns.On("PLAYER_CAMPING", function()
    if not ns.db.settings.alerts.bagLogout or not BelowMax() or IsResting() then return end
    if Buffs.BagReady() and not HasAura(ns.Data.sleepingBag.buffSpellID) then
        Remind({ "bagLogout" })
    end
end)

-- What the reminders see right now: /nw buffs
function Buffs.Report()
    local function YesNo(v) return v and L["yes"] or L["no"] end
    local carried, banked, toy = BagWhere()
    local cd = BagCooldown()
    ns.Print(format(L["Below max level: %s. Resting: %s. In combat: %s."], YesNo(BelowMax()),
        YesNo(IsResting()), YesNo(InCombatLockdown())))
    ns.Print(format(L["Well Fed XP Boost (%d): %s."], ns.Data.wellFedXPSpellID, YesNo(HasAura(ns.Data.wellFedXPSpellID))))
    ns.Print(format(L["Cozy Sleeping Bag (%d): %d in bags, %d in the bank, toy: %s, cooldown: %s."],
        ns.Data.sleepingBag.itemID, carried, banked, YesNo(toy), cd > 0 and ns.FormatDuration(cd) or L["ready"]))
    ns.Print(format(L["Well-Rested buff (%d): %s. Bag reminder possible now: %s."], ns.Data.sleepingBag.buffSpellID,
        YesNo(HasAura(ns.Data.sleepingBag.buffSpellID)),
        YesNo(Buffs.BagReady() and not IsResting() and not HasAura(ns.Data.sleepingBag.buffSpellID))))
end
