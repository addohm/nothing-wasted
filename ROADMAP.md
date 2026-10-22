# Roadmap

What's done for Nothing Wasted and what's next. Update it in the same commit as the change.
[README.md](README.md) describes the features.

## Next, in order

1. **Test in game.** Install with `tools\install_forever.cmd`, check `/nw help` shows the build, load
   with no errors, then check:
   - The bars and times match the game: log out a character in an inn, check the estimate the next
     day against the real value when you log it in.
   - The cap alert, early warning, logout warning, glow and sound.
   - Well Rested: `/nw perks` lists the perk (spell 1225478), and spending a point changes the cap.
   - Cooldowns, professions, recipes (open each profession window), bank, mail sent to an alt, item
     search, Legacy goals and the planner.
   - The small bars window pops up in an inn or city and hides when leaving; the full window doesn't.
   - The full window: tabs, view links, the gear button, option rows and Defaults buttons.
2. **Confirm the open game facts** below, and fix `Data.lua` where they differ.
3. **Release** on CurseForge and Wago (see DEPLOY.md), then open translations on CurseForge.

## To confirm in game

- **Saving across characters:** after logging out of one character, `/nw chars` on the next one
  should say "saved by <first character>". If it says no saved data was found, the game isn't
  writing the file.
- **Logout values:** whether the game still reports XP, rested XP and the zone at logout. The addon
  keeps the last good snapshot if it doesn't, which can make an alt's estimate start a little early.

- **Rested rate away from inns:** the addon uses a quarter of the inn rate (the Classic rule).
- **Well Rested:** whether +4% per rank multiplies the cap (rank 5: 180%) or adds to it (170%). The
  addon multiplies.
- **Interface number:** 16001, taken from the old reference addon.
- **Future spells:** whether Forever lists untrained spells in the spellbook. If not, "spells to
  train" only updates at a trainer.
- **Cozy Sleeping Bag:** which of quests 79007 and 79008 is Alliance or Horde (either counts), and
  whether lying in the bag counts as resting at logout.
- **Campfires:** whether logging out at a campfire counts as resting.
- **First mount:** level 40, 120g (from fan guides).
- **Recipe tooltips:** that recipe items show the "Requires <profession> (<skill>)" line the addon
  reads, and that recipe names match the item name after "Pattern:", "Recipe:" and so on.
- **Recipe list:** `C_TradeSkillUI.GetFilteredRecipeIDs` is used by Blizzard's UI but undocumented.

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
