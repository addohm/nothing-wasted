-- A fake WoW client for headless tests of Nothing Wasted, under Lua 5.1.
--
-- NewClient(opts) builds an isolated environment, loads the addon's files in .toc order into it and
-- returns a client to drive. The mock is strict so real mistakes surface:
--   * reading an undefined global errors (except a few that may legitimately be nil);
--   * writing a global the addon isn't supposed to create errors;
--   * widgets only have the methods implemented here, so a misspelled method fails;
--   * NaN or infinity reaching text, a bar or a tooltip fails.
local M = {}

local T0 = 1700000000 -- client.now at the start of every test

local NILABLE = { NothingWastedDB = true, GetAddOnMetadata = true }
local ALLOWED_GLOBALS = {
    NothingWastedDB = true,
    NothingWasted_OnAddonCompartmentClick = true,
    SLASH_NOTHINGWASTED1 = true,
    SLASH_NOTHINGWASTED2 = true,
}
local TEMPLATES = {
    BackdropTemplate = true, UIPanelCloseButton = true, UIPanelButtonTemplate = true,
    UICheckButtonTemplate = true, UIPanelScrollFrameTemplate = true, InputBoxTemplate = true,
}

local function IsBadNumber(v)
    return type(v) == "number" and (v ~= v or v == math.huge or v == -math.huge)
end

local function CheckValue(where, v)
    if IsBadNumber(v) then error(where .. ": NaN or infinity", 3) end
    if type(v) == "string" and (v:find("%f[%a]nan%f[%A]") or v:find("%f[%a]inf%f[%A]") or v:find("1%.#IN")) then
        error(where .. ": text contains NaN or infinity: " .. v, 3)
    end
end

local function Copy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = Copy(v) end
    return out
end
M.Copy = Copy

-- Widgets ----------------------------------------------------------------------------------------

local Region = {}
Region.__index = Region

