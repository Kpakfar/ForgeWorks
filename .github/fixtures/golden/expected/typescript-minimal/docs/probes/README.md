# Reality probes

One file per observed external collaborator, at `docs/probes/<slice>-<name>.md`.
Required by `AGENTS.md` `<investigation-discipline>`: before building on any
library, API, service, protocol, or data source, observe it for real -- one real
call, real dispatch, or real run -- and record what actually came back.

## Format

```
# <slice-id> probe: <collaborator>
Date: <date>
How observed: <the exact command / call / script used>

## Request (as sent)
<verbatim>

## Response (as observed)
<verbatim, trimmed to the relevant shape>

## Verdict
What this confirms or kills. Red flags, if any, each with a mitigation or an
explicit user acceptance.
```

Fixtures and fakes are authored FROM these files -- never from docs, README
claims, a sibling endpoint, or memory.
