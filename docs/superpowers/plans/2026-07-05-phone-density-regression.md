# 00631L Phone Density Regression Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a cross-tab phone layout regression guard so the main 00631L app tabs stay compact after future UI work.

**Architecture:** This version is intentionally test-and-documentation focused. It uses existing widget keys in the 00631L screen and does not change data fetching, source status mapping, investment text, or generated static data.

**Tech Stack:** Flutter widget tests, existing 00631L Riverpod repository overrides, Markdown docs.

---

### Task 1: Cross-Tab Phone Density Guard

**Files:**
- Modify: `test/etf_00631l_widget_test.dart`
- Create: `docs/00631l_v16_20_phone_density_regression.md`
- Modify: `README.md`
- Modify: `docs/00631l_docs_index.md`

- [ ] **Step 1: Add the widget test**

Insert a new widget test after `phone tabs open distinct first-screen content`. The test checks the compact first-screen bounds for overview, AI, position, and settings on a 390px phone viewport using existing `ValueKey` anchors.

- [ ] **Step 2: Run the targeted test**

Run:

```powershell
flutter test test\etf_00631l_widget_test.dart --plain-name "phone first-screen density guard covers main app tabs"
```

Expected: PASS.

- [ ] **Step 3: Add the v16.20 docs**

Create `docs/00631l_v16_20_phone_density_regression.md` with the release scope, the guarded tab list, the exact validation command, and the note that no data or advice behavior changed.

- [ ] **Step 4: Update index and README**

Add v16.20 to the top of the README mobile UI polish list and the top of `docs/00631l_docs_index.md`.

- [ ] **Step 5: Run full direct validation**

Run direct terminal commands only:

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
py backend\scripts\check_public_config_00631l.py
py backend\scripts\check_public_static_data_00631l.py
git diff --check
```

Also run the forbidden wording scan over `lib`, `test`, `docs`, `README.md`, and `backend`.

- [ ] **Step 6: Commit, tag, and push**

Stage only:

```powershell
git add README.md docs\00631l_docs_index.md docs\00631l_v16_20_phone_density_regression.md docs\superpowers\plans\2026-07-05-phone-density-regression.md test\etf_00631l_widget_test.dart
```

Commit and tag:

```powershell
git commit -m "Add 00631L phone density regression guard"
git tag -a 00631l-lab-v16.20-phone-density-regression -m "00631L lab v16.20 phone density regression"
git push origin main
git push origin 00631l-lab-v16.20-phone-density-regression
```
