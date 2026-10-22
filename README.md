# Well Rested

A planned World of Warcraft addon for WoW: Forever (Interface 16001) that tracks every character on
your account as it levels: rested XP, level, professions and Legacy goals. Its main job: make sure no
alt sits at the rested XP cap wasting time.

**Status:** design. There's no addon code yet. See [ROADMAP.md](ROADMAP.md) for the plan.

## Planned features

### Rested XP

- Records each character's exact rested XP, level and resting state at login, while you play, and at
  logout.
- Estimates rested XP for characters you're not playing, as accurately as possible. That accounts for
  whether they logged out resting (an inn or city) and their rank in the Legacy perk Well Rested,
  which raises the rate and the cap.
- Shows how long until each character reaches the rested XP cap.

### Alerts

- **Cap reached:** the moment any character reaches the cap, whoever you're playing, you get a chat
  message ("Kyol has hit the rested XP cap! Log in and use it."), a sound, and a red glow around
  the screen edge like low health.
- The alert repeats at every login until you play that character. An option limits it to once.
- **Early warning:** a heads-up before a character caps, 2 hours ahead by default. Adjustable, and it
  can be turned off.
- **Logout warning:** a chat line if you log out somewhere that isn't resting, where rested XP builds
  at a quarter of the rate.
- You pick the alert sound. The default is the raid warning sound.

### Progress bars

- One bar per character, running from 0 to that character's rested cap, sorted with the soonest to
  cap at the top.
- They appear when you enter an inn or city and hide when you leave. A slash command and the minimap
  button show them anywhere.
- Max-level characters can be shown or hidden.
- Hover a bar for the details: time left to cap, level, professions and skill levels, gold, where the
  character logged out, Legacy goal progress, and more. You choose which details show.

### Legacy goals

- Each character can pick one or more Legacy challenges as goals. Its progress toward them is tracked
  and shown.
- Challenges that are already complete are hidden from the list.

### Other

- Designed for a single account. Hardcore characters are ignored while they're hardcore.
- Settings live in the addon's own options window.
- To be released on CurseForge and Wago.

## Repository layout

- `RestedRoster/`: an older addon kept only as an example and inspiration. Well Rested won't use it.

## Docs

- [CHANGELOG.md](CHANGELOG.md): what changed
- [DEPLOY.md](DEPLOY.md): installing and releasing, once there's something to install
- [SECURITY.md](SECURITY.md): what the addon will access, its data, and reporting problems
- [ROADMAP.md](ROADMAP.md): the plan and open questions
- [HANDOFF.md](HANDOFF.md): where the work stands
- [CLAUDE.md](CLAUDE.md): notes for coding assistants
