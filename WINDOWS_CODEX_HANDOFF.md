# Windows Desktop Companion QA handoff

## Project and branch

- Godot version: 4.7.1 stable
- Source branch: `codex/windows-export`
- The project opens from `project.godot` and starts at `main.tscn`.
- This source archive intentionally excludes `build/`, `.godot/`, unused art, and other local generated files.

## Cross-task context summary (2026-09-07)

This handoff combines the useful context from the long Codex tasks **“选择Steam 3D游戏开发电脑”** and **“修复猫项目QA问题”**. The older task began as hardware and Steam-release planning, then became the early game-development thread. It eventually handed the project to later tasks after growing very large. The current repository, committed assets, and automated tests are the source of truth whenever an older design discussion or generated preview conflicts with the implementation.

### Product and release objective

- This is a cozy 2D Godot desktop-pet game intended for release on Steam for both Windows and macOS.
- The normal game includes Home, cat adoption/store, Cat Shelter, fishing levels, Fish Book, aquarium, persistent local save data, shared XP, hearts, and Desktop Companion mode.
- The immediate goal is to make a Windows build that can be QA-tested on the user's real Windows PC without regressing the working macOS behavior.
- The Windows QA machine uses an NVIDIA RTX 4050. Native Windows compositor behavior must be verified there; macOS and headless tests cannot prove transparent-window correctness.

### Canonical repository and branch policy

- Canonical remote: `https://github.com/yufanmo219/DesktopPet.git`
- Common baseline: `master`
- Windows-only work: `codex/windows-export`
- macOS-only work: `codex/macos-export`
- Keep Windows and macOS platform fixes on their respective branches. Do not fold a Windows windowing workaround into the macOS path unless the user explicitly requests it and both platforms are retested.
- The Windows host must use a real clone of the GitHub repository, not a downloaded ZIP or a newly initialized snapshot. The expected Windows branch for this handoff is `codex/windows-export`.

### Stable gameplay and UI context from QA

The long QA task made many user-directed adjustments. They are considered intentional behavior and are out of scope for the Windows transparency fix:

- Cat adoption/store uses full-body cat art in purchase congratulations and Cat Shelter details. Locked cats use shape-following gray silhouettes rather than rectangular masks; the left-side locked-cat mask is deliberately heavier. Pearl unlocks before Cedar.
- Fishing failure UI has separate **Go Home** and **Try Again** buttons. Leaving an active level warns that returning home costs one heart.
- Retry assistance is temporary to the current level and resets after passing it. Catch chance improves on retries; once it reaches 100%, later failed retries add target-fish appearances only for that level.
- Fishing escape chance increases through the normal range and is reduced temporarily after repeated failures; passing the level returns it to the normal rate.
- The active horizontal net catch range was set to `x = 320..770`.
- The caught-fish popup changes from one column to two columns when more than three species are caught, with up to three species per column.
- Fishing spawn variety is capped at 15 species. Target fish have a minimum guaranteed count of `ceil(target_count * 1.2)`; rarity weights were rebalanced. A proposed special `10x` multiplier for targets below 10 was undone and must not be reintroduced accidentally.
- The QA level skipper lives under `qa_tools/fishing_level_skipper/`. It previews changes, backs up the save, skips only levels without a newly introduced fish, and awards the XP for skipped levels. It is QA-only and designed for easy removal.
- Desktop Companion must not play background music.
- Follow Me reacts to a continuously moving distant cursor instead of waiting for the cursor to stop. Unfollow returns the cat to its Station using the intentionally tuned return behavior.
- Refactoring removed Pinball and its references. Unused source art and previews were moved under `dev_only/unused_assets/`; `dev_only/.gdignore` prevents them from being imported or exported with the game.

### Character and art invariants from the older development task

