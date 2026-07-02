# 00631L v11.8 AI today-first summary

## Goal

Make the AI page feel like it is interpreting today's ETF data instead of
starting with source metadata.

## Change

- The AI page now leads with the today interpretation card before source and
  disclaimer badges.
- The first-screen fact row uses DAY, LIVE, and HOLD data.
- HOLD shows the latest official holdings focus: TX weight and TSMC weight.
- Deeper source details remain inside the AI detail expansion.

## Expected behavior

- Users see the current data interpretation before technical source details.
- AI remains rule-based and non-advisory.
- No LLM API, TX live connection, or trading workflow is added.

## Verification

- Widget tests assert the today interpretation appears before source details.
- Widget tests assert the first-screen fact row uses HOLD instead of a generic
  history count.
- Existing forbidden wording scan remains part of release check.
