# Handoff

Where the work stands, so it can carry on from another workspace. Written 2026-10-22.

## Picking up

```bash
git clone https://github.com/addohm/rested-xp.git
cd rested-xp
python -m venv .venv
.venv/Scripts/python -m pip install lupa
```

On macOS or Linux the interpreter is `.venv/bin/python`. lupa 2.8 bundles Lua 5.1
(`import lupa.lua51`), which matches the game's Lua and includes `setfenv` and `math.atan2`.

## What's done

- **`RestedAlts/`** is the new addon (v0.1.0): a movable roster window with live estimates, time
  until full, rested status icon, sorting, filters, tooltips, forget-with-confirm, a minimap button
  that uses no libraries, and a one-time import from RestedRoster. [README.md](README.md) describes
  the features; [CLAUDE.md](CLAUDE.md) covers the code layout and rules.
- **`RestedRoster/`** is the original addon, included only as inspiration. **Never modify it.**
- The root docs and `.gitignore`.
- The only check so far: a Python script confirmed every Lua block and bracket is balanced. Nothing
  has run in the game client or under a real Lua interpreter.

## In progress: headless smoke test

The goal is to load the addon under Lua 5.1 (via lupa) against a fake WoW API and drive it through
realistic sessions. Nothing is written yet except the venv. The planned design:

### Files

- `tests/wowmock.lua`: `NewClient(opts)` builds a fresh, isolated client environment. Each addon file
  is loaded with `setfenv(loadfile(path), env)` and called with `("RestedAlts", ns)`. File order and
  `## Version` come from parsing `RestedAlts.toc`.
- `tests/smoke.lua`: the scenarios. Returns `passed, failed`.
- `tests/run_smoke.py`: creates `lupa.lua51.LuaRuntime`, routes Lua `print` to Python's print,
  runs `smoke.lua` with the repo root as its argument, and exits non-zero on any failure.

### Mock rules (to catch real bugs)

- **Strict globals:** reading an undefined global errors. The exceptions are `RestedAltsDB`,
  `RestedRosterDB`, `C_AddOns` and `GetAddOnMetadata`, which can legitimately be nil. Every global
  write is recorded. Only these are allowed: `RestedAltsDB`, `RestedAltsFrame`,
  `RestedAltsMinimapButton`, `SLASH_RESTEDALTS1` and `SLASH_RESTEDALTS2`.
- **Widgets:** `__index` is an explicit method table, so a misspelled method fails as "attempt to call
  a nil value". Implement only the methods the addon uses, with real state for `Show`, `Hide`,
  `SetShown` (firing OnShow and OnHide), `SetText`, `SetFormattedText`, `SetValue`, `SetChecked`,
  `SetPoint`, `GetPoint`, scripts and events.
- **Templates:** only `BackdropTemplate`, `UIPanelCloseButton`, `UIPanelButtonTemplate`,
  `UICheckButtonTemplate` and `UIPanelScrollFrameTemplate` are allowed. `SetBackdrop` requires
  `BackdropTemplate`.
- **NaN and inf guard:** every number or string passed to `SetText`, `SetFormattedText`, `SetValue`,
  `AddLine` or `AddDoubleLine` fails if it's NaN or inf. Windows prints these as `-nan(ind)`/`1.#INF`.
  Don't use test character names that contain "nan".
- **Player API:** reads a mutable `client.player` table. `IsResting` returns `1`/`nil` like older
  clients. `GetXPExhaustion` returns nil when rested XP is 0. `GetMaxPlayerLevel` returns 60.
  `time()` returns `client.now`.
- **Other fakes:** `C_Timer.NewTicker` records tickers, and `client:Tick()` fires them.
  `StaticPopup_Show` records the formatted text and the data, so a test can call the dialog's
  `OnAccept`. `GameTooltip` records its lines and owner.
- **Helpers:** `Fire(event, ...)`, `Slash(msg)`, `Click(btn, mouseButton)` (which toggles
  CheckButtons), `Hover(row)`, `Rows()` (frames with `.entry` that are shown, in creation order),
  `FindText(pattern)`, `TooltipHas(text)`, and `Copy(db)` to carry saved variables into the next
  session.

### Scenarios and expected values

`HOUR = 3600`, `T0 = 1700000000`.

