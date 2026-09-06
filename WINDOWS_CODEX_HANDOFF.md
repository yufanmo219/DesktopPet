# Windows Desktop Companion QA handoff

## Project and branch

- Godot version: 4.7.1 stable
- Source branch: `codex/windows-export`
- The project opens from `project.godot` and starts at `main.tscn`.
- This source archive intentionally excludes `build/`, `.godot/`, unused art, and other local generated files.

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
