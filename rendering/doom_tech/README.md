# doom_tech

A Picotron cartridge that experiments with DOOM-like sector rendering by building a tiny software 3D pipeline entirely in Lua. The project demonstrates how to stitch convex sectors together, simulate a player controller, and draw textured walls, floors, ceilings, and rigid models on modern Picotron builds.

## Features

- **Software 3D renderer** with camera, model, and viewport transforms stored in `userdata` matrices for speed.@rendering/doom_tech/render.lua#17-133
- **Sector + stitch world geometry**: convex polygons described by wall "stitches" that each render floor/ceiling spans.@rendering/doom_tech/sector.lua#10-54
- **Player controller** supporting stick input, mouse look, multiple video modes, and performance overlay toggles.@rendering/doom_tech/main.lua#25-154
- **Reusable math/utility helpers** for interpolation, button scaling, and logging output to the Picotron console.@rendering/doom_tech/utils.lua#7-60

## Directory Layout

| Path | Description |
| --- | --- |
| `main.lua` | Cartridge entry point: boots video mode, updates the player each frame, and drives the renderer.@rendering/doom_tech/main.lua#25-154 |
| `render.lua` | Core rendering module (camera setup, mesh rasterizer, wall/floor batching, model drawing).@rendering/doom_tech/render.lua#17-548 |
| `sector.lua` | Convex sector container that owns stitches and draws their walls.@rendering/doom_tech/sector.lua#10-54 |
| `stitch.lua` | Line-segment primitive with tangents, normals, and wall draw routine.@rendering/doom_tech/stitch.lua#6-55 |
| `player.lua` | Minimal player struct with `pos`, `angle`, `fov`, and relative movement logic.@rendering/doom_tech/player.lua#10-24 |
| `utils.lua` | Misc helpers (lerp/remap, sign, button scaling, logging).@rendering/doom_tech/utils.lua#7-60 |
| `gfx/`, `sfx/`, `map/` | Asset placeholders created by Picotron when the cart was saved; currently unused but reserved for future content.

## Requirements

- Latest public Picotron build (the cart relies on `userdata`, `tline3d`, and `mouselock`, which arrived in mid-2025 nightlies).
- A mouse is optional but recommended for smooth look control.

## Quick Start

1. Copy this folder into your Picotron `drive/rendering/` directory (or load it via the Picotron host UI).
2. From Picotron, run `load rendering/doom_tech/main.lua`.
3. Press **CTRL+R** (or click **Run**) to execute the cart.
4. Use the controls below to explore the test sector and floating cube.

## Controls

| Action | Input |
| --- | --- |
| Move | Left stick / D-pad (buttons 0–3 mapped to `move` offset).@rendering/doom_tech/main.lua#34-126 |
| Look (digital) | Right stick horizontal (buttons 8–9 mapped to `look` offset).@rendering/doom_tech/main.lua#34-125 |
| Look (mouse) | Move the mouse while Picotron captures the cursor via `mouselock(true, 1, 0)`.@rendering/doom_tech/main.lua#118-122 |
| Toggle perf HUD | Press `p` to show/hide CPU usage overlay.@rendering/doom_tech/main.lua#115-153 |
| Cycle video mode | Buttons 14 / 15 iterate through the `modes` table and resize the render target.@rendering/doom_tech/main.lua#25-114 |

*Tip:* Picotron's analog helper `btnv` returns a scalar 0–1 value, so movements scale smoothly with stick displacement.@rendering/doom_tech/utils.lua#40-43

## Coordinate System

The project assumes a **left-handed system** with **Y-up** and **Z-forward**. Stitch normals rotate 90° clockwise in 2D space, which is important when defining convex sectors so the containment test works correctly.@rendering/doom_tech/main.lua#15-21 @rendering/doom_tech/stitch.lua#13-47

## Rendering Pipeline Overview

