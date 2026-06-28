# 00631L v6.48 AI fact row compact

v6.48 makes the AI page easier to scan on phones.

## What changed

- The top AI briefing keeps its daily interpretation and non-advice disclaimer.
- The `內容物`, `盤中 NAV`, and `歷史資料` facts now render as a compact three-cell row on phone width.
- Desktop and wider layouts still use the existing multi-card layout.

## Data behavior

- Rule-based analysis remains the active provider.
- No external LLM, data source, or calculation behavior changed.
- The AI text remains limited to data status, holdings context, price deviation context, and program actions.

## Validation focus

- Widget coverage verifies the three AI fact labels fit inside the phone-width row.
- Existing AI and settings wording tests continue to verify non-advice language.
