# Security

## Reporting a problem

Email addohm@gmail.com with the details and steps to reproduce it. Please don't post exploitable
problems in a public issue.

## What the addon can access

Nothing Wasted runs inside the World of Warcraft addon sandbox. It reads your
character's name, realm, class, level, XP, rested XP, rested status, zone, gold, professions, skill
levels and known recipes, reputations and currencies, cooldowns, quest progress, Legacy perks and
challenge progress, the contents of bags, bank and mailbox, and the mail you send to your own
characters. It has no network, file system or chat-sending access beyond printing messages to
your own chat frame and playing sounds.

## Repository access

Only the repository owner (addohm) pushes to `main`. Players install the addon by copying the folder
or from CurseForge and Wago (see [DEPLOY.md](DEPLOY.md)). Release uploads use CurseForge and Wago API
keys, which belong in the CI's secret store, never in the repository.

## Data and secrets

- The data is saved locally by the game client in `WTF/Account/<account>/SavedVariables/`. It
  contains the character details above and logout times. It never leaves your machine
  unless you copy it somewhere.
- The addon handles no credentials or secrets. `.gitignore` excludes secret-looking files anyway.
