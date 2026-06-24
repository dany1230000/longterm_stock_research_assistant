# 00631L lab v5.60 compact position entry

Release tag: `00631l-lab-v5.60-compact-position-entry`

v5.60 makes the position page shorter and more app-like.

## What changed

- The tall position header was replaced by a compact page title.
- The local-only account summary now appears immediately after the page title.
- Save, JSON export, and clear actions remain near the account summary.
- If a local position already exists, the edit form is collapsed behind
  `輸入持倉資料`.
- If no local position exists, the input form remains visible so first-time
  setup is straightforward.

## Boundaries

- Position data remains local-only.
- No login, broker connection, or account upload was added.
- Position estimates still depend on the currently available market price.
- No trading guidance was added.

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
