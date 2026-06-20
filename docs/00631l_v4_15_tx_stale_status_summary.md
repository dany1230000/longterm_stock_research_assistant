# 00631L v4.15 TX stale status summary

Date: 2026-06-20

## Scope

This patch makes TAIFEX TX quote status clearer during weekends, holidays, and other non-session periods.

## Changes

- Backend TX quote normalization returns `sourceStatus: stale` when a quote has a valid price but the TAIFEX `dataTime` is older than the freshness threshold.
- Frontend proxy mapping treats `isStale: true` TX quote payloads as `EtfDataStatus.stale`, even if an older backend still sends `sourceStatus: official`.
- Cached TX quote fallback also displays stale when the cached quote itself is stale.

## Why

During closed-market periods, TAIFEX can still return the last available TX quote. The app should show that as stale/last data instead of making it look like a current live update.

## Validation

- Backend tests cover stale TAIFEX quote normalization.
- Frontend repository tests cover stale TX quote mapping.

## Boundaries

This patch only changes data-status handling. It does not add investment guidance, broker integration, notifications, or broader product scope.
