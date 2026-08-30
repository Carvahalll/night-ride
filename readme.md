# Streetlighter

First-person neon bicycle racer. Built as an outdoor art installation: a real bicycle with Arduino brake triggers drives the game.

---

## Hardware & platform

| Target | Details |
|--------|---------|
| Display | 1080p screen (fullscreen) |
| Compute | Raspberry Pi 5 (production), macOS (development) |
| Input | Arduino Leonardo presenting as USB keyboard — LEFT arrow (left brake), RIGHT arrow (right brake) |
| Restart | Hold LEFT + RIGHT simultaneously (game over screen) or SPACE |

The same Love2D source runs on both platforms without modification. Flip `FULLSCREEN = true` at the top of `main.lua` for deployment.

---

## Repository layout

```
Street_Lighter/
├── streetlighter_game.py       pygame prototype (reference, do not delete)
├── arduino_code/               Arduino Leonardo sketch
├── README.md                   this file
├── .gitignore
├── love/                       Love2D project (run with: love love/)
│   ├── conf.lua                window / module config
│   ├── main.lua                entry point; FULLSCREEN flag lives here
│   ├── input.lua               key polling + both-brakes edge detection
│   ├── assets/
│   │   ├── background/
│   │   │   ├── pilatus.svg     source artwork
│   │   │   └── pilatus.png     white-on-transparent PNG (rendered from SVG)
│   │   └── scenery/
│   │       ├── *.svg           source artwork (altstadt, bahnhof, hofkirche, …)
│   │       └── *.png           white-on-transparent PNGs (rendered from SVGs)
│   └── game/
│       ├── constants.lua       all magic numbers; HORIZON_Y controls sky height
│       ├── state.lua           game state + reset
│       ├── road.lua            project() + drawRoad()
│       ├── objects.lua         RoadObject — obstacles, swans, coins, gate
│       ├── background.lua      Pilatus image + lake shimmer
│       ├── scenery.lua         Lucerne landmark sprites (perspective zoom-in)
│       ├── sparks.lua          particle burst on coin collect
│       ├── bloom.lua           GPU bloom shader
│       └── hud.lua             score, speed bar, combo, hitbox, game-over overlay
└── docs/                       GitHub Pages site (served from main branch /docs)
    ├── index.html              landing page
    └── game/
        ├── shell.html          custom dark shell — SOURCE OF TRUTH, edit this one
        ├── index.html          served page; a copy of shell.html (love.js overwrites it)
        ├── game.data           bundled game assets (rebuilt by love.js)
        ├── game.js             love.js loader glue  (rebuilt by love.js)
        ├── love.js             Emscripten runtime   (rebuilt by love.js)
        └── love.wasm           Love2D WebAssembly   (rebuilt by love.js)
```

---

## Deploying to GitHub Pages

The live site is at **https://carvahalll.github.io/streetlighter/**.
GitHub Pages serves the `docs/` folder on the `main` branch automatically — pushing is all that's needed.

### Steps

**1. Rebuild the web bundle**

```bash
npx love.js@11.4.1 -c -t "Streetlighter" love/ docs/game/
```

This regenerates `docs/game/game.data`, `game.js`, `love.js`, and `love.wasm`.
It also overwrites `docs/game/index.html` with love.js's generic default shell.

**2. Restore the custom shell**

```bash
cp docs/game/shell.html docs/game/index.html
```

`shell.html` is the hand-maintained dark shell and is the source of truth for the
page; `index.html` is the file GitHub Pages actually serves, so it must be a copy
of it. Edit `shell.html` — never `index.html`, which the next rebuild will clobber.

**3. Stage the rebuilt files and the restored shell**

```bash
git add docs/game/game.data docs/game/game.js docs/game/love.js docs/game/love.wasm
git add docs/game/index.html   # only after the cp above — never a raw love.js index.html
```

If you also changed Lua source or assets, stage those too:

```bash
git add love/
```

**4. Commit and push**

```bash
git commit -m "Rebuild web bundle: <short description>"

# The large love.wasm (≈4.5 MB) needs a bigger HTTP buffer:
git -c http.postBuffer=524288000 push origin main
```

GitHub Pages rebuilds automatically within ~1–2 minutes after the push.

### Lua compatibility note

love.js runs **Lua 5.1**. Avoid:
- `goto` / `::label::` statements (Lua 5.2+)
- `table.unpack` with index range args — use a helper table instead

### Re-rendering SVG assets

The scenery and Pilatus images are stored as both `.svg` (source) and `.png` (white-on-transparent, loaded by the game). To re-render after editing an SVG:

```bash
# Pilatus (full game width)
sed 's/fill="#000000"/fill="#ffffff"/g' love/assets/background/pilatus.svg > /tmp/w.svg
sips -s format png --resampleWidth 1280 /tmp/w.svg --out love/assets/background/pilatus.png

# Scenery items (max 600 px)
for svg in love/assets/scenery/*.svg; do
  name=$(basename "${svg%.svg}")
  sed 's/fill="#000000"/fill="#ffffff"/g' "$svg" > /tmp/w.svg
  sips -s format png -Z 600 /tmp/w.svg --out "love/assets/scenery/${name}.png"
done
```

Then run `git add love/assets/` and rebuild the bundle.

---

## Running the game

```bash
# macOS (Homebrew)
brew install love
love love/

# Raspberry Pi (apt)
sudo apt install love
love love/
```

---

## Development environment setup (macOS)

Everything needed to open this repo cold on a new Mac and keep working. Versions listed are what development has been pinned to as of 2026-08-30 — newer patch versions of each tool are expected to work fine.

