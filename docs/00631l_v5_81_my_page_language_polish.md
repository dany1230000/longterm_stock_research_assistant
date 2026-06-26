# 00631L lab v5.81 my page and language polish

This release tightens the ETF research-room app surface without changing data calculations.

## Changed

- Bottom navigation now labels the rightmost section as `我的` instead of `設定`.
- The rightmost page now opens with `我的` / `我的總覽`, putting account, appearance, selected ETF, and local-only position status first.
- Technical diagnostics remain available in collapsed advanced panels.
- Symbol search and selected ETF readiness labels now use user-facing Chinese wording:
  - `歷史可用`
  - `回測可用`
  - `僅清單資料`
  - `盤中 NAV 限 00631L`
- Internal widget keys still keep stable English identifiers for tests.

## Not changed

- No TX live integration was added.
- No generated ETF history data was committed.
- No fallback or mock data is labeled as official.
- No investment guidance was added.
