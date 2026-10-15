# Architecture

This document describes the intended dependency boundaries of Desktop Pet. It
is a maintenance guide, not a requirement to introduce abstractions where a
small scene script is sufficient.

## Design goals

- Keep gameplay rules independent from Godot nodes, textures, audio, and
  tweens whenever practical.
- Give each piece of persistent state one runtime owner.
- Compose screens from scenes instead of duplicating programmatic UI trees.
- Keep platform-specific window behavior behind a narrow boundary.
- Preserve unknown save fields so newer data survives older code paths.
- Make content additions data-driven and testable.

## Application shell

`main.gd` is the composition root. It creates feature screens, injects the
current player state, and connects feature signals to application services.

- `AppCoordinator` owns cross-screen policy such as music selection.
- `ScreenRouter` owns mounting, unmounting, and caching screen roots.
- `ScreenId` provides stable identifiers instead of scattered string values.

Feature screens must request navigation through signals. They must not free or
replace sibling screens directly.

## Persistent state

`SaveGameRepository` is the only component that reads or writes the JSON save.
It validates staged writes, keeps the last valid backup, restores damaged
primary saves, and opens unsupported future-version saves in read-only mode.

The persistence boundary remains a `Dictionary` for compatibility. Typed
runtime owners sit inside that boundary:

- `GameStateStore` owns shared progression.
- `PlayerProgress` normalizes XP, fishing level, hearts, retry state, unlocked
  fish, and aquarium selection.
- `PlayerProfileStore` owns the pet roster, owned catalog IDs, and active pet.

New state should be added to the appropriate owner and covered by round-trip,
legacy-migration, and unknown-field-preservation tests.

## Pets

`PetCatalog` resolves stable catalog and save IDs. Each `PetDefinition` stores
metadata and resource paths without eagerly loading every texture.

`PetAvatar` renders the active pet. Screens and controllers should request a
pet by stable ID rather than referencing pet-specific files themselves.

The remaining architectural direction is to move pet-specific animation timing
and layout metadata into definitions so `PetAvatar` can become a generic
animation renderer.

## Desktop companion

The desktop feature is split into three roles:

- `DesktopCompanionStateMachine` contains platform-neutral behavior decisions.
- `DesktopWindowHost` owns transparent native windows, z-order, monitor bounds,
  and restoration of the main window.
- `DesktopCompanionController` translates input and state-machine decisions
  into window and avatar updates.

State transitions belong in the state machine. Operating-system window calls
belong in the host. Visual layout belongs in scenes or view scripts.

## Fishing

`FishingSession` owns round rules, goals, deterministic spawn planning, retry
assistance, time, and idempotent completion rewards. `HeartService` owns heart
spending and time-based recovery. Neither depends on the scene tree.

`FishingGame` is the Godot adapter: it binds the composed fishing view, renders
actors and progress, forwards player input, plays presentation effects, and
publishes updated state.

Future work should continue moving presentation-only responsibilities into
fish actor, popup, pet-reaction, and audio collaborators while keeping session
rules stable.

## Catalog and aquarium screens

Store and Fishipedia are separate features that compose the shared
`BookShell`. They may share view components, but neither feature should inherit
domain behavior from the other.

Aquarium and its loading screen use reusable view scenes. The runtime script
owns asynchronous texture preparation and fish actor lifecycles; static layout
belongs in `.tscn` files.

## Dependency direction

Preferred direction:

```text
Godot scenes and controllers
        ↓
application coordinators and feature adapters
        ↓
domain models and state owners
        ↓
persistence and platform boundaries
```

Domain models must not load scenes or call window APIs. Persistence must not
know about concrete screens. Feature screens communicate outward through
signals rather than reaching into the composition root.

## Testing strategy

- Domain tests cover state transitions and invariants without rendering.
- Scene-structure tests verify that production `.tscn` files remain the source
  of UI composition.
- Integration tests exercise feature flows and signal wiring.
- Cross-platform CI runs the suite on macOS and Windows from a clean checkout.
- QA exports verify the actual Windows and macOS packaging paths.

Before a structural change, add or identify the regression test that captures
the behavior being preserved. Refactoring commits should avoid unrelated game
balance, content, and visual changes.
