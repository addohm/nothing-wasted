# Roadmap

What's done for Nothing Wasted and what's next. Update it in the same commit as the change.
[README.md](README.md) describes the features.

## Next, in order

1. **Check the rested rates in game.** The rest of the first in-game pass checked out. Measure the
   inn rate and the away-from-rest rate with the `/run` lines in HANDOFF.md, and compare an alt's
   estimate with its real value the next time it logs in.
2. **Confirm the other open game facts** below, and fix `Data.lua` where they differ.
3. **Release** on CurseForge and Wago (see DEPLOY.md), then open translations on CurseForge.

## To confirm in game

- **Logout values:** whether the game still reports XP, rested XP and the zone at logout. The addon
  keeps the last good snapshot if it doesn't, which can make an alt's estimate start a little early.
- **Rested rates (hardest to test):** 5% of a level per 8h in an inn or city, and a quarter of that
  away from rest (the Classic rule). The `/run` lines in HANDOFF.md measure them.
- **Well Rested:** whether +4% per rank multiplies the cap (rank 5: 180%) or adds to it (170%). The
  addon multiplies.
- **Interface number:** 16001, taken from the old reference addon.
- **Cozy Sleeping Bag:** which of quests 79007 and 79008 is Alliance or Horde (either counts), and
  whether lying in the bag counts as resting at logout.
- **Campfires:** whether logging out at a campfire counts as resting.
- **Recipe tooltips:** that recipe items show the "Requires <profession> (<skill>)" line the addon
  reads, and that recipe names match the item name after "Pattern:", "Recipe:" and so on.
- **Recipe list:** `C_TradeSkillUI.GetFilteredRecipeIDs` is used by Blizzard's UI but undocumented.

## Confirmed in game

- Untrained spells don't show in the spellbook, only at the trainer (2026-10-22).
- The first mount at level 40 costs 100g (2026-10-22).
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
