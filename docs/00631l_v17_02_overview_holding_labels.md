# 00631L v17.02 overview holding labels

v17.02 makes the phone overview holdings strip read like a user-facing app
instead of a data table.

## Changes

- The first-screen holdings strip now shows `台指期` instead of `TX`.
- The first-screen holdings strip now shows `台積電` instead of `2330`.
- The compact data ribbon still avoids code-like labels so source/status
  information stays separate from holdings information.

## Scope

This release only changes user-facing labels and widget assertions. It does not
change official holdings parsing, futures matching, stock holding lookup, or
exposure calculations.
