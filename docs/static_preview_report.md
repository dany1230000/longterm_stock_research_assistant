# Static Preview Report

## Version

- Latest commit hash: `9ba0038`
- Local git tag: `v0.1.0-web-mvp`
- Tag status: local only, not pushed to remote.

## Validation Results

- `flutter pub get`: success. Dependency resolution completed; only non-blocking newer-version notices were shown.
- `dart format .`: success. 36 files checked, 0 changed.
- `flutter analyze`: success. `No issues found!`
- `flutter test`: success. 5 tests passed.
- `flutter build web`: success. `build/web` generated. Flutter reported successful Wasm dry run as an informational notice.

## Static Server

- Server command: `py -m http.server 8080`
- Server root: `C:\dev\longterm_stock_research_assistant\build\web`
- Preview URL: `http://localhost:8080`
- Detail route checked: `http://localhost:8080/#/stocks/2330`

## Checked Pages

- Dashboard
- Stock detail page
- Screener
- Backtest
- Research journal
- Settings

## Desktop Check

- Viewport: default desktop browser size.
- Result: all primary pages loaded and navigated correctly.
- Demo label: visible.
- Mock data label: visible.
- Disclaimer: visible where expected.
- UI overflow: no obvious overflow observed.
- Product tone: remained research and education oriented.

## 390px Narrow Screen Check

- Viewport: 390px wide.
- Result: bottom navigation worked across all 5 tabs.
- Stock detail route loaded correctly.
- Stock detail section controls wrapped into multiple rows and remained usable.
- Demo label and disclaimer remained visible.
- UI overflow: no obvious overflow observed.

## Console Results

- Desktop: no console error or warning observed.
- 390px narrow screen: no console error or warning observed.

## Demo Package

- Zip path: `C:\dev\longterm_stock_research_assistant_artifacts\longterm_stock_demo_web_9ba0038.zip`
- Zip source: contents of `build/web`
- Zip location: outside the git repository.

## Not Ready For Formal Launch

- The app still uses mock data only.
- Real market data authorization has not been confirmed.
- There is no production data update pipeline.
- There is no account system, privacy policy, terms flow, monitoring, or support process.
- Cross-browser QA and wider visual regression coverage are not complete.

## Next Steps

- Share the local demo package with a small early-review group.
- Collect feedback on workflow clarity, copy, and research usefulness.
- Define the authorized data source plan before integrating any real data.
- Keep the mock repository path available for tests and demos.
- Plan formal hosting only after data licensing, compliance copy, and operational checks are ready.