function Region:SetPoint(...) self.points[#self.points + 1] = { ... } end
function Region:ClearAllPoints() self.points = {} end
function Region:GetPoint(i)
    local p = self.points[i or 1]
    if not p then return end
    if type(p[2]) == "table" then return p[1], p[2], p[3], p[4], p[5] end
    return p[1], nil, p[1], p[2], p[3]
end
function Region:SetAllPoints() self.points = { { "ALL" } } end
function Region:SetSize(w, h) self.width, self.height = w, h end
function Region:SetWidth(w) CheckValue("SetWidth", w) self.width = w end
function Region:SetHeight(h) CheckValue("SetHeight", h) self.height = h end
function Region:GetWidth() return self.width or 300 end
function Region:GetHeight() return self.height or 20 end
function Region:Show()
    local was = self.shown
    self.shown = true
    if not was and self.scripts and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function Region:Hide()
    local was = self.shown
    self.shown = false
    if was and self.scripts and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function Region:SetShown(v) if v then self:Show() else self:Hide() end end
function Region:IsShown() return self.shown end
function Region:IsVisible()
    local r = self
    while r do
        if not r.shown then return false end
        r = r.parent
    end
    return true
end
function Region:SetParent(p) self.parent = p end
function Region:SetAlpha(a) CheckValue("SetAlpha", a) self.alpha = a end

local FontString = setmetatable({}, Region)
FontString.__index = FontString
function FontString:SetText(t)
    CheckValue("SetText", t)
    self.text = t
end
function FontString:GetText() return self.text end
function FontString:GetStringWidth() return #(tostring(self.text or "")) * 7 end
function FontString:SetJustifyH() end
function FontString:SetTextColor(...) for _, v in ipairs({ ... }) do CheckValue("SetTextColor", v) end end
function FontString:SetFontObject(f) self.font = f end

local Texture = setmetatable({}, Region)
Texture.__index = Texture
function Texture:SetTexture(t) self.texture = t end
function Texture:SetColorTexture(...) for _, v in ipairs({ ... }) do CheckValue("SetColorTexture", v) end end
function Texture:SetTexCoord() end
function Texture:SetBlendMode(m) self.blend = m end
function Texture:SetGradient(orientation, a, b)
    assert(orientation == "HORIZONTAL" or orientation == "VERTICAL", "bad gradient orientation")
    assert(type(a) == "table" and type(b) == "table", "SetGradient needs color objects")
end

local Anim = {}
Anim.__index = Anim
function Anim:SetFromAlpha(v) CheckValue("SetFromAlpha", v) end
function Anim:SetToAlpha(v) CheckValue("SetToAlpha", v) end
function Anim:SetDuration(v) CheckValue("SetDuration", v) end
function Anim:SetOrder() end
function Anim:SetSmoothing() end

local AnimGroup = {}
AnimGroup.__index = AnimGroup
function AnimGroup:CreateAnimation(kind)
    assert(kind == "Alpha", "unexpected animation type " .. tostring(kind))
    return setmetatable({}, Anim)
end
function AnimGroup:SetLooping(l)
    assert(l == "NONE" or l == "REPEAT" or l == "BOUNCE", "bad looping " .. tostring(l))
end
function AnimGroup:SetScript(name, fn) self.scripts[name] = fn end
function AnimGroup:Play()
    self.playing = true
    if self.scripts.OnPlay then self.scripts.OnPlay(self) end
end
function AnimGroup:Stop()
    local was = self.playing
    self.playing = false
    if was and self.scripts.OnStop then self.scripts.OnStop(self) end
end
function AnimGroup:IsPlaying() return self.playing end

local Frame = setmetatable({}, Region)
Frame.__index = Frame

function Frame:RegisterEvent(e) self.client.events[e] = self.client.events[e] or {}; self.client.events[e][self] = true end
function Frame:UnregisterEvent(e) if self.client.events[e] then self.client.events[e][self] = nil end end
function Frame:SetScript(name, fn) self.scripts[name] = fn end
function Frame:GetScript(name) return self.scripts[name] end
function Frame:HookScript(name, fn)
    local orig = self.scripts[name]
    self.scripts[name] = function(...)
        if orig then orig(...) end
        return fn(...)
    end
end
function Frame:SetFrameStrata() end
function Frame:SetFrameLevel() end
function Frame:EnableMouse() end
function Frame:SetMovable() end
function Frame:SetClampedToScreen() end
function Frame:StartMoving() end
function Frame:StopMovingOrSizing()
    self.points = { { "TOPLEFT", self.client.UIParent, "BOTTOMLEFT", 123, 456 } }
end
function Frame:RegisterForDrag() end
function Frame:SetBackdrop()
    assert(self.templates.BackdropTemplate, "SetBackdrop needs BackdropTemplate")
end
function Frame:SetBackdropColor(...)
    assert(self.templates.BackdropTemplate, "SetBackdropColor needs BackdropTemplate")
    for _, v in ipairs({ ... }) do CheckValue("SetBackdropColor", v) end
end
function Frame:SetBackdropBorderColor(...)
    assert(self.templates.BackdropTemplate, "SetBackdropBorderColor needs BackdropTemplate")
end
function Frame:CreateTexture()
    local t = setmetatable({ points = {}, shown = true, parent = self }, Texture)
    return t
end
function Frame:CreateFontString(_, _, font)
    local f = setmetatable({ points = {}, shown = true, parent = self, font = font }, FontString)
    self.fontStrings = self.fontStrings or {}
    self.fontStrings[#self.fontStrings + 1] = f
    return f
end
function Frame:CreateAnimationGroup()
    return setmetatable({ scripts = {} }, AnimGroup)
end
function Frame:GetCenter() return 100, 100 end
function Frame:GetEffectiveScale() return 1 end

local Button = setmetatable({}, Frame)
Button.__index = Button
function Button:RegisterForClicks() end
function Button:SetNormalTexture(t) self.normal = t end
function Button:SetPushedTexture(t) self.pushed = t end
function Button:SetHighlightTexture() end
function Button:SetText(t)
    CheckValue("Button:SetText", t)
    assert(self.templates.UIPanelButtonTemplate, "Button:SetText needs UIPanelButtonTemplate here")
    self.text = t
end
function Button:GetText() return self.text end
function Button:Click(mouseButton)
    if self.scripts.OnClick then self.scripts.OnClick(self, mouseButton or "LeftButton") end
end

local CheckButton = setmetatable({}, Button)
CheckButton.__index = CheckButton
function CheckButton:SetChecked(v) self.checked = v and true or false end
function CheckButton:GetChecked() return self.checked end
function CheckButton:Click(mouseButton)
    self.checked = not self.checked
    if self.scripts.OnClick then self.scripts.OnClick(self, mouseButton or "LeftButton") end
end

local StatusBar = setmetatable({}, Frame)
StatusBar.__index = StatusBar
function StatusBar:SetStatusBarTexture() end
function StatusBar:SetStatusBarColor(...) for _, v in ipairs({ ... }) do CheckValue("SetStatusBarColor", v) end end
function StatusBar:SetMinMaxValues(a, b) CheckValue("SetMinMaxValues", a) CheckValue("SetMinMaxValues", b) self.min, self.max = a, b end
function StatusBar:SetValue(v)
    CheckValue("SetValue", v)
    self.value = v
end

local ScrollFrame = setmetatable({}, Frame)
ScrollFrame.__index = ScrollFrame
function ScrollFrame:SetScrollChild(c) self.child = c end

local EditBox = setmetatable({}, Frame)
EditBox.__index = EditBox
function EditBox:SetAutoFocus() end
function EditBox:SetText(t) CheckValue("EditBox:SetText", t) self.text = t end
function EditBox:GetText() return self.text or "" end
function EditBox:ClearFocus() self.focus = false end
function EditBox:HasFocus() return self.focus or false end

local KINDS = {
    Frame = Frame, Button = Button, CheckButton = CheckButton, StatusBar = StatusBar,
    ScrollFrame = ScrollFrame, EditBox = EditBox,
}

-- Tooltip ----------------------------------------------------------------------------------------

local function NewTooltip()
    local tip = { lines = {} }
    function tip:SetOwner(owner) self.owner = owner; self.lines = {} end
    function tip:AddLine(t, ...)
        CheckValue("AddLine", t)
        for _, v in ipairs({ ... }) do CheckValue("AddLine color", v) end
        self.lines[#self.lines + 1] = tostring(t)
    end
    function tip:AddDoubleLine(a, b, ...)
        CheckValue("AddDoubleLine", a)
        CheckValue("AddDoubleLine", b)
        self.lines[#self.lines + 1] = tostring(a) .. " | " .. tostring(b)
    end
    function tip:SetHyperlink(l) self.lines[#self.lines + 1] = l end
    function tip:Show() self.shown = true end
    function tip:Hide() self.shown = false end
    function tip:Has(pattern)
        for _, l in ipairs(self.lines) do
            if l:find(pattern) then return true end
        end
        return false
    end
    return tip
end

-- Client -------------------------------------------------------------------------------------------

local function ReadToc(root)
    local files, version = {}, nil
    for line in io.lines(root .. "/NothingWasted/NothingWasted.toc") do
        line = line:gsub("\r", "")
        local v = line:match("^## Version:%s*(.-)%s*$")
        if v then version = v end
        if line ~= "" and not line:find("^#") then
            files[#files + 1] = line:gsub("\\", "/")
        end
    end
    return files, version
end

local DEFAULT_PLAYER = {
    name = "Kyol", realm = "Forever", className = "Mage", class = "MAGE", faction = "Alliance",
    level = 20, xp = 1000, xpMax = 10000, rested = 0, resting = false,
    zone = "Elwynn Forest", subzone = "Goldshire", bind = "Goldshire", money = 50000,
    hardcore = false, xpDisabled = false,
    professions = {},   -- { name, icon, rank, max, skillLine } in GetProfessions order
    riding = 0,
    spells = {},        -- [spellID] = true
    spellCooldowns = {},-- [spellID] = { start, duration } in GetTime() seconds
    items = {},         -- [itemID] = count (bags)
    itemCooldowns = {}, -- [itemID] = { start, duration }
    auras = {},         -- [spellID] = expirationTime (GetTime() seconds)
    quests = {},        -- [questID] = true
    perks = {},         -- [spellID] = rank, for Legacy nodes
    legacyUnlocked = true,
    legacy = { unspent = 2, spent = 4, cap = 16 },
    achievements = {},  -- [id] = { completed, earnedByMe, q, req }
}

function M.NewClient(opts)
    opts = opts or {}
    local root = assert(opts.root, "root")
    local client = {
        now = opts.now or T0,
        events = {},
        timers = {},
        chat = {},
        sounds = {},
        popups = {},
        globalWrites = {},
        postCalls = {},
        sentMail = {},
        inbox = opts.inbox or {},
        mailItems = opts.sendItems or {},
        sendMoney = 0,
        sendCOD = 0,
        trainer = opts.trainer or {},
        recipes = opts.recipes or {},
        catalog = opts.catalog or { { id = 15579, name = "Mage", achievements = {} } },
    }
    local player = Copy(DEFAULT_PLAYER)
    for k, v in pairs(opts.player or {}) do player[k] = Copy(v) end
    client.player = player

    local env = {}
    local namedFrames = {}

    -- Lua basics and WoW's extras
    for _, k in ipairs({ "assert", "error", "ipairs", "next", "pairs", "pcall", "print", "select", "setmetatable",
        "getmetatable", "tonumber", "tostring", "type", "unpack", "rawget", "rawset", "math", "string", "table", "xpcall" }) do
        env[k] = _G[k]
    end
    env._G = env
    env.format = string.format
    env.tinsert = table.insert
    env.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
    env.geterrorhandler = function() return function(err) error(err, 0) end end
    env.time = function() return client.now end
    env.date = function(fmt, t) return os.date(fmt, t or client.now) end
    env.GetTime = function() return client.now - T0 + 1000 end
    env.hooksecurefunc = function(name, fn)
        local orig = env[name]
        rawset(env, name, function(...)
            local r = { orig(...) }
            fn(...)
            return unpack(r)
        end)
    end

    -- Frames
    local function CreateFrame(kind, name, parent, template)
        local class = assert(KINDS[kind], "CreateFrame: unsupported type " .. tostring(kind))
        local templates = {}
        for t in tostring(template or ""):gmatch("[^,%s]+") do
            assert(TEMPLATES[t], "CreateFrame: unknown template " .. t)
            templates[t] = true
        end
        local f = setmetatable({ client = client, points = {}, scripts = {}, shown = true, parent = parent,
            templates = templates, kind = kind, name = name }, class)
        if kind == "CheckButton" then f.checked = false end
        if templates.UIPanelButtonTemplate or templates.UICheckButtonTemplate then f.templates.UIPanelButtonTemplate = true end
        client.frames = client.frames or {}
        client.frames[#client.frames + 1] = f
        if name then
            namedFrames[name] = f
            rawset(env, name, f)
        end
        return f
    end
    env.CreateFrame = CreateFrame
    env.UIParent = CreateFrame("Frame")
    client.UIParent = env.UIParent
    env.Minimap = CreateFrame("Frame")
    env.Minimap.width = 140
    env.GetCursorPosition = function() return client.cursorX or 100, client.cursorY or 200 end
    env.CreateColor = function(r, g, b, a) return { r = r, g = g, b = b, a = a } end
    env.UISpecialFrames = {}
    env.StaticPopupDialogs = {}
    env.StaticPopup_Show = function(which, a1, a2, data)
        local d = assert(env.StaticPopupDialogs[which], "unknown popup " .. which)
        client.popups[#client.popups + 1] = { which = which, text = d.text:format(a1, a2), data = data }
    end
    env.YES, env.NO, env.CLOSE = "Yes", "No", "Close"
    env.SlashCmdList = {}
    env.RAID_CLASS_COLORS = setmetatable({}, { __index = function() return { r = 0.5, g = 0.6, b = 0.7 } end })
    env.GameTooltip = NewTooltip()
    env.ItemRefTooltip = NewTooltip()
    env.GameTooltip_Hide = function() env.GameTooltip:Hide() end
    env.DEFAULT_CHAT_FRAME = {
        AddMessage = function(_, msg)
            CheckValue("AddMessage", msg)
            client.chat[#client.chat + 1] = msg
        end,
    }
    env.SOUNDKIT = { RAID_WARNING = 8959, READY_CHECK = 8960, RAID_BOSS_EMOTE_WARNING = 12197,
        UI_RAID_BOSS_WHISPER_WARNING = 37666, ALARM_CLOCK_WARNING_3 = 12889, TELL_MESSAGE = 3081, MAP_PING = 3175 }
    env.PlaySound = function(id) client.sounds[#client.sounds + 1] = id end
    env.GetLocale = function() return opts.locale or "enUS" end
    for i = 1, 8 do env["FACTION_STANDING_LABEL" .. i] = "Standing" .. i end
    env.ATTACHMENTS_MAX_SEND, env.ATTACHMENTS_MAX_RECEIVE = 12, 16
    env.InCombatLockdown = function() return client.inCombat or false end
    env.IsShiftKeyDown = function() return client.shift or false end
    -- Midnight's secret values: tests mark values secret by wrapping them with mock.Secret().
    env.issecretvalue = function(v) return type(v) == "table" and getmetatable(v) == M.SecretMeta end

    env.Enum = {
        BankType = { Character = 0, Account = 2 },
        SpellBookSpellBank = { Player = 0 },
        TooltipDataType = { Item = 0 },
        TooltipDataLineType = { UsageRequirement = 4 },
    }
    env.Constants = { LegacyConsts = { LEGACY_TREE_PROFESSIONS_ID = 1187, LEGACY_TREE_ADVENTURE_ID = 1188, LEGACY_TREE_PROGRESSION_ID = 1189 } }

    -- Timers: Advance moves the clock and runs what's due (a ticker runs at most once per Advance).
    env.C_Timer = {
        After = function(sec, fn) client.timers[#client.timers + 1] = { at = client.now + sec, fn = fn } end,
        NewTicker = function(sec, fn)
            local t = { at = client.now + sec, fn = fn, every = sec }
            function t:Cancel() self.cancelled = true end
            client.timers[#client.timers + 1] = t
            return t
        end,
    }

    -- Addon metadata
    local files, version = ReadToc(root)
    env.C_AddOns = { GetAddOnMetadata = function(_, field) if field == "Version" then return version end end }

    -- Player
    env.UnitName = function() return player.name end
    env.UnitClass = function() return player.className, player.class, 8 end
    env.UnitLevel = function() return player.level end
    env.UnitXP = function() return player.xp end
    env.UnitXPMax = function() return player.xpMax end
    env.UnitFactionGroup = function() return player.faction end
    env.GetXPExhaustion = function() if player.rested > 0 then return player.rested end end
    env.IsResting = function() return player.resting end
    env.IsXPUserDisabled = function() return player.xpDisabled end
    env.GetRealmName = function() return player.realm end
    env.GetRealZoneText = function() return player.zone end
    env.GetSubZoneText = function() return player.subzone end
    env.GetBindLocation = function() return player.bind end
    env.GetMoney = function() return player.money end
    env.GetMaxPlayerLevel = function() return 60 end
    env.GameRulesUtil = { GetEffectiveMaxLevelForPlayer = function() return 60 end }
    env.C_GameRules = { IsHardcoreActive = function() return player.hardcore end }

    -- Legacy perks: one tree node per perk in player.perks, plus a few others.
    local NODE_SPELLS = { [501] = 1225478, [502] = 1225469, [503] = 999001 }
    env.C_Traits = {
        GetConfigIDByTreeID = function(tree) if player.legacyUnlocked then return 9000 + tree end end,
        GetTreeNodes = function(tree)
            if tree == 1188 then return { 501, 503 } elseif tree == 1187 then return { 502 } end
            return {}
        end,
        GetNodeInfo = function(_, node)
            local spell = NODE_SPELLS[node]
            return { ID = node, activeRank = player.perks[spell] or 0, maxRanks = 5, entryIDs = { node * 10 } }
        end,
        GetEntryInfo = function(_, entry) return { definitionID = entry } end,
        GetDefinitionInfo = function(def) return { spellID = NODE_SPELLS[def / 10] } end,
        GetTreeCurrencyInfo = function()
            return { { quantity = player.legacy.unspent, spent = player.legacy.spent, maxQuantity = player.legacy.cap } }
        end,
        GetMaxAvailableTraitCurrency = function() return 65 end,
        GetTraitCurrencyForAchievement = function() return 1 end,
    }
    env.C_MajorFactions = { GetCurrentRenownLevel = function() return 6 end }
    env.C_Spell = {
        GetSpellName = function(id) return "Spell" .. id end,
        GetSpellCooldown = function(id)
            local cd = player.spellCooldowns[id]
            return { startTime = cd and cd[1] or 0, duration = cd and cd[2] or 0, isEnabled = true, isActive = cd ~= nil }
        end,
    }

    -- Achievements (Legacy challenges)
    local function Ach(id)
        for _, cat in ipairs(client.catalog) do
            for _, a in ipairs(cat.achievements) do if a.id == id then return a end end
        end
    end
    local function AchState(a)
        return player.achievements[a.id] or {}
    end
    env.GetCategoryList = function()
        local ids = {}
        for _, cat in ipairs(client.catalog) do ids[#ids + 1] = cat.id end
        return ids
    end
    env.GetCategoryInfo = function(id)
        for _, cat in ipairs(client.catalog) do if cat.id == id then return cat.name, -1 end end
    end
    env.GetCategoryNumAchievements = function(id)
        for _, cat in ipairs(client.catalog) do if cat.id == id then return #cat.achievements, 0, #cat.achievements end end
        return 0, 0, 0
    end
    env.GetAchievementInfo = function(a1, a2)
        local a
        if a2 then
            for _, cat in ipairs(client.catalog) do if cat.id == a1 then a = cat.achievements[a2] end end
        else
            a = Ach(a1)
        end
        if not a then return end
        local s = AchState(a)
        return a.id, a.name, 1, s.completed or false, nil, nil, nil, "", 0, 136243, "", false, s.earnedByMe or false, nil
    end
    env.GetAchievementNumCriteria = function() return 1 end
    env.GetAchievementCriteriaInfo = function(id)
        local a = Ach(id)
        local s = AchState(a)
        return a.criteria or a.name, 0, s.earnedByMe or false, s.q or 0, a.req or 1
    end

    -- Professions and skills
    env.GetProfessions = function()
        local p = player.professions
        return p[1] and 1 or nil, p[2] and 2 or nil, nil, p[3] and 3 or nil, p[4] and 4 or nil
    end
    env.GetProfessionInfo = function(i)
        local p = player.professions[i]
        return p.name, p.icon or 134939, p.rank, p.max, 0, 0, p.skillLine
    end
    env.C_SkillInfo = { GetSkillLineInfoByID = function(id) if id == 762 and player.riding > 0 then return { rank = player.riding } end end }
    env.C_Reputation = {
        GetFactionDataByID = function(id)
            if id == 2586 and player.faction == "Alliance" then
                return { factionID = id, name = "Azeroth Commerce Authority", reaction = 5, currentReactionThreshold = 3000, nextReactionThreshold = 9000, currentStanding = 4500 }
            end
        end,
        GetNumFactions = function() return 0 end,
        GetFactionDataByIndex = function() end,
    }
    env.C_CurrencyInfo = { GetCurrencyInfo = function(id) if id == 3402 then return { name = "Merchant's Favor", quantity = player.favor or 0, iconFileID = 1 } end end }
    env.C_TradeSkillUI = {
        IsDataSourceChanging = function() return false end,
        IsTradeSkillLinked = function() return false end,
        GetBaseProfessionInfo = function() return client.openProfession and { professionName = client.openProfession } or {} end,
        GetFilteredRecipeIDs = function()
            local ids = {}
            for id in pairs(client.recipes) do ids[#ids + 1] = id end
            table.sort(ids)
            return ids
        end,
        GetRecipeInfo = function(id) local r = client.recipes[id] return { recipeID = id, name = r.name, learned = r.learned, icon = 1 } end,
        GetRecipeSchematic = function(id)
            local r = client.recipes[id]
            local slots = {}
            for _, reagent in ipairs(r.reagents or {}) do
                slots[#slots + 1] = { reagents = { { itemID = reagent[1] } }, quantityRequired = reagent[2], required = true }
            end
            return { recipeID = id, outputItemID = r.output, reagentSlotSchematics = slots }
        end,
    }
    env.C_SpellBook = {
        IsSpellKnown = function(id) return player.spells[id] or false end,
    }
    env.GetNumTrainerServices = function() return #client.trainer end
    env.GetTrainerServiceInfo = function(i) local s = client.trainer[i] return s.name, s.kind, 1, s.level end
    env.IsTradeskillTrainer = function() return false end

    -- Items, bags, bank
    env.C_Item = {
        GetItemCount = function(id) return player.items[id] or 0 end,
        GetItemInfoInstant = function(id)
            local info = client.itemInfo and client.itemInfo[id]
            if info then return id, nil, nil, nil, nil, info.classID, info.subclassID end
            return id, nil, nil, nil, nil, 7, 0
        end,
        GetItemNameByID = function(id) local info = client.itemInfo and client.itemInfo[id] return info and info.name or ("Item" .. id) end,
    }
    env.C_Container = {
        GetItemCooldown = function(id)
            local cd = player.itemCooldowns[id]
            if cd then return cd[1], cd[2], 1 end
            return 0, 0, 1
        end,
        GetContainerNumSlots = function(bag)
            if bag == 0 then return 16 end
            if bag >= 1 and bag <= 4 then return 0 end
            if bag == 6 then return client.bankOpen and 28 or 0 end
            return 0
        end,
        GetContainerItemInfo = function(bag, slot)
            local list = bag == 0 and player.bagSlots or (bag == 6 and player.bankSlots) or nil
            local e = list and list[slot]
            if e then return { itemID = e[1], stackCount = e[2], itemName = e[3], hyperlink = "|Hitem:" .. e[1] .. "|h[" .. e[3] .. "]|h" } end
        end,
    }
    env.C_Bank = { FetchPurchasedBankTabData = function() return { { ID = 6 } } end }
    env.C_UnitAuras = { GetPlayerAuraBySpellID = function(id) local exp = player.auras[id] if exp then return { expirationTime = exp } end end }
    env.C_QuestLog = { IsQuestFlaggedCompleted = function(id) return player.quests[id] or false end }

    -- Mail
    env.SendMail = function(to, subject, body) client.sentMail[#client.sentMail + 1] = { to = to, subject = subject } end
    env.GetSendMailItem = function(i) local e = client.mailItems[i] if e then return e[3], e[1], 1, e[2] end end
    env.GetSendMailItemLink = function() return nil end
    env.GetSendMailMoney = function() return client.sendMoney end
    env.GetSendMailCOD = function() return client.sendCOD end
    env.GetInboxNumItems = function() return #client.inbox, #client.inbox end
    env.GetInboxHeaderInfo = function(i)
        local m = client.inbox[i]
        return nil, nil, m.sender, m.subject, m.money or 0, m.cod or 0, m.daysLeft, m.items and #m.items or 0, false, false
    end
    env.GetInboxItem = function(i, a) local e = client.inbox[i].items and client.inbox[i].items[a] if e then return e[3], e[1], 1, e[2] end end
    env.GetInboxItemLink = function() return nil end

    -- Tooltip data
    env.TooltipDataProcessor = { AddTooltipPostCall = function(kind, fn) client.postCalls[#client.postCalls + 1] = fn end }

    -- Strict globals
    setmetatable(env, {
        __index = function(_, k)
            if NILABLE[k] then return nil end
            error("read of undefined global '" .. tostring(k) .. "'", 2)
        end,
        __newindex = function(t, k, v)
            if not ALLOWED_GLOBALS[k] then error("addon wrote global '" .. tostring(k) .. "'", 2) end
            client.globalWrites[k] = true
            rawset(t, k, v)
        end,
    })
    if opts.db then rawset(env, "NothingWastedDB", Copy(opts.db)) end

    client.env = env
    client.ns = {}
    for _, file in ipairs(files) do
        local fn = assert(loadfile(root .. "/NothingWasted/" .. file))
        setfenv(fn, env)
        fn("NothingWasted", client.ns)
    end

    -- Driving -------------------------------------------------------------------------------------

    function client:Fire(event, ...)
        local set = self.events[event]
        if not set then return end
        local list = {}
        for f in pairs(set) do list[#list + 1] = f end
        for _, f in ipairs(list) do
            if f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
        end
    end

    function client:Advance(seconds)
        self.now = self.now + seconds
        local due = {}
        for _, t in ipairs(self.timers) do
            if t.at <= self.now and not t.cancelled then due[#due + 1] = t end
        end
        local keep = {}
        for _, t in ipairs(self.timers) do
            if not t.cancelled and (t.at > self.now or t.every) then keep[#keep + 1] = t end
        end
        self.timers = keep
        for _, t in ipairs(due) do
            if t.every then t.at = self.now + t.every end
            t.fn()
        end
    end

    function client:Login()
        self:Fire("ADDON_LOADED", "NothingWasted")
        self:Fire("PLAYER_LOGIN")
        self:Fire("PLAYER_ENTERING_WORLD", true, false)
        self:Advance(6) -- let the login timers run
    end

    function client:Logout()
        self:Fire("PLAYER_LOGOUT")
        return Copy(rawget(self.env, "NothingWastedDB"))
    end

    function client:Slash(msg) self.env.SlashCmdList.NOTHINGWASTED(msg) end

    function client:Frame(name) return namedFrames[name] end

    function client:ChatHas(pattern)
        for _, m in ipairs(self.chat) do
            if m:find(pattern) then return true end
        end
        return false
    end

    function client:ClearChat() self.chat = {}; self.sounds = {} end

    -- Shown rows of the visible list in a tab panel: frames with .item that are shown.
    function client:Rows(panel)
        local rows = {}
        for _, f in ipairs(self.frames) do
            if f.item and f.shown and f.parent and f.parent.parent and f.parent.parent:IsVisible()
                and f:IsVisible() then
                local inPanel = false
                local p = f.parent
                while p do
                    if p == panel then inPanel = true end
                    p = p.parent
                end
                if inPanel then rows[#rows + 1] = f end
            end
        end
        return rows
    end

    function client:Hover(frame)
        frame.scripts.OnEnter(frame)
        return self.env.GameTooltip
    end

    function client:ItemTooltip(itemID, lines)
        local tip = NewTooltip()
        for _, fn in ipairs(self.postCalls) do fn(self.env.GameTooltip, { id = itemID, lines = lines or {} }) end
        return self.env.GameTooltip
    end

    return client
end

M.SecretMeta = { __tostring = function() return "<secret>" end }
function M.Secret(v) return setmetatable({ value = v }, M.SecretMeta) end

M.T0 = T0
return M