1. **Fresh install on Maxi** (level 60 Warrior on realm Forever, `xpMax = 0`):
   - The first-run hint is printed and Maxi is saved with `isMax`.
   - The window starts hidden and `/alts` opens it.
   - Maxi's row says "Max level", its bar is hidden, its info line shows "online", and the tooltip
     mentions max level.
2. **Kyol** (level 20 Mage on Forever, xp 1000/10000, rested 2000, resting) at `T0 + 2h`, with a
   `RestedRosterDB` containing Oldie, Broken and Maxi:
   - Oldie: level 30, xpMax 20000, rested 0, resting, saved 8h earlier.
   - Broken: xpMax 0.
   - Maxi: level 59.
   - No first-run hint this time.
   - Exactly "imported 1 character(s)": Broken is skipped, and Maxi is not overwritten (it stays
     level 60).
   - Rested sort gives Kyol, Oldie, Maxi.
   - Kyol shows "20%" and "full in 8d 16h", with the rest icon shown.
   - Oldie's bar is about 5 (8h in an inn) and its status is "full in 9d 16h".
   - The summary reads "3 characters  |  0 fully rested".
   - **10 days later**, after `Tick()`: the order is Oldie, Kyol, Maxi. Oldie is at 150 and "Fully
     rested". Kyol stays at 20% (a live value). The summary says 1 fully rested.
   - **Sort button cycle:**
     - Level: Maxi, Oldie, Kyol.
     - Name: Kyol, Maxi, Oldie.
     - Last seen: Kyol first, then Maxi, Oldie.
     - Then back to Rested.
   - **Hide max level** removes Maxi, and the total stays 3.
   - **Right-click Oldie**: the popup reads "Forget Oldie-Forever?". Accepting it removes the row.
   - **Window drag** saves the position.
   - **Minimap drag:** with the cursor straight above the minimap's center, the angle is about 90.
   - `/alts` again hides the window and cancels the ticker.
   - `"  MINIMAP "` hides the minimap button, and running it again shows it.
   - `help` prints "v0.1.0".
   - `RestedAltsFrame` is in `UISpecialFrames`.
3. **Kyol on realm Other** (level 10, xpMax 5000, rested 0, not resting) at `T0 + 12h`, using the
   legacy `GetAddOnMetadata` (no `C_AddOns`):
   - Start with `UnitLevel = 0`: `PLAYER_LOGIN` saves nothing. After setting the level and firing
     `PLAYER_ENTERING_WORLD`, the character is saved.
   - The saved window position is restored.
   - There are two "Kyol" rows. Only the Forever one shows "Forever" in its info line.
   - "This realm" leaves 1 row.
   - Kyol-Other: no rest icon, "0%", "full in 40d 0h", and the tooltip says "quarter".
4. **Maxi** at `T0 + 20h`:
   - Kyol-Other's bar is about 1.25 (8h not resting).
   - `/alts reset` then accepting leaves only Maxi.
   - `settings.sort` persisted as "rested".

The full-in times above come from `(cap - rested) / (xpMax * rate)`, where the inn rate is
`0.05 / 28800` per second and the world rate is a quarter of that.

### After it passes

- Add `.venv/Scripts/python tests/run_smoke.py` to CLAUDE.md's Commands, and a CHANGELOG entry.
- Fix whatever it finds, in the same commit as the test.

## Still open

- **Untested in game.** The target is "WoW: Forever", Interface 16001, copied from RestedRoster.
  Before relying on the code, confirm in game that these Classic-era APIs exist: `BackdropTemplate`,
  `C_Timer.NewTicker`, `GetMaxPlayerLevel`, `UICheckButtonTemplate` and
  `UIPanelScrollFrameTemplate`.
- Confirm the rested rates and the 150% cap for that client. The constants are at the top of
  `RestedAlts/Core.lua`.
- See [ROADMAP.md](ROADMAP.md) for the rest.

## Owner's standing rules

These come from the user's global instructions and also apply in the new workspace:

- `.gitignore` excludes secrets from the first commit, and nothing secret-looking gets staged.
- Never print credentials from remotes or env vars.
- The repository root keeps README, CLAUDE, ROADMAP, SECURITY and CHANGELOG (plus DEPLOY here), and
  each change updates them in the same commit.
