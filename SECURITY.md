# Security

## Reporting a problem

Email addohm@gmail.com with the details and steps to reproduce it. Please don't post exploitable
problems in a public issue.

## What the addon can access

Rested Alts runs inside the World of Warcraft addon sandbox. It reads your character's name, realm,
class, level, XP, rested XP, rested status and zone. It has no network, file system or chat-sending
access beyond printing messages to your own chat frame.

## Repository access

Only the repository owner (addohm) pushes to `main`. Players install the addon by copying the folder
(see [DEPLOY.md](DEPLOY.md)), so no deploy access is needed.

## Data and secrets

- The data is saved locally by the game client in `WTF/Account/<account>/SavedVariables/RestedAlts.lua`.
  It contains character names, realms, levels, XP and logout times. It never leaves your machine
  unless you copy it somewhere.
- The addon handles no credentials or secrets. `.gitignore` excludes secret-looking files anyway.
