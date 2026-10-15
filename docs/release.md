# Desktop Pet release pipeline

## Supported build inputs

- Engine: Godot 4.7.1 stable.
- Windows: x86_64 executable plus external PCK, with ANGLE selected for the
  OpenGL compatibility renderer.
- macOS: Universal application archive with hardened runtime enabled.
- Generated output always stays under the ignored `build/` directory.

`export_presets.cfg` is the single source of truth for both platforms. The
platform branches should merge the source branch; they must not maintain a
second copy of export settings.

## Local verification

Run all tests, then export one or both QA targets:

```bash
python3 tools/run_tests.py
python3 tools/export_builds.py --target windows
python3 tools/export_builds.py --target macos
```

The export command fails if Godot exits unsuccessfully, if the Windows PCK is
missing, or if the macOS archive does not contain `Desktop Pet.app`.

## GitHub automation

- `.github/workflows/ci.yml` runs the complete test suite on macOS and Windows
  for every push and pull request.
- `.github/workflows/qa-builds.yml` is manually dispatched and publishes
  unsigned/ad-hoc QA artifacts for 14 days.

QA artifacts are not production releases. Before public distribution, configure
the repository's protected release environment with the real signing material:

- macOS: Developer ID Application certificate, certificate password, Apple team
  ID, and an app-specific password or App Store Connect API key. Sign with
  hardened runtime, submit with `xcrun notarytool`, staple, then verify with
  `codesign --verify` and `spctl --assess`.
- Windows: a trusted code-signing certificate and password. Sign both the EXE
  and installer/package with `signtool`, a SHA-256 digest, and a trusted
  timestamp server, then verify the signatures before upload.

Do not commit certificates, passwords, provisioning data, API keys, or decoded
temporary keychains. Production release jobs should fail when protected secrets
are absent; they should never silently publish unsigned binaries.

## Git LFS asset policy and migration record

Git LFS is required for this repository. `.gitattributes` tracks every `*.png`
and `*.wav`; source code, fonts, project settings, and release artifacts remain
ordinary Git content. GitHub Actions checks out LFS objects and runs
`git lfs fsck --objects --pointers HEAD` before tests or QA exports.

The binary history migration completed on 2026-10-14 for `master`,
`codex/industry-refactor-step-1`, `codex/windows-export`, and
`codex/macos-export`. It uploaded 769 unique LFS objects (about 315 MB) before
the four branch tips were updated with explicit force-with-lease guards.
Migration-time recovery refs are retained on GitHub under:

- `backup/pre-lfs-2026-10-14/master`
- `backup/pre-lfs-2026-10-14/industry-refactor`
- `backup/pre-lfs-2026-10-14/windows-export`
- `backup/pre-lfs-2026-10-14/macos-export`

Do not merge a pre-migration backup ref into rewritten history. Recover an old
change by generating a patch or carefully cherry-picking it, then confirm that
no raw PNG or WAV blob was reintroduced.

Existing clones should be replaced with a fresh clone after installing Git LFS.
If a contributor has no local work and intentionally repairs a clone in place,
they may fetch, hard-reset their branch to its rewritten remote tip, and run
`git lfs pull`. Back up local commits first; old and rewritten commit IDs are
unrelated.

`tools/check_tracked_file_sizes.py` examines committed Git blobs rather than
materialized worktree files. CI rejects direct Git blobs above 20 MiB while LFS
pointers remain small; `git lfs fsck` independently verifies that tracked LFS
paths contain valid pointers and available objects.
