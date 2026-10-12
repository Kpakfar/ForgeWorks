# Plans -- one per FEATURE, alive only while it is being built

One file per feature (`<feature-id>.md`): decisions, approach, and -- when the
security trigger matches -- the threat model. The `iteration` skill's GRILL
step writes it; the owner approves it once, live. Chores have no plan.

**A plan is deleted at MERGE** by `scripts/prune.py`. It is working state for
one feature, not a record. Everything durable it produced has a home already:

| In the plan | Durable home |
|---|---|
| Acceptance criteria and tests | the entry's `acceptance` and `tests` arrays in `docs/features.json` |
| Threat model | new rows / edited checklist lines in `docs/SECURITY.md` |
| The approved mockup | `docs/design/mockups/<id>-<name>.html`, named in the entry's `mockup` |
| A decision that binds later work | the entry's `decisions` |
| Deviations and owed work | the entry's `notes` |
| What shipped, and the evidence | the merge commit |
| A surprise reality handed you | `docs/gotchas.md` |

If something in the plan is not in one of those and still changes a future
decision, put it there first, then let the prune delete the plan. The full
text stays in git history.
