-- Nothing Wasted: English strings. Keys are the English text, so a missing translation falls back
-- to English. Other locale files only set the keys they translate.
local _, ns = ...

ns.L = setmetatable({}, {
    __index = function(t, key)
        rawset(t, key, key)
        return key
    end,
})
