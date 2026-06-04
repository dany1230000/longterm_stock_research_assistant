# Web Deployment Notes

## Build Web

```bash
flutter pub get
flutter build web
```

`build/web` 是 Flutter Web 的部署產物。部署時只需要上傳 `build/web` 內的檔案。

## 本機預覽 Release Build

可用任一靜態檔案伺服器預覽，例如：

```bash
cd build/web
python -m http.server 8080
```

然後開啟：

```text
http://localhost:8080
```

## 未來可部署平台

- GitHub Pages
- Firebase Hosting
- Vercel 類靜態網站服務
- 其他支援靜態檔案託管的服務

## GitHub Pages Base Href

若使用 GitHub Pages project page，通常網址會是：

```text
https://<account>.github.io/<project-name>/
```

這種情境可能需要在 build 時調整 base href：

```bash
flutter build web --base-href="/<project-name>/"
```

若部署在自訂網域或 root path，則需依實際路徑設定。

目前規劃的 repository 名稱為 `longterm_stock_research_assistant`，對應 build 指令為：

```bash
flutter build web --base-href="/longterm_stock_research_assistant/"
```

若 repository 名稱不同，請將 `--base-href` 改成實際 repository path。例如 repository 名稱為 `stock-research-demo` 時：

```bash
flutter build web --base-href="/stock-research-demo/"
```

## GitHub Pages With GitHub Actions

本專案已提供 workflow 草稿：

```text
.github/workflows/deploy_web.yml
```

此 workflow 規劃在 push 到 `main` 時執行：

- `flutter pub get`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- `flutter build web --base-href="/longterm_stock_research_assistant/"`
- 發佈 `build/web` 到 GitHub Pages

使用前需在 GitHub repository 設定：

- Pages source 使用 GitHub Actions。
- 預設分支或部署分支與 workflow 的 `main` 設定一致。
- 若 repository 名稱不同，需同步修改 workflow 中的 `--base-href`。

目前 workflow 僅為部署準備草稿，尚未 push 到 GitHub，也未設定任何密鑰。

## 部署前檢查

- 不得放入 API key。
- 不得放入個資。
- 不得放入真實帳號資料。
- 不得放入未授權資料。
- 需確認所有展示內容仍標示為 Demo 與模擬資料。
