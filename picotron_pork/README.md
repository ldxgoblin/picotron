# Picotron Roguelike

This project is a port / adaptation of the original PICO-8 game "Porklike with:

- 480×270 Picotron display
- 16×16 logical dungeon (`MAP_W`, `MAP_H`) with **32×32** rendered tiles
- Camera-based scrolling, tweened movement, and fog-of-war
- Map/AI/gameplay logic preserved as closely as possible to the original

This document describes the systems, data flow, and major modules so you can
modify or extend the game without re-reading the whole codebase.

---

## Requirements & Runtime

- **Platform:** Picotron ≥ 0.2.x
- **Language:** Lua 5.4 (Picotron-flavoured)
- **Entrypoint:** `main.lua`

### How the cart boots

`main.lua` is a thin host that:

1. Configures fullscreen mode and focus handling.
2. Replaces `_init`, `_update`, `_draw` with wrappers that:
   - Call the game-defined `_init` / `_update60` / `_draw` from the PICO-8
     compatibility layer.
   - Drive at 60 FPS when `_update60` exists.
3. Loads game modules from disk using `fetch` + `load` into a shared `_ENV`:
   - Root modules: `configuration.lua`, `globals.lua`
   - Game tabs: all files in `src/` (`core.lua`, `update.lua`, `draw.lua`,
     `gameplay.lua`, `ui_windows.lua`, `mobs.lua`, `inventory.lua`,
     `items.lua`, `mapGenerator.lua`)

Picotron’s VM runs `_init()` once and then alternates `_update()` / `_draw()`
(defined in `main.lua`, which in turn call into the game’s update/draw).

---

## Project Layout

Top-level structure:

- `main.lua` – Picotron bootstrap and PICO-8 compatibility wrapper.
- `configuration.lua` – Game configuration and all packed data tables
  (items, mobs, wall signatures, etc.).
- `globals.lua` – Global constants and small helpers.
- `src/` – Core game logic.
- `lib/` – Reusable utilities (logging, custom `require`, ECS, etc.).
- `docs-picotron/` – Picotron documentation bundle (reference only).
- `gfx/`, `map/`, `sfx/` – Cart assets.

### src/

- `core.lua`
  - Implements game `_init` (data unpack, initial state) and `startgame()`.
  - Sets `_upd` and `_drw` function pointers used by `update.lua` / `draw.lua`.
- `update.lua`
  - Input handling and high-level state machine:
    - `update_game`, `update_pturn`, `update_aiturn`, `update_inv`,
      `update_throw`, `update_gover`.
  - Button buffering (`getbutt` / `dobuttbuff`).
- `draw.lua`
  - `draw_game()` – world rendering, camera, fog overlay, float text.
  - `drawlogo()` – title logo animation.
  - `drawmob()` – sprite drawing via `drawspr` helper.
  - `draw_gover()` – game over screen.
  - `animap()` – simple tile animation driven via `mget`/`mset`.
- `gameplay.lua`
  - Player movement, bump handling, LOS & fog-of-war, throws.
  - Combat and status: `hitmob`, `healmob`, `stunmob`, `blessmob`.
  - Turn-end logic, win/lose detection (`checkend`, `showgover`).
- `mapGenerator.lua`
  - Floor generation pipeline and dungeon topology.
- `mobs.lua`
  - Mob creation, animation tweens, and AI tasks.
- `inventory.lua`, `items.lua`
  - Inventory grid, item use/equip/throw, food effects.
- `ui_windows.lua`
  - Minimal window system for HP, messages, inventory menus, etc.

### lib/

- `require.lua` – Custom Lua 5.4-compatible `require` based on Picotron paths.
- `log.lua` – Logging abstraction that can target an external `logview` process
  or console.
- `ecs/` – Generic ECS utilities (not central to the current game flow).

---

## Global Configuration & Constants

Defined in `globals.lua`:

- `SCREEN_W, SCREEN_H = 480, 270` – World-space camera dimensions.
- `MAP_W, MAP_H = 16, 16` – Logical dungeon size in tiles.
- `TILE_SRC_SIZE = 8` – Size of source sprites in the atlas.
- `TILE_SIZE = 32` – On-screen size of a logical tile.
- `SHOW_FOG` – Debug flag toggling fog rendering (logic still runs either way).

Key helpers:

