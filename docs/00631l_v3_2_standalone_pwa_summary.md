# 00631L lab v3.2 standalone PWA summary

Completion target: turn the public web app into a dedicated `00631L 正二研究室` PWA.

## What Changed

- App name, browser title, PWA name, short name, and description are 00631L-specific.
- Root route `/` opens the 00631L app directly.
- Compatibility route `/#/00631l-lab` remains supported.
- The previous general dashboard and research screens remain as internal development routes.
- The 00631L screen keeps a mobile-first stock-app layout with sections:
  - 總覽
  - 內容物
  - 歷史
  - 回測
  - 持倉
  - AI 分析
  - 系統狀態
- Top segmented navigation is horizontally scrollable on small screens.
- Static-public mode now surfaces row count, coverage, and generated time in the UI.

## Public Entry

Primary public URL:

```text
https://dany1230000.github.io/longterm_stock_research_assistant/
```

Compatibility URL:

```text
https://dany1230000.github.io/longterm_stock_research_assistant/#/00631l-lab
```

PWA install starts from the root URL and opens the 00631L app.

## Static-Public Data

Static-public mode remains the default GitHub Pages path when there is no public backend yet.

- `USE_00631L_STATIC_DATA=true`
- `00631L_STATIC_DATA_BASE_URL=00631l-static-data`
- Generated data folder: `web\00631l-static-data`
- Generated data remains ignored by Git.
- History and backtest can work from generated static JSON.
- live intraday NAV and official live holdings refresh still require backend.

## Data Source Truthfulness

- Yuanta holdings / ratio: official daily snapshot, not intraday holdings.
- TWSE price history: official historical price source after static export/update.
- TWSE intraday NAV: live or cached only when backend proxy is deployed and configured.
- TX live: not connected.
- Mock/fallback data is never labeled as official.

## Position And Backtest

- Position tracking stays local-only in the browser.
- No login is required.
- Position data is not uploaded to an external service.
- Historical backtest still supports one-time and periodic contribution scenarios.
- 回測不代表未來表現，非買賣建議。

## Next Deployment Step

To make intraday NAV live from anywhere, deploy the FastAPI backend publicly, configure CORS, set a public backend URL during Flutter build, and mount a persistent backend data volume.

## Scope Boundaries

This release does not add TX live, expand beyond 00631L, add notifications, add automated trading, or provide investment guidance.
