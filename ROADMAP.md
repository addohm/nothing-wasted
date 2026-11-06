# Roadmap

What's done for Nothing Wasted and what's next. Update it in the same commit as the change.
[README.md](README.md) describes the features.

## Next, in order

1. **Check the away-from-rest rate in game.** The inn rate and the rest of the first in-game pass
   checked out. Set `/nw rate`, log out somewhere that isn't an inn or city, and run it again after
   a few hours; the login checks it lists help too.
2. **Confirm the other open game facts** below, and fix `Data.lua` where they differ.
3. **Release** on CurseForge and Wago (see DEPLOY.md; page text in LISTING.md, icon and banner in
   `art/`), then open translations on CurseForge.

## To confirm in game

- **Rested rate away from rest:** a quarter of the inn rate (the Classic rule). In progress: being
  measured with `/nw rate` across a logout outside an inn or city.
- **Well Rested cap:** whether +4% per rank multiplies the cap (rank 5: 180%) or adds to it (170%). The
  addon multiplies. Long term: it only shows once a character with Well Rested reaches the cap.
- **Cozy Sleeping Bag:** which of quests 79007 and 79008 is Alliance or Horde (either counts).
- **Buff reminder extras:** how the gold and class-colour screen borders look (a grey copy of the
  low-health texture, tinted), the large text (`GameFontNormalHuge3`) and the taskbar flash
  (`FlashClientIcon`).
- **Click to fix:** that clicking the icons eats and uses the bag (`SecureActionButtonTemplate`,
  `type1` item or toy), that the click buttons sit right over the icons (placed by `GetCenter`),
  and that food tooltips name Well Fed (English: "you will become well fed"). In other languages
  the tooltip may word it differently; `/nw buffs` shows the food found.
- **XP missed:** that XP gained minus `QUEST_TURNED_IN`'s XP reward matches the kill XP in chat, and
  that the 5% looks right next to the Well Fed tooltip.
- **Sleeping bag buff:** that it's Well-Rested (429959). Wowhead lists it; not yet seen in game.
- **Characters page and the bar menu:** that right-clicking a bar opens the Stop tracking / Forget
  menu (`MenuUtil.CreateContextMenu`), and the page's tick boxes and Forget buttons line up.
- **Recipe tooltips:** on a recipe item (Pattern:, Recipe:, …), the "Requires <profession> (<skill>)"
  line the addon reads, and recipe names matching the item name after the prefix. Also the new
  "Can make" line on crafted items, such as the Basic Campfire Kit.

## Confirmed in game

- The "Not Well Fed" reminder clears after eating, now that it looks for any buff named Well Fed
  (2026-11-06).
- Untrained spells don't show in the spellbook, only at the trainer (2026-10-22).
- The first mount at level 40 costs 100g (2026-10-22).
- The inn rate matches: `/nw rate` measured 6.06% of a level per 8h at Well Rested rank 5, expected
  6.00% (2026-10-22).
- Logging out in the Cozy Sleeping Bag gives no rested XP bonus; it isn't a rested area (2026-10-22).
- Logging out by a campfire doesn't count as resting either (2026-10-22).
- Recipes are recorded when a profession window is opened (`GetFilteredRecipeIDs` works) (2026-10-22).
- At logout the game reports empty data (professions vanished from saved characters), so the addon
  doesn't re-read at logout except the XP snapshot and Well Rested, both guarded (2026-10-22).
- A first in-game pass: the windows, alerts, tracking and saving work (2026-10-22).
- The client is 1.60.1 (70450), so Interface 16001 is right, and it's the build of Blizzard's UI
  source the API was checked against (2026-10-22).

## Ideas

- Show rested XP on the character-select screen, if the client ever allows addons there.
- Per-realm group headers for players with many alts.

## Done

- Buff reminder extras: pulsing screen border, repeated sound, build up, large text, taskbar
  flash (2026-11-06).
- XP missed without Well Fed on its icon, and a kill bringing dismissed icons back (2026-11-06).
- Click a reminder icon to eat food that gives Well Fed or use the sleeping bag (2026-11-06).
- Untrack characters (a bank alt) and forget deleted ones: Options → Characters, and a right-click
  menu on the bars (2026-11-04).
- Standard docs (2026-10-22).
- Removed the 0.1.0 draft to plan the project first (2026-10-22).
- Core design: features, alerts, bars, Legacy goals and the name Well Rested (2026-10-22).
- 1.0.0 release package prepared: changelog, listing and `release/NothingWasted-1.0.0.zip`
  (2026-10-23).
- Renamed to Nothing Wasted (2026-10-22).
- Scope set: leveling alts and Legacy points. Added cooldowns, sleeping bag, mail, item search,
  professions, leveling and Legacy planner features (2026-10-22).
- Launch scope: every planned feature, including mail and item search. Starter set of six
  languages plus English (2026-10-22).
- Translations from contributors. Window: tabs, with the Rested tab showing only the bars
  (name and time to cap) and their tooltips (2026-10-22).
- 1.0.0 written: every planned feature, with headless tests (2026-10-22).
