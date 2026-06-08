# 00631L lab v1.30 daily experience summary

Completed on 2026-06-09.

v1.30封存 v1.21 到 v1.29 的日常使用體驗改進。這一階段沒有接 TX live，沒有擴大到所有正二，沒有加入推播通知、自動交易或投資建議。

## Completed scope

### Direct entry

- Dashboard 顯示清楚的「00631L 正二研究室」入口。
- Flutter web manifest 的 `start_url` 指向 `/#/00631l-lab`。
- `scripts\00631l_start_frontend_live.cmd` 與 `scripts\00631l_open_lab.cmd` 都提示直接 route。

### Mobile layout

- `/00631l-lab` 在手機寬度下使用更緊湊的一欄卡片。
- 表格維持橫向可讀，不會讓整頁空白或破版。
- status、sourceContract、折溢價狀態與 operations/status 保持文字可讀。

### PWA metadata

- `web/manifest.json` 與 `web/index.html` 使用 `00631L 正二研究室` metadata。
- Flutter web build 仍可輸出到 `build\web`。
- live data 仍需要 backend proxy。

### Backup

- `scripts\00631l_backup_data.cmd` 建立本機備份。
- 備份輸出到 ignored `backend\backups\`。
- 備份範圍包含 holdings history、intraday NAV history、daily cycle status 與 export metadata。

### Data health

- `scripts\00631l_check_env.cmd` 檢查 `backend\data`、`backend\exports`、`backend\backups` 是否存在與可寫入。
- `/api/etf/00631l/operations/status` 顯示 data directory health 與 backup 狀態。
- `/00631l-lab` 顯示資料目錄、backup、export、daily cycle 與 env 狀態。

### Open lab helper

- `scripts\00631l_open_lab.cmd` 是最簡單的日常入口。
- helper 會跑環境檢查、檢查 backend health，並列出 backend、daily cycle、frontend live 與 direct route。
- helper 不把 server 藏在背景執行。

### Troubleshooting

- `docs/00631l_troubleshooting.md` 說明常見問題：
  - 看到 app 外殼時如何進 00631L route
  - backend uvicorn 畫面
  - `.env` 未建立
  - intraday NAV unavailable
  - smoke WARN
  - Flutter path
  - web build
  - port 8000
  - CSV export
  - history 空資料

### Deployment notes

- `docs/00631l_deployment_notes.md` 說明本機開發、Flutter web build、backend proxy、`.env`、資料持久化、exports/backups、GitHub Pages 限制與家用主機/VPS 注意事項。

### Operations guidance

- `/00631l-lab` 的「今日資料狀態」加入「下一步操作提示」。
- 提示只包含 app 操作：
  - 執行 daily cycle
  - 參考 `.env.example`
  - 檢查 TWSE URL 設定或交易時段
  - 建立 CSV export
  - 建立 local backup
  - 檢查資料目錄

## Daily command list

最簡單入口：

```cmd
cd C:\dev\longterm_stock_research_assistant
scripts\00631l_open_lab.cmd
```

backend：

```cmd
scripts\00631l_start_backend.cmd
```

daily cycle：

```cmd
scripts\00631l_daily_cycle.cmd
```

Flutter live proxy：

```cmd
scripts\00631l_start_frontend_live.cmd
```

direct route：

```text
http://127.0.0.1:<flutter-port>/#/00631l-lab
```

CSV export：

```cmd
scripts\00631l_export_history.cmd
```

backup：

```cmd
scripts\00631l_backup_data.cmd
```

release check：

```cmd
scripts\00631l_release_check.cmd
```

## Validation scope

Required release validation:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```

WARN is acceptable for missing local `.env` or off-hours intraday freshness when `failures` is empty.

## Known limitations

- TX live remains mock/fallback by design.
- Scope remains 00631L only.
- No push notification.
- No auto trading.
- No investment or trading advice.
- Live data requires backend proxy.
- GitHub Pages can host only the static frontend unless a separate backend is available.

## Release conclusion

v1.30 is the daily experience release for the 00631L 正二研究室. It is intended to make the tool easier to open, verify, back up, deploy, and troubleshoot while preserving the original data-source transparency rules.
