# 00631L lab v10.4 overview mode label cleanup

Release tag: `00631l-lab-v10.4-overview-mode-label-cleanup`

## Goal

Make the overview header read like a finished app instead of exposing technical
mode wording.

## Changes

- The top mode badge now uses `示範` instead of `Mock 預設` in default mode.
- Live and static labels remain `即時後端` and `公開靜態`.
- Detailed source labels remain available in data/source panels.

## Unchanged

- Data source selection, mock fallback behavior, static public data, live proxy
  priority, and parser behavior were not changed.
