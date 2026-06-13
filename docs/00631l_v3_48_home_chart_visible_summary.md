# 00631L v3.48 home chart visible summary

Date: 2026-06-13

## Purpose

v3.48 makes the overview chart area visible immediately on the home screen.

The home page previously placed the recent price chart and official exposure summary inside a collapsed panel. That added one extra tap before users could see the most important visual context. The overview now shows the chart and exposure block directly after the core data cards.

## Changes

- The overview price/exposure chart block is no longer rendered as an expansion tile.
- The rest of the deeper overview details remain behind expansion panels.
- Widget tests now assert that the home screen shows the recent price chart and official exposure summary without expansion.

## Scope

This is a UI information hierarchy change only. It does not change data sources, TX live status, ETF scope, notifications, automated trading, or investment guidance.
