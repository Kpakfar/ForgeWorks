# Security: threat model and defenses for {{PROJECT_NAME}}

This is a living document. It states what an attacker would try, the defenses in
place, and the red-team checklist the test suite must cover. Update it whenever a
slice matches the canonical security trigger (quoted from `AGENTS.md`
`<delivery-evidence>`): *external input handling, dependence on untrusted
generated output, public publishing of content, authentication or authorization,
a tool or automation with side effects, or persistence of untrusted content* --
or record `Security doc delta: none, because ...` in the slice's design memo.
The rules themselves live in `AGENTS.md` `<security-discipline>`; this file is
where they become concrete for this project.

Fill in the `TODO` and `*<...>*` slots as the project takes shape. An empty
threat model is a red flag in review.

## Attack surface

List every place untrusted data enters the system, and every consequential action
it can reach. Review each row "through the lens of an attacker."

| External input | Where it enters | What it can reach |
|---|---|---|
| *<e.g. request body / params>* | TODO | TODO |
| *<e.g. uploaded file>* | TODO | TODO |
| *<e.g. third-party API / tool result>* | TODO | TODO |

## Universal risks and defenses

These apply to every project regardless of stack or subject.

1. **Broken access control (IDOR)** -- the most common real vulnerability. One user
   reaches another's data by supplying or incrementing an id. **Defense:** never
   trust a user-supplied identity; derive the acting user from a verified session
   or signed token (verify the signature, don't just decode it), enforced in one
   middleware layer. Scope every query and file path to that owner. Validate and
   sandbox any path or id from input so `../` cannot escape. *Where enforced:* TODO.
2. **Secrets exposure** -- keys in source, logs, prompts, or committed config.
   **Defense:** secrets live only in env or a secret store; the ignore file
   excludes them; an example env file documents the variables with empty values.
   *Where enforced:* TODO.
3. **Supply-chain / slopsquatting** -- a compromised or hallucinated dependency runs
   code on dev/CI machines. **Defense:** install from the lockfile only (no blind
   updates); vet every new package (real, established, right author, not a
   lookalike); prefer dependencies more than ~a week old. Enforced by the
   `deps-guard` hook, not by trust.
4. **Unbounded input** -- a huge payload buries an injection or runs up cost.
   **Defense:** length-bound every input that enters a prompt, a log, or storage.
5. **Blast radius** -- assume something will be compromised; limit what it reaches.
   **Defense:** least privilege per session; isolate production; do not give broad
   direct production access. Fail closed on any security-check error.

<!-- AI-SECURITY-START -->
## LLM / agent risks and defenses

These apply because this project uses prompts, LLMs, or agentic flows. If that ever
stops being true, delete this section.

- **The lethal trifecta.** An agent is prompt-injectable when ONE agent holds all
  three of: reads untrusted content, touches private data, can act on the outside
  world. **Defense:** remove one leg, or split the agent so no single one holds all
  three. A human-approval gate before any outbound/consequential action removes the
  "acts" leg cheaply. *How this project breaks the trifecta:* TODO.
- **Prompt injection (indirect).** Untrusted content the model ingests (web/tool/MCP
  results, documents, messages) smuggles instructions. It does not have to work every
  time to be dangerous. **Layered defense** (each layer independent):
  1. Sanitize at ingest -- clean untrusted fields at the boundary, strip injection
     imperatives, length-bound.
  2. Fence untrusted text -- wrap it as data (e.g. `<untrusted>...</untrusted>`);
     neutralize any copy of the delimiter; prompts declare fenced content as data,
     never instructions.
  3. Fail-closed input judge -- classify risky input with a separate model before the
     main agent runs; block on error or ambiguity.
  4. Output filter -- before persisting/displaying, scan for leaked prompt internals.
  5. Typed structured outputs -- every model response validates against a schema;
     free-form bypass fails to parse.
- **Tool design.** No tool that acts on an attacker-chosen id; bind every tool to the
  session's owner. Prefer read-only tools; gate consequential actions behind a human.
- **Account-recovery / high-consequence flows** are socially engineerable -- add MFA
  and a human in the loop.
<!-- AI-SECURITY-END -->

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
<!-- AI-REDTEAM-START -->
- [ ] **Prompt injection per source.** For EACH external data source (prioritize
      tool/MCP results over direct chat), inject context-specific instructions
      (impersonation + urgency, not "give me the secrets"); confirm no leak or
      unintended action.
- [ ] **Trifecta containment.** Confirm no single agent reads untrusted content,
      holds private data, and acts outward without a human gate.
<!-- AI-REDTEAM-END -->

## Enforcement

- **Hook:** `.claude/hooks/deps-guard.sh` (PreToolUse) gates dependency installs.
- **Tests:** the red-team checklist above lives in the test suite and runs in CI.
- **Hook:** `.claude/hooks/slice-audit.sh` (PreToolUse) blocks ship commits whose
  record lacks a `Security surface:` disposition; the CI ship-audit job re-checks.
- **Reviews:** `@security-reviewer` is MANDATORY for every slice matching the
  canonical security trigger above, and runs at least once per iteration
  (`AGENTS.md` `<recurring-reviews>`).
