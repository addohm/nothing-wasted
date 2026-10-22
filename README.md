# Nothing Wasted

A World of Warcraft addon for WoW: Forever (Interface 16001) for leveling alts and earning Legacy
points. It tracks every character on your account and makes sure nothing goes to waste: no alt sits
at the rested XP cap, no cooldown sits ready unused, and no mail expires unnoticed.

**Status:** 1.0.0, written and passing its headless tests, but not yet run in the game client. See
[ROADMAP.md](ROADMAP.md) for what still needs checking in game.

**Scope:** leveling alts and earning Legacy points. Features outside that stay out, to avoid clutter.

## Install

Copy the `NothingWasted` folder into your client's `Interface/AddOns` folder (for Forever,
`_forever_/Interface/AddOns`), then log in each character once so it gets recorded.

## Commands

| Command | What it does |
| --- | --- |
| `/nw` | Show or hide the window |
| `/nw [item]` | Find an item on all your characters (an item link or part of a name) |
| `/nw options` | Open the options |
| `/nw minimap` | Show or hide the minimap button |
| `/nw reset` | Forget every character (asks first) |
| `/nw perks` | List the Legacy perk nodes, to check perk spell IDs |

`/nothingwasted` works too, in case another addon uses `/nw`. The minimap button and the game's
addon menu by the minimap also open the window (right-click for options).

## Features

### Rested XP

- Records each character's exact rested XP, level and resting state at login, while you play, and at
  logout.
- Estimates rested XP for characters you're not playing, as accurately as possible. That accounts for
  whether they logged out resting (an inn or city) and their rank in the Legacy perk Well Rested,
  which raises the rate and the cap.
- Shows how long until each character reaches the rested XP cap.

### Cooldowns and camping

- **Dedicated Study:** when the Legacy perk's daily skill point is ready on each character.
- **Camp Tent:** when each character can next use the Leatherworking tent's rested top-up.
- **Profession cooldowns:** for example Mooncloth, transmutes and Salt Shaker. "Ready on 3 alts."
- **Cozy Sleeping Bag:** each character's progress through the quest chain (from level 14), whether
  it has the bag, and when its cooldown is ready.

### Alerts

- **Rested cap reached:** the moment any character reaches the cap, whoever you're playing, you get a
  chat message ("Kyol has hit the rested XP cap! Log in and use it."), a sound, and a red glow around
  the screen edge like low health.
- The alert repeats at every login until you play that character. An option limits it to once.
- **Early warning:** a heads-up before a character caps, 2 hours ahead by default. Adjustable, and it
  can be turned off.
- **Cooldowns ready** and **mail about to expire** use the same alert system.
- **Logout warning:** a chat line if you log out somewhere that isn't resting, where rested XP builds
  at a quarter of the rate.
- You pick the alert sound. The default is the raid warning sound.

### Window

- One window with tabs: Rested (the bars), Cooldowns, Leveling, Professions, Mail and items, Legacy,
  and Options.
- The Rested tab shows only the bars: one per character, with its name and time to cap. The details
  are in each bar's tooltip.

### Progress bars

- One bar per character, running from 0 to that character's rested cap, sorted with the soonest to
  cap at the top.
- They appear when you enter an inn or city and hide when you leave. A slash command and the minimap
  button show them anywhere. A window you open yourself stays open when you leave; an option makes
  it hide too.
- Max-level characters can be shown or hidden.
- Hover a bar for the details: time left to cap, level, professions and skill levels, gold, where the
  character logged out, Legacy goal progress, and more. You choose which details show.
- Right-click a bar to forget that character.

### Leveling

- **Who to play next:** ranks alts by the time you have. "You have 2h: play Oldie, caps in 3h, rested
  covers 1.4 levels."
- **How far rested XP carries a character:** "rested takes Kyol to about 34.6."
- **Leveling pace:** XP per hour online (the addon keeps its own count, no /played needed), and an
  estimate of when each alt reaches 60.
- **Untrained spells:** "Kyol hit 24 and has spells to train."
- **Mount gold:** gold saved toward the level-40 mount as an alt gets close.
- **Hearthstone:** where each alt is bound and when its hearthstone is ready.

### Professions

- Professions and skill levels for every character, including secondary skills.
- **Recipe tooltips:** "Kyol knows this", or "Kyol can learn this at 175".
- **Next trainer rank:** for example "Journeyman at 50". Flags alts stuck at a skill cap that need a
  trainer or a higher level.
- **Forever's trade economy:** Merchant's Favor and the trade reputations (Azeroth Commerce Authority,
  Durotar Supply and Logistics) per character. Recipes are gated behind them.
- **Crafts across alts:** "Kyol can make 12 of this with what your alts hold."

### Mail and items

- **Mail sent to alts:** recorded when you send it (items, gold, cash on delivery), so each alt's
  mailbox is known before you log in. Includes arrival time when there's a delay.
- **Expiring mail:** a warning before uncollected mail is returned or deleted.
- **Item search** across all characters' bags, bank, mailbox and mail in transit, from the addon
  window or with `/nw [item link]`.
- **Free bag space** per character.

### Legacy

- Each character can pick one or more Legacy challenges as goals. Its progress toward them is tracked
  and shown. Challenges that are already complete are hidden from the list.
- **Account planner:** which class milestones (levels 25, 45 and 60) and profession points the account
  still lacks. "A level-25 Paladin would earn a point."

### Other

- Designed for a single account. Hardcore characters are ignored while they're hardcore.
- Settings live in the addon's own options window.
- Slash commands: `/nw`, with `/nothingwasted` as a fallback in case another addon uses `/nw`.
- English, with a starter set of translations: German, French, Spanish, Russian, Simplified Chinese
  and Korean. Translations come from contributors (for example CurseForge's localization tool), so
  each ships when it's ready. More languages later.
- Released on CurseForge and Wago (once tested in game).

### Out of scope

- Auction house mail (sales and expired auctions).
- Item counts added to every item's tooltip. Use item search instead.

## How the estimates work

- Rested XP builds at 5% of a level per 8 hours in an inn or city, a quarter of that elsewhere, up to
  150% of a level. Each Well Rested rank adds 4% to the rate and the cap.
- A character's numbers are exact when you log out; after that they're estimated from where it logged
  out. Logging it in shows the exact value again.
- Some data can only be read at certain times: recipes when a profession window is open, the bank when
  it's open, the mailbox when it's open. The addon keeps what it last saw.

## Repository layout

- `NothingWasted/`: the addon. This folder is what gets installed.
- `tests/`: headless tests that run the addon against a fake WoW API under Lua 5.1.
- `tools/`: `install_forever.cmd`, which installs your build into the game on Windows.
- `RestedRoster/`: an older addon kept only as an example and inspiration. Nothing Wasted doesn't use it.

## Development

Run the tests with Python and lupa (`pip install lupa`):

```bash
python3 tests/run_tests.py
```

To try the latest pushed build on Windows, run `tools\install_forever.cmd` (or double-click it). It
pulls the repo, copies `NothingWasted/` into the Forever client's AddOns folder (creating it on the
first run), and stamps the commit so `/nw help` shows which build is running. Edit `WOW` at the top if
your client is installed elsewhere.

## Docs

- [CHANGELOG.md](CHANGELOG.md): what changed
- [DEPLOY.md](DEPLOY.md): installing and releasing
- [SECURITY.md](SECURITY.md): what the addon accesses, its data, and reporting problems
- [ROADMAP.md](ROADMAP.md): the plan and open questions
- [HANDOFF.md](HANDOFF.md): where the work stands
- [CLAUDE.md](CLAUDE.md): notes for coding assistants
