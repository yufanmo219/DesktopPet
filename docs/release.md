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

## Git LFS migration boundary

The current checkout contains about 314 MiB of runtime assets and the existing
Git object pack is about 2.34 GiB. Git LFS is not installed in the current
development environment, and the repository's existing binary history is
already shared by `master`, `codex/windows-export`, and `codex/macos-export`.

Adding only a `.gitattributes` file would not migrate existing objects and could
leave contributors with pointer files they cannot materialize. A real migration
therefore needs a coordinated maintenance window:

1. Confirm GitHub LFS storage/bandwidth and install Git LFS on every build host.
2. Freeze all three long-lived branches.
3. Run a full `git lfs migrate import` for approved binary patterns.
4. Force-push the rewritten branch tips, then have every contributor reclone.
5. Enable `lfs: true` in checkout jobs and verify clean Windows/macOS exports.

Until that coordinated migration, CI uses shallow clones and new individual
assets are limited to 20 MiB by `tools/check_tracked_file_sizes.py`.
