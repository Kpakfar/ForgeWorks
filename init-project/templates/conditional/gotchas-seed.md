### [General] Patch the cause, not the symptom
**Symptom:** a failure was fixed but the same bug recurs with a different shape.
**Cause:** the fix patched the surface (special case, magic string, swallowed exception) instead of the underlying category (bad input, wrong config, dependency version, race, missing edge case).
**Fix:** identify which category the cause is in first; fix at that level.
**Date / Task:** seeded by `/init-project`.

### [General] Trust artifacts, not summaries
**Symptom:** a subagent reported success; the actual artifact (test run, metric, file change) told a different story.
**Cause:** subagent summaries describe intent, not reality.
**Fix:** open the artifact on disk, run the test yourself, or grep the file before trusting any "done" claim.
**Date / Task:** seeded by `/init-project`.

### [General] Handle external I/O at one boundary, not everywhere
**Symptom:** a single transient failure (a DNS blip, a momentary 5xx, a dropped connection) aborted a whole multi-step run.
**Cause:** the error propagated raw from deep inside the flow; nothing between the call site and the top retried or degraded it, and the framework did not absorb it either.
**Fix:** wrap each external call (network, third-party API, tool) at a single boundary that retries transient errors with backoff and then degrades gracefully (empty result + a logged warning). One dead call then costs a call, not the run; a real outage still ends loudly after the retry budget.
**Date / Task:** seeded by `/init-project`.
