# 00631L v4.0 App Store foundation summary

Completed date: 2026-06-13

## Scope

v4.0 prepares the current public PWA for the next App Store / Play Store workstream. It does not add trading, notifications, broker login, TX live, or broader ETF scope.

## What Changed

- Product metadata now presents the app as `ETF 研究室 · 00631L 正二研究室`.
- The 00631L lab remains the first complete room and the only supported ETF research room.
- The market header shows the ETF research room framing while preserving the 00631L identity.
- History and backtest are now more direct: the backtest form is visible on the history/backtest page instead of hidden behind an expansion panel.
- Settings now includes an `App 上架準備` section covering PWA, Android, iOS, privacy/support, and live backend readiness.
- The App Store path document was rewritten in readable Chinese.
- A dedicated app-store release plan was added for Android/iOS follow-up.

## Current App Store Readiness

- PWA: ready for public daily use.
- Android: planned; native scaffold and signing are not yet in this repo.
- iOS: planned; requires macOS, Xcode, Apple Developer, signing, and App Store Connect.
- Backend: public deploy-ready, with HTTPS/public backend path already documented.
- Store materials: privacy policy, support URL, icon, screenshots, and descriptions still need final assets.

## Data Boundary

- Static public data supports history and backtest.
- Live intraday NAV and latest official holdings require backend connectivity.
- Holdings remains official daily snapshot data, not intraday holdings.
- AI remains rule-based by default.

## Validation

Run:

```cmd
flutter analyze
flutter test
flutter build web
py -m unittest discover -s backend\tests
scripts\00631l_release_check.cmd
git diff --check
```
