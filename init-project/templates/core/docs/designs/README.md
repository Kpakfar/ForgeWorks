# Design memos

One memo per non-trivial slice, at `docs/designs/<slice>.md`. This is the hard gate
from `AGENTS.md` `<investigation-discipline>`: no feature code -- not even Red-phase
tests -- until the user has approved the slice's memo. Commit the approved memo
BEFORE the Red suite so the gate order is provable from history.

## Format

One page is the target; when the required headings below and the page target
conflict, completeness wins. Every heading is required (the memo floor from
`<planning-discipline>`) -- a lean or no-pause directive may compress the answers,
never remove a heading.

```
# <slice-id> <title>
Approved: <date, written by the user or with their explicit OK -- absent means NOT approved>

## Problem
One paragraph. What user-visible step this slice delivers (the core journey).

## Options
2-3 candidate approaches, one line of trade-off each. Say which one and why.

## Riskiest assumption
The one thing that sinks the slice if wrong -- and the probe/spike result that
de-risks it (link the `docs/probes/` file or the experiments/ folder).

## Unhappy paths
Error states, empty/edge inputs, and failure modes this slice must survive.
For a security-triggering slice, add the attacker story: who sends what,
through which surface, to get what.

## Non-goals
What this slice deliberately does not do (pushed to proposals/backlog).

## Security surface
none | the matching canonical-trigger clause (see <delivery-evidence>) --
plus the threat-model disposition: the docs/SECURITY.md delta, or
"Security doc delta: none, because ...".

## Autonomy
attended | the autonomy envelope from <loop-discipline>: goal condition + proof
command, allowed scope and side-effect authority, protected verifier paths,
isolation (branch/worktree), stop caps + no-progress rule, escalation.

## Test plan
Unit / functional / e2e / security tests by name, each tagged with the AC it
proves. If the suite is fake-only, name the live smoke check that pairs with it.
```

Keep memos after shipping -- they are the project's decision record. The ship record
at `docs/ships/<slice>.md` links back here.
