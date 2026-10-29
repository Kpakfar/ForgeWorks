# Security: threat model and defenses for Hostile "Fixture" & <Sons>, Ltd. `v0`

This is a living document. It states what an attacker would try, the defenses in
place, and the red-team checklist the test suite must cover. Update it whenever a
feature matches the security trigger: see `.claude/skills/security-review/SKILL.md`.
When no delta is needed, record why in the feature's `notes` instead. The hard rule requiring this review lives in `AGENTS.md`
`<hard-rules>`; this file is where the threat model becomes concrete for this
project.

Fill in the `TODO` and `*<...>*` slots as the project takes shape. An empty
threat model is a red flag in review.

**The sections below are the whole file.** A security-triggered feature edits
them in place -- a new row in the attack-surface table, a tightened checklist
line, one accepted-risk line -- and never appends a section of its own. Its
full threat model lives in that feature's plan file and dies with it. A
`SECURITY.md` with a subsection per feature is a changelog, not a threat model:
nobody reads it, and the current posture becomes impossible to see. Its budget
is enforced by the `docs-budget` CI job; at the cap, delete what is no longer
true rather than moving it aside.

## Attack surface

List every place untrusted data enters the system, and every consequential action
it can reach. Review each row "through the lens of an attacker."

Security profile (chosen during setup): reads untrusted content: **yes**; holds private data: **yes**; acts on the outside world: **no**.

| External input | Where it enters | What it can reach |
|---|---|---|
| *<e.g. request body / params>* | TODO | TODO |
| *<e.g. uploaded file>* | TODO | TODO |
| *<e.g. third-party API / tool result>* | TODO | TODO |

## Universal risks and defenses

One line per risk; the value is in the *where enforced* slot, not the lecture.

1. **Broken access control (IDOR).** Derive the acting user from a verified session or signed token (verify, not decode) in one middleware layer; scope every query and path to that owner; sandbox any path or id from input. *Where enforced:* TODO.
2. **Secrets exposure.** Secrets live only in env or a secret store; the ignore file excludes them; `.env.example` documents the variables with empty values. *Where enforced:* TODO.
3. **Supply chain / slopsquatting.** Install from the lockfile only; vet every new package (real, established, right author, not brand new). Enforced by committed lockfiles, reviewed updates (`.github/dependabot.yml`), the CI `audit` job, and the `deps-guard` hook where Claude Code drives.
4. **Unbounded input.** Length-bound every input that enters a prompt, a log, or storage. *Where enforced:* TODO.
5. **Blast radius.** Least privilege per session; isolate production; fail closed on any security-check error. *Where enforced:* TODO.

## Red-team checklist

The security tests in the suite must cover these. A passing test is not proof of
safety -- it only has to fail once. Walk the OWASP Top 10 (web) and, if LLMs are
used, the OWASP Top 10 for LLM apps, time-boxing each category.

- [ ] **Access control / IDOR.** For every endpoint, forge and increment ids; confirm
      you cannot read or act on another owner's data. Confirm tokens are signature-
      verified, not just decoded.
- [ ] **Path traversal.** Feed `../` and absolute paths to any id or path from input;
      confirm it stays inside the sandbox.
- [ ] **Input bounds.** Send oversized payloads; confirm they are rejected before the
      handler runs.
- [ ] **Strict format validation.** For any value parsed into a type (dates, ids, numbers),
      feed unexpected-but-accepted encodings (e.g. compact/locale/ISO-week dates, leading
      zeros, unicode digits); confirm only the exact intended format is accepted and the
      rest are rejected, so none slips past a downstream gate.
- [ ] **Secrets.** Grep the repo and logs; confirm no keys are committed or logged.
- [ ] **Supply chain.** Confirm the lockfile is committed and installs use it; scan
      for hallucinated/unvetted packages.

## Enforcement

- **Hook:** `.claude/hooks/deps-guard.sh` (PreToolUse) gates dependency installs.
- **Tests:** the red-team checklist above lives in the test suite and runs in CI.
- **Reviews:** an independent security red-team pass is MANDATORY for work
  matching the trigger in `.claude/skills/security-review/SKILL.md` (via
  the reviewer's security lens when Claude Code drives; as a manual
  fresh-context pass otherwise), per `AGENTS.md` `<hard-rules>`.
