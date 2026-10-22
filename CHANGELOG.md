# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Nothing Wasted 1.0.0 (not yet released): rested XP tracking with offline estimates that account
  for Well Rested; cap alerts with sound and a red screen-edge glow, early warnings, login reminders
  and a logout warning; a tabbed window (Rested, Cooldowns, Leveling, Professions, Mail and items,
  Legacy, Options) and a small damage-meter-style bars window that pops up in inns and cities
  instead of the full window; character tooltips; cooldown tracking
  (Dedicated Study, Mooncloth, transmutes, Salt Shaker, Camp Tent, Cozy Sleeping Bag, hearthstone);
  leveling pace, who to play next, spells to train and mount gold; professions, trainer ranks,
  recipe tooltips, crafts from your alts' items, Merchant's Favor and trade reputations; mail sent to
  alts, expiring mail, bags, bank and item search; Legacy goals and an account planner; a minimap
  button and the addon menu entry; `/nw`.
- Headless tests under Lua 5.1 with a strict fake WoW client.
- Packaging for CurseForge and Wago (`.pkgmeta`), with translations from contributors.
- `tools/install_forever.cmd`: pulls the repo and installs the addon into the Forever client on
  Windows, creating the addon folder on the first run and stamping the commit so `/nw help` shows
  the build.
- The repository is now `addohm/nothing-wasted` (was `rested-xp`).
- Standard docs: README, CLAUDE, CHANGELOG, DEPLOY, SECURITY and ROADMAP.
- HANDOFF.md: current status, plus the design for the planned headless smoke test.
- The design for Nothing Wasted: features in README.md, plan and open questions in ROADMAP.md.
  Includes slash commands, translations at launch, and the option for manually opened bars.
- Renamed the planned addon from Well Rested to Nothing Wasted.
- Design scope: leveling alts and Legacy points, with cooldowns, Cozy Sleeping Bag, mail, item
  search, professions, leveling and Legacy planner features. Slash command `/nw`.
- Launch scope: all planned features. Translations: a starter set of six languages plus English,
  from contributors.
- Window design: one window with tabs. The Rested tab shows bars with name and time to cap, plus
  tooltips.

### Fixed

- Other characters were missing from the bars. The logout save could record empty XP data, which hid
  the character like a max-level one. Saves now keep the last good values, and every character gets
  a bar (only max level can be hidden). `/nw chars` lists the saved characters.

### Removed

- The RestedAlts 0.1.0 draft (`RestedAlts/`), to plan the project before writing code. It was never
  released or tested. Its ideas are listed in ROADMAP.md.

## [0.1.0] - 2026-10-22

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
