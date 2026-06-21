# 00631L lab v4.21 AI Daily Clarity

Date: 2026-06-21

## Scope

v4.21 makes the AI tab easier to scan on mobile. The rule-based summary now starts with a compact daily data briefing before the longer bullets.

## Changes

- Added an AI `今日資料狀態` block for readiness, backend/static/mock state, price history source, official holdings date, and intraday NAV data time.
- Added `資料來源與時間` so generated time, analysis data time, and historical coverage are visible without reading the full report.
- Added `缺口與下一步` using existing program-action items from the rule-based summary.
- Kept AI source as `rule_based`; no external LLM key or provider is enabled.

## Boundaries

- No new investment instruction wording.
- No automatic trading, broker login, or notification flow.
- No change to TX live source behavior.
- No mock/fallback data is labeled as official.

## Validation

- Widget coverage checks that the AI page renders `今日資料狀態`, `資料來源與時間`, and `缺口與下一步`.
