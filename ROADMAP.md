# Roadmap

What's done for rested-xp and what's next. Update it in the same commit as the change.

## Next

1. Spitball and settle the design: what the addon is for, what it shows, and how it behaves.
2. Then write the code, with a headless test.

## Ideas from the removed 0.1.0 draft

These are open for discussion, not decisions.

- A movable window with one row per character: class-colored name, level, last seen, a rested bar to
  the 150% cap with a one-level tick, and time until fully rested.
- An icon for characters that logged out somewhere rested (inn or city).
- Offline estimates that update live while the window is open.
- Row tooltips with exact XP, rested amount, cap and logout zone.
- Sort by rested XP, level, name or last seen. Filter to this realm, or hide max-level characters.
- Right-click a row to forget a character, and a reset command; both ask first.
- A minimap button with no library dependency.
- Slash commands: `/alts`, `/alts minimap`, `/alts reset`.
- A headless smoke test under Lua 5.1 (via lupa) against a mocked WoW API. HANDOFF.md has the old
  design.

## Other ideas

- Show rested XP on the character-select screen, if the client ever allows addons there.
- A resizable window, and per-realm group headers for players with many alts.

## Done

- Standard docs (2026-10-22).
- Removed the 0.1.0 draft to plan the project first (2026-10-22).
