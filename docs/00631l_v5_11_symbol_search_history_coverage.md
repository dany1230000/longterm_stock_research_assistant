# 00631L v5.11 Symbol Search History Coverage

Release tag: `00631l-lab-v5.11-symbol-search-history-coverage`

## Scope

v5.11 makes the top-left ETF search sheet clearer about how much ETF history
data is currently available.

## Changes

- The symbol search sheet now shows `歷史覆蓋 ready / catalog rows`.
- The label uses the actual imported history readiness count when available.
- The existing `可用歷史` label remains for quick scanning.

## Data Behavior

- No new data source was added.
- No parser or split-adjustment behavior changed.
- No TX quote behavior changed.

## Validation

- Widget coverage checks the new history-coverage label in the search sheet.
- Backend health metadata is updated to v5.11.
- Release check requires this summary file.
