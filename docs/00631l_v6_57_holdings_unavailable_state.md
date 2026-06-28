# 00631L v6.57 holdings unavailable state

v6.57 improves overview data truthfulness during live backend fallback states.

If the current holdings snapshot is an error/zero-value placeholder, the overview no longer renders TX, TSMC, and mix digest tiles with `0` or `unavailable` values. It shows a compact unavailable state instead.

This keeps the first screen clear:

- Static public history can still power the chart and backtest.
- Live intraday NAV still depends on the public backend.
- Official holdings digest appears only when a usable holdings snapshot exists.
- Placeholder values are not presented as official holdings.

Verification:

- Widget test covers the unavailable holdings digest state.
- Full release validation remains required before tag/push.
