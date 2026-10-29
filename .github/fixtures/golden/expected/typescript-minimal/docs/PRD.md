# Linkcheck -- PRD

> The one-page picture of the finished product. Owner-approved at bootstrap.
> Every feature's `serves:` line points here. If a feature cannot say which
> part of this page it serves, question the feature.

## What and for whom

A CLI that finds dead links in a Markdown docs folder before they ship.

Primary user: A docs maintainer who keeps finding broken links after release. Problem: Dead links are only discovered by readers; existing checkers are heavyweight CI services when a fast local CLI would do.
Today's alternative: clicking links by hand or a heavyweight CI service. Why this wins: one fast local command, no service to configure

## The journey (end to end)

1. The maintainer runs the CLI against a docs folder.
2. The CLI scans every Markdown file and collects links.
3. It reports dead links with file and line, exiting non-zero when any are found.

## Surfaces

- (no user-facing surfaces -- API/CLI product)

## v1 includes

- Markdown link extraction across a folder tree.
- Concurrent liveness checks with one retry.
- file:line reporting and a non-zero exit on failures.

## v1 excludes

- No HTML or PDF scanning; Markdown only.
- No CI service or hosted dashboard; local CLI only.

## Success looks like

- scan time on 200 files -- under 30 seconds
- false positives per run -- zero on the reference docs tree
