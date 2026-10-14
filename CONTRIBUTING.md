# Contributing

Thank you for taking an interest in Desktop Pet.

## Before starting

For a substantial change, open an issue describing the problem and proposed
scope before implementation. Keep refactoring, gameplay changes, and asset
changes in separate pull requests so each can be reviewed and reverted
independently.

## Development setup

Install Godot 4.7.1, Git LFS, and Python 3. Then clone the repository and
materialize the LFS objects:

```bash
git lfs install
git clone https://github.com/yufanmo219/DesktopPet.git
cd DesktopPet
git lfs pull
```

Import `project.godot` in Godot once before editing scenes or running the game.

## Change guidelines

- Preserve stable save IDs and backwards-compatible save migrations.
- Put gameplay rules in domain models rather than UI callbacks.
- Prefer composed `.tscn` scenes for static layouts.
- Keep platform window calls inside the desktop window boundary.
- Do not commit generated builds, credentials, signing material, or local save
  data.
- Track PNG and WAV files through Git LFS.
- Do not include third-party assets without documented redistribution rights.

## Validation

Run the complete test suite:

```bash
python3 tools/run_tests.py
```

Also run the relevant QA export when changing project settings, packaging,
window behavior, or platform-specific code:

```bash
python3 tools/export_builds.py --target windows
python3 tools/export_builds.py --target macos
```

## Pull requests

Describe:

- the user-visible effect, if any;
- the architectural boundary being changed;
- tests run and their results;
- save compatibility considerations; and
- screenshots or recordings for visual changes.

All CI checks must pass before merge. By submitting a contribution, you affirm
that you have the right to provide it and grant the repository owner permission
to use, modify, and redistribute it as part of Desktop Pet. Repository access
remains governed by the project license.