- `drawspr(spr, x, y, col, flip)` – Draws an 8×8 sprite scaled to `TILE_SIZE`.
- `rectfill2(x,y,w,h,c)` – Rectfill with inclusive coordinates.
- `oprint8(text,x,y,col,shadow)` – 8-direction outline text.
- `dist(fx,fy,tx,ty)` – Euclidean distance in tile space.
- `blankmap(default)` – Allocates a `MAP_W`×`MAP_H` 2D table.
- `doshake()` – Updates `shake_x`, `shake_y` based on global `shake`.

Packed data tables (items, mobs, wall signatures, etc.) live in
`configuration.data` and are unpacked in `core._init()`.

---

## Core Flow

### Initialisation (`core.lua`)

1. `_init()` (game) runs under Picotron’s wrapper:
   - Unpacks configuration tables into globals (`itm_*`, `mob_*`, `crv_*`, ...).
   - Initialises `debug` array for on-screen debug prints.
   - Calls `startgame()`.

2. `startgame()`:
   - Resets timers (`t`, `fadeperc`, `shake`), logo animation, stats.
   - Creates `mob` list and player `p_mob` at (1,1) via `addmob`.
   - Sets up inventory structures `inv`, `eqp`.
   - Creates UI containers: `wind`, `float`, `hpwind`.
   - Sets `_upd = update_game`, `_drw = draw_game`.
   - Calls `genfloor(0)` for the first floor.

### Update Loop (`update.lua`)

- Picotron’s `_update()` (in `main.lua`) prefers `game_update60` when present.
- The game’s `_update60()` (in `core.lua`):
  - Increments global time `t`.
  - Calls `_upd()` (one of `update_game`, `update_pturn`, `update_aiturn`,
    `update_inv`, `update_throw`, `update_gover`).
  - Updates float text and HP window (`dofloats`, `dohpwind`).

Key states:

- `update_game()` – high-level input:
  - If a talk window is open, waits for button to dismiss.
  - Otherwise buffers a button and delegates to `dobutt`.
- `dobutt()` handles movement, inventory open, skipping logo, etc.
- `update_pturn()` – animates player move/bump via `p_t`, then:
  - Triggers stairs (`trig_step`), win/lose (`checkend`), and AI (`doai`).
- `update_aiturn()` – advances all mob `mov` functions for one enemy turn.

### Rendering (`draw.lua`)

`_draw()` from `core.lua` calls:

1. `doshake()` – compute camera shake offsets.
2. `_drw()` – currently `draw_game()`.
3. `drawind()` – UI windows (HP, inventory, messages, talk, etc.).
4. `drawlogo()` – if the intro logo is still active.
5. `checkfade()` – applies palette fades when `fadeperc > 0`.

`draw_game()`:

- Clears screen.
- Animates special map tiles via `animap()`.
- Computes camera center using the **tweened** player sprite position:
  - `px,py = p_mob.x*TILE_SIZE + p_mob.ox + TILE_SIZE/2`, etc.
- Calls `camera(camx+shake_x, camy+shake_y)`.
- Draws: map (`map()` with scaling), death animations in `dmob`, all `mob`s.
- If in throw-preview state, draws a projected throw line and highlight.
- Applies fog overlay when `SHOW_FOG` is true.
- Renders floating combat text.
- Resets camera before HUD / logo.

---

## Dungeon Generation (`mapGenerator.lua`)

Entry point: `genfloor(floor)`.

1. Resets mob list (preserving `p_mob`).
2. For special floors:
   - `floor == 0` – copies a static intro map region via `copymap(16,0)`.
   - `floor == winfloor` – copies a static win map via `copymap(32,0)`.
3. For regular floors:
   - Creates full fog (`fog = blankmap(1)`).
   - Calls `mapgen()` and then `unfog()` from the player start position.

### `mapgen()` pipeline

Within a repeat-loop ensuring a single connected component:

1. `copymap(48,0)` seeds from a template region.
2. `init_borders()` sets the **outer ring** (`x==0 || y==0 || x==MAP_W-1 || y==MAP_H-1`)
   to solid walls (`tile 2`).
3. `genrooms()` places a set of axis-aligned rooms:
   - `doesroomfit` forbids touching the outer border and overlapping existing
     walkable tiles.
4. `mazeworm()` carves maze-like corridors using `cancarve`, which never
   operates on border tiles.
5. `placeflags()` / `carvedoors()` ensure that all walkable tiles belong to a
   single connected component, adding doors as needed.

Once connectivity is guaranteed:

6. `carvescuts()` optionally adds extra connections.
7. `startend()` chooses start and exit tiles using distance maps.
8. `fillends()` fills dead ends with solid walls, again using `cancarve` to
   avoid touching special tiles and borders.
