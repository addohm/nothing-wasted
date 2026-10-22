# CLAUDE.md

Guidance for coding assistants working in this repository.

## Layout

- `RestedRoster/`: an older addon kept only as an example and inspiration. **Do not modify it.**
- There's no addon code yet. The project is in planning; see [ROADMAP.md](ROADMAP.md).

## Rules

- Don't write or change code until the user asks for it. Discuss ideas first.
- The new addon stands alone: no references to RestedRoster, no import of its data, no dependency
  on it.
- Target client: WoW: Forever, Interface 16001.

## Commands

None yet. Lua 5.1 is available here through Python's lupa (`import lupa.lua51`) for syntax checks
and tests once there's code.

## Workflow

1. Pull before changing anything.
2. Make the change, and **update the docs it affects in the same commit**:
   - `CHANGELOG.md`: an entry under Unreleased.
   - `ROADMAP.md`: tick off finished items, add new ones.
   - `README.md`: when commands, features or install steps change.
   - `DEPLOY.md`: when installing or releasing changes.
   - `SECURITY.md`: when what the addon can access or store changes.
   - `HANDOFF.md`: when work in progress moves on.
   - This file: when the layout, workflow or conventions change.
   - `RestedAlts.toc` `## Version`: when cutting a release.
3. Check that nothing secret-looking is staged, then commit.

## Don't

- Modify `RestedRoster/`.
- Commit secrets (`.env`, keys, tokens) or the `.venv/` folder.
