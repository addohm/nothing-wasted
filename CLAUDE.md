# CLAUDE.md

Guidance for coding assistants working in this repository.

## Layout

- `NothingWasted/`: the addon. `NothingWasted.toc` sets the load order; its `## Version` is the only
  version source.
  - `Locales/`: strings. English text is the key (`L["..."]`); other locales are filled by the
    CurseForge packager.
  - `Core.lua`: saved data and defaults, the event bus (`ns.On`, `ns.Fire`; `NW_*` are internal
    messages), shared helpers.
  - `Data.lua`: game IDs and numbers (rested rules, perks, cooldowns, quests, factions). Each value
    says whether it's confirmed.
  - `Rested.lua`: the rested XP model.
  - `Character.lua`, `Legacy.lua`, `Cooldowns.lua`, `Professions.lua`, `Inventory.lua`, `Mail.lua`,
    `Leveling.lua`: read the game and save per character. `Alerts.lua` scans the saved data.
  - `UI/`: the window (`Window.lua`), one file per tab, the character tooltip (`Tooltip.lua`,
    `Sections.lua`), widgets, the screen glow and the minimap button.
  - `Slash.lua`: `/nw` and the popups.
- `tests/`: `wowmock.lua` (a strict fake WoW client), `smoke.lua` (scenarios), `run_tests.py`.
- `.pkgmeta`: packaging for CurseForge and Wago.
- `tools/install_forever.cmd`: pulls and copies the addon into the user's Forever client on Windows, and
  stamps the commit into the installed `NothingWasted/Build.lua` (empty in the repo and in releases).
  Keep it CRLF (`.gitattributes`).
- `RestedRoster/`: an older addon kept only as an example and inspiration. **Do not modify it.**

## Rules

- Discuss new ideas with the user before building them; record agreed design in README and ROADMAP.
- The addon stands alone: no references to RestedRoster, no import of its data, no dependency on it.
- Target client: WoW: Forever, Interface 16001. That's the modern retail client with the Midnight
  addon API, not a Classic-era client. Check API in Blizzard's UI source, `forever` branch:
  https://github.com/Gethe/wow-ui-source/tree/forever. Prefer `C_*` functions; many old globals are gone.
- No external libraries (Ace, LibDBIcon and so on).
- Files share state through the namespace (`local _, ns = ...`). The only globals are
  `NothingWastedDB`, `NothingWastedFrame`, `NothingWastedMinimapButton`,
  `NothingWasted_OnAddonCompartmentClick` and the slash/popup registrations. The tests enforce this.
- New settings go in `DEFAULT_SETTINGS` in `Core.lua`, so existing installs pick them up.
- Game IDs go in `Data.lua`, with a note on where they were checked.
- User-facing text goes through `L["..."]`.
- No code copied from other addons.

## Commands

```bash
python3 tests/run_tests.py   # headless tests under Lua 5.1 (needs: pip install lupa)
```

To try it in game on Windows, push, then run `tools\install_forever.cmd` and `/reload`.

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
   - `NothingWasted.toc` `## Version`: when cutting a release.
3. Run the tests, check that nothing secret-looking is staged, then commit.

## Don't

- Modify `RestedRoster/`.
- Commit secrets (`.env`, keys, tokens) or the `.venv/` folder.
