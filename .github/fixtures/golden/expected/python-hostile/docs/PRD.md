# Hostile "Fixture" & <Sons>, Ltd. `v0` -- PRD

> The one-page picture of the finished product. Owner-approved at bootstrap.
> Every feature's `serves:` line points here. If a feature cannot say which
> part of this page it serves, question the feature.

## What and for whom

A "goal" with 'single quotes',
an escaped newline, {{lowercase braces}}, `backticks`, & ampersands — plus a trailing backslash \ and a $dollar.

Primary user: A user who types "quotes" & <angle brackets> into every form field they meet. Problem: Systems break when text contains {{curly}} braces, `ticks`, "quotes",
or newlines; this fixture proves the renderer does not.
Today's alternative: hoping users never type quotes. Why this wins: it is the test, not the product

## The journey (end to end)

1. Feed the renderer text full of "quotes" & braces.
2. Render.
3. Every structured file still parses; every prose file carries the text verbatim.

## Surfaces

- Dash</td>{{oops}}board"
- Settings

## v1 includes

- Hostile values in every free-text answer field.
- Structured-file escaping (TOML & JSON) and prose passthrough.

## v1 excludes

- No attempt to sanitize or prettify hostile text; it must land verbatim.
- No support for text containing HTML comment markers (validated out).

## Success looks like

- structured-file parse failures -- zero
- hostile characters altered in prose -- zero
