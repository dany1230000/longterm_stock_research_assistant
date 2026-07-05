# 00631L v16.38 overview cash label

This release localizes the phone overview first-glance cash label.

## What changed

- The phone overview `AI / TX / 2330 / CASH` strip now reads
  `AI / TX / 2330 / 現金`.
- Widget tests assert that `CASH` no longer appears in the phone overview
  first-glance strip.

## Why

The first screen should read like a finished ETF app. TX and 2330 are actual
market identifiers, while `CASH` was an internal-style English label for a
Chinese data category.
