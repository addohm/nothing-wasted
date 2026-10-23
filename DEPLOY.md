# Deploying Nothing Wasted

Nothing Wasted is a World of Warcraft addon. It runs inside the game client (WoW: Forever,
Interface 16001), and there's no server.

## First-time setup

1. Find the client's addon folder. For Forever it's `<WoW install>/_forever_/Interface/AddOns`.
2. Copy the `NothingWasted` folder into it. Don't copy the repository root.
3. Start the game, or type `/reload` if you're already in. Check that Nothing Wasted is enabled under
   AddOns on the character-select screen.

## Shipping a change

1. Run the tests: `python3 tests/run_tests.py`.
2. Bump `## Version` in `NothingWasted/NothingWasted.toc`. It's the only version source.
3. Move the CHANGELOG's Unreleased entries under the new version.
4. Commit and tag the release (`git tag v1.0.0`).
5. To try it locally, run `tools\install_forever.cmd` (see below) and `/reload`.

## Installing your own build on Windows

`tools\install_forever.cmd` pulls the repo from GitHub (`git pull --ff-only`), mirrors
`NothingWasted/` into `<WOW>\Interface\AddOns\NothingWasted`, and writes the commit into the
installed `Build.lua`. `WOW` at the top of the script is the client folder, by default
`C:\Program Files (x86)\World of Warcraft\_classic_beta_` (the beta client). Change it to
`_forever_` for the live game.

- On the first run it creates the addon folder (and `Interface\AddOns` if the client has none yet).
  If `WOW` itself doesn't exist it stops instead, since the path is probably wrong.
- `/nw help` then shows `v1.0.0 build <commit>`; "-dirty" means the copy included uncommitted changes.
- The pull can update the script itself, so it runs from a copy in `%TEMP%`.
- WoW reads the addon's file list only when the game starts. When files were added, renamed or
  removed, the script says so: fully restart the game instead of using `/reload`.
- It only gets what's pushed, so push first. If creating or copying fails, the WoW folder may need
  the script to run as administrator.

## Releasing on CurseForge and Wago

`.pkgmeta` configures the BigWigs packager, which CurseForge and Wago both use. It packages only
the `NothingWasted/` folder and fills in translations from CurseForge's localization tool.

First time only:

1. Create the projects on CurseForge and Wago. `LISTING.md` has the page text, categories and
   screenshot list; `art/` has the icon (`nothing-wasted-icon-400.png` for the avatar) and banner.
2. Add their IDs to the `.toc` as `## X-Curse-Project-ID: <id>` and `## X-Wago-ID: <id>`.
3. Set up the packager: either a GitHub Action (`BigWigsMods/packager`) with `CF_API_KEY` and
   `WAGO_API_TOKEN` as repository secrets, or the sites' own webhooks. Keep the keys out of the repo.

Then each pushed tag builds and uploads a release.

## Translations

Translators add strings on the CurseForge project's localization page. The English text is the key
(see `NothingWasted/Locales/enUS.lua`). The packager writes the translations into the `Locales/`
files at build time, so the copies in the repository stay empty.

## Rolling back

Copy an older version's `NothingWasted` folder from git history (`git checkout <tag> -- NothingWasted`)
over the installed copy.

## Configuration

There are no secrets or environment settings in the addon. In-game settings are saved in
`WTF/Account/<account>/SavedVariables/NothingWasted.lua`.

## Troubleshooting

- **Nothing happens on `/nw`:** the addon isn't loaded. Check the AddOns list. If the game says the
  addon is out of date, the client's Interface number differs from 16001: update the `.toc` or enable
  "Load out of date AddOns". Try `/nothingwasted` in case another addon took `/nw`.
- **Lua errors:** turn on `/console scriptErrors 1` to see them, then report them along with the
  addon version.
- **Well Rested isn't picked up:** run `/nw perks` and check the perk's spell ID against `Data.lua`.
