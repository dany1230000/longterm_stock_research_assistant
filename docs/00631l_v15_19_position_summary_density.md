# 00631L lab v15.19 position summary density

This release tightens the phone position page after values are entered.

## Changes

- The phone position page keeps the account summary first.
- The duplicate estimate-details grid is hidden on phone width because the
  account summary already shows market value, cost, unrealized result, and
  asset weight.
- Editable inputs remain available behind the compact input panel.

## Validation

- Widget coverage verifies phone width shows the account summary before the
  input panel and does not render the duplicate estimate-details panel.
- No position calculation, storage, export, backend, or parser behavior changed.