- Preserve each cat's established colors, markings, proportions, and personality when changing animation frames. Do not introduce tabby stripes, transparency holes, background-colored pixels, stray lines, cropped paws/tails/noses, or beige/green matte remnants.
- Poppy is a round blue-gray British Shorthair with golden-yellow eyes, a white muzzle/chin, and white paw gloves. Poppy is slow-to-react and adorably goofy, not aloof. Older Poppy toy-animation images were previews; use committed assets and current code to determine what is actually integrated.
- Many cat walk, double-click, sleep, fishing-failure, and fishing-success sprites were individually cleaned during QA. Do not regenerate or recolor them as part of a windowing fix.
- Many fish were deliberately resized or redrawn, including salmon, catfish, eels, sharks, gar, arowana, arapaima, sturgeon, sawfish, flying fish, and small schooling fish. Do not normalize their scales globally.
- The game uses the user's original handwriting font. Do not replace it with a third-party font.

### Steam release context

- Windows and macOS exports are being prepared separately before external-computer QA and Steam upload.
- macOS was still using ad-hoc signing during local QA; proper distribution signing/notarization remains a later release task.
- AI-assisted in-game artwork should be disclosed in the Steam Content Survey as pre-generated AI content, with commercial-use rights confirmed. This disclosure was not identified as an automatic publishing blocker.
- The current Windows Desktop Companion rendering bug is the release-blocking platform issue being handed off now. Do not broaden this task into unrelated Steamworks or gameplay changes.

### Working style and verification guardrails

- Communicate findings in Chinese unless code or platform terminology is clearer in English.
- Diagnose with fresh Windows logs and a minimal reproducible build before changing architecture again.
- Keep gameplay, save-schema, XP, hearts, fish balance, cat assets, sizes, Station placement, and Follow Me behavior unchanged.
- After each Windows-specific change, run the available focused tests and a smoke test, then reproduce Desktop Companion on the real Windows desktop. Record which build was tested and preserve the fresh `godot.log`.

## Current Windows-only bug

The normal game screens render correctly on Windows. After choosing **Keep as desktop companion**, translucent or blurred rectangles appear around the expected Desktop Companion area, but the Station and cat artwork are not visible.

The problem still reproduces in the latest Windows QA4 export on the user's Windows computer.

## Attempts already made

1. The first Windows build used two separate native transparent Godot `Window` nodes for the Station and cat. Both visible areas appeared blurred/transparent without their artwork.
2. The renderer was changed to ANGLE. A Windows log then confirmed ANGLE/D3D11 on an NVIDIA RTX 4050, but showed this error:

   ```text
   ERROR: Windows with the 'on top' can't become transient.
      at: _create_window (platform/windows/display_server_windows.cpp:7147)
   ```

3. The Windows implementation was changed so the real main window hosts the Station while the cat remains a separate native window. The cat window now explicitly uses `transient=false`, `transient_to_focused=false`, and `always_on_top=true`, which removes that logged flag conflict.
4. QA4 still does not display the Station or cat correctly on the user's Windows machine.

## Relevant Windows-specific source

- `project.godot`: Windows transparency overrides, non-embedded subwindows, and ANGLE.
- `export_presets.cfg`: Windows x86_64 export with ANGLE and an external PCK.
- `src/main.gd`:
  - `enter_desktop_mode()`
  - `show_widget_preview()`
  - `_desktop_station_uses_main_window()`
  - `_build_station_window()`
  - `_apply_station_window_transparency()`
  - `_build_pet_window()`
  - `_apply_pet_window_transparency()`
  - `_raise_pet_window_above_station()`

QA4 prints a line beginning with `DESKTOP_COMPANION_READY` after it creates the windows. The live Windows log is located at:

```text
%APPDATA%\Godot\app_userdata\Desktop Pet\logs\godot.log
```

Please reproduce locally on Windows, inspect that fresh log, and test changes on the actual Windows display compositor rather than relying only on headless tests.

## Behavior that must remain unchanged

Do not change gameplay, save data, cat assets, sizes, Station placement, or Follow Me behavior while fixing the Windows rendering issue. In particular, these shared positioning/layering functions are unchanged from the common baseline and should remain unchanged:

- `get_station_pet_anchor()`
- `_sync_desktop_station_art_layer()`

The macOS implementation lives on the separate `codex/macos-export` branch and must not be modified as part of the Windows fix.

## Existing verification

The current source passes the editor load check, full smoke test, `tests/desktop_follow_test.gd`, `tests/desktop_music_test.gd`, and Windows export generation on macOS. Those checks do not prove correct native composition on Windows, which is the remaining issue.
