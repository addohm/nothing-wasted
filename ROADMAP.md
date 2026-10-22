# Roadmap

What's done for Nothing Wasted and what's next. Update it in the same commit as the change.
[README.md](README.md) describes the planned features.

## Next, in order

1. Finish the design. Still open:
   - Which languages, and how translations are sourced (for example CurseForge's localization tool).
   - Which of the extra ideas below go in at launch.
   - Anything else the user wants to settle before code.
2. Confirm the game facts the estimates depend on (see below), from the
   [Forever UI source](https://github.com/Gethe/wow-ui-source/tree/forever) and in game.
3. Build it, with a headless test under Lua 5.1 against a mocked WoW API. HANDOFF.md has an older
   test design to adapt.
4. Test in game, then release on CurseForge and Wago.

## To confirm

- **Base rested rules on Forever:** 5% of a level per 8 hours resting, a quarter of that elsewhere,
  capped at 150% of a level.
- **Well Rested perk:** the ranks and their effects. A third-party addon (ForeverAlts) says +4% rate
  and +6% cap per rank, up to a 180% cap. How to read a character's rank (probably `C_Traits` on the
  Legacy trees), and which event fires when a point is spent or refunded.
- **Legacy challenges:** these are achievements in per-class categories (`Constants.LegacyConsts`).
  How to read progress toward one, and whether completion is per character or per account.
- **Camping:** whether logging out at a campfire counts as resting. The Leatherworking Camp Tent tops
  rested XP up to 5% of a level once an hour, which the addon sees live.
- **Hardcore:** `C_GameRules.IsHardcoreActive()`, and what reincarnation does to a character.
- **Logout warning:** which event fires when a logout starts (probably `PLAYER_CAMPING`).

## Ideas

Not decided yet. A possible theme: "nothing wasted", using the same alerts as the rested cap.

- **Cooldowns:** Dedicated Study (Legacy daily skill point), Camp Tent, profession cooldowns
  (Mooncloth, transmutes, Salt Shaker).
- **Mail:** record mail sent to alts (items, gold, COD) so their mailbox is known before login;
  auction mail; expiring-mail warnings.
- **Items:** search across alts (bags, bank, mail, mail in transit), item tooltip counts, free bag
  space. A large feature; likely after launch.
- **Professions:** recipe tooltips ("Kyol knows this" / "can learn at 175"), next trainer rank, alts
  stuck at a skill cap, Merchant's Favor and trade reputations, crafts possible from alts' reagents.
- **Leveling:** who to play next, how far rested carries a character, leveling pace and ETA to 60,
  untrained spells, mount gold at 40, hearthstone location and cooldown.
- **Legacy planner:** which class milestones and profession points the account still lacks.
- Show rested XP on the character-select screen, if the client ever allows addons there.
- Per-realm group headers for players with many alts.

## Done

- Standard docs (2026-10-22).
- Removed the 0.1.0 draft to plan the project first (2026-10-22).
- Core design: features, alerts, bars, Legacy goals and the name Well Rested (2026-10-22).
- Renamed to Nothing Wasted (2026-10-22).
