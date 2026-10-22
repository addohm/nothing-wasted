# Rested Alts

A World of Warcraft addon (Interface 16001) that shows how much rested XP each of your characters has,
in a small window you can move around. For characters you're not playing, it estimates the rested XP
they've built up since you last logged out.

**Status:** 0.1.0. Written but not yet tested in the game client. See [ROADMAP.md](ROADMAP.md).

## What it does

- One row per character: name in class color, level, when you last played it, a rested bar, and when
  that character will be fully rested.
- The rested bar runs to the 150% cap. The tick mark on it is one full level.
- A sleeping icon means the character logged out somewhere rested (an inn or a city), where rested XP
  builds four times faster.
- Hover a row for the details: XP, exact rested numbers, the cap, and where you logged out.
  Right-click a row to forget that character.
- Sort by rested XP, level, name or last seen. Filter to this realm, or hide max-level characters.
- Draggable minimap button. Escape closes the window.

## Install

Copy the `RestedAlts` folder into your client's `Interface/AddOns` folder, then log in each character
once so it gets recorded.

## Commands

| Command | What it does |
| --- | --- |
| `/alts` or `/restedalts` | Show or hide the window |
| `/alts minimap` | Show or hide the minimap button |
| `/alts reset` | Forget every character (asks first) |

## Limits

- Addons can't run on the character-select screen, so the roster is only visible in game.
- Offline numbers are estimates from the standard rested rates (5% of a level per 8 hours rested,
  a quarter of that elsewhere, capped at 1.5 levels). Logging that character in shows the exact value.

## Repository layout

- `RestedAlts/`: the new addon
- `RestedRoster/`: an older addon kept only as an example and inspiration. Rested Alts doesn't use it.

## Docs

- [CHANGELOG.md](CHANGELOG.md): what changed in each version
- [DEPLOY.md](DEPLOY.md): installing and releasing
- [SECURITY.md](SECURITY.md): what it can access, its data, and reporting problems
- [ROADMAP.md](ROADMAP.md): what's done and what's next
- [HANDOFF.md](HANDOFF.md): where work in progress stands
- [CLAUDE.md](CLAUDE.md): notes for coding assistants
