# Design memos

One memo per non-trivial slice, at `docs/designs/<slice>.md`. This is the hard gate
from `AGENTS.md` `<investigation-discipline>`: no feature code -- not even Red-phase
tests -- until the user has approved the slice's memo.

## Format (one page or less)

```
# <slice-id> <title>
Approved: <date, written by the user or with their explicit OK -- absent means NOT approved>

## Problem
One paragraph. What user-visible step this slice delivers.

## Options
2-3 candidate approaches, one line of trade-off each. Say which one and why.

## Riskiest assumption
The one thing that sinks the slice if wrong -- and the probe/spike result that
de-risks it (link the `docs/probes/` file or the experiments/ folder).

## Test plan
Unit / functional / e2e / security tests by name. If the suite is fake-only,
name the live smoke check that pairs with it.
```

Keep memos after shipping -- they are the project's decision record.
