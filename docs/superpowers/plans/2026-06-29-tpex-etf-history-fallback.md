# TPEx ETF History Fallback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an official TPEx ETF historical daily-price fallback so ETF histories that are empty in TWSE STOCK_DAY can be verified and populated from TPEx instead of remaining classified as generic official empty data.

**Architecture:** Keep TWSE STOCK_DAY import unchanged and add a separate TPEx parser/fetcher module with its own `sourceContract`. Add a focused CLI that fetches TPEx daily all-ETF rows by date, saves matching ETF records through the existing `EtfPriceHistoryStore`, and records import attempts truthfully.

**Tech Stack:** Python FastAPI backend modules, Windows `.cmd` wrappers, existing JSONL price-history store, GitHub Actions Pages workflow, Flutter static/public frontend consuming existing exported JSON.

---

### Task 1: Official TPEx Parser And Fetcher

**Files:**
- Create: `backend/app/tpex_etf_price_history.py`
- Test: `backend/tests/test_tpex_etf_price_history.py`

- [ ] Add parser for TPEx `ETFReport/historical` JSON rows.
- [ ] Parse ROC dates such as `1150626` into `2026-06-26`.
- [ ] Map fields to existing price-history point shape: date, open, high, low, close, volume, source status, source contract, source URL.
- [ ] Add tests for successful parsing, filtering a requested code, and empty official rows.

### Task 2: TPEx Import CLI

**Files:**
- Create: `backend/scripts/import_tpex_etf_price_history.py`
- Create: `scripts/00631l_import_tpex_etf_price_history.cmd`
- Modify: `backend/app/config.py`
- Test: `backend/tests/test_tpex_etf_price_history.py`

- [ ] Add `TPEX_ETF_PRICE_HISTORY_URL` setting with the verified official endpoint.
- [ ] Add CLI flags for `--codes`, `--from-catalog`, `--missing-only`, `--official-empty-only`, `--start-date`, `--end-date`, `--limit`, `--allow-partial`, and `--summary-only`.
- [ ] Fetch TPEx daily all-ETF report by trading day and save matching codes.
- [ ] Record TPEx attempts with `sourceContract: tpex_etf_price_history_import_attempt`.
- [ ] Keep failures explicit; do not replace missing data with mock rows.

### Task 3: Static Export Workflow Wiring

**Files:**
- Modify: `scripts/00631l_build_pages_static.cmd`
- Modify: `.github/workflows/deploy_web.yml`
- Modify: `scripts/00631l_release_check.cmd` or `backend/scripts/release_check_00631l.py` if needed.

- [ ] Run TPEx fallback after restoring public attempts and before final static export.
- [ ] Keep TPEx fallback best-effort for broad Pages builds, but fail in explicit strict local runs.
- [ ] Ensure release check can detect the wrapper script and does not require live TPEx network success.

### Task 4: Documentation And Validation

**Files:**
- Create: `docs/00631l_v8_7_tpex_etf_history_fallback.md`
- Modify: `README.md`
- Modify: `docs/00631l_docs_index.md`

- [ ] Document the verified TPEx official endpoint and source contract.
- [ ] Explain that TWSE empty rows are now rechecked against TPEx official daily ETF history.
- [ ] Run backend tests, Flutter tests/build, release check, static status, public static check, and whitespace check.
- [ ] Commit, tag `00631l-lab-v8.7-tpex-etf-history-fallback`, push main and tag.
