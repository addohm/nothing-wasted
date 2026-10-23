# Handoff

Where the work stands, so it can carry on from another workspace. Written 2026-10-22.

## Picking up

```bash
git clone https://github.com/addohm/nothing-wasted.git
cd nothing-wasted
pip install lupa
python3 tests/run_tests.py
```

lupa 2.8 bundles Lua 5.1 (`import lupa.lua51`), which matches the game's Lua.

## Where it stands

- **Nothing Wasted 1.0.0 is written and in daily in-game testing** on the Forever beta (as of
  2026-10-22). The first pass checked out and many refinements followed (tabbed window, bars window,
  glowing buff reminder icons, `/nw rate`, `/nw buffs`, resize grips). Still open: the
  away-from-rest rate (being measured) and the Well Rested cap (long term); see ROADMAP.md. After
  that comes the release on CurseForge and Wago. The 1.0.0 package is prepared (2026-10-23):
  `release/NothingWasted-1.0.0.zip`, the CHANGELOG entry and LISTING.md.
- APIs were checked against Blizzard's Forever UI source (build 1.60.1) and game IDs against Wowhead's
  Forever tooltips. Where a value is a guess, `Data.lua` and ROADMAP.md say so.
- The GitHub repo is `addohm/nothing-wasted` (renamed from `rested-xp` on 2026-10-22).
- **Scope:** leveling alts and earning Legacy points. The user cut auction-house mail and item
  tooltip counts as clutter; keep new features inside that scope.
- Key point from the user: estimates must be accurate, so nothing sits at the cap unnoticed. The Well
  Rested rank is read at login, at logout, and when perks change.
- Similar addons exist: ForeverAlts, CLIAlts, Alt Ledger, Rested XP Tracker and Rested XP Helper.
  Nothing Wasted is built from scratch, with no code copied from them.

## Measuring rested rates in game

The rates are the main thing left to confirm. `/nw rate` does it in game: the first run shows the
live XP and rested XP with the expected rate and sets a mark (saved, so it works across a logout);
the next run shows the rate since the mark next to the expected one, and warns if XP was earned in
between. Each login also records a check of the estimate against the real value, listed by
`/nw rate`. Expected per 8 hours: 5.00% of a level resting (6.00% at Well Rested rank 5), a quarter
of that elsewhere. Characters at the beta's level cap report no rested XP, so use one below it.

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
