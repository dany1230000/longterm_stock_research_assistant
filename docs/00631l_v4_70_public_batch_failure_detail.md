# 00631L v4.70 Public Batch Failure Detail

v4.70 improves public ETF catalog batch diagnostics.

## What Changed

- Top-level `failures` now include child batch failure details such as HTTP 502
  or timeout messages.
- Resume state behavior is unchanged.
- `--soft-fail` still exits without crashing, but the payload is more useful for
  deciding the next maintenance command.

## Example

If a batch at offset 25 receives HTTP 502, top-level failures now include the
offset and the HTTP reason instead of only the offset.

## Validation

- Unit tests cover child failure details in top-level payloads.
- Release check still treats public backend/transient local warnings as WARN
  when `failures=[]`.
