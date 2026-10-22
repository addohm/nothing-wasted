# CLAUDE.md

Guidance for coding assistants working in this repository.

## Layout

- `RestedAlts/`: the addon under active development.
  - `RestedAlts.toc`: metadata and load order (Core, UI, Minimap). `## Version` here is the only
    version source; the code reads it with `GetAddOnMetadata`.
  - `Core.lua`: saved data, rested XP estimates, events, popups, slash commands.
  - `UI.lua`: the roster window (rows, sorting, filters, tooltips).
  - `Minimap.lua`: the minimap button. It uses no libraries.
- `RestedRoster/`: an older addon kept only as an example and inspiration. **Do not modify it.**

## Rules

- Rested Alts stands alone: no references to RestedRoster, no import of its data, no dependency on it.
- Target client: Interface 16001. Use only API that Classic-era clients have.
  Don't add feature checks for API that has always existed. Do check API that moved, such as
  `C_AddOns.GetAddOnMetadata`.
- No external libraries (Ace, LibDBIcon and so on). Keep the addon lightweight.
- Files share state through the addon namespace (`local addonName, ns = ...`). Add no new globals
  beyond `RestedAltsDB`, the named frames and the slash/popup registrations.
- Saved data lives in `RestedAltsDB.chars` (keyed `Name-Realm`) and `RestedAltsDB.settings`. New
  settings go in `DEFAULT_SETTINGS` in `Core.lua`, so existing installs pick them up.

## Commands

There's no build step. To try a change, copy `RestedAlts/` into the client's `Interface/AddOns`
and `/reload` in game. If Lua 5.1 is installed, run a syntax check:

```bash
luac -p RestedAlts/*.lua
```

A headless smoke test with a mocked WoW API is planned but not written yet. Its design is in
[HANDOFF.md](HANDOFF.md).

## Workflow

1. Pull before changing anything.
2. Make the change, and **update the docs it affects in the same commit**:
   - `CHANGELOG.md`: an entry under Unreleased.
   - `ROADMAP.md`: tick off finished items, add new ones.
   - `README.md`: when commands, features or install steps change.
   - `DEPLOY.md`: when installing or releasing changes.
   - `SECURITY.md`: when what the addon can access or store changes.
   - `HANDOFF.md`: when work in progress moves on.
   - This file: when the layout, workflow or conventions change.
   - `RestedAlts.toc` `## Version`: when cutting a release.
3. Check that nothing secret-looking is staged, then commit.

## Don't

- Modify `RestedRoster/`.
- Commit secrets (`.env`, keys, tokens) or the `.venv/` folder.
