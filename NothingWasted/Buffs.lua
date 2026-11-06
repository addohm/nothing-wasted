-- Nothing Wasted: reminders for the leveling buffs, below max level.
--
-- Well Fed (+5% kill XP from cooked food) and the Cozy Sleeping Bag's Well-Rested (up to
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

-- The spell ID of the player's Well Fed buff, or nil. Foods use different Well Fed spells, so this
-- goes by the name. Returns nil when the names are secret (in combat).
local function WellFedName()
    return C_Spell.GetSpellName(ns.Data.wellFedSpellID) or L["Well Fed"]
end

local function WellFedSpell()
    local name = WellFedName()
    for i = 1, 255 do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not aura or (issecretvalue and issecretvalue(aura.name)) then return nil end
        if aura.name == name then return aura.spellId end
    end
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

-- What clicking the sleeping bag icon does: use the bag from your bags, or the toy. nil if neither.
function Buffs.BagAction()
    local carried, _, toy = BagWhere()
    local itemID = ns.Data.sleepingBag.itemID
    if carried > 0 then return { type = "item", item = "item:" .. itemID } end
    if toy then return { type = "toy", toy = itemID } end
end

-- Food in your bags that gives Well Fed: a consumable whose tooltip mentions Well Fed by name.
local FOOD_BAGS = { 0, 1, 2, 3, 4 }
local CONSUMABLE = 0       -- Enum.ItemClass.Consumable
local foodCache = {}       -- [itemID] = whether it gives Well Fed
local lastFoodID, lastFoodName

local function GivesWellFed(bag, slot, itemID)
    if foodCache[itemID] ~= nil then return foodCache[itemID] end
    local classID = select(6, C_Item.GetItemInfoInstant(itemID))
    if classID ~= CONSUMABLE then
        foodCache[itemID] = false
        return false
    end
    local data = C_TooltipInfo.GetBagItem(bag, slot)
    local lines = data and data.lines
    if not lines or #lines == 0 then return false end -- not loaded yet; try again next time
    local name = WellFedName()
    local lower = name:lower()
    local yes = false
    for _, line in ipairs(lines) do
        local text = line.leftText
        if type(text) == "string" and not (issecretvalue and issecretvalue(text))
            and (text:find(name, 1, true) or text:lower():find(lower, 1, true)) then
            yes = true
            break
        end
    end
    foodCache[itemID] = yes
    return yes
end

-- The item ID and name of a food in your bags that gives Well Fed, or nil. In combat, the last answer.
function Buffs.WellFedFood()
    if InCombatLockdown() then return lastFoodID, lastFoodName end
    lastFoodID, lastFoodName = nil, nil
    for _, bag in ipairs(FOOD_BAGS) do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID and GivesWellFed(bag, slot, info.itemID) then
                lastFoodID, lastFoodName = info.itemID, info.itemName
                return lastFoodID, lastFoodName
            end
        end
    end
end

-- True if the bag can be used now: in your bags (or a toy) and off cooldown. A bag in the bank
-- can't be used.
function Buffs.BagReady()
    local carried, _, toy = BagWhere()
    return (carried > 0 or toy) and BagCooldown() == 0
end

local YELLOW = "|cffffd100"

-- Shows buff reminders on the reminder card (kinds: "wellFed", "bag", "bagLogout"), with one sound
-- and one screen-edge flash for the batch, and optionally as yellow chat lines, large text and a
-- flash of the game's taskbar icon too.
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
    if settings.buffBigText then ns.Reminder.BigText(kinds) end
    if settings.buffFlash and FlashClientIcon then FlashClientIcon() end
end

-- While the icons are up: the steady screen border and the repeated sound. With "build up" on,
-- both wait until the icons have been up a while; the repeated sound then plays at once.
local nextSoundAt
local function UpdateAttention()
    local s = ns.db.settings.alerts
    local since = ns.Reminder.ShownSince()
    if not since then
        ns.Glow.SetSteady(false)
        return
    end
    local now = GetTime()
    local wait = s.buffEscalate and s.buffEscalateMinutes * 60 or 0
    local ready = now - since >= wait
    ns.Glow.SetSteady(s.buffBorder and ready, s.buffBorderColor, s.buffBorderStrength)
    if s.buffRepeat and ready then
        nextSoundAt = nextSoundAt or (since + (wait > 0 and wait or s.buffRepeatMinutes * 60))
        if now >= nextSoundAt then
            ns.Alerts.PlaySound("buff")
            nextSoundAt = now + s.buffRepeatMinutes * 60
        end
    end
end
ns.On("NW_REMINDER", function()
    nextSoundAt = nil
    UpdateAttention()
end)
ns.On("NW_REFRESH", function()
    UpdateAttention()
    ns.Reminder.Refresh()
end)
ns.On("NW_INIT", function()
    C_Timer.NewTicker(5, function()
        UpdateAttention()
        ns.Reminder.SyncActions() -- the bars window may have been moved
    end)
end)
ns.On("BAG_UPDATE_DELAYED", function() ns.Reminder.Refresh() end)

-- The Test button: everything that's turned on, with the border for a few seconds.
function Buffs.Preview()
    local s = ns.db.settings.alerts
    ns.Alerts.PlaySound("buff")
    if s.buffGlow then ns.Glow.Pulse() end
    if s.buffBigText then ns.Reminder.BigText({ "wellFed" }) end
    if s.buffFlash and FlashClientIcon then FlashClientIcon() end
    if s.buffBorder then
        ns.Glow.SetSteady(true, s.buffBorderColor, s.buffBorderStrength)
        C_Timer.After(5, UpdateAttention)
    end
