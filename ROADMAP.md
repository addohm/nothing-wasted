# Roadmap

What's done for Nothing Wasted and what's next. Update it in the same commit as the change.
[README.md](README.md) describes the features.

## Next, in order

1. **Check the away-from-rest rate in game.** The inn rate and the rest of the first in-game pass
   checked out. Set `/nw rate`, log out somewhere that isn't an inn or city, and run it again after
   a few hours; the login checks it lists help too.
2. **Confirm the other open game facts** below, and fix `Data.lua` where they differ.
3. **Release** on CurseForge and Wago (see DEPLOY.md), then open translations on CurseForge.

## To confirm in game

- **Rested rate away from rest:** a quarter of the inn rate (the Classic rule). `/nw rate` across a
  logout outside an inn or city, or the login checks it lists, will show it.
- **Well Rested:** whether +4% per rank multiplies the cap (rank 5: 180%) or adds to it (170%). The
  addon multiplies.
- **Interface number:** 16001, taken from the old reference addon.
- **Cozy Sleeping Bag:** which of quests 79007 and 79008 is Alliance or Horde (either counts).
- **Campfires:** whether logging out at a campfire counts as resting.
- **Leveling buffs:** that eating cooked food puts Well Fed XP Boost (spell 1243969) on the player,
  and that the sleeping bag's buff is Well-Rested (429959). Wowhead lists both; not yet seen in game.
- **Recipe tooltips:** that recipe items show the "Requires <profession> (<skill>)" line the addon
  reads, and that recipe names match the item name after "Pattern:", "Recipe:" and so on.
- **Recipe list:** `C_TradeSkillUI.GetFilteredRecipeIDs` is used by Blizzard's UI but undocumented.

## Confirmed in game

- Untrained spells don't show in the spellbook, only at the trainer (2026-10-22).
- The first mount at level 40 costs 100g (2026-10-22).
- The inn rate matches: `/nw rate` measured 6.06% of a level per 8h at Well Rested rank 5, expected
  6.00% (2026-10-22).
- Logging out in the Cozy Sleeping Bag gives no rested XP bonus; it isn't a rested area (2026-10-22).
- At logout the game reports empty data (professions vanished from saved characters), so the addon
  doesn't re-read at logout except the XP snapshot and Well Rested, both guarded (2026-10-22).
- A first in-game pass: the windows, alerts, tracking and saving work (2026-10-22).

## Ideas

- Show rested XP on the character-select screen, if the client ever allows addons there.
- Per-realm group headers for players with many alts.

## Done

- Standard docs (2026-10-22).
- Removed the 0.1.0 draft to plan the project first (2026-10-22).
- Core design: features, alerts, bars, Legacy goals and the name Well Rested (2026-10-22).
- Renamed to Nothing Wasted (2026-10-22).
- Scope set: leveling alts and Legacy points. Added cooldowns, sleeping bag, mail, item search,
  professions, leveling and Legacy planner features (2026-10-22).
- Launch scope: every planned feature, including mail and item search. Starter set of six
  languages plus English (2026-10-22).
- Translations from contributors. Window: tabs, with the Rested tab showing only the bars
  (name and time to cap) and their tooltips (2026-10-22).
- 1.0.0 written: every planned feature, with headless tests (2026-10-22).
