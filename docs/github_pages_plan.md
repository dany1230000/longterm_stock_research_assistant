# GitHub Pages Deployment Plan

## Suggested Repository Name

建議 repository 名稱：`longterm_stock_research_assistant`

原因：

- 與目前專案資料夾名稱一致，方便對應 build base href。
- 清楚表達產品是長線股票研究助理，而不是交易指令工具。
- 適合 GitHub Pages project page 路徑：`/<repository-name>/`。

若實際 repository 名稱不同，GitHub Pages project page 的 base href 也必須同步調整。

## GitHub Pages Deployment Options

### A. Manual Upload Of `build/web`

流程：

1. 在本機執行 `flutter build web --base-href="/longterm_stock_research_assistant/"`。
2. 將 `build/web` 內容上傳到 GitHub Pages 指定來源。
3. 每次改版都手動重新 build 與上傳。

優點：

- 設定較少。
- 初期可快速確認部署產物。

限制：

- 容易漏跑 `flutter analyze`、`flutter test` 或格式檢查。
- 產物來源不易追溯。
- 每次更新都需要人工處理。

### B. GitHub Actions Auto Build And Deploy

流程：

1. push 到 `main`。
2. GitHub Actions 自動執行驗證。
3. 通過後自動執行 Flutter Web build。
4. 將 `build/web` 發佈到 GitHub Pages。

優點：

- 每次部署前都會固定執行格式、分析與測試。
- 部署產物可追溯到 commit。
- 不需要把本機 build 產物提交進 repository。
- 可降低人工操作漏步風險。

## Why Use GitHub Actions

建議使用 GitHub Actions 作為正式 GitHub Pages 流程，原因是它能把驗證與部署合併成可重複的流程。對 Demo Web MVP 來說，這比手動上傳更適合保存品質紀錄，也能確保公開頁面來自已通過檢查的 commit。

## Base Href For Project Pages

GitHub Pages project page 通常會部署在：

```text
https://<account>.github.io/<repository-name>/
```

Flutter Web 需要讓 `base href` 對應 project page path。若 repository 名稱是 `longterm_stock_research_assistant`，建議 build 指令為：

```bash
flutter build web --base-href="/longterm_stock_research_assistant/"
```

若 repository 名稱不同，請將 base href 改成實際 repository path：

```bash
flutter build web --base-href="/<actual-repository-name>/"
```

若未來部署在自訂網域 root path，通常可改回：

```bash
flutter build web --base-href="/"
```

## Deployment Checklist

- 確認 GitHub repository 名稱。
- 確認 GitHub Pages source 設為 GitHub Actions。
- 確認預設分支或部署分支是 `main`。
- 確認 workflow build 指令的 base href 與 repository 名稱一致。
- 執行 `flutter analyze` 並確認通過。
- 執行 `flutter test` 並確認通過。
- 確認 `flutter build web --base-href="/longterm_stock_research_assistant/"` 成功。
- 確認 Demo 頁面仍明確標示目前使用模擬資料。
- 確認免責聲明仍清楚顯示。
- 確認不提交 `build/` 產物到 repository。
- 確認不提交本機 zip 展示包。
- 不得上傳 API key。
- 不得上傳個資。
- 不得上傳真實帳號資料。
- 不得上傳未授權資料。

## Demo Copy Requirements

公開 Demo 頁面仍需明確表達：

- 目前為 Demo 版本。
- 目前使用模擬資料。
- 僅供研究與教育用途。
- 不構成投資建議、買賣建議或收益保證。
