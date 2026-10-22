-- Nothing Wasted: a red glow around the screen edge that pulses, using the game's own low-health
-- texture.
local _, ns = ...

local Glow = {}
ns.Glow = Glow

local TEXTURE = "Interface\\FullScreenTextures\\LowHealth"
local PULSES = 4       -- fade in and out this many times per alert
local HALF_PULSE = 0.5 -- seconds

local frame, anim

local function Build()
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetAllPoints(UIParent)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:EnableMouse(false)
    frame:Hide()

    local tex = frame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    tex:SetTexture(TEXTURE)
    tex:SetBlendMode("ADD")

    anim = frame:CreateAnimationGroup()
    local pulse = anim:CreateAnimation("Alpha")
    pulse:SetFromAlpha(0.15)
    pulse:SetToAlpha(1)
    pulse:SetDuration(HALF_PULSE)
    anim:SetLooping("BOUNCE")

    local halves = 0
    anim:SetScript("OnPlay", function() halves = 0 end)
    anim:SetScript("OnLoop", function()
        halves = halves + 1
        if halves >= PULSES * 2 then anim:Stop() end
    end)
    anim:SetScript("OnStop", function() frame:Hide() end)
end

function Glow.IsPulsing()
    return anim ~= nil and anim:IsPlaying()
end

function Glow.Pulse()
    if not frame then Build() end
    anim:Stop()
    frame:Show()
    anim:Play()
end
