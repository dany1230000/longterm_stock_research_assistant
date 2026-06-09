# 00631L lab v1.46 release summary

Completed on 2026-06-09.

## Scope

v1.46 strengthens local backup integrity checks with SHA256 checksums.

## Changes

- Backup manifest now records SHA256 for every included source file.
- Backup payload reports the SHA256 of the generated zip archive.
- Restore dry-run now verifies each archive entry against the manifest SHA256.
- Restore dry-run output includes:
  - backup zip SHA256
  - entries with checksum
  - entries verified
  - checksum mismatch failures
- Backend tests cover manifest checksums and checksum mismatch failure.

## Behavior

- New backups can be verified without restoring or overwriting data.
- Old backups without per-entry SHA256 remain readable but may produce WARN states.
- Local backup archives remain under ignored `backend/backups/`.

## Limits

- No restore overwrite script was added.
- No TX live source was added.
- No notifications or investment guidance were added.

## Validation

Run:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
