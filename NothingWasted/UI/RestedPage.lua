-- Nothing Wasted: the Rested XP page. The same bars as the small bars window, in the full window.
local _, ns = ...
local L = ns.L

local ROW_HEIGHT = 24

ns.Window.AddPage({
    id = "rested",
    group = "rested",
    label = L["Rested"],
    order = 1,
    build = function(panel)
        panel.list = ns.UI.List(panel, ROW_HEIGHT, ns.Bars.CreateRow, ns.Bars.UpdateRow)
    end,
    refresh = function(panel)
        panel.list:SetItems(ns.Bars.Items(), L["Log in to each character once to add it."])
    end,
})
