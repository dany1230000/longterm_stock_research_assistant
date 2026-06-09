# 00631L lab v2.1 mobile + AI summary

Completed on 2026-06-09.

## Goal

v2.1 makes the 00631L lab easier to use on a phone and adds a safe rule-based AI analysis summary. The release keeps the product scoped to 00631L and keeps all analysis as data-status explanation.

## Completed Scope

- LAN mobile helper scripts:
  - `scripts\00631l_lan_info.cmd`
  - `scripts\00631l_start_backend_lan.cmd`
  - `scripts\00631l_start_frontend_lan.cmd`
- Mobile usage guide: `docs\00631l_mobile_usage.md`
- AI analysis guide: `docs\00631l_ai_analysis.md`
- Backend endpoint: `GET /api/etf/00631l/analysis/summary`
- Backend provider interface:
  - `AnalysisProvider`
  - `RuleBasedAnalysisProvider`
  - `ExternalLlmAnalysisProvider` placeholder
- Frontend `AI 分析摘要` block on `/#/00631l-lab`
- Frontend `資料更新頻率` block on `/#/00631l-lab`
- 30-second lightweight page refresh while the lab screen is open
- Release check coverage for AI endpoint and mobile/AI docs/scripts

## Data Update Frequency

- official holdings / ratio: Yuanta official daily snapshot, not intraday real-time holdings.
- intraday NAV / premium discount: TWSE all_etf.txt through backend proxy, approximately 15–30 seconds when backend and env are ready.
- TX live: not connected in this release; mock/fallback only.

## AI Analysis

The default analysis source is `rule_based`. It uses existing local and live-proxy state:

- official holdings history
- intraday NAV history
- premium/discount state
- daily readiness
- data integrity
- report/export/backup status

It returns bullets and program action items only. It does not call an external LLM and does not need an API key.

## Explicitly Not Included

- TX live source.
- Expansion beyond 00631L.
- Notifications.
- Automated trading.
- Investment operation guidance.
- Any committed `.env`, build output, local data, reports, exports, backups, cache, or logs.
