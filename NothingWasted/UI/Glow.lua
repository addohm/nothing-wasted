-- Nothing Wasted: a glow around the screen edge that pulses, using the game's own low-health
-- texture. Pulse() flashes it red a few times (the alerts); SetSteady() keeps one pulsing until
-- it's turned off (a missing leveling buff), in red or another colour.
local _, ns = ...

local Glow = {}
ns.Glow = Glow

local TEXTURE = "Interface\\FullScreenTextures\\LowHealth"
local PULSES = 4       -- fade in and out this many times per alert
local HALF_PULSE = 0.5 -- seconds

-- How strong the steady glow gets at the top of each pulse.
Glow.STRENGTHS = { low = 0.4, medium = 0.7, high = 1 }

-- A glow frame with its pulse. `pulses` stops it after that many; nil pulses until stopped.
local function NewGlow(pulses)
    local g = {}
    g.frame = CreateFrame("Frame", nil, UIParent)
    g.frame:SetAllPoints(UIParent)
    g.frame:SetFrameStrata("FULLSCREEN_DIALOG")
    g.frame:EnableMouse(false)
    g.frame:Hide()

    g.tex = g.frame:CreateTexture(nil, "BACKGROUND")
    g.tex:SetAllPoints()
    g.tex:SetTexture(TEXTURE)
    g.tex:SetBlendMode("ADD")

    g.anim = g.frame:CreateAnimationGroup()
    g.alpha = g.anim:CreateAnimation("Alpha")
    g.alpha:SetFromAlpha(0.15)
    g.alpha:SetToAlpha(1)
    g.alpha:SetDuration(HALF_PULSE)
    g.anim:SetLooping("BOUNCE")

    local halves = 0
    g.anim:SetScript("OnPlay", function() halves = 0 end)
    if pulses then
        g.anim:SetScript("OnLoop", function()
            halves = halves + 1
            if halves >= pulses * 2 then g.anim:Stop() end
        end)
    end
    g.anim:SetScript("OnStop", function() g.frame:Hide() end)
    return g
end

local flash, steady
local steadyKey -- the colour and strength the steady glow was started with

function Glow.IsPulsing()
    return flash ~= nil and flash.anim:IsPlaying()
end

function Glow.Pulse()
    flash = flash or NewGlow(PULSES)
    flash.anim:Stop()
    flash.frame:Show()
    flash.anim:Play()
end

-- The colour for a setting: "red" (the texture's own), "gold" or "class".
local function Colour(name)
    if name == "gold" then return 1, 0.82, 0 end
    if name == "class" then
        local _, class = UnitClass("player")
        local c = RAID_CLASS_COLORS[class]
        if c then return c.r, c.g, c.b end
    end
end

-- Starts the steady glow (colour "red", "gold" or "class"; strength a key of STRENGTHS), or
-- stops it when `on` is false. Starting it again with the same look leaves the pulse running.
function Glow.SetSteady(on, colour, strength)
    if not on then
        steadyKey = nil
        if steady then steady.anim:Stop() end
        return
    end
    local key = tostring(colour) .. ":" .. tostring(strength)
    if steadyKey == key and steady.anim:IsPlaying() then return end
    steady = steady or NewGlow(nil)
    steadyKey = key
    local r, g, b = Colour(colour)
    -- Other colours tint a grey copy of the red texture.
    steady.tex:SetDesaturated(r ~= nil)
    steady.tex:SetVertexColor(r or 1, g or 1, b or 1)
    local top = Glow.STRENGTHS[strength] or Glow.STRENGTHS.medium
    steady.alpha:SetFromAlpha(top * 0.15)
    steady.alpha:SetToAlpha(top)
    steady.anim:Stop()
    steady.frame:Show()
    steady.anim:Play()
end

function Glow.IsSteady()
    return steady ~= nil and steady.anim:IsPlaying()
end
