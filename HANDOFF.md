# Handoff

Where the work stands, so it can carry on from another workspace. Written 2026-10-22.

## Picking up

```bash
git clone https://github.com/addohm/nothing-wasting.git
cd nothing-wasting
pip install lupa
python3 tests/run_tests.py
```

lupa 2.8 bundles Lua 5.1 (`import lupa.lua51`), which matches the game's Lua.

## Where it stands

- **Nothing Wasted 1.0.0 is written** (`NothingWasted/`) and passes the headless tests
  (`tests/`). It hasn't run in the game client yet. That's the next step; ROADMAP.md has the
  checklist and the game facts still to confirm.
- APIs were checked against Blizzard's Forever UI source (build 1.60.1) and game IDs against Wowhead's
  Forever tooltips. Where a value is a guess, `Data.lua` and ROADMAP.md say so.
- The GitHub repo is `addohm/nothing-wasting` (renamed from `rested-xp` on 2026-10-22).
- **Scope:** leveling alts and earning Legacy points. The user cut auction-house mail and item
  tooltip counts as clutter; keep new features inside that scope.
- Key point from the user: estimates must be accurate, so nothing sits at the cap unnoticed. The Well
  Rested rank is read at login, at logout, and when perks change.
- Similar addons exist: ForeverAlts, CLIAlts, Alt Ledger, Rested XP Tracker and Rested XP Helper.
  Nothing Wasted is built from scratch, with no code copied from them.
- **`RestedRoster/`** is an older addon, included only as an example and inspiration. The addon must
  not reference it or import from it. **Never modify it.**

## How the tests work

- `tests/wowmock.lua` builds a fake client per session and loads the addon's files in `.toc` order.
  It's strict: undefined global reads, unexpected global writes, unknown widget methods or templates,
  and NaN or infinity reaching text, bars or tooltips all fail.
- `client:Login()`, `client:Logout()` (returns the saved variables for the next session),
  `client:Advance(seconds)` (moves the clock and runs due timers; a ticker runs at most once per call),
  `client:Fire(event, ...)`, `client:Slash(msg)`, `client:Rows(panel)`, `client:Hover(row)`.
- `tests/smoke.lua` drives sessions across characters: rested estimates and alerts, login reminders,
  hardcore, mail and search, recipes, cooldowns, Legacy goals, and every tab and tooltip.

## Owner's standing rules

These come from the user's global instructions and also apply in the new workspace:

- `.gitignore` excludes secrets from the first commit, and nothing secret-looking gets staged.
- Never print credentials from remotes or env vars.
- The repository root keeps README, CLAUDE, ROADMAP, SECURITY and CHANGELOG (plus DEPLOY here), and
  each change updates them in the same commit.