1. **Camera setup** – `render:setcam` stores FOV, builds a camera transform, and precomputes a 2D basis for floor/ceiling UV math.@rendering/doom_tech/render.lua#65-104
2. **Model transform** – `render:setmodel` loads a matrix applied to all mesh vertices before rasterization.@rendering/doom_tech/render.lua#106-133
3. **Triangle rasterization** – `render:model3d` walks face indices, transforms vertices, clips near-plane intersections, and calls `viewtri3d` to emit textured spans.@rendering/doom_tech/render.lua#237-373
4. **Walls/floors/ceilings** – `render:wall3d` projects a vertical quad, clips it per column, and reuses the same data to draw floor and ceiling textures beneath/above the wall slice.@rendering/doom_tech/render.lua#375-548
5. **Sector draw loop** – Each `Sector` iterates its `stitches` array and asks them to `draw(lo, hi)`, where `lo/hi` are floor/ceiling heights in world units.@rendering/doom_tech/sector.lua#34-54 @rendering/doom_tech/stitch.lua#49-55

## Gameplay / Systems

- **Player movement** uses local axes: forward/back scales `movey`, strafing uses `movex`, and both rotate around the player's `angle`.@rendering/doom_tech/player.lua#19-24
- **Dynamic bobbing** – The cube model's y-offset oscillates via `sin(t()/1.5)` to show animation within the render loop.@rendering/doom_tech/main.lua#123-148
- **Performance logging** – Toggle `perf` to print CPU usage and flush accumulated log messages each frame.@rendering/doom_tech/main.lua#115-153 @rendering/doom_tech/utils.lua#45-60

## Extending the Prototype

1. **Add sectors** – Create more `Stitch:new{ pos1=vec(...), pos2=vec(...) }` entries and wrap them in additional `Sector:new` calls. Keep polygons convex so `Sector:contains` stays valid.@rendering/doom_tech/sector.lua#34-45
2. **Texturing** – Pass Picotron sprite IDs for wall/floor/ceiling textures via each stitch's `s` attribute when you instantiate it (defaults to `1`).@rendering/doom_tech/stitch.lua#18-55
3. **Player logic** – Extend `player.lua` with collision checks (e.g., test `Sector:contains`) or add vertical look/pitch if you expand the input scheme.@rendering/doom_tech/player.lua#10-24
4. **AABB + culling** – `Sector:aabb()` is stubbed; implementing it enables fast rejection when many sectors exist.@rendering/doom_tech/sector.lua#26-32
5. **Logging** – Use `utils.log("message")` anywhere, then `utils.flush()` at the end of `_draw()` to visualize debug info onscreen.@rendering/doom_tech/utils.lua#45-60 @rendering/doom_tech/main.lua#145-149

## Known Limitations / TODO

- **No collision detection**: The player can leave the convex sector since `Sector:contains` is not wired into `player:move` yet.
- **Single sector**: Only one hard-coded test room is defined in `main.lua`. Add more data structures or load maps from `map/` for richer spaces.@rendering/doom_tech/main.lua#74-84
- **No sector-neighbor stitching**: Portals/linked sectors will need per-stitch metadata indicating adjacent sector IDs.
- **Camera pitch**: The renderer assumes horizontal camera plane (no up/down tilt), though the math pipeline could be extended.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| Black screen after launching | Ensure `render:setsize(get_display_size())` ran; pressing buttons 14/15 forces the renderer to recompute viewport dimensions.@rendering/doom_tech/main.lua#86-114 |
| Mouse not captured | Picotron only locks the cursor after the first `mouselock(true, 1, 0)` call; click the window to focus first.@rendering/doom_tech/main.lua#118-122 |
| Walls disappear near the camera | This is near-plane clipping. Increase `render.near` or keep geometry > 1/256 units away from the camera origin.@rendering/doom_tech/render.lua#17-40

---

Feel free to fork the cart, add actual DOOM textures, or wire the `map/` folder up to procedurally generate `Sector` graphs. Happy hacking!
