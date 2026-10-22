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
- Leveling buff reminders below max level: a missing Well Fed XP Boost (+5% kill XP) and an unused,
  ready Cozy Sleeping Bag (up to +3% XP), once after login and when the buff wears off; and at
  logout, a reminder to rest in a ready sleeping bag first. Each can be turned off.
- `/nw rate`: measures the rested XP rate in game (a mark, then the rate since it, across a logout
  too) next to the expected rate, and lists automatic checks of the estimate made at each login.
  It shows the mark's clock time and rested value.
- Leveling buff reminders now come when you leave an inn or city, and when a buff wears off out in
  the world, instead of at login. `/nw buffs` shows what they see (Well Fed, where the sleeping bag
  is, its cooldown and buff). A sleeping bag that's a toy counts as carried; one in the bank doesn't.
- A "Farewell" sound choice plays one of the four human NPC farewell lines ("See ya later" and
  others) at random each time, and custom sound IDs can be a comma-separated list played at random.
- Any game sound can be used: a "Custom" choice takes a sound kit ID (as on Wowhead's sound pages)
  or a sound file ID (`file:12345`). The buff reminders have their own sound setting, the same as
  the alert sound by default.
- Spells to train lists each spell under its character (collapsible, open at first), with its rank and training cost, and the
  character's total cost (recorded at the next trainer visit).
- The bars window's title is "Nothing Wasted". A "Bar shows" option picks the bar text: time to cap
  (default), rested XP, rested % of a level, rested % of the cap, or the level rested XP reaches.
- Buff reminders are yellow, play the alert sound (raid warning by default) and flash the screen
  edge; the sound and the flash can each be turned off.
- Mail expiring within 7 days is yellow, within 3 days red, and a login message lists characters with
  mail expiring within 7 days (can be turned off).
- Crafts: character headers start open and profession headers collapsed. Choose goals: categories
  are collapsible (collapsed at first), with a search box.
- Crafted items' tooltips say which of your characters can make them ("Can make: Kampf, Whoat").
- Items → Mail and Professions → Crafts group their rows under collapsible character headers,
  collapsed by default.
- Headless tests under Lua 5.1 with a strict fake WoW client.
- Packaging for CurseForge and Wago (`.pkgmeta`), with translations from contributors.
- `tools/install_forever.cmd`: pulls the repo and installs the addon into the Forever client on
  Windows, creating the addon folder on the first run and stamping the commit so `/nw help` shows
  the build. It says when the addon's file list changed, since the game must then be restarted
  rather than reloaded. It runs from a temporary copy, so a pull that updates the script can't break
  the run.
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

### Changed

- The full window has tabs again, cleaned up: six text tabs (Rested, Leveling, Cooldowns, Professions,
  Items, Legacy), views within a tab as links under it instead of "Show:" buttons, options behind a
  gear button, and lists with indentation, light striping and ruled headers. Options use
  label-and-control rows with arrow selectors and a Defaults button. The item search box sits in the
  Items tab's header, so it's on every Items view.

- "Who to play next" no longer asks how long you'll play. It ranks alts by who's capped, then who
  caps soonest.

### Fixed

- Unticking a challenge on Choose goals left it on the Goals list.

- Other characters' tooltips only showed professions for the character being played. The logout save
  re-read professions, bags and cooldowns while the game reported none, wiping them. They're now read
  at login and as they change during play, not at logout, and an empty logout reading can't lower
  the Well Rested rank. Each alt shows its professions again after its next login.

- The level-40 mount costs 100g in Forever, not 120g.

- "Spells to train" was wiped at every login: the addon looked for untrained spells in the
  spellbook, where Forever doesn't list them. It now saves what the class trainer lists, including
  spells for higher levels, and counts them as trainable once the character reaches their level.

- Other characters were missing from the bars. The logout save could record empty XP data, which hid
  the character like a max-level one. Saves now keep the last good values, and every character gets
  a bar (only max level can be hidden). `/nw chars` lists the saved characters.
- Saved data could fail to save if it held one of Midnight's secret values; they're now removed
  just before the game writes the file. Each save records which character wrote it, and
  `/nw chars` reports it, so a save that didn't happen is visible.

### Removed

- `RestedRoster/`, the older addon that was kept in the repository as an example.
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
