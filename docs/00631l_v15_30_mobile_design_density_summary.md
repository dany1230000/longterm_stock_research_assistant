# 00631L lab v15.30 mobile design density summary

This release closes the current phone-first design-density batch.

## Completed in this batch

- AI detail entry uses shorter collapsed copy on phone width.
- Overview first screen has height guards so important content stays visible.
- History/backtest date controls use compact spacing.
- Backtest result summary stays short on phone width.
- ETF search result rows are shorter and easier to scan.
- Settings quick controls use a compact two-column layout.
- Bottom navigation uses a shorter fixed height.
- Top app bar and ETF search pill use a shorter fixed height.
- Overview chart keeps start, middle, and end date anchors visible on phone.

## Product direction

The app remains an ETF research room with a mobile-first layout. The current
focus is first-screen readability, clear data labels, and compact controls. Data
source behavior is unchanged: live backend, static public data, and mock fallback
must stay labeled truthfully.

## Validation

The batch is guarded by widget tests for phone width, chart readability, search
row density, settings layout, AI detail collapse, and bottom/top navigation
height. Release check still includes forbidden wording scan, backend tests,
Flutter analyze/test/build, static data checks, and public deployment checks.
