-- Nothing Wasted: bags and bank of every character, and item search.
--
-- Bags are read whenever they change. The bank can only be read while it's open, so it's saved
-- then and shown with its age.
local _, ns = ...
local L = ns.L

local Inventory = {}
ns.Inventory = Inventory

local BAGS = { 0, 1, 2, 3, 4, 5 } -- backpack, four bags, reagent bag

local function RememberItem(itemID, name, link)
    if not itemID then return end
    ns.db.items = ns.db.items or {}
    local item = ns.db.items[itemID]
    if not item then
        item = {}
        ns.db.items[itemID] = item
    end
    if name then item.name = name end
    if link then item.link = link end
end
Inventory.RememberItem = RememberItem

-- Adds the contents of a container to `counts`. Returns the number of slots and free slots.
local function ReadContainer(bag, counts)
    local slots = C_Container.GetContainerNumSlots(bag) or 0
    local free = 0
    for slot = 1, slots do
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info and info.itemID then
            counts[info.itemID] = (counts[info.itemID] or 0) + (info.stackCount or 1)
            RememberItem(info.itemID, info.itemName, info.hyperlink)
        else
            free = free + 1
        end
    end
    return slots, free
end

function Inventory.ReadBags(c)
    local counts = {}
    local slots, free = 0, 0
    for _, bag in ipairs(BAGS) do
        local s, f = ReadContainer(bag, counts)
        if bag <= 4 then -- the reagent bag only holds reagents, so it isn't counted as free space
            slots, free = slots + s, free + f
        end
    end
    c.bags = counts
    c.bagSlots, c.bagFree = slots, free
end

local bankOpen = false

function Inventory.ReadBank(c)
    if not bankOpen or not C_Bank then return end
    local counts = {}
    for _, tab in ipairs(C_Bank.FetchPurchasedBankTabData(Enum.BankType.Character) or {}) do
        ReadContainer(tab.ID, counts)
    end
    c.bank = counts
    c.bankAt = ns.Now()
end

-- Totals ---------------------------------------------------------------------------------------------

-- Where a character holds an item: bags, bank, mailbox, in transit.
function Inventory.CountFor(c, itemID)
    local bags = c.bags and c.bags[itemID] or 0
    local bank = c.bank and c.bank[itemID] or 0
    local mailbox, transit = 0, 0
    if c.mail then
        for _, m in ipairs(c.mail.inbox or {}) do mailbox = mailbox + (m.items and m.items[itemID] or 0) end
        for _, m in ipairs(c.mail.incoming or {}) do transit = transit + (m.items and m.items[itemID] or 0) end
    end
    return bags, bank, mailbox, transit
end

function Inventory.TotalCount(itemID)
    local total = 0
    for _, c in pairs(ns.db.chars) do
        local a, b, m, t = Inventory.CountFor(c, itemID)
        total = total + a + b + m + t
    end
    return total
end

-- Search ---------------------------------------------------------------------------------------------

-- Item IDs matching a query: an item link, an item ID, or part of a name.
function Inventory.Find(query)
    query = query or ""
    local linkID = query:match("item:(%d+)")
    if linkID then return { tonumber(linkID) } end
    if query:match("^%d+$") then return { tonumber(query) } end
    local needle = query:lower()
    if needle == "" then return {} end
    local ids = {}
    for id, item in pairs(ns.db.items or {}) do
        if item.name and item.name:lower():find(needle, 1, true) then ids[#ids + 1] = id end
    end
    table.sort(ids, function(a, b) return (ns.db.items[a].name or "") < (ns.db.items[b].name or "") end)
    return ids
end

-- Search results: one entry per item, each with a list of characters holding it.
function Inventory.Search(query)
    local results = {}
    for _, id in ipairs(Inventory.Find(query)) do
        local holders, total = {}, 0
        for _, c in pairs(ns.db.chars) do
            local bags, bank, mailbox, transit = Inventory.CountFor(c, id)
            local sum = bags + bank + mailbox + transit
            if sum > 0 then
                total = total + sum
                holders[#holders + 1] = { c = c, bags = bags, bank = bank, mailbox = mailbox, transit = transit, total = sum }
            end
        end
        table.sort(holders, function(a, b) return a.total > b.total end)
        local item = ns.db.items and ns.db.items[id] or {}
        results[#results + 1] = { itemID = id, name = item.name or ("item:" .. id), link = item.link, total = total, holders = holders }
    end
    return results
end

function Inventory.ShowSearch(query)
    Inventory.lastQuery = query
    ns.Fire("NW_SEARCH", query)
end

-- Events ---------------------------------------------------------------------------------------------

local pending
local function ReadSoon()
    if pending then return end
    pending = true
    C_Timer.After(1, function()
        pending = false
        local c = ns.Me()
        if not c then return end
        Inventory.ReadBags(c)
        Inventory.ReadBank(c)
        ns.Fire("NW_REFRESH")
    end)
end

ns.On("NW_CHARACTER_SAVED", function(c, reason)
    if reason then Inventory.ReadBags(c) end
end)
ns.On("BAG_UPDATE_DELAYED", ReadSoon)
ns.On("BANKFRAME_OPENED", function()
    bankOpen = true
    ReadSoon()
end)
ns.On("BANKFRAME_CLOSED", function() bankOpen = false end)
ns.On("PLAYERBANKSLOTS_CHANGED", ReadSoon)
ns.On("BANK_TABS_CHANGED", ReadSoon)

-- Tooltip section: bag space.
ns.Tooltip.AddSection({
    id = "bags",
    label = L["Bag space"],
    order = 80,
    add = function(tip, c)
        if c.bagSlots then
            tip:AddDoubleLine(L["Free bag space"], format("%d / %d", c.bagFree or 0, c.bagSlots), 1, 0.82, 0, 1, 1, 1)
        end
    end,
})
