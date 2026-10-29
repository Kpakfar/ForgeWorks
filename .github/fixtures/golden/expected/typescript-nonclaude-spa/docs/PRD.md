# Ledgerline -- PRD

> The one-page picture of the finished product. Owner-approved at bootstrap.
> Every feature's `serves:` line points here. If a feature cannot say which
> part of this page it serves, question the feature.

## What and for whom

A web app that turns a freelancer's raw bank CSV export into a categorized income/expense ledger.

Primary user: A solo freelancer who dreads sorting a quarter's transactions before filing taxes. Problem: Bank CSV exports are flat and uncategorized; freelancers currently hand-sort hundreds of rows in a spreadsheet before every filing.
Today's alternative: hand-sorting rows in a spreadsheet. Why this wins: low-confidence rows are flagged instead of silently miscategorized

## The journey (end to end)

1. The freelancer uploads a bank CSV export.
2. The app categorizes each transaction and flags anything it cannot confidently place.
3. The freelancer confirms or recategorizes flagged rows and exports a clean ledger.

## Surfaces

- Ledger review
- CSV upload

## v1 includes

- CSV upload and rules-based categorization.
- Low-confidence flagging and manual recategorization.
- Clean CSV export of the final ledger.

## v1 excludes

- No bank API integrations in the first iteration; CSV upload only.
- No multi-currency support; single-currency ledgers only.

## Success looks like

- time to exported ledger -- under 10 minutes
- rows requiring manual recategorization -- under 10% on the reference export
