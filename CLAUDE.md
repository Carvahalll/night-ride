# Night Ride — Claude Code project guide

First-person neon bicycle racer, built as an outdoor art installation ("Lilu" / "Streetlighter" project). A real bicycle with Arduino brake triggers drives the game via simulated keyboard input.

**Read `readme.md` first** — it has the full repo layout, GitHub Pages deploy steps, dependency/setup instructions, key technical decisions, and the implementation status checklist. This file only adds operating notes for AI-assisted sessions; it doesn't duplicate that content.

## Orientation

- Active development is in `love/` (Love2D / Lua). Run with `love love/` from repo root.
- `nightride_game.py` is the original pygame prototype — **reference only, do not modify or delete**. It documents the gameplay/collision logic the Love2D port must match exactly.
- `docs/` is the GitHub Pages site (served from `main` branch). `docs/game/` is a love.js web build of the same Love2D source.
- `arduino_code/` holds the Arduino Leonardo sketch that turns brake-lever presses into LEFT/RIGHT arrow key events (`Keyboard.h`, no external libraries).
- Full dependency list and macOS setup steps (LÖVE, Node/love.js, conda env for the python prototype, Arduino IDE) are in `readme.md` under "Development environment setup" — check that section, not this file, when setting up a new machine.

## Hard constraints — do not violate

- **Lua 5.1 only** in `love/`. love.js runs Lua 5.1, not LuaJIT/5.2+. No `goto`/`::label::`, no `table.unpack` with index-range args (use a helper table instead).
- **Never touch `docs/game/shell.html`** — it's the custom dark shell and is hand-maintained; it does not survive a love.js rebuild if overwritten.
- **Never `git add docs/game/index.html`** — `npx love.js` regenerates it with a generic default shell on every rebuild; it must stay unstaged/ignored in practice even though it's tracked.
- After rebuilding the web bundle, only stage the specific regenerated files (`game.data`, `game.js`, `love.js`, `love.wasm`) plus any changed `love/` source — see the exact commands in `readme.md`.
- Pushing after a rebuild needs `git -c http.postBuffer=524288000 push` — the `love.wasm` (~4.5 MB) can fail a normal push otherwise.
- This working directory is synced by OneDrive. Don't leave the game running from two machines against the same synced folder simultaneously, and let sync settle before switching machines.

## Current status (as of 2026-08-30)

Gameplay port and GPU bloom shader are both complete (threshold → half-res Gaussian blur → additive composite). See the checklist in `readme.md` for the authoritative up-to-date state — it's a living list of `[x]`/`[ ]` items, update it there when shipping planned items, don't track status separately here.

Remaining planned work per that checklist: sound effects, custom pixel/neon font, Raspberry Pi deployment test, configurable key bindings.

## Testing a change

There's no automated test suite — verify by running the game:

```bash
love love/
```

`FULLSCREEN` is set in `love/main.lua` (top of file) — leave it `false` for windowed dev testing; it only needs to flip to `true` for the actual 1080p installation deployment on the Raspberry Pi.
