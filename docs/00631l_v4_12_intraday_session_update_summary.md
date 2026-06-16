# 00631L v4.12 intraday session update summary

本版修正盤中即時資料的更新節奏與顯示方式。

## 完成內容

- Backend `/api/etf/00631l/intraday-nav` 新增 `marketSession` metadata。
- `marketSession` 會標示 Asia/Taipei 盤前、盤中、收盤確認、盤後、休市。
- 盤中資料會計算資料年齡、預期刷新秒數與 freshness。
- Frontend 改成動態自動刷新：
  - live proxy 盤中依 TWSE `userDelay` 或至少約 15 秒刷新 intraday NAV。
  - 完整 lab data 低頻刷新，避免高頻重抓歷史與 catalog。
  - static public / mock mode 降低刷新頻率。
- 行情卡顯示盤中時段、資料狀態與資料年齡。
- 資料覆蓋區新增「盤中時段」狀態列。

## 資料頻率

- 官方 holdings / ratio：每日快照，不是盤中即時內容物。
- intraday NAV / 折溢價：盤中更新，需 live backend。
- TX live：仍依現有資料狀態顯示，不把 fallback 標示成 official。

## 驗收

- `flutter analyze`
- `flutter test`
- `flutter build web`
- `py -m unittest discover -s backend\tests`
- `scripts\00631l_release_check.cmd`
- `git diff --check`

release check 若只有本機 persistence、Docker unavailable 或既有資料完整性 WARN，且 `failures=[]`，可接受。
