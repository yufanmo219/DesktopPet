# Development-only files

Godot ignores this entire directory because it contains a `.gdignore` marker.
Nothing here is imported as a game resource or included in an exported build.

- `removed_pinball/`: retired Garden Pinball code, tooling, and artwork kept only
  as a recoverable archive.
- `unused_assets/`: source artwork, previews, superseded versions, and other
  media that is not referenced by the current game.
- `artifacts/`, `design/`, and `outputs/`: development previews and notes.
- `documents/`: project documents that are not runtime resources.

The separate `tests/`, `tools/`, and `qa_tools/` directories also contain their
own `.gdignore` markers. They remain runnable from the command line but are not
scanned or exported as game resources.

Runtime assets must stay under `res://assets/` and be referenced by the code or
scene that uses them.
