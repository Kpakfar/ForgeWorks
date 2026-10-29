# Feedgate -- PRD

> The one-page picture of the finished product. Owner-approved at bootstrap.
> Every feature's `serves:` line points here. If a feature cannot say which
> part of this page it serves, question the feature.

## What and for whom

An internal HTTP service that validates and normalizes partner RSS feeds before ingestion.

Primary user: A data engineer who babysits broken partner feeds every Monday. Problem: Partner feeds break silently (bad encodings, missing fields, wrong dates) and corrupt the downstream pipeline; validation happens too late, after ingestion.
Today's alternative: letting feeds into the pipeline and cleaning up after incidents. Why this wins: validates and quarantines at the front door instead of repairing downstream

## The journey (end to end)

1. A partner feed URL is registered with the service.
2. The service fetches the feed, validates it against a strict schema, and normalizes encodings and dates.
3. Clean feeds pass through to the pipeline; broken ones are quarantined with a precise error report.

## Surfaces

- (no user-facing surfaces -- API/CLI product)

## v1 includes

- Feed registration, fetching, and strict-schema validation.
- Encoding and date normalization.
- Quarantine with actionable error reports and a status endpoint.

## v1 excludes

- No feed content transformation beyond encoding/date normalization.
- No partner-facing UI; engineers query the status endpoint.

## Success looks like

- pipeline incidents caused by bad feeds -- zero after rollout
- validation latency per feed -- p95 under 500ms
