# Nothing Wasted: CurseForge and Wago listing

Copy-paste material for the project pages. Placeholders are in [brackets].

---

## Basics

| Field | Value |
| --- | --- |
| Name | Nothing Wasted |
| Slug | `nothing-wasted` |
| Game version | WoW: Forever (Interface 16001, client 1.60.1) |
| Author | addohm |
| License | [choose: All Rights Reserved, MIT, ...] |
| Source | https://github.com/addohm/nothing-wasted |
| Issues | https://github.com/addohm/nothing-wasted/issues |

**Categories**
- CurseForge: Quests & Leveling (main), Professions, Bags & Inventory, Mail
- Wago: Leveling (main), Professions, Inventory, Mail

**Summary** (the one-liner under the name; 142 characters)

> Never waste rested XP again. Tracks every alt's rested XP, cooldowns, professions and mail, and
> tells you the moment a character hits the cap.

**Short tagline** (for images or a Discord post)

> Your alts are resting. Nothing Wasted makes sure it counts.

---

## Description

*(Paste as Markdown. Both sites accept it.)*

### Nothing Wasted

**Built for WoW: Forever, where leveling alts earns Legacy points.**

Every alt you're not playing is quietly building rested XP, and every one of them eventually hits
the cap and starts wasting it. Nothing Wasted watches all your characters at once, so you always
know who to play next and nothing sits idle: no capped rested XP, no ready cooldown left unused,
no mail left to expire.

#### Rested XP, for every character

- A small bars window pops up when you enter an inn or city: one bar per character, soonest to cap
  at the top. It hides again when you leave.
- Offline estimates that account for where each character logged out (inn or city, or out in the
  world) and its **Well Rested** Legacy perk rank, which raises both the rate and the cap.
- Choose what the bars show: time to cap, rested XP, % of a level, % of the cap, or the level the
  rested XP takes you to.
- Hover a bar for everything about that character: rested XP, time to cap, level, professions,
  cooldowns, gold, where it logged out, Legacy goals and more. You pick which details show.

#### Alerts that get your attention

- **Rested cap reached:** the moment any alt hits the cap, whoever you're playing, you get a chat
  alert, a sound and a red screen-edge glow. It reminds you again at each login until you play
  that character.
- **Early warning** before an alt caps (2 hours by default, adjustable).
- **Leveling buffs:** leave town without Well Fed (+5% kill XP) or with your Cozy Sleeping Bag
  unused (+3% XP), and the missing buffs' icons light up where the bars window was.
- **Logout warning** if you log out somewhere rested XP only builds at a quarter of the rate.
- Pick any game sound, including the "See ya later" NPC farewell, or enter any sound ID.

#### Leveling

- **Who to play next:** alts ranked so nothing waits, capped ones first.
- **Spells to train:** visit your trainer once, and as you level the addon lists the spells you can
  train and what they'll cost.
- Leveling pace, how far rested XP carries each alt, and gold saved toward the level-40 mount.
- **Cooldowns** for every character: Dedicated Study, Camp Tent, Cozy Sleeping Bag, Mooncloth,
  transmutes, Salt Shaker, hearthstone.

#### Professions

- Every character's professions and skill levels, with a flag when one is stuck at a trainer cap.
- **Crafts from your alts' items:** what each character can make right now from everything your
  characters hold.
- Item tooltips show which characters can make an item, and recipe tooltips which ones already know
  it or when they can learn it.
- Merchant's Favor and the trade reputations, per character.

#### Mail and items

- Mail you send to your alts is recorded when you send it, so you know what's waiting before you
  log in. Expiring mail turns yellow, then red, and you're told at login.
- Search every character's bags, bank, mailbox and mail in transit: `/nw linen cloth`.

#### Legacy

- Pick Legacy challenges as goals for each character and track their progress.
- The account planner shows the challenges no character has completed yet.

#### Commands

- `/nw`: the full window. `/nw bars`: the bars window. `/nw [item]`: item search.
- `/nw options`, `/nw minimap`, `/nw chars`, `/nw rate`, `/nw buffs`, `/nw help`
- `/nothingwasted` works too.

#### Good to know

- Log in each character once so it gets recorded.
- Everything stays on your computer in the game's own saved data. No network access, no libraries.
- Hardcore characters aren't tracked while they're hardcore.
- **Translations welcome:** German, French, Spanish, Russian, Simplified Chinese and Korean, through
  CurseForge's localization page.

---

## Screenshots to take

1. **Hero:** the bars window in an inn with several alts, one bar red ("At cap!").
2. A bar's tooltip, full of character details.
3. The reminder icons glowing as you leave town (Well Fed and the sleeping bag).
4. The full window, Rested tab.
5. Leveling → Who to play next.
6. Leveling → Spells to train, with prices.
7. Professions → Crafts from your alts' items, expanded.
8. Items → Mail with yellow and red expiry times.
9. Legacy → Choose goals, with the search box in use.
10. Options → Alerts.
11. The cap alert: chat line plus the red screen-edge glow.

Tips: use a clean UI (hide other addons), 16:9 at 1920×1080, crop to the subject, and keep
character names you're happy to show.

---

## Release notes for 1.0.0

> First release, for WoW: Forever.
>
> - Rested XP tracking for every character, with offline estimates that include Well Rested
> - Cap alerts with sound and screen glow, early warnings, login reminders and a logout warning
> - Bars window in inns and cities; glowing reminders for missing Well Fed and sleeping bag buffs
> - Leveling: who to play next, spells to train with costs, pace, mount gold
> - Cooldowns, professions, crafts from your alts' items, recipe and crafted-item tooltips
> - Mail sent to alts, expiring mail warnings, item search across all characters
> - Legacy goals and an account planner

---

## Before publishing

- Confirm the remaining open facts in ROADMAP.md, mainly the away-from-rest rate.
- Bump `## Version` in `NothingWasted.toc` if needed, move the CHANGELOG entries under the version,
  and tag the release (see DEPLOY.md).
- Add the project IDs to the `.toc` (`## X-Curse-Project-ID`, `## X-Wago-ID`) and set up the
  packager.
- Project icon: `art/nothing-wasted-icon-400.png`, the same badge as the in-game minimap button.
