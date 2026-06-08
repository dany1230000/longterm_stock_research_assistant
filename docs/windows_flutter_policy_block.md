# Windows Flutter policy block

本機 Flutter CLI 目前被 Windows 應用程式控制原則擋住。這是驗收阻塞，不代表 00631L app 程式碼已通過 Flutter analyze/test/build。

## Error

目前看到的錯誤原文：

```text
ProcessStarter::StartForExec failed: 應用程式控制原則已封鎖此檔案。 (at ../../runtime/bin/process_win.cc:703)
```

## Local Evidence

目前 `where` 結果：

```text
C:\src\flutter\bin\flutter
C:\src\flutter\bin\flutter.bat
C:\src\flutter\bin\dart
C:\src\flutter\bin\dart.bat
```

`flutter` 在 PowerShell 解析為：

```text
C:\src\flutter\bin\flutter.bat
```

直接執行 Dart SDK 可用：

```text
C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe --version
```

`flutter.bat` 與 `dart.bat` 都有 `Zone.Identifier`：

```text
[ZoneTransfer]
ZoneId=3
ReferrerUrl=C:\Users\User\Downloads\flutter_windows_3.44.1-stable.zip
```

這表示 Flutter SDK 內檔案保留了從網路下載 zip 解壓後的來源標記。`dart.exe` 可以直接跑，但 `flutter` 會啟動 Flutter tool 與其他子程序；Windows App Control / AppLocker / WDAC 可能在子程序啟動時擋下其中某個檔案。

## Possible Causes

- Windows App Control
- AppLocker
- Windows Defender Application Control, WDAC
- 公司或學校裝置政策
- Flutter SDK 或 zip 來源被 Windows 標記封鎖
- SDK 放在受控路徑或被組織政策限制的路徑

## Safe Handling

以下是安全、可回復的處理方式；不要關閉安全性設定，不要使用不明繞過工具。

1. 確認官方 Flutter SDK 路徑：

```powershell
where flutter
where dart
Get-Command flutter | Format-List Source,Path,CommandType
Get-Command dart | Format-List Source,Path,CommandType
```

2. 檢查 Flutter SDK 是否有網路來源標記：

```powershell
Get-Item -LiteralPath C:\src\flutter\bin\flutter.bat -Stream *
Get-Content -LiteralPath C:\src\flutter\bin\flutter.bat -Stream Zone.Identifier
Get-Item -LiteralPath C:\src\flutter\bin\dart.bat -Stream *
Get-Content -LiteralPath C:\src\flutter\bin\dart.bat -Stream Zone.Identifier
```

3. 如果這是自己的電腦，優先重新下載官方 Flutter SDK 到非受控路徑，例如 `C:\src\flutter`。下載來源應使用 Flutter 官方網站。建議先解除官方 zip 的封鎖後再解壓，或重新解壓到乾淨目錄。只針對你確認來源可信的官方 Flutter SDK 使用檔案內容/來源解除封鎖，不要對不明檔案批次解除。

4. 可檢查 SDK 內是否還有 Zone.Identifier：

```powershell
Get-ChildItem -LiteralPath C:\src\flutter -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { Get-Item -LiteralPath $_.FullName -Stream Zone.Identifier -ErrorAction SilentlyContinue }
```

5. 如果這是公司或學校管理裝置，應請管理者允許官方 Flutter SDK 與 Dart SDK。需要允許的內容通常包含：

```text
C:\src\flutter\bin\flutter.bat
C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe
C:\src\flutter\bin\cache\flutter_tools.snapshot
```

實際 allow list 應由管理者依政策工具確認。

## Not Recommended

- 不要關閉 Windows Security、SmartScreen、WDAC 或 AppLocker。
- 不要下載非官方 Flutter SDK。
- 不要從不明來源複製可執行檔覆蓋 SDK。
- 不要用 policy bypass 工具。
- 不要為了通過驗收刪測試或跳過 Flutter 驗收。

## Current Validation Impact

目前可以用直接 Dart SDK 跑：

```powershell
C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe analyze
```

但以下 Flutter 驗收仍被 policy block：

```powershell
flutter analyze
flutter test
flutter build web
```

## Current Concrete Block

本輪診斷已定位到具體被擋檔案：

```text
C:\src\flutter\bin\cache\dart-sdk\bin\dartvm.exe
```

`flutter --version` 失敗，但 `dart --version` 與直接執行 `C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe --version` 可成功。Windows Code Integrity log 顯示：

```text
Code Integrity determined that a process
(\Device\HarddiskVolume3\src\flutter\bin\cache\dart-sdk\bin\dart.exe)
attempted to load
\Device\HarddiskVolume3\src\flutter\bin\cache\dart-sdk\bin\dartvm.exe
that did not meet the Enterprise signing level requirements or violated code integrity policy.
```

直接執行 `dartvm.exe` 也會被擋：

```text
Program 'dartvm.exe' failed to run: An Application Control policy has blocked this file
```

`dart.exe` 與 `dartvm.exe` 的 `Get-AuthenticodeSignature` 結果都是 `NotSigned`，且 SDK 檔案仍帶有來自官方 zip 下載檔的 `Zone.Identifier`。

目前判斷：這不是 Flutter app 專案設定、route、test、backend 或 PATH 順序造成；阻塞點是 Windows Smart App Control / Code Integrity / WDAC 類政策對 Flutter 內建 Dart VM 檔案的執行限制。

## Safe Next Steps

可回復且不降低系統安全性的處理順序：

1. 從 Flutter 官方網站重新下載 SDK zip。
2. 只針對確認來源可信的官方 Flutter zip 做 unblock，然後重新解壓到乾淨目錄，例如 `C:\src\flutter-clean`。
3. 將 `C:\src\flutter-clean\bin` 放到 PATH 前面，開新 PowerShell 後重跑 `where flutter`、`flutter --version`。
4. 若仍出現 Code Integrity enterprise signing block，表示本機政策不只看 Zone.Identifier；需要由裝置管理者允許 Flutter SDK 內建 Dart VM，例如 `dart.exe`、`dartvm.exe` 與 Flutter tool 相關檔案。
5. 不要關閉 WDAC/AppLocker/Smart App Control，不要下載非官方 SDK，不要用 policy bypass 工具。

## Dart Test Note

本 Flutter app 的測試架構使用 `flutter_test`，主要驗收指令是：

```powershell
flutter test
```

`dart test` 需要 `package:test` dev dependency；目前專案沒有採用純 Dart `package:test` 測試架構，所以 `dart test` 的 package not found 不應視為 app 測試失敗。未來若新增純 Dart package/test 架構，再把 `dart test` 納入主要驗收。
