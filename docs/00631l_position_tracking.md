# 00631L position tracking guide

The position section is a local-only calculator for a user's own 00631L holding record.

## Stored Fields

- Shares.
- Average cost.
- Optional total assets.
- Optional fee and tax adjustment.
- Optional note.

## Displayed Results

- Current market value, when intraday market price is available.
- Cost.
- Unrealized result.
- Unrealized result percentage.
- Position share of user-entered total assets, when total assets is provided.
- Data time.
- Local-only storage status.

## Storage

The default storage is browser local storage.

- No login is required.
- The app does not upload this position record to the backend by default.
- The data is not committed to git.
- The user can export JSON or clear the local record from the position section.

## Data Quality

If market price is unavailable, the calculator keeps the saved input visible and marks the result as unavailable. It does not substitute mock market price as official data.

The section is a local record and calculation aid only. It is marked as `非買賣建議`.
