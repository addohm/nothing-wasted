-- Nothing Wasted: a draggable minimap button, without external libraries.
local _, ns = ...
local L = ns.L

local Minimap_ = {}
ns.Minimap = Minimap_

local ICON = "Interface\\AddOns\\NothingWasted\\Media\\Icon" -- the addon's own badge (art/make_logo.py)

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

local function Build()
    button = CreateFrame("Button", "NothingWastedMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetPoint("TOPLEFT", 7, -5)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetTexture(ICON)
    icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)
    icon:SetPoint("TOPLEFT", 7, -6)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT")

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            ns.Window.Toggle("options")
        elseif IsShiftKeyDown() then
            ns.Meter.Toggle()
        else
            ns.Window.Toggle()
        end
    end)
    button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", FollowCursor) end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Nothing Wasted")
        GameTooltip:AddLine(L["Click to show your characters."], 1, 1, 1)
        GameTooltip:AddLine(L["Shift-click for the small bars window."], 1, 1, 1)
        GameTooltip:AddLine(L["Right-click for options."], 1, 1, 1)
        GameTooltip:AddLine(L["Drag to move this button."], 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
end

-- The game's addon menu by the minimap (set in the .toc as AddonCompartmentFunc).
function NothingWasted_OnAddonCompartmentClick(_, mouseButton)
    if mouseButton == "RightButton" then
        ns.Window.Toggle("options")
    else
        ns.Window.Toggle()
    end
end

function Minimap_.SetShown(shown)
    ns.db.settings.minimap.hide = not shown
    if button then button:SetShown(shown) end
end

ns.On("NW_INIT", function()
    Build()
    UpdatePosition()
    button:SetShown(not ns.db.settings.minimap.hide)
end)
