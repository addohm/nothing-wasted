# Deploying Well Rested

There's nothing to install yet: the addon is being designed. The steps below are from the removed
draft (folder `RestedAlts/`). They'll be updated for Well Rested, including CurseForge and Wago
releases, once there's code.

The addon is a World of Warcraft addon. It runs inside the game client (Interface 16001), and
there's no server.

## First-time setup

1. Find the client's addon folder: `<WoW install>/<client folder>/Interface/AddOns`.
2. Copy the `RestedAlts` folder into it. Don't copy the repository root.
3. Start the game, or type `/reload` if you're already in. Check that Rested Alts is enabled under
   AddOns on the character-select screen.

## Shipping a change

1. Bump `## Version` in `RestedAlts/RestedAlts.toc`. It's the only version source.
2. Move the CHANGELOG's Unreleased entries under the new version.
3. Copy the folder over the installed copy and `/reload`.

To roll back, copy an older version's `RestedAlts` folder from git history
(`git checkout <tag> -- RestedAlts`) over the installed copy. The saved data format hasn't changed
since 0.1.0, so older versions read it fine.

## Configuration

There are no secrets or environment settings. In-game settings (sort, filters, window and minimap
positions) are saved in `WTF/Account/<account>/SavedVariables/RestedAlts.lua`.

## Troubleshooting

- **Nothing happens on `/alts`:** the addon isn't loaded. Check the AddOns list. If the game says
  the addon is out of date, the client's Interface number differs from 16001: update the `.toc` or
  enable "Load out of date AddOns".
- **Lua errors:** turn on `/console scriptErrors 1` to see them, then report them along with the
  addon version.
