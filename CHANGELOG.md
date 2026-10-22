# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Standard docs: README, CLAUDE, CHANGELOG, DEPLOY, SECURITY and ROADMAP.
- HANDOFF.md: current status, plus the design for the planned headless smoke test.

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
