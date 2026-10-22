-- Nothing Wasted: the character tooltip shown when hovering a bar.
--
-- Modules add sections with Tooltip.AddSection. Each section can be turned off in the options
-- (settings.tooltip[id]).
local _, ns = ...

local Tooltip = {}
ns.Tooltip = Tooltip

local sections = {}

-- def: { id, label, order, add(tooltip, c, now, isMe) }
function Tooltip.AddSection(def)
    sections[#sections + 1] = def
    table.sort(sections, function(a, b) return a.order < b.order end)
end

function Tooltip.Sections()
    return sections
end

-- Adds a character's name and every enabled section to a tooltip.
function Tooltip.Fill(tip, c, now, isMe)
    tip:AddLine((c.name or "?") .. (c.realm and ("  |cff999999" .. c.realm .. "|r") or ""), ns.ClassColor(c))
    local enabled = ns.db.settings.tooltip
    for _, def in ipairs(sections) do
        if enabled[def.id] ~= false then
            def.add(tip, c, now, isMe)
        end
    end
end

function Tooltip.ShowCharacter(owner, c, isMe)
    local tip = GameTooltip
    tip:SetOwner(owner, "ANCHOR_RIGHT")
    Tooltip.Fill(tip, c, ns.Now(), isMe)
    tip:Show()
end
