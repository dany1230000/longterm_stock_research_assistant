# ETF History Source Redirect Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent official TWSE 3xx redirects from being misclassified as ETF price-history source failures.

**Architecture:** Keep the existing TWSE STOCK_DAY parser and ETF history store unchanged. Add a narrow redirect fallback in the shared backend fetcher, then document that official empty payloads remain unavailable rather than being treated as usable history.

**Tech Stack:** Python FastAPI backend, unittest, existing ETF price-history import/status scripts.

---

### Task 1: Redirect-Aware Backend Fetch

**Files:**
- Modify: `backend/app/fetcher.py`
- Test: `backend/tests/test_fetcher.py`

- [x] **Step 1: Add a failing test for HTTP 307**

```python
with patch(
    "backend.app.fetcher.urlopen",
    side_effect=HTTPError(url, 307, "Temporary Redirect", {}, None),
), patch(
    "backend.app.fetcher._fetch_text_with_curl",
    return_value='{"stat":"很抱歉，沒有符合條件的資料!","total":0}',
) as curl_fallback:
    payload = fetch_text(url, timeout_seconds=3)
```

- [x] **Step 2: Add a test that HTTP 500 stays an error**

```python
with patch(
    "backend.app.fetcher.urlopen",
    side_effect=HTTPError(url, 500, "Internal Server Error", {}, None),
), patch("backend.app.fetcher._fetch_text_with_curl") as curl_fallback:
    with self.assertRaises(FetchError):
        fetch_text(url, timeout_seconds=3)
```

- [x] **Step 3: Implement minimal redirect fallback**

```python
if 300 <= error.code < 400:
    return _fetch_text_with_curl(url, timeout_seconds)
```

- [x] **Step 4: Verify**

Run:

```cmd
py -m unittest backend.tests.test_fetcher
```

Expected: PASS.

### Task 2: Documentation and Release Notes

**Files:**
- Create: `docs/00631l_v8_4_etf_source_redirect.md`
- Modify: `README.md`
- Modify: `docs/00631l_docs_index.md`

- [x] **Step 1: Document the behavior**

Explain that v8.4 follows official TWSE redirects and keeps official empty
responses classified as unavailable data.

- [x] **Step 2: Run full validation before commit**

```cmd
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_import_etf_price_history.cmd --status-only --summary-only
scripts\00631l_validate_etf_price_history.cmd
scripts\00631l_release_check.cmd
git diff --check
```

- [x] **Step 3: Commit and tag**

```cmd
git add backend/app/fetcher.py backend/tests/test_fetcher.py docs/00631l_v8_4_etf_source_redirect.md README.md docs/00631l_docs_index.md docs/superpowers/plans/2026-06-29-etf-history-source-redirect.md
git commit -m "Handle ETF history source redirects"
git tag -a 00631l-lab-v8.4-etf-source-redirect -m "00631L lab v8.4 ETF source redirect handling"
```
