# ETF research room v4.48 compact AI detail

Date: 2026-06-22

## Scope

v4.48 shortens the AI page for mobile reading.

## Changes

- The AI page now shows only the first few current-day bullets and program actions by default.
- The complete data briefing is preserved behind an expandable detail panel.
- The analysis source, readiness, generated time, data time, and non-advisory disclaimer remain visible.
- This change is UI structure only. It does not change the rule-based analysis provider, backend analysis endpoint, or data calculations.

## Verification

- Widget coverage verifies the complete briefing is hidden by default.
- Widget coverage verifies the complete briefing appears after expanding the detail panel.
- Existing wording checks remain active.
