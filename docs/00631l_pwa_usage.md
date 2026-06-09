# 00631L PWA usage

00631L 正二研究室可以用 Flutter Web 形式部署成 PWA。PWA 是前端入口，live data 仍需要 backend proxy。

## 手機使用

1. 用手機瀏覽器開公開網址。
2. 進入：

```text
https://your-frontend.example.com/#/00631l-lab
```

3. 確認頁面上的 backend 狀態不是 `backend disconnected`。
4. 確認資料標籤是 official、proxy、cached、stale、mock、unavailable 或 error。

## 加到主畫面

Android Chrome：

- 開公開網址。
- 使用瀏覽器選單的「新增到主畫面」或「安裝應用程式」。

iOS Safari：

- 開公開網址。
- 使用分享選單的「加入主畫面」。

iOS 和 Android 的安裝文字可能不同，但本質都是把 web app 入口放到主畫面。

## Live data 條件

- 前端 build 必須指定公開 backend：

```cmd
flutter build web --dart-define=USE_00631L_LIVE_PROXY=true --dart-define=00631L_PROXY_BASE_URL=https://your-backend.example.com
```

- backend 必須設定 `ALLOWED_ORIGINS`，允許前端網域。
- backend data directory 必須使用 persistent storage。
- backend `/health` 必須正常。

## 資料更新頻率

- Yuanta holdings / ratio 是官方每日快照，不是盤中即時。
- TWSE intraday NAV / 折溢價可約 15-30 秒更新，前提是 backend 與 env 正常。
- TX live 尚未接入；頁面只顯示 mock/fallback 狀態。

## backend 不通時

頁面應維持可讀，並顯示 backend disconnected、mock、unavailable 或 error。這些狀態不能被標示為 official。
