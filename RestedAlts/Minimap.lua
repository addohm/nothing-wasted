-- Rested Alts: a draggable minimap button, without external libraries.
local _, ns = ...

local ICON = "Interface\\Icons\\Spell_Nature_Sleep"

local button

local function UpdatePosition()
    local angle = math.rad(ns.db.settings.minimap.angle)
    local radius = Minimap:GetWidth() / 2 + 5
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function FollowCursor()
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    ns.db.settings.minimap.angle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
    UpdatePosition()
end

function ns.InitMinimap()
    button = CreateFrame("Button", "RestedAltsMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetPoint("TOPLEFT", 7, -5)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetTexture(ICON)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetPoint("TOPLEFT", 7, -6)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT")

    button:SetScript("OnClick", ns.ToggleUI)
    button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", FollowCursor) end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Rested Alts")
        GameTooltip:AddLine("Click to show your characters' rested XP.", 1, 1, 1)
        GameTooltip:AddLine("Drag to move this button.", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)

    UpdatePosition()
    button:SetShown(not ns.db.settings.minimap.hide)
end

function ns.SetMinimapShown(shown)
    ns.db.settings.minimap.hide = not shown
    button:SetShown(shown)
    ns.Print(shown and "minimap button shown." or "minimap button hidden. Type /alts minimap to bring it back.")
end
