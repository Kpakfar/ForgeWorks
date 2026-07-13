# Ship records

One record per shipped non-trivial slice, at `docs/ships/<slice>.md`, committed in the
shipping commit BEFORE the backlog row moves to Shipped. This is the durable delivery
evidence from `AGENTS.md` `<delivery-evidence>`: `docs/current-task/task.md` gets reset,
commit messages get squashed -- this file is what a later audit reads.

The `slice-audit.sh` hook blocks a ship commit without a valid record; CI re-validates
changed records. Field names below are literal -- the validators grep for them.

## Format

```
# Ship record: <slice-id> <title>

- Task class: standard | trivial-exception | spike
- Memo: docs/designs/<slice>.md (Approved: <date>)
- Red proof: <commit hash or logged run -- the failing suite, failing for missing-implementation reasons>
- Green proof: <the gate run that passed, e.g. commit + "qa green, N passed">
- TDD audit: strong | weak -- <if weak: tests and code were authored together; Red proven retroactively -- give the reason>
- Evidence origin: native | imported -- <if imported: the parked branch / prior-session reference>
- Reviewers: code-reviewer <verdict>; security-reviewer <verdict | not-triggered>
- Security surface: none | <matching canonical-trigger clause> -- <SECURITY.md delta, or "none, because ...">
- Review rounds: <N>; fix rounds: <M>
- Live smoke: <link to output | n/a>
```

## Field notes

- **Reviewers.** `security-reviewer: not-triggered` is valid ONLY when the slice matches
  no clause of the canonical security trigger (quoted in `<delivery-evidence>`). A
  "security focus" folded into the code-reviewer brief does not count as a
  security-reviewer run.
- **Evidence origin: native** means the memo commit, the Red commit, and the Green
  commit landed separately and in order in this branch's history -- CI proves the
  chain (memo strictly before Red, Red strictly before Green, both ancestors of
  HEAD), so for native records `Red proof:` AND `Green proof:` must each contain a
  commit hash. **imported** means the memo approval or Red suite came from a parked
  branch or an earlier session; give the reference and let the reviewer judge
  provenance.
- **TDD audit: weak** is an exception flag, not a synonym for "we wrote tests". Two
  weak slices in a row are a process smell -- raise it with the user.