end

local function BelowMax()
    local c = ns.Me()
    return ns.IsTracked(c) and not c.isMax and not c.xpDisabled
end

-- State between checks. nil until the first check after login or a reload: that one reminds only
-- if you're out in the world (and that's turned on), then sets the baseline.
local wasResting, hadWellFed, hadBagBuff

-- Kill XP and what Well Fed would have added to it. Kill XP is worked out as XP gained minus quest
-- rewards (QUEST_TURNED_IN), so it's rough: exploration XP counts as kills too.
local KILL_NUDGE_SECONDS = 300 -- a kill brings the icons back at most this often
local missedXP = 0             -- Well Fed's share of the kill XP gained without it, since it was last on
local killedSinceCheck = false
local lastKillNudge
local lastXP, lastXPMax, lastLevel
local gainedXP, questXP = 0, 0
local CheckSoon

-- About how much XP Well Fed would have added since it was last on (this session).
function Buffs.MissedXP()
    return missedXP
end

local function OnKillXP(xp)
    if not BelowMax() then return end
    killedSinceCheck = true
    if hadWellFed == false then
        missedXP = missedXP + xp * ns.Data.wellFedXPBonus
        ns.Reminder.Refresh()
    end
    CheckSoon()
end

local function FlushXP()
    local kill = gainedXP - questXP
    gainedXP, questXP = 0, 0
    if kill > 0 then OnKillXP(kill) end
end

local function AddXP(xp, quest)
    if gainedXP == 0 and questXP == 0 then C_Timer.After(1, FlushXP) end
    if xp then gainedXP = gainedXP + xp end
    if quest then questXP = questXP + quest end
end

ns.On("PLAYER_XP_UPDATE", function(unit)
    if unit and unit ~= "player" then return end
    local xp, xpMax, level = UnitXP("player"), UnitXPMax("player"), UnitLevel("player")
    if issecretvalue and (issecretvalue(xp) or issecretvalue(xpMax)) then return end
    if lastXP then
        local gained
        if level == lastLevel then
            gained = xp - lastXP
        elseif level > lastLevel then
            gained = (lastXPMax - lastXP) + xp
        end
        if gained and gained > 0 then AddXP(gained) end
    end
    lastXP, lastXPMax, lastLevel = xp, xpMax, level
end)
ns.On("QUEST_TURNED_IN", function(_, xpReward)
    if type(xpReward) == "number" and xpReward > 0 then AddXP(nil, xpReward) end
end)

function Buffs.Check()
    -- Auras can be secret in combat; the check runs again when combat ends, transitions intact.
    if InCombatLockdown() or not BelowMax() then return end
    local settings = ns.db.settings.alerts
    local resting = IsResting() and true or false
    local leftRest = wasResting == true and not resting
    -- The first check after logging in or a reload, out in the world, counts as leaving rest.
    local firstOut = wasResting == nil and not resting and settings.buffAtLogin
    local wellFed = WellFedSpell() ~= nil
    local bagBuff = HasAura(ns.Data.sleepingBag.buffSpellID)
    local killed = killedSinceCheck
    killedSinceCheck = false

    -- Fed again: say what going without cost.
    if wellFed then
        if hadWellFed == false and missedXP >= 1 and settings.buffMissedXP then
            ns.Print(YELLOW .. format(L["Well Fed again. Without it you missed about %s XP."], ns.FormatNumber(missedXP)) .. "|r")
        end
        missedXP = 0
    end

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
        local trigger = (missing.wellFed and (leftRest or firstOut or hadWellFed))
            or (missing.bag and (leftRest or firstOut or hadBagBuff))
        -- A kill without a buff brings the icons back if they were dismissed, now and then.
        if not trigger and killed and settings.buffOnKill and (missing.wellFed or missing.bag)
            and not ns.Reminder.IsShown()
            and (not lastKillNudge or GetTime() - lastKillNudge >= KILL_NUDGE_SECONDS) then
            trigger = true
            lastKillNudge = GetTime()
        end
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
function CheckSoon()
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
    lastXP, lastXPMax, lastLevel = UnitXP("player"), UnitXPMax("player"), UnitLevel("player")
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
    local wellFedSpell = WellFedSpell()
    ns.Print(wellFedSpell and format(L["Well Fed: yes (spell %d)."], wellFedSpell) or L["Well Fed: no."])
    ns.Print(format(L["Cozy Sleeping Bag (%d): %d in bags, %d in the bank, toy: %s, cooldown: %s."],
        ns.Data.sleepingBag.itemID, carried, banked, YesNo(toy), cd > 0 and ns.FormatDuration(cd) or L["ready"]))
    ns.Print(format(L["Well-Rested buff (%d): %s. Bag reminder possible now: %s."], ns.Data.sleepingBag.buffSpellID,
        YesNo(HasAura(ns.Data.sleepingBag.buffSpellID)),
        YesNo(Buffs.BagReady() and not IsResting() and not HasAura(ns.Data.sleepingBag.buffSpellID))))
    local _, food = Buffs.WellFedFood()
    ns.Print(food and format(L["Food that gives Well Fed in your bags: %s."], food) or L["Food that gives Well Fed in your bags: none found."])
end
