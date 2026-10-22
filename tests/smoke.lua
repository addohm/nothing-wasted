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

local function TabPanel(client, id)
    for _, def in ipairs(client.ns.Window and {} or {}) do end
    -- Tab panels are children of the window; find the one that's shown.
    local window = client:Frame("NothingWastedFrame")
    for _, f in ipairs(client.frames) do
        if f.parent == window and f.kind == "Frame" and f.shown and #f.points == 2 then return f end
    end
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
        local frame = c:Frame("NothingWastedFrame")
        check(frame and frame.shown, "window pops up when logging in somewhere resting")
        local texts = RowTexts(c, TabPanel(c))
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

        -- Leaving the inn hides a window that popped up by itself.
        c:Fire("PLAYER_UPDATE_RESTING")
        check(not frame.shown, "auto-shown window hides when leaving rest")
        c.player.resting = true
        c:Fire("PLAYER_UPDATE_RESTING")
        check(frame.shown, "window pops up again when resting")
        c:Slash("")
        c:Slash("")
        c.player.resting = false
        c:Fire("PLAYER_UPDATE_RESTING")
        check(frame.shown, "a window opened by hand stays open when leaving")
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

        -- Recipes recorded while the profession window is open.
        c.openProfession = "Tailoring"
        c:Fire("TRADE_SKILL_LIST_UPDATE")
        c:Advance(2)
        local kyol = db.chars["Kyol-Forever"]
        check(kyol.recipes and kyol.recipes.Tailoring and kyol.recipes.Tailoring[3915], "known recipe recorded")
        eq(c.ns.Professions.CraftableFromAlts(3915), 15, "crafts from all characters' items")

        -- Stuck at a trainer cap.
        local name, skill, level, stuck = c.ns.Professions.NextRank(kyol.professions[1], kyol.level)
        eq(name, "Expert", "next rank")
        check(stuck, "flagged as stuck at 150 and able to train")

        -- Recipe tooltip.
        c.itemInfo = { [4355] = { classID = 9, subclassID = 2, name = "Pattern: Icy Cloak" } }
        local tip = c:ItemTooltip(4355, { { type = 4, leftText = "Requires Tailoring (175)" } })
        check(tip:Has("can learn at 175 %(now 150%)"), "recipe tooltip shows when Kyol can learn it")

        -- Expiring mail warning 3 days before Oldie's mail expires.
        c:ClearChat()
        c:Advance(27 * DAY + HOUR)
        check(c:ChatHas("mail from Kyol expires in"), "warning before sent mail expires")
        db3 = c:Logout()
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
        c.ns.Window.Select("legacy")
        local panel = TabPanel(c)
        panel.cycle.button:Click()
        local texts = RowTexts(c, panel)
        local listed25, listed45 = false, false
        for _, t in ipairs(texts) do
            if t:find("level 25") then listed25 = true end
            if t:find("level 45") then listed45 = true end
        end
        check(listed25, "open challenge listed to choose")
        check(not listed45, "completed challenge hidden")
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
                futureSpells = { { name = "Frostbolt", level = 24 }, { name = "Blizzard", level = 26 } },
                professions = { { name = "Tailoring", rank = 150, max = 150, skillLine = 197 }, { name = "Cooking", rank = 40, max = 75, skillLine = 185 } },
                quests = { [79008] = true, [79192] = true },
            },
        })
        c:Login()
        local kyol = rawget(c.env, "NothingWastedDB").chars["Kyol-Forever"]
        eq(kyol.trainable and #kyol.trainable, 1, "one spell to train at level 24")
        eq(kyol.sleepingBag and kyol.sleepingBag.done, 2, "sleeping bag chain progress")
        check(kyol.trade and kyol.trade.commerce, "trade reputation read")
        check(c:Frame("NothingWastedFrame").shown, "window already open (logged in resting)")
        for _, tab in ipairs({ "rested", "cooldowns", "leveling", "professions", "items", "legacy", "options" }) do
            c.ns.Window.Select(tab)
            local panel = TabPanel(c)
            check(panel ~= nil, tab .. " tab shown")
            if tab ~= "options" then check(#c:Rows(panel) > 0, tab .. " tab has rows") end
            -- Cycle every mode and hover every row.
            for _ = 1, 3 do
                if panel.cycle then panel.cycle.button:Click() end
                for _, row in ipairs(c:Rows(panel)) do
                    if row.scripts.OnEnter then c:Hover(row) end
                end
            end
        end
        -- Every option toggles without errors.
        c.ns.Window.Select("options")
        for _, f in ipairs(c.frames) do
            if f.kind == "CheckButton" and f:IsVisible() then
                f:Click()
                f:Click()
            elseif f.kind == "Button" and f.templates.UIPanelButtonTemplate and f:IsVisible() and f.parent and f.parent.label then
                f:Click()
            end
        end
        c.ns.Glow.Pulse()
        c:Logout()
    end)

    return passed, failed
end
