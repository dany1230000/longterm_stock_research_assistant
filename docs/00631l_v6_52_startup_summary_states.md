# 00631L v6.52 startup summary states

v6.52 makes the first screen feel ready while background data continues loading.

## What changed

- The overview DAY / LIVE / HIS row no longer shows generic `loading` text.
- DAY shows `syncing` while official daily data refreshes in the background.
- LIVE shows `checking` while the backend intraday NAV check is pending.
- HIS still shows the available static history row count whenever it is already loaded.

## Data behavior

- This does not change any repository, parser, or calculation behavior.
- Static history remains historical data, not live intraday data.
- Live intraday NAV still requires the public backend.

## Validation focus

- Widget coverage verifies the fast first screen shows background status labels instead of generic loading text.
