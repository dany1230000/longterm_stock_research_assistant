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
flutter build web --base-href /<project-name>/
```

若部署在自訂網域或 root path，則需依實際路徑設定。

## 部署前檢查

- 不得放入 API key。
- 不得放入個資。
- 不得放入真實帳號資料。
- 不得放入未授權資料。
- 需確認所有展示內容仍標示為 Demo 與模擬資料。
