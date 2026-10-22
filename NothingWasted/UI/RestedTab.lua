-- Nothing Wasted: the Rested tab. The same bars as the small bars window, in the full window.
local _, ns = ...
local L = ns.L

local ROW_HEIGHT = 24

ns.Window.AddTab({
    id = "rested",
    label = L["Rested"],
    order = 1,
    build = function(panel)
        panel.list = ns.UI.List(panel, ROW_HEIGHT, ns.Bars.CreateRow, ns.Bars.UpdateRow)
    end,
    refresh = function(panel)
        panel.list:SetItems(ns.Bars.Items(), L["Log in to each character once to add it."])
    end,
})
