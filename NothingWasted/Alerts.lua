-- Nothing Wasted: alerts for rested caps, cooldowns and expiring mail.
--
-- A scan runs every few seconds. Each alert remembers what it fired for (the character's save
-- time, a cooldown's ready time, a mail's expiry), so it fires once at that moment. At login, every
-- alt sitting at the cap is announced again unless the "only once" option is on.
local _, ns = ...
local L = ns.L

local Alerts = {}
ns.Alerts = Alerts

local SCAN_SECONDS = 10

-- Plays a custom sound: a sound kit ID ("12345", as on Wowhead's sound pages) or a sound file ID
-- ("file:12345"). Returns false if the text isn't a usable ID.
function Alerts.PlayCustom(text)
    text = (text or ""):gsub("%s", "")
    local file = text:match("^file:(%d+)$")
    if file then
        if not PlaySoundFile then return false end
        PlaySoundFile(tonumber(file), "Master")
        return true
    end
    local kit = tonumber(text:match("^kit:(%d+)$") or text:match("^(%d+)$"))
    if not kit then return false end
    PlaySound(kit, "Master")
    return true
end

-- kind "buff" plays the buff reminders' sound, which can be its own or the same as the alerts'.
function Alerts.PlaySound(kind)
    local s = ns.db.settings.alerts
    local name, custom = s.sound, s.customSound
    if kind == "buff" and s.buffSoundName ~= "SAME" then
        name, custom = s.buffSoundName, s.buffCustomSound
    end
    if name == "CUSTOM" then
        if Alerts.PlayCustom(custom) then return end
        name = "RAID_WARNING" -- no usable ID yet
    end
    local id = SOUNDKIT[name] or SOUNDKIT.RAID_WARNING
    if id then PlaySound(id, "Master") end
end

local function Announce(msg, opts)
    ns.Print(msg)
    if opts.sound ~= false then Alerts.PlaySound() end
    if opts.glow and ns.db.settings.alerts.glow and ns.Glow then ns.Glow.Pulse() end
end

-- Rested cap and early warning for one alt. `login` is true for the scan right after logging in.
local function CheckRested(c, now, login, out)
    local settings = ns.db.settings.alerts
    if ns.Rested.IsIdle(c) then return end
    local _, _, toCap = ns.Rested.Estimate(c, now)
    c.alerts = c.alerts or {}
    local cycle = c.savedAt -- changes every time the character is played

    if toCap <= 0 then
        if not settings.cap then return end
        local isNew = c.alerts.cap ~= cycle
        if isNew or (login and not settings.once) then
            c.alerts.cap = cycle
            out.capped[#out.capped + 1] = c
        end
    elseif settings.early and toCap <= settings.earlyMinutes * 60 and c.alerts.early ~= cycle then
        c.alerts.early = cycle
        out.early[#out.early + 1] = { c = c, toCap = toCap }
    end
end

-- Cooldowns that became ready, for any character including the current one.
local function CheckCooldowns(c, now, out)
    if not ns.db.settings.alerts.cooldowns or not c.cooldowns then return end
    c.alerts = c.alerts or {}
    c.alerts.cooldowns = c.alerts.cooldowns or {}
    for id, cd in pairs(c.cooldowns) do
        if cd.alert ~= false and cd.readyAt and cd.readyAt <= now and c.alerts.cooldowns[id] ~= cd.readyAt then
            c.alerts.cooldowns[id] = cd.readyAt
            -- Cooldowns that were already ready before we ever saw them aren't news.
            if now - cd.readyAt < 7 * 86400 then
                out.cooldowns[#out.cooldowns + 1] = { c = c, name = cd.name }
            end
        end
    end
end

-- Mail that expires soon and hasn't been warned about yet.
local function CheckMail(c, now, out)
    local settings = ns.db.settings.alerts
    if not settings.mail or not c.mail then return end
    c.alerts = c.alerts or {}
    c.alerts.mail = c.alerts.mail or {}
    local window = settings.mailDays * 86400
    for _, m in ipairs(ns.Mail.Pending(c)) do
        local id = m.id
        if m.expiresAt and m.expiresAt > now and m.expiresAt - now <= window and not c.alerts.mail[id] then
            c.alerts.mail[id] = true
            out.mail[#out.mail + 1] = { c = c, m = m, left = m.expiresAt - now }
        end
    end
end

function Alerts.Scan(login)
    if not ns.db then return end
    local now = ns.Now()
    local me = ns.PlayerKey()
    local out = { capped = {}, early = {}, cooldowns = {}, mail = {} }
    for key, c in pairs(ns.db.chars) do
        if key ~= me then CheckRested(c, now, login, out) end
        CheckCooldowns(c, now, out)
        CheckMail(c, now, out)
    end

    for i, c in ipairs(out.capped) do
        -- One sound and glow for the whole batch.
        Announce(format(L["|cffff4040Bing!|r %s has hit the rested XP cap! Log in and use it."], ns.ColoredName(c)),
            { glow = true, sound = i == 1 })
    end
    for i, e in ipairs(out.early) do
        Announce(format(L["%s reaches the rested XP cap in %s."], ns.ColoredName(e.c), ns.FormatDuration(e.toCap)),
            { sound = i == 1 and #out.capped == 0 })
    end
    local played = #out.capped + #out.early > 0
    for i, e in ipairs(out.cooldowns) do
        Announce(format(L["%s: %s is ready."], ns.ColoredName(e.c), e.name), { sound = i == 1 and not played })
    end
    played = played or #out.cooldowns > 0
    for i, e in ipairs(out.mail) do
        Announce(format(L["%s: mail from %s expires in %s."], ns.ColoredName(e.c), e.m.sender or "?",
            ns.FormatDuration(e.left)), { sound = i == 1 and not played })
    end
    if #out.capped + #out.early + #out.cooldowns + #out.mail > 0 then ns.Fire("NW_REFRESH") end
end

ns.On("PLAYER_ENTERING_WORLD", function(isInitialLogin, isReload)
    if not isInitialLogin and not isReload then return end
    -- Give the login a moment so the alerts aren't lost in the chat spam.
    C_Timer.After(5, function() Alerts.Scan(isInitialLogin) end)
    if not Alerts.ticker then
        Alerts.ticker = C_Timer.NewTicker(SCAN_SECONDS, function() Alerts.Scan(false) end)
    end
end)

-- Logout warning: logging out away from an inn or city builds rested XP at a quarter of the rate.
ns.On("PLAYER_CAMPING", function()
    if not ns.db.settings.alerts.logout or IsResting() then return end
    local c = ns.Me()
    if c and ns.Rested.IsIdle(c) then return end
    ns.Print(L["you're logging out somewhere that isn't resting: rested XP builds at a quarter of the rate. Log out in an inn or city to build it faster."])
end)
