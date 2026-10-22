-- Headless scenarios for Nothing Wasted. Returns a function(root) -> passed, failed.
local mock = require("wowmock")

local HOUR, DAY = 3600, 86400
local T0 = mock.T0

local passed, failed = 0, 0
local current

local function check(cond, msg)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        print("  FAIL [" .. current .. "] " .. msg)
    end
end

local function eq(a, b, msg)
    check(a == b, msg .. " (expected " .. tostring(b) .. ", got " .. tostring(a) .. ")")
end

local function near(a, b, tol, msg)
    check(type(a) == "number" and math.abs(a - b) <= tol, msg .. " (expected ~" .. tostring(b) .. ", got " .. tostring(a) .. ")")
end

local function test(name, fn)
    current = name
    print(name)
    local ok, err = pcall(fn)
    if not ok then
        failed = failed + 1
        print("  ERROR [" .. name .. "] " .. tostring(err))
    end
end

local function RowTexts(client, panel)
    local out = {}
    for _, row in ipairs(client:Rows(panel)) do
        local t = (row.name and row.name.text) or (row.left and row.left.text) or ""
        out[#out + 1] = t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    end
    return out
end

local function TabPanel(client)
    return client.ns.Window.CurrentPanel()
end

local MAXI = { name = "Maxi", class = "WARRIOR", className = "Warrior", level = 60, xp = 0, xpMax = 0, resting = false }
local KYOL = { name = "Kyol", level = 20, xp = 1000, xpMax = 10000, rested = 2000, resting = true }

return function(root)
    local db1, db2, db3

    test("1. fresh install on a max-level character", function()
        local c = mock.NewClient({ root = root, player = MAXI })
        c:Login()
        check(c:ChatHas("type /nw"), "first-run hint printed")
        local db = rawget(c.env, "NothingWastedDB")
        local maxi = db.chars["Maxi-Forever"]
        check(maxi and maxi.isMax, "Maxi saved as max level")
        check(c:Frame("NothingWastedFrame") == nil, "window not built before it's needed")
        c:Slash("")
        local frame = c:Frame("NothingWastedFrame")
        check(frame and frame.shown, "/nw opens the window")
        local panel = TabPanel(c)
        eq(#c:Rows(panel), 0, "max-level characters hidden by default")
        db.settings.bars.showMax = true
        c.ns.Window.Refresh()
        local rows = c:Rows(panel)
        eq(#rows, 1, "max-level character shown when enabled")
        check(rows[1] and rows[1].time.text == "Max level", "row says Max level")
        local tip = c:Hover(rows[1])
        check(tip:Has("Level 60"), "tooltip shows the level")
        c:Slash("")
        check(not frame.shown, "/nw again hides the window")
        check(c:ChatHas("v1%.0%.0") == false, "no help yet")
        c:Slash("help")
        check(c:ChatHas("v1%.0%.0"), "help prints the version")
        db.settings.bars.showMax = false
        db1 = c:Logout()
    end)

    test("1b. every character that logged in gets a bar", function()
        local a = mock.NewClient({ root = root, player = { name = "Alpha", level = 10, xp = 200, xpMax = 5000, rested = 100, resting = true } })
        a.player.professions = { { name = "Tailoring", rank = 120, max = 150, skillLine = 197 } }
        a.player.bagSlots = { { 2589, 7, "Linen Cloth" } }
        a.player.perks[1225478] = 3
        a:Login()
        -- While leaving the world the game may report no data at all; the good values must survive.
        a.player.xpMax, a.player.xp, a.player.rested, a.player.zone = 0, 0, 0, ""
        a.player.professions, a.player.bagSlots, a.player.perks = {}, {}, {}
        local db = a:Logout()
        local alpha = db.chars["Alpha-Forever"]
        eq(alpha.xpMax, 5000, "logout with no XP data keeps the last good max XP")
        eq(alpha.rested, 100, "and the rested XP")
        eq(alpha.zone, "Elwynn Forest", "and the zone")
        eq(alpha.professions and #alpha.professions, 1, "and the professions")
        eq(alpha.bags and alpha.bags[2589], 7, "and the bags")
        eq(alpha.wellRested, 3, "and the Well Rested rank")

        local b = mock.NewClient({ root = root, db = db, now = T0 + HOUR, player = { name = "Beta", level = 12, xp = 0, xpMax = 6000, resting = true } })
        b:Login()
        local texts = RowTexts(b, b.ns.Meter.Frame())
        eq(#texts, 2, "both characters have a bar")
        local hasAlpha, alphaRow = false, nil
        for i, t in ipairs(texts) do
            if t:find("Alpha") then hasAlpha, alphaRow = true, b:Rows(b.ns.Meter.Frame())[i] end
        end
        check(hasAlpha, "the other character is listed")
        local tip = alphaRow and b:Hover(alphaRow)
        check(tip and tip:Has("Tailoring"), "the other character's tooltip shows its professions")

        -- /nw chars says where the loaded data came from.
        b:ClearChat()
        b:Slash("chars")
        check(b:ChatHas("saved by Alpha%-Forever"), "/nw chars names the session that saved the data")

        -- A secret value somewhere in the data is removed before saving, so the save can't fail.
        rawget(b.env, "NothingWastedDB").chars["Beta-Forever"].legacyProgress = { [1] = { name = mock.Secret("A challenge") } }
        local saved = b:Logout()
        check(saved.chars["Beta-Forever"].legacyProgress[1].name == nil, "secret values are removed before saving")
        eq(saved.lastSave and saved.lastSave.secretsRemoved, 1, "and counted")
        eq(saved.lastSave.by, "Beta-Forever", "the save records who wrote it")

        -- A character with no XP data at all still gets a bar.
        rawget(b.env, "NothingWastedDB").chars["Gamma-Forever"] = { name = "Gamma", realm = "Forever", level = 5 }
        b.ns.Meter.Refresh()
        eq(#b:Rows(b.ns.Meter.Frame()), 3, "a character without XP data still gets a bar")
        b:ClearChat()
        b:Slash("chars")
        check(b:ChatHas("3 saved character"), "/nw chars lists them")
        check(b:ChatHas("Gamma%-Forever.-no XP data yet"), "and says why a bar is empty")
    end)

    test("1c. leveling buff reminders", function()
        local c = mock.NewClient({ root = root, player = {
            name = "Buffy", level = 20, xp = 0, xpMax = 10000, resting = true, items = { [211527] = 1 },
        } })
        c:Login()
        c:Advance(6)
        local R = c.ns.Reminder
        local function Card() return table.concat(R.Kinds(), ",") end
        check(not R.IsShown(), "no reminder card at login")
        local meter = c.ns.Meter.Frame()
        check(meter and meter.shown, "bars window up in town")

        -- Leaving the city: the bars window goes, the card takes its place.
        c.player.resting = false
        c:Fire("PLAYER_UPDATE_RESTING")
        check(not meter.shown, "bars window hides on leaving rest")
        check(R.IsShown(), "the reminder shows at the same moment, no gap")
        c:Advance(2)
        eq(Card(), "wellFed,bag", "with both missing buffs")
        -- The labels mustn't overlap: each icon's slot is as wide as its label.
        local icons = {}
        for _, f in ipairs(c.frames) do
            if f.kind == "Button" and f.label and f.icon and f:IsVisible() then icons[#icons + 1] = f end
        end
        eq(#icons, 2, "two icons")
        if #icons == 2 then
            local x1, x2 = icons[1].points[1][2], icons[2].points[1][2]
            local w1 = icons[1].label:GetStringWidth()
            check(x2 - x1 >= (w1 + 38) / 2 + 14 - 1, "the second icon clears the first label")
        end
        eq(c.sounds[1], 8959, "with the alert sound")
        check(c.ns.Glow.IsPulsing(), "and the screen-edge flash")
        check(not c:ChatHas("Not Well Fed"), "no chat lines by default")

        -- Rows go as the buffs come.
        c.player.auras[1243969] = 99999
        c:Fire("UNIT_AURA", "player")
        c:Advance(2)
        eq(Card(), "bag", "eating removes the Well Fed row")
        c.player.auras[429959] = 99999
        c:Fire("UNIT_AURA", "player")
        c:Advance(2)
        check(not R.IsShown(), "the card hides when nothing's missing")

        -- The food wears off out in the world: the card comes back with just that.
        c.sounds = {}
        c.player.auras[1243969] = nil
        c:Fire("UNIT_AURA", "player")
        c:Advance(2)
        eq(Card(), "wellFed", "card when Well Fed wears off out in the world")
        eq(#c.sounds, 1, "one sound")

        -- Back in town the card goes; a buff wearing off there waits until you leave.
        c.player.resting = true
        c:Fire("PLAYER_UPDATE_RESTING")
        c:Advance(2)
        check(not R.IsShown(), "card hides in a rested area")
        c.player.resting = false
        c:Fire("PLAYER_UPDATE_RESTING")
        c:Advance(2)
        eq(Card(), "wellFed", "and shows again on leaving")

        -- Chat lines can be turned on.
        rawget(c.env, "NothingWastedDB").settings.alerts.buffChat = true
        c.player.resting = true
        c:Fire("PLAYER_UPDATE_RESTING")
        c:Advance(2)
        c.player.resting = false
        c:Fire("PLAYER_UPDATE_RESTING")
        c:Advance(2)
        check(c:ChatHas("|cffffd100Not Well Fed"), "yellow chat line when turned on")

        -- Logging out with a ready bag and no bag buff.
        c.player.auras[429959] = nil
        c:Fire("UNIT_AURA", "player")
        c:Advance(2)
        R.Hide()
        c:Fire("PLAYER_CAMPING")
        eq(Card(), "bagLogout", "logout reminder card for a ready sleeping bag")
        R.Hide()
        c.player.itemCooldowns[211527] = { c.env.GetTime(), 3600 }
        c:Fire("PLAYER_CAMPING")
        check(not R.IsShown(), "no logout reminder while the bag is on cooldown")

        -- /nw buffs shows where the bag is.
        c.player.itemCooldowns[211527] = nil
        c.player.items[211527] = nil
        c.player.bankItems = { [211527] = 1 }
        c:ClearChat()
        c:Slash("buffs")
        check(c:ChatHas("0 in bags, 1 in the bank"), "/nw buffs shows a banked bag")
        check(c:ChatHas("Bag reminder possible now: no"), "a banked bag can't be reminded about")
        c.player.toys = { [211527] = true }
        c:ClearChat()
        c:Slash("buffs")
        check(c:ChatHas("Bag reminder possible now: yes"), "a sleeping bag toy counts as carried")

        -- Custom sounds: the reminders can use any sound kit or sound file ID.
        local alerts = rawget(c.env, "NothingWastedDB").settings.alerts
        alerts.buffSoundName, alerts.buffCustomSound = "CUSTOM", "file:567890"
        c:ClearChat()
        c.ns.Alerts.PlaySound("buff")
        eq(c.sounds[1], "file:567890", "a sound file ID")
        alerts.buffCustomSound = " 12345 "
        c.ns.Alerts.PlaySound("buff")
        eq(c.sounds[2], 12345, "a sound kit ID")
        c.ns.Alerts.PlaySound()
        eq(c.sounds[3], 8959, "the alert sound stays raid warning")
        alerts.buffCustomSound = "nonsense"
        c.ns.Alerts.PlaySound("buff")
        eq(c.sounds[4], 8959, "an unusable ID falls back to raid warning")
        alerts.buffSoundName = "FAREWELL"
        for _ = 1, 20 do c.ns.Alerts.PlaySound("buff") end
        local seen = {}
        for i = 5, #c.sounds do seen[c.sounds[i]] = true end
        local kinds = 0
        for id in pairs(seen) do
            check(id == "file:552199" or id == "file:552209" or id == "file:552208" or id == "file:552205", "farewell plays one of the four lines")
            kinds = kinds + 1
        end
        check(kinds > 1, "and picks at random")
        alerts.buffSoundName, alerts.buffCustomSound = "CUSTOM", "file:1, file:2"
        c.ns.Alerts.PlaySound("buff")
        local last = c.sounds[#c.sounds]
        check(last == "file:1" or last == "file:2", "comma-separated custom IDs pick one at random")
        alerts.buffSoundName, alerts.buffCustomSound = "SAME", ""

        -- Max level: none of it.
        local m = mock.NewClient({ root = root, player = { name = "Maxi", level = 60, xpMax = 0, items = { [211527] = 1 } } })
        m:Login()
        m.player.resting = false
        m:Fire("PLAYER_UPDATE_RESTING")
        m:Advance(2)
        m:Fire("PLAYER_CAMPING")
        check(not m:ChatHas("Well Fed") and not m:ChatHas("Sleeping Bag"), "no buff reminders at max level")
    end)

    test("1d. measuring rested rates", function()
        local c = mock.NewClient({ root = root, player = { name = "Rater", level = 27, xp = 19455, xpMax = 38900, rested = 6958, resting = true } })
        c:Login()
        c:ClearChat()
        c:Slash("rate")
        check(c:ChatHas("rested 6,958"), "/nw rate shows the live rested XP")
        check(c:ChatHas("Expected: 5%.00%% of a level per 8h resting %(%+243 per hour%)"), "and the expected rate")
        check(c:ChatHas("Mark set at %d%d:%d%d:%d%d with rested 6,958"), "first run sets a mark and shows its time")
        c:ClearChat()
        c.now = c.now + 3600
        c.player.rested = 6958 + 243
        c:Slash("rate")
        check(c:ChatHas("Since the mark at %d%d:%d%d:%d%d %(1h 0m ago, rested 6,958 then%): rested %+243 = 5%.00%% of a level per 8h"), "second run measures the rate since the mark")
        check(not c:ChatHas("isn't a clean"), "clean when XP didn't change")
        c.player.xp = 20000
        c:ClearChat()
        c:Slash("rate")
        check(c:ChatHas("isn't a clean measurement"), "flags XP gained since the mark")
        c.player.xp = 19455

        -- A login check: logged out 8h in an inn, came back with 5% of a level more.
        local db = c:Logout()
        local saved = db.chars["Rater-Forever"]
        local d = mock.NewClient({ root = root, db = db, now = c.now + 8 * HOUR,
            player = { name = "Rater", level = 27, xp = 19455, xpMax = 38900, rested = saved.rested + 1945, resting = true } })
        d:Login()
        local sample = rawget(d.env, "NothingWastedDB").rateSamples[1]
        check(sample ~= nil, "a login check is recorded")
        near(sample and sample.rate, 5.0, 0.01, "measured 5% per 8h")
        near(sample and sample.expectedRate, 5.0, 0.01, "against an expected 5%")
        d:ClearChat()
        d:Slash("rate")
        check(d:ChatHas("Checks at login"), "/nw rate lists the login checks")
    end)

    test("2. rested estimates, alerts and the logout warning", function()
        local db = mock.Copy(db1)
        local now = T0 + 2 * HOUR
        db.chars["Oldie-Forever"] = {
            name = "Oldie", realm = "Forever", class = "PRIEST", className = "Priest", level = 30,
            xp = 0, xpMax = 20000, rested = 0, resting = true, savedAt = now - 8 * HOUR,
        }
        local c = mock.NewClient({ root = root, db = db, now = now, player = KYOL })
        c:Login()
        check(not c:ChatHas("type /nw"), "no first-run hint on later logins")
        check(c:Frame("NothingWastedFrame") == nil, "the full window doesn't pop up by itself")
        local frame = c.ns.Meter.Frame()
        check(frame and frame.shown, "the bars window pops up when logging in somewhere resting")
        local texts = RowTexts(c, frame)
        eq(#texts, 2, "two characters that can rest")
        check(texts[1] and texts[1]:find("Kyol"), "Kyol first (caps sooner)")
        check(texts[2] and texts[2]:find("Oldie"), "Oldie second")

        local ns = c.ns
        local oldie = rawget(c.env, "NothingWastedDB").chars["Oldie-Forever"]
        local rested, cap, toCap = ns.Rested.Estimate(oldie, c.now)
        near(rested, 1000 + 20000 * 0.05 / 28800 * 6, 1, "Oldie built 5% of a level in 8h at an inn")
        eq(cap, 30000, "Oldie's cap is 150% of a level")
        near(toCap, 835200 - 6, 2, "Oldie caps in 9d 16h")
        local kyol = rawget(c.env, "NothingWastedDB").chars["Kyol-Forever"]
        local _, kcap, ktoCap = ns.Rested.Estimate(kyol, kyol.savedAt)
        eq(kcap, 15000, "Kyol's cap")
        near(ktoCap, 748800, 1, "Kyol caps in 8d 16h")
        eq(ns.FormatDuration(748800), "8d 16h", "duration format")

        -- Early warning an hour before Oldie caps.
        c:ClearChat()
        c:Advance(toCap - HOUR)
        check(c:ChatHas("Oldie.-reaches the rested XP cap in"), "early warning before the cap")
        check(not c:ChatHas("Kyol"), "no alerts for the character being played")
        eq(c.sounds[1], 8959, "raid warning sound by default")

        c:ClearChat()
        c:Advance(2 * HOUR)
        check(c:ChatHas("Oldie.-has hit the rested XP cap"), "cap alert the moment Oldie caps")
        eq(#c.sounds, 1, "one sound for the alert")
        c:ClearChat()
        c:Advance(60)
        check(not c:ChatHas("has hit"), "the cap alert fires once per session")

        -- Logout warning.
        c:ClearChat()
        c:Fire("PLAYER_CAMPING")
        check(not c:ChatHas("isn't resting"), "no warning when logging out resting")
        c.player.resting = false
        c:Fire("PLAYER_CAMPING")
        check(c:ChatHas("isn't resting"), "warning when logging out away from rest")

        -- Spending a Well Rested point mid-session is picked up right away.
        c.player.perks[1225478] = 5
        c:Fire("TRAIT_CONFIG_UPDATED", 10188)
        c:Advance(2)
        eq(kyol.wellRested, 5, "Well Rested rank read when perks change")
        local _, wcap, wtoCap = ns.Rested.Estimate({ xpMax = 10000, rested = 2000, resting = true, wellRested = 5, savedAt = 0 }, 0)
        eq(wcap, 18000, "rank 5 raises the cap by 20%")
        near(wtoCap, 768000, 1, "rank 5 builds rested XP 20% faster")

        -- Hovering a bar shows the character tooltip.
        local tip = c:Hover(c:Rows(frame)[2])
        check(tip:Has("Time to cap"), "bar tooltip shows the time to cap")

        -- Leaving the inn hides a bars window that popped up by itself.
        c:Fire("PLAYER_UPDATE_RESTING")
        check(not frame.shown, "auto-shown bars window hides when leaving rest")
        c.player.resting = true
        c:Fire("PLAYER_UPDATE_RESTING")
        check(frame.shown, "bars window pops up again when resting")
        c:Slash("bars")
        c:Slash("bars")
        c.player.resting = false
        c:Fire("PLAYER_UPDATE_RESTING")
        check(frame.shown, "a bars window opened by hand stays open when leaving")

        -- What the bar text shows is up to the player.
        local settings = rawget(c.env, "NothingWastedDB").settings
        local function KyolText()
            for i, t in ipairs(RowTexts(c, frame)) do
                if t:find("Kyol") then return c:Rows(frame)[i].time.text end
            end
        end
        check(KyolText():find("%dd %d+h"), "time to cap by default")
        settings.meter.text = "rested"
        c.ns.Meter.Refresh()
        eq(KyolText(), "2,000", "rested XP amount")
        settings.meter.text = "levelPct"
        c.ns.Meter.Refresh()
        eq(KyolText(), "20%", "rested % of a level")
        settings.meter.text = "capPct"
        c.ns.Meter.Refresh()
        eq(KyolText(), "11%", "rested % of the cap (rank 5 cap of 18,000)")
        settings.meter.text = "carries"
        c.ns.Meter.Refresh()
        eq(KyolText(), "to 20.5", "level rested XP reaches")
        settings.meter.text = "toCap"

        -- The bar count limit.
        rawget(c.env, "NothingWastedDB").settings.meter.maxBars = 1
        c.ns.Meter.Refresh()
        eq(#c:Rows(frame), 1, "bars window shows at most the set number of bars")
        rawget(c.env, "NothingWastedDB").settings.meter.maxBars = 10
        db2 = c:Logout()
        eq(db2.chars["Kyol-Forever"].wellRested, 5, "rank saved at logout")
        eq(db2.chars["Kyol-Forever"].resting, false, "logged out not resting")
    end)

    test("3. reminders at every login, or only once", function()
        local c = mock.NewClient({ root = root, db = db2, now = T0 + 12 * DAY, player = MAXI })
        c:Login()
        check(c:ChatHas("Oldie.-has hit the rested XP cap"), "capped alt announced again at login")
        check(not c:ChatHas("Kyol.-has hit"), "Kyol (not resting, rank 5) hasn't capped")
        local db = c:Logout()
        db.settings.alerts.once = true
        local c2 = mock.NewClient({ root = root, db = db, now = T0 + 13 * DAY, player = MAXI })
        c2:Login()
        check(not c2:ChatHas("has hit"), "no repeat at login when 'only once' is on")
        db3 = c2:Logout()
        db3.settings.alerts.once = false
    end)

    test("4. hardcore characters aren't tracked", function()
        local c = mock.NewClient({ root = root, db = db3, player = { name = "Hardy", hardcore = true } })
        c:Login()
        check(rawget(c.env, "NothingWastedDB").chars["Hardy-Forever"] == nil, "hardcore character not saved")
    end)

    test("5. mail, items, search and recipes", function()
        local p = {
            name = "Kyol", level = 20, xp = 1000, xpMax = 10000, rested = 2000, resting = true,
            bagSlots = { { 2589, 10, "Linen Cloth" } },
            professions = { { name = "Tailoring", rank = 150, max = 150, skillLine = 197 } },
        }
        local c = mock.NewClient({
            root = root, db = db3, now = T0 + 14 * DAY, player = p,
            sendItems = { { 2589, 20, "Linen Cloth" } },
            recipes = { [3915] = { name = "Bolt of Linen Cloth", learned = true, reagents = { { 2589, 2 } } } },
        })
        c:Login()
        local db = rawget(c.env, "NothingWastedDB")
        c.env.SendMail("Oldie", "cloth", "")
        c:Fire("MAIL_SEND_SUCCESS")
        local oldie = db.chars["Oldie-Forever"]
        eq(oldie.mail and #oldie.mail.incoming, 1, "mail to Oldie recorded at send time")
        eq(oldie.mail.incoming[1].items[2589], 20, "with its items")

        c.env.SendMail("Stranger", "hi", "")
        c:Fire("MAIL_SEND_SUCCESS")
        eq(#oldie.mail.incoming, 1, "mail to other players isn't recorded")

        local results = c.ns.Inventory.Search("linen")
        eq(#results, 1, "search finds the item by name")
        eq(results[1] and results[1].total, 30, "bags plus mail in transit")

        c:Slash("linen")
        local frame = c:Frame("NothingWastedFrame")
        check(frame.shown, "/nw <item> opens the window")
        local texts = RowTexts(c, TabPanel(c))
        check(texts[1] and texts[1]:find("Linen Cloth"), "search result shown")

        -- The search box is in the Items header, so it shows on every Items view.
        local box
        for _, f in ipairs(c.frames) do
            if f.kind == "EditBox" then box = f end
        end
        check(box and box:IsVisible() and box:GetText() == "linen", "search box shows the query")
        c.ns.Window.Select("mail")
        check(box:IsVisible(), "search box stays on the Mail view")
        box:SetText("lin")
        box.scripts.OnTextChanged(box, true)
        eq(rawget(c.env, "NothingWastedDB").settings.window.tab, "search", "typing switches to the Search view")
        c.ns.Window.Select("rested")
        check(not box:IsVisible(), "search box only on the Items tab")

        -- Recipes recorded while the profession window is open.
        c.openProfession = "Tailoring"
        c:Fire("TRADE_SKILL_LIST_UPDATE")
        c:Advance(2)
        local kyol = db.chars["Kyol-Forever"]
        check(kyol.recipes and kyol.recipes.Tailoring and kyol.recipes.Tailoring[3915], "known recipe recorded")
        eq(c.ns.Professions.CraftableFromAlts(3915), 15, "crafts from all characters' items")

        -- A crafted item's tooltip says who can make it.
        c.recipes[3915].output = 2996
        c:Fire("TRADE_SKILL_LIST_UPDATE")
        c:Advance(2)
        local made = c:ItemTooltip(2996)
        check(made:Has("Can make | .*Kyol"), "crafted item tooltip lists who can make it")

        -- Stuck at a trainer cap.
        local name, skill, level, stuck = c.ns.Professions.NextRank(kyol.professions[1], kyol.level)
        eq(name, "Expert", "next rank")
        check(stuck, "flagged as stuck at 150 and able to train")

        -- Recipe tooltip.
        c.itemInfo = { [4355] = { classID = 9, subclassID = 2, name = "Pattern: Icy Cloak" } }
        local tip = c:ItemTooltip(4355, { { type = 4, leftText = "Requires Tailoring (175)" } })
        check(tip:Has("can learn at 175 %(now 150%)"), "recipe tooltip shows when Kyol can learn it")

        -- Mail is grouped by character, collapsed until clicked.
        c.ns.Window.Select("mail")
        local mailRows = c:Rows(TabPanel(c))
        eq(#mailRows, 1, "mail starts collapsed to one header per character")
        mailRows[1].scripts.OnClick(mailRows[1], "LeftButton")
        eq(#c:Rows(TabPanel(c)), 2, "clicking the header shows its mail")
        c.ns.Window.Select("crafts")
        local craftRows = c:Rows(TabPanel(c))
        eq(#craftRows, 2, "crafts: character open, profession collapsed")
        craftRows[2].scripts.OnClick(craftRows[2], "LeftButton")
        eq(#c:Rows(TabPanel(c)), 3, "expanding the profession shows its crafts")
        craftRows[1].scripts.OnClick(craftRows[1], "LeftButton")
        eq(#c:Rows(TabPanel(c)), 1, "collapsing the character hides everything under it")

        -- Mail colours: yellow within 7 days, red within 3.
        eq(c.ns.Mail.ExpiryColor(6 * DAY), "|cffffd100", "yellow within 7 days")
        eq(c.ns.Mail.ExpiryColor(2 * DAY), "|cffff4040", "red within 3 days")
        eq(c.ns.Mail.ExpiryColor(10 * DAY), "", "no colour further out")

        -- Expiring mail warning 3 days before Oldie's mail expires.
        c:ClearChat()
        c:Advance(27 * DAY + HOUR)
        check(c:ChatHas("mail from Kyol expires in"), "warning before sent mail expires")
        db3 = c:Logout()
        -- And a summary at the next login.
        local l = mock.NewClient({ root = root, db = db3, now = c.now + HOUR, player = { name = "Kyol", level = 20, xpMax = 10000 } })
        l:Login()
        l:Advance(8)
        check(l:ChatHas("Mail expiring within 7 days"), "login lists mail expiring soon")
        check(l:ChatHas("Oldie.-1 mail%(s%), first in"), "with the character and time")
    end)

    test("6. cooldowns", function()
        local c = mock.NewClient({
            root = root, db = db3, now = T0 + 50 * DAY,
            player = {
                name = "Kyol", level = 20, xpMax = 10000, rested = 0, resting = true,
                spells = { [18560] = true },
                spellCooldowns = { [18560] = { 50 * DAY + 1000, 95 * HOUR } }, -- started at login (GetTime)
                items = { [6948] = 1 },
                itemCooldowns = { [6948] = { 50 * DAY + 1000, HOUR } },
            },
        })
        c:Login()
        local kyol = rawget(c.env, "NothingWastedDB").chars["Kyol-Forever"]
        check(kyol.cooldowns.mooncloth, "Mooncloth cooldown recorded")
        near(kyol.cooldowns.mooncloth.readyAt - c.now, 95 * HOUR - 6, 2, "ready in 95 hours")
        check(kyol.cooldowns.hearthstone, "hearthstone recorded")
        c:ClearChat()
        c.player.spellCooldowns = {}
        c.player.itemCooldowns = {}
        c:Advance(2 * HOUR)
        check(not c:ChatHas("Hearthstone is ready"), "no alert for short cooldowns")
        c:Advance(95 * HOUR)
        check(c:ChatHas("Mooncloth is ready"), "alert when Mooncloth is ready")
        db3 = c:Logout()
    end)

    test("7. Legacy goals", function()
        local catalog = { { id = 15579, name = "Mage", achievements = {
            { id = 1001, name = "Reach level 25 as a Mage", req = 25 },
            { id = 1002, name = "Reach level 45 as a Mage", req = 45 },
        } } }
        local c = mock.NewClient({
            root = root, db = db3, now = T0 + 60 * DAY, catalog = catalog,
            player = { name = "Kyol", level = 20, xpMax = 10000, achievements = { [1001] = { q = 20 }, [1002] = { completed = true, earnedByMe = true } } },
        })
        c:Login()
        local kyol = rawget(c.env, "NothingWastedDB").chars["Kyol-Forever"]
        c.ns.Legacy.SetGoal(1001, true)
        eq(kyol.legacyProgress[1001].q, 20, "goal progress recorded")
        c:Slash("")
        c.ns.Window.Select("choose")
        local panel = TabPanel(c)
        eq(#c:Rows(panel), 2, "categories start collapsed (intro line and one header)")
        local catHeader = c:Rows(panel)[2]
        catHeader.scripts.OnClick(catHeader, "LeftButton")
        local texts = RowTexts(c, panel)
        local listed25, listed45 = false, false
        for _, t in ipairs(texts) do
            if t:find("level 25") then listed25 = true end
            if t:find("level 45") then listed45 = true end
        end
        check(listed25, "open challenge listed to choose")
        check(not listed45, "completed challenge hidden")

        -- Search: the box on Choose goals filters challenges.
        local search
        for _, f in ipairs(c.frames) do
            if f.kind == "EditBox" and f:IsVisible() then search = f end
        end
        check(search ~= nil, "Choose goals has a search box")
        catHeader.scripts.OnClick(catHeader, "LeftButton") -- collapse again; search shows matches anyway
        search:SetText("zzz")
        search.scripts.OnTextChanged(search, true)
        check(RowTexts(c, panel)[2] and RowTexts(c, panel)[2]:find("No open challenge"), "no match message")
        search:SetText("25")
        search.scripts.OnTextChanged(search, true)
        local found = false
        for _, t in ipairs(RowTexts(c, panel)) do if t:find("level 25") then found = true end end
        check(found, "search finds the challenge even in a collapsed category")
        search:SetText("")
        search.scripts.OnTextChanged(search, true)

        -- Unticking a goal removes it from Goals.
        c.ns.Legacy.SetGoal(1002, true)
        c.ns.Legacy.SetGoal(1002, false)
        check(kyol.legacyProgress[1002] == nil, "unticked goal leaves the Goals list")
        c.player.achievements[1001] = { completed = true, earnedByMe = true, q = 25 }
        c:Fire("CRITERIA_UPDATE")
        c:Advance(3)
        check(kyol.legacyGoals[1001] == nil, "finished goal removed")
        check(c:ChatHas("Legacy goal complete"), "goal completion announced")
        eq(kyol.legacyPoints and kyol.legacyPoints.cap, 16, "Legacy points and cap read")
        db3 = c:Logout()
    end)

    test("8. every tab and tooltip renders", function()
        local c = mock.NewClient({
            root = root, db = db3, now = T0 + 70 * DAY,
            player = {
                name = "Kyol", level = 24, xpMax = 12000, rested = 500, resting = true, money = 425000,
                professions = { { name = "Tailoring", rank = 150, max = 150, skillLine = 197 }, { name = "Cooking", rank = 40, max = 75, skillLine = 185 } },
                quests = { [79008] = true, [79192] = true },
            },
        })
        c:Login()
        local kyol = rawget(c.env, "NothingWastedDB").chars["Kyol-Forever"]
        -- Untrained spells come from the trainer, not the spellbook.
        eq(#c.ns.Leveling.Trainable(kyol), 0, "nothing known before a trainer visit")
        c.trainer = {
            { name = "Frostbolt", kind = "available", level = 24, rank = "Rank 4", cost = 6000 },
            { name = "Blizzard", kind = "unavailable", level = 26, rank = "Rank 2", cost = 8000 },
            { name = "Arcane Intellect", kind = "used", level = 14 },
        }
        c:Fire("TRAINER_SHOW")
        eq(#c.ns.Leveling.Trainable(kyol), 1, "one spell to train at level 24")
        c.player.level = 26
        c:Fire("PLAYER_LEVEL_UP", 26)
        c:Advance(1) -- the save notices the new level
        c:Advance(4) -- then the level-up message
        eq(#c.ns.Leveling.Trainable(kyol), 2, "reaching level 26 adds the spell the trainer listed for it")
        check(c:ChatHas("reached level 26 and has 2 spell"), "level-up says how many spells to train")
        local _, total = c.ns.Leveling.Trainable(kyol)
        eq(total, 14000, "total training cost")
        c.ns.Window.Show("train")
        local trainTexts = RowTexts(c, TabPanel(c))
        check(trainTexts[1] and trainTexts[1]:find("Kyol"), "character header first")
        check(trainTexts[2] and trainTexts[2]:find("Frostbolt") and trainTexts[2]:find("Rank 4"), "then each spell with its rank")
        local trainRows = c:Rows(TabPanel(c))
        check(trainRows[1].right.text:find("1"), "header shows the total cost")
        check(trainRows[2].right.text:find("60"), "spell rows show their price")
        trainRows[1].scripts.OnClick(trainRows[1], "LeftButton")
        eq(#c:Rows(TabPanel(c)), 1, "the character's spells collapse")
        c.ns.Window.Hide()
        eq(kyol.sleepingBag and kyol.sleepingBag.done, 2, "sleeping bag chain progress")
        check(kyol.trade and kyol.trade.commerce, "trade reputation read")
        check(c.ns.Meter.IsShown(), "bars window open (logged in resting)")
        c:Slash("")
        check(c:Frame("NothingWastedFrame").shown, "/nw opens the full window")
        local expectRows = { rested = true, cooldowns = true, pace = true, train = true, skills = true,
            bags = true, goals = true, choose = true, planner = true, alerts = false }
        local ids = c.ns.Window.PageIDs()
        check(#ids >= 18, "every page has a tab or view")
        for _, id in ipairs(ids) do
            c.ns.Window.Select(id)
            local panel = TabPanel(c)
            check(panel and panel:IsVisible(), id .. " page shown")
            if expectRows[id] then check(#c:Rows(panel) > 0, id .. " page has rows") end
            for _, row in ipairs(c:Rows(panel)) do
                if row.scripts.OnEnter then c:Hover(row) end
            end
            -- Options pages: toggle every checkbox, step every selector, press Defaults.
            for _, f in ipairs(c.frames) do
                if f:IsVisible() and f.kind == "CheckButton" then
                    f:Click()
                    f:Click()
                elseif f:IsVisible() and f.kind == "Button" and f.parent and f.parent.box then
                    f:Click() -- selector arrows and boxes
                end
            end
            local hasDefaults = false
            for _, f in ipairs(c.frames) do
                if f.kind == "Button" and f.text == "Defaults" and f:IsVisible() then
                    hasDefaults = true
                    f:Click()
                end
            end
            if id == "alerts" then check(hasDefaults, "options pages have a Defaults button") end
        end
        -- Defaults put the alert settings back.
        local settings = rawget(c.env, "NothingWastedDB").settings
        settings.alerts.earlyMinutes = 30
        c.ns.Window.Select("alerts")
        for _, f in ipairs(c.frames) do
            if f.text == "Defaults" and f:IsVisible() then f:Click() end
        end
        eq(settings.alerts.earlyMinutes, 120, "Defaults resets the page's settings")
        -- Old page names still work.
        c.ns.Window.Select("options")
        eq(rawget(c.env, "NothingWastedDB").settings.window.tab, "alerts", "'options' opens the Alerts page")
        -- A tab reopens the view used last.
        c.ns.Window.Select("mail")
        c.ns.Window.Select("rested")
        c.ns.Window.Select("items")
        eq(rawget(c.env, "NothingWastedDB").settings.window.tab, "mail", "a tab reopens its last view")
        c.ns.Glow.Pulse()
        c:Logout()
    end)

    return passed, failed
end
