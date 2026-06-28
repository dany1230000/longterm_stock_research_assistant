# 00631L v6.47 position empty hint compact

v6.47 shortens the empty-state area on the local position page.

## What changed

- Replaced the large `尚未輸入持倉` empty panel with a compact hint strip.
- Kept the account strip, local-only action row, input fields, JSON export, clear action, and estimate details unchanged.
- The compact hint explains that shares and average cost unlock market value, profit/loss, and position ratio estimates.

## Data behavior

- Position data remains local-only in the browser.
- No login, external upload, formula, or storage behavior changed.
- Output remains a data-status estimate and non-advice text.

## Validation focus

- Widget coverage verifies the compact empty hint strip appears in the position page.
- Existing local-only save/export/clear controls remain covered.
