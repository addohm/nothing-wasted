# Nothing Wasted

A planned World of Warcraft addon for WoW: Forever (Interface 16001) for leveling alts and earning
Legacy points. It tracks every character on your account and makes sure nothing goes to waste:
no alt sits at the rested XP cap, no cooldown sits ready unused, and no mail expires unnoticed.

**Status:** design. There's no addon code yet. See [ROADMAP.md](ROADMAP.md) for the plan.

**Scope:** leveling alts and earning Legacy points. Features outside that stay out, to avoid clutter.

## Planned features

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

### Progress bars

- One bar per character, running from 0 to that character's rested cap, sorted with the soonest to
  cap at the top.
- They appear when you enter an inn or city and hide when you leave. A slash command and the minimap
  button show them anywhere. A window you open yourself stays open when you leave; an option makes
  it hide too.
- Max-level characters can be shown or hidden.
- Hover a bar for the details: time left to cap, level, professions and skill levels, gold, where the
  character logged out, Legacy goal progress, and more. You choose which details show.

### Leveling

- **Who to play next:** ranks alts by the time you have. "You have 2h: play Oldie, caps in 3h, rested
  covers 1.4 levels."
- **How far rested XP carries a character:** "rested takes Kyol to about 34.6."
- **Leveling pace:** levels per hour played, and an estimate of when each alt reaches 60.
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
- Translated into the game's languages at launch.
- To be released on CurseForge and Wago.

### Out of scope

- Auction house mail (sales and expired auctions).
- Item counts added to every item's tooltip. Use item search instead.

## Repository layout

- `RestedRoster/`: an older addon kept only as an example and inspiration. Nothing Wasted won't use it.

## Docs

- [CHANGELOG.md](CHANGELOG.md): what changed
- [DEPLOY.md](DEPLOY.md): installing and releasing, once there's something to install
- [SECURITY.md](SECURITY.md): what the addon will access, its data, and reporting problems
- [ROADMAP.md](ROADMAP.md): the plan and open questions
- [HANDOFF.md](HANDOFF.md): where the work stands
- [CLAUDE.md](CLAUDE.md): notes for coding assistants