| Tool | Version used | Install | Needed for |
|------|--------------|---------|------------|
| Homebrew | — | https://brew.sh | Installing `love`, general toolchain |
| LÖVE (love2d) | 11.5 | see note below | Running/testing the game (`love love/`) |
| Xcode Command Line Tools | — | `xcode-select --install` | `git`, compilers; `sips` (used in the asset pipeline) ships with macOS itself, no separate install |
| Node.js | v26.4.0 (Homebrew) | `brew install node` — only used to run `npx love.js`, not part of the game runtime | Rebuilding the web bundle (`docs/game/`) |
| Python | 3.11.16 + pygame 2.6.1 (conda env `bicycle-game`, via miniforge) | `brew install --cask miniforge && conda init zsh`, then `conda create -n bicycle-game python=3.11 pygame` | Running the pygame prototype `streetlighter_game.py` only — not required for the Love2D game |
| Git | system | via Xcode CLT | Version control; large `love.wasm` push needs `http.postBuffer=524288000` (see deploy section above) |
| Arduino IDE | 2.x | https://www.arduino.cc/en/software | Flashing `arduino_code/streetlighter_controller/streetlighter_controller.ino` to the Arduino Leonardo. Uses only the built-in `Keyboard.h` library — no extra board packages needed beyond the standard AVR core (Leonardo is supported out of the box). |

**Apple Silicon note:** development moved from an Intel Mac to an M2 (Apple Silicon) in August 2026. Everything is now installed natively as arm64 — Homebrew at `/opt/homebrew`, a universal LÖVE binary, miniforge's arm64 Python — so nothing runs under Rosetta. Only the repo contents (code, assets, git history) move between machines: `git clone https://github.com/Carvahalll/streetlighter.git`.

**⚠️ LÖVE install note:** do **not** use `brew install --cask love` — it is deprecated upstream (fails the macOS Gatekeeper check) and Homebrew disables it on 2026-09-01. Install manually instead, which is how the current M2 machine is set up:

```bash
curl -L -o love.zip https://github.com/love2d/love/releases/download/11.5/love-11.5-macos.zip
unzip love.zip && cp -R love.app /Applications/
xattr -dr com.apple.quarantine /Applications/love.app          # clears the Gatekeeper block
ln -sf /Applications/love.app/Contents/MacOS/love /opt/homebrew/bin/love
love --version                                                  # LOVE 11.5 (Mysterious Mysteries)
```

The 11.5 release is a universal binary, so it runs natively on both Intel and Apple Silicon.

**Note on this repo living in OneDrive:** the working directory is synced by OneDrive. LÖVE writes nothing into the project folder at runtime, so this is safe for normal use, but avoid running `love love/` from two machines against the same synced folder at the same time, and let OneDrive finish syncing before switching machines to avoid conflicted copies of source files.

### Quick start on a new Mac

```bash
git clone https://github.com/Carvahalll/streetlighter.git
cd streetlighter
# install LÖVE 11.5 manually — see the LÖVE install note above
love love/                 # should boot the game windowed at 1280x720
```

That's sufficient to run and edit the Love2D game. Node and the conda env are only needed if you're rebuilding the web bundle or touching the pygame prototype, respectively.

**Git note:** the transfer between machines set the execute bit on every tracked file, which made all 54 of them show as modified. The repo now sets `core.fileMode false` locally so git ignores permission bits — if you clone onto another machine and see the same phantom "modified" list, run `git config core.fileMode false` there too.

---

## Gameplay

- **Steer** left/right by squeezing the corresponding brake
- **Avoid** neon obstacles (pink/orange/red) rushing toward you
- **Collect** yellow coins for combo-multiplied score
- Speed increases every 10 seconds
- Game over on obstacle collision; restart with SPACE or both brakes

---

## Key technical decisions

| Decision | Rationale |
|----------|-----------|
| Love2D over pygame | GPU-accelerated rendering; runs well on Pi 5; LÖVE is stable and minimal |
| Logical canvas (1280×720) scaled to window | Single codebase for dev (windowed) and installation (1080p fullscreen) without changing draw code |
| CPU glow for first pass | Concentric transparent shapes, no shader dependency — gets gameplay running first |
| Shader-based bloom (planned) | Will replace CPU glow once gameplay is confirmed; real GPU bloom is the aesthetic goal |
| Edge-triggered both-brakes restart | Prevents accidental instant re-restart after game over |
| `love.math.random` throughout | Deterministic seeding possible for reproducibility |

---

## Implementation status

### Love2D port
- [x] Project structure and conf.lua
- [x] Constants (mirrors all pygame globals)
- [x] Game state + reset
- [x] Input module (steer, both-brakes edge detect, SPACE restart)
- [x] Perspective road (grid lines, lane dashes, neon edges)
- [x] RoadObject — obstacles (car shape + headlights) and coins (circle + spin)
- [x] Collision detection (matches pygame logic exactly)
- [x] Spark particles on coin collect
- [x] HUD (score, speed bar, combo display, hitbox square)
- [x] Game-over overlay + restart
- [x] Logical canvas → letterboxed window scaling
- [x] GPU bloom shader (threshold → half-res Gaussian blur → additive composite)

### Planned
- [ ] Sound effects (coin collect, obstacle hit, engine hum)
- [ ] Custom pixel/neon font
- [ ] Raspberry Pi deployment test
- [ ] Configurable key bindings (for remapping Arduino if needed)

---

## Pygame prototype notes

`streetlighter_game.py` is the original prototype. Key differences from the Love2D port:
- Uses pre-baked `SRCALPHA` surfaces for glow (expensive on Pi)
- Hardcoded to 1920×1080 fullscreen
- Glow cache warms on startup to avoid first-frame stutter

The Love2D port preserves all gameplay constants and collision logic exactly. Visual parity (especially glow quality) will improve once the shader pass is added.
