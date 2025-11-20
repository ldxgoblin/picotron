# NBRE Picotron Port – Progress

This file tracks the status of the NBRE engine port and documents any compatibility shims or wrappers introduced during the process.

## Tasks

- [x] Bootstrap NBRE namespace and logger wiring
- [x] Implement core registry system (without auto-loading or definition emission)
- [x] Create progress tracking document
- [x] Add initial bootstrap test fixture
- [ ] Port ECS base modules (Object, Component, Entity, Actor, System, SystemManager)
- [ ] Port storage/query/scheduler/level logic with pure-Lua buffers
- [ ] Port math, algorithms, and data structures
- [ ] Port extra gameplay modules (inventory, equipment, etc.)
- [ ] Final integration tests and cleanup of shims

## Wrappers & Shims

- **nbre.logger** – direct alias to the template `log` module; centralizes logging for the NBRE engine.
- **nbre.registry** – registry and registration API (`registerRegistry`, `register`, `resolveFactory`) mirroring the original engine's behavior without auto-loading or definition emission.
