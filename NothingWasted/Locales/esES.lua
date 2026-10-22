-- Nothing Wasted: esES strings. Translations come from contributors through CurseForge's
-- localization tool; the packager fills in the line below when building a release.
local locale = GetLocale()
if locale ~= "esES" and locale ~= "esMX" then return end
local _, ns = ...
local L = ns.L

--@localization(locale="esES", format="lua_additive_table", handle-unlocalized="ignore")@
