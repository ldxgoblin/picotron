                                                                 
░█▀█░█▀█░█▀█░█▀▄░█▀█░█░█
░█░█░█░█░█░█░█▀▄░█░█░░█░
░▀░▀░▀▀▀░▀░▀░▀▀░░▀▀▀░░▀░   

ダンジョンクロウラ
Picotron Crawler Engine

Dungeon-generation for Picotron with deterministic map creation, theme-driven tuning, and lightweight 2D visualization.

---

## Quick Facts

- **Platform**: Picotron 0.2.1e • Lua 5.4
- **Entry point**: `main.lua`
- **Focus**: Generator workflows + map inspection UI (no runtime 3D engine)
- **Key modules**:
  - `lib/` – infrastructure (require, logging, UI widgets)
  - `src/procgen/` – dungeon pipeline, data contracts, map bootstrap
  - `src/render/` – compact 2D dungeon map renderer

---

## Feature Overview

1. **Deterministic dungeon generator** with adaptive spacing, corridor carving, door/key progression, and multiple biome themes.
2. **Picotron-native UI** built with `lib/ui.lua`, providing buttons, live stats, and seed/theme selectors.
3. **Map bootstrap & state capture** (`map_bootstrap.lua`, `map_state.lua`) allocating userdata-backed tile layers and exposing read/write helpers.
4. **Top-down renderer** (`render/dungeon_map_renderer.lua`) that visualizes occupied regions, door/exits, and object markers with scaling.
5. **Rich observability hooks** (structured logs, history buffers, tunable generator telemetry).

---

## Runtime Layout (`main.lua`)

- **Module bootstrap**: adds `lib/` and `src/` to the module path, loads `globals.lua` + `configuration.lua`, and resolves `log`, `procgen.dungeon_factory`, and `render.dungeon_map_renderer`.
- **UI composition**: uses `Observable` values and `ConcreteViewClass` components from `lib/ui.lua` to construct text rows, buttons, and layout stacks (`HStack`, `VStack`).
- **Input loop**: `_update()` polls the mouse via `mouse()` and dispatches click events to registered buttons.
- **Draw loop**: `_draw()` (defined internally by the UI framework) renders the UI tree plus the dungeon overview drawn by `render/dungeon_map_renderer.draw(state, opts)`.

---

## Procedural Generation Pipeline (`src/procgen/`)

### `map_bootstrap.lua`
- Allocates userdata layers (`map.walls`, `map.doors`, `map.floors`) sized by `map_size` from `configuration.lua`.
- Sets up `get_*` / `set_*` helpers, initializes `player`, `floor`, `roof`, `doorgrid`, and shared arrays (`doors`, `objects`, `animated_objects`).
- Provides `map_bootstrap.get_context()` so downstream modules can access the live world tables without touching globals.

### `map_state.lua`
- Builds a read-only snapshot referencing the live globals (map, doors, objects, player start, generator statistics, theme metadata).
- Used by renderers, tooling, or tests to avoid duplicating state.

### `dungeon_factory.lua`
- High-level orchestration: `init()` bootstraps the world, `generate()` invokes the pipeline and constructs a new `map_state` snapshot.

### `dungeon/pipeline.lua`
- Central generator script coordinating:
  - **Room sampling** (`rooms.lua`): weighted shapes, bias radius, adaptive center bias, and style classification.
  - **Corridors & doors** (`corridors.lua`, `doors.lua`): ensures boundary passages, retries placements, and records logical door objects.
  - **Spacing heuristics** (`spacing.lua`): relax/restore spacing after repeated failures; tracks protected tiles and history logs.
  - **Progression** (`progression.lua`): locks edges, relocates keys, validates reachability.
  - **Population** (`population.lua`): enemies, items, decorations, exits, plus animated object registration.
- Theme rules (`themes.lua`) drive room sizing tweaks, corridor jog probability, and erosion intensity.
- Finishes by enforcing outer walls, restoring door tiles, seeding player spawn, and exporting stats `{rooms, objects, seed, history}`.

---

## Rendering & UI

- `render/dungeon_map_renderer.lua`
  - Determines occupied bounds from `state.gen_nodes` to focus rendering.
  - Scales the map to fit the requested viewport and draws floors/walls/doors/exits with color coding.
  - Marks the player start position plus all spawned objects.
- UI widgets from `lib/ui.lua` (e.g., `Button`, `Text`, `HStack`, `VStack`) provide declarative layout helpers with clipping, padding, and simple styling.
- `ui_state` observables keep on-screen stats in sync with the latest `gen_stats`.

---

## Configuration Highlights (`src/configuration.lua`)

- **World size**: `map_size = 128` controls the userdata grid dimensions.
- **Generator knobs**: `gen_params`, `gen_observability`, and `gen_adaptive_settings` expose room counts, spacing, logging levels, and heuristics.
- **Themes**: `themes` table lists biome presets (`dng`, `out`, `dem`, `house`, `dark`) with floor/roof combos and rule overrides.
- **Objects & enemies**: `obj_types`, `enemy_types`, `decoration_types` centralize sprite metadata, collision, and generation weights.
- **Door & exit IDs**: `door_normal`, `door_locked`, `door_stay_open`, `exit_start`, `exit_end` ensure consistent tile usage across the pipeline.
- **Logging**: `configuration.log` toggles console logging and sets the minimum level (default `DEBUG`).

Tweak these values, reload `main.lua`, and re-run the generator to immediately observe the effects.

---

## Logging & Observability

- `lib/log.lua` provides leveled logging with console output; integrates with `src/logview.lua` if you launch that cart separately.
- `spacing.gen_log` records structured generation events (room failures, door placement attempts, repairs). Logs can be surfaced through `gen_stats.history` or console output when `gen_observability.enable_console` is true.
- Errors during generation bubble up via `pcall` in `dungeon_factory.generate()` and are routed to `wtf()` for user-visible alerts.

---

## Directory Map

```
.
├── README.md
├── lib/
│   ├── ecs.lua
│   ├── jsonParser.lua
│   ├── log.lua
│   ├── require.lua
│   └── ui.lua
├── main.lua
└── src/
    ├── configuration.lua
    ├── globals.lua
    ├── logview.lua
    ├── procgen/
    │   ├── dungeon/
    │   │   ├── corridors.lua
    │   │   ├── doors.lua
    │   │   ├── geometry.lua
    │   │   ├── pipeline.lua
    │   │   ├── population.lua
    │   │   ├── progression.lua
    │   │   ├── rooms.lua
    │   │   ├── spacing.lua
    │   │   └── themes.lua
    │   ├── dungeon_factory.lua
    │   ├── map_bootstrap.lua
    │   └── map_state.lua
    └── render/
        └── dungeon_map_renderer.lua
```

