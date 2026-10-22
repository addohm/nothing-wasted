# Roadmap

What's done for rested-xp and what's next. Update it in the same commit as the change.

## Next, in priority order

1. Headless smoke test with a mocked WoW API, under Lua 5.1 via lupa. The full design is in
   [HANDOFF.md](HANDOFF.md).
2. Test in the game client: load with no errors, window and minimap button work, numbers match the
   in-game XP bar for the current character.
3. Check the rested rates and the 150% cap against this client's behavior. Adjust the constants in
   `Core.lua` if they differ.

## Ideas

- Show rested XP on the character-select screen, if the client ever allows addons there.
- A resizable window, and per-realm group headers for players with many alts.

## Done

- Standard docs (2026-10-22).
- 0.1.0 (2026-10-22): a rewrite of RestedRoster with a GUI window, estimates that stay live, time
  until full, rested status, sorting and filters, row tooltips, forget-with-confirm, a minimap
  button, a single version source, and a one-time import from RestedRoster.
- Removed the RestedRoster import and optional dependency, so Rested Alts stands alone (2026-10-22).
