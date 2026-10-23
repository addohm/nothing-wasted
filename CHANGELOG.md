# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.0.0] - 2026-10-23

First release, for WoW: Forever (client 1.60.1, Interface 16001).

### Added

- **Rested XP for every character:** exact values at login, during play and at logout; offline
  estimates that account for where a character logged out and its Well Rested rank (rate and cap);
  time to cap.
- **Bars window** that pops up in inns and cities (one bar per character, soonest to cap first);
  the bar text can show time to cap, rested XP, % of a level, % of the cap, or the level rested XP
  reaches. Resizable, lockable, and hover any bar for a full character tooltip.
- **Alerts:** rested cap reached (chat, sound, red screen-edge glow), repeated at each login until
  played or only once; early warning before the cap; logout warning away from rest; expiring mail
  (yellow within 7 days, red within 3, listed at login). Any game sound, including a random NPC
  farewell, or a custom sound ID.
- **Leveling buff reminders:** missing Well Fed (+5% kill XP) or an unused Cozy Sleeping Bag
  (up to +3% XP) show as glowing icons where the bars window was when you leave town, with sound and
  flash; and a reminder at logout to rest in a ready bag.
- **Full window** with tabs (Rested, Leveling, Cooldowns, Professions, Items, Legacy) and options
  behind a gear button; resizable.
- **Leveling:** who to play next, leveling pace, how far rested XP carries, spells to train with
  rank and cost (from your class trainer), gold toward the level-40 mount.
- **Cooldowns:** Dedicated Study, Camp Tent, Cozy Sleeping Bag (and its quest chain), Mooncloth,
  transmutes, Salt Shaker, hearthstone.
- **Professions:** skills and trainer ranks, Merchant's Favor and trade reputations, crafts from
  your characters' items, and tooltips on recipe items (who knows it, who can learn it) and crafted
  items (who can make it).
- **Mail and items:** mail sent to your alts recorded at send time, expiring mail, bag space, and
  search across all characters' bags, bank, mailbox and mail in transit (`/nw [item]`).
- **Legacy:** goals per character with progress, a searchable challenge list, and an account
  planner.
- **Tools:** `/nw rate` measures the rested XP rate in game (and checks the estimate at each
  login), `/nw chars`, `/nw buffs`, `/nw perks`.
- Minimap button and the game's addon menu entry, with the addon's own icon.
- Translations ready for contributors on CurseForge (German, French, Spanish, Russian, Simplified
  Chinese, Korean).

## [0.1.0] - 2026-10-22 (draft, never released)

### Added

- Rested Alts: a new addon inspired by RestedRoster (which stays unchanged in `RestedRoster/`).
- A movable roster window that closes with Escape: class-colored names, level, last seen, a rested
  bar running to the 150% cap with a one-level tick, time until full, and a rested status icon.
- Estimates that update while the window is open, plus hover tooltips with exact numbers.
- Sorting by rested XP, level, name or last seen. Filters for this realm and for max level.
- Right-click a row to forget a character, with a confirm popup. `/alts reset` also asks first.
- A draggable minimap button with no library dependency. `/alts minimap` toggles it.
- A one-time import of characters from RestedRoster's saved data.

### Fixed (compared to RestedRoster)

- The version comes from one source, the `.toc`.
- Characters on other realms show their realm, so same-name alts can be told apart.
- Max-level characters no longer appear to gain rested XP.
- The current character shows live values instead of "estimated".
- The saved entry is updated in place instead of rebuilt on every XP event.