9. `prettywalls()` turns solid walls into bitmasked wall sprites and adds
   supporting top tiles for floors under walls.
10. `installdoors()` converts certain corridor tiles into actual door tiles.
11. `spawnchests()`, `spawnmobs()`, `decorooms()` add chests, enemies, and
    decoration (dirt, ferns, vases, torches, carpets).

The result is a fully enclosed dungeon with a one-tile wall border and a
single connected walkable component.

---

## Fog of War & LOS

Defined in `gameplay.lua`:

- `fog[x][y] == 1` means the tile is hidden; `0` means revealed.
- `unfog()` iterates all tiles and clears fog when:
  - Tile is within `p_mob.los` distance, and
  - `los(px,py,x,y)` reports an unobstructed line of sight.
- `los` uses Bresenham-like stepping and `iswalkable(x,y,"sight")` to treat
  certain tiles as opaque.
- `unfogtile(x,y)` also reveals non-walkable neighbors (walls
  immediately adjacent to visible floor).

Fog drawing happens in `draw_game()` after map/mobs, via `rectfill2` overlay
per tile when `SHOW_FOG` is true.

---

## Player, Mobs, and Combat

### Player & mob movement (`mobs.lua`, `gameplay.lua`)

- `addmob(type,x,y)` creates a mob:
  - Logical position `x,y` (tile coordinates).
  - Render offsets `ox,oy` for tweening.
  - Animation frames derived from `mob_ani[type]`.
- `mobwalk(mb,dx,dy)` and `mobbump(mb,dx,dy)`:
  - Adjust `x,y` (for walks) or leave them (for bumps).
  - Set `sox,soy` and `mov` (`mov_walk` or `mov_bump`).
- `mov_walk` / `mov_bump` use global `p_t` (turn progress) to interpolate
  `ox,oy`, which now directly drives the camera as well.

### AI

- Each mob has a `task`: `ai_wait` or `ai_attac`.
- `doai()` steps tasks for all non-player mobs and decides if an enemy turn is
  needed.
- `cansee(m1,m2)` uses LOS and mob-specific `los` radius.
- `ai_attac` handles both melee attacks and pathfinding toward the player using
  `calcdist` / `distmap`.

### Combat

- `hitmob(atkm, defm, rawdmg)` computes damage from attacker or raw value plus
  equipment and bless/curse effects.
- `healmob`, `stunmob`, `blessmob` apply status changes and floating text.
- On death, mobs move into `dmob` for a short death animation duration.

---

## Items & Inventory

- Item data (`itm_*`) comes from `configuration.data`.
- `showinv()` builds a menu window listing:
  - Equipped weapon/armor slots.
  - Up to 6 inventory slots.
- `showuse()` opens a context menu for the selected slot (equip/eat/throw/trash).
- `triguse()` executes the chosen verb and may advance the turn.
- `throw()` and `throwtile()` implement tile-based projectile throws.
- `eat()` drives food effects via `itm_stat1` and `itm_known`.

---

## UI Windows & Messages

All basic UI windows share one structure defined in `ui_windows.lua`:

- `addwind(x,y,w,h,txt)` – push a window spec into global `wind`.
- `drawind()` – central renderer for all windows.
- `showmsg`, `floormsg`, `showtalk` – create temporary message or dialogue
  windows.
- `hpwind` is updated by `dohpwind()` every frame; its position shifts based on
  player Y to avoid overlapping the character.
- Inventory, stats, use and hint windows are all created via `addwind`.

Because everything uses `wind` and `drawind()`, you can add new UI panels by
creating additional windows and populating `txt` / `col` arrays.

---

## Debugging & Dev Aids

- `SHOW_FOG` in `globals.lua` – set to `false` to temporarily render without
  fog overlay (fog logic still runs).
- `debug` table in `core.lua` – strings pushed here are printed at the top-left
  of the screen on every frame.
- Logging (`lib/log.lua` + `lib/logview.lua`):
  - Controlled via `configuration.log`.
  - Can target either a dedicated `logview` process or the console.

---

## Extending the Game

When making structural changes, keep these invariants in mind:

- `MAP_W`, `MAP_H` currently match the Picotron map resource (16×16). If you
  change them, you will also need to provision a larger map userdata and adjust
  all generation and rendering that assumes 16×16.
- Gameplay, LOS, AI, and procgen all operate in **tile space**; rendering is
  fully parameterized by `TILE_SIZE` and `SCREEN_W/H`.
- The outer border ring is treated as permanent wall during generation via
  `init_borders` and blocked out by `cancarve`/`doesroomfit`.
