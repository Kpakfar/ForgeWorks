# Requirements: {{PROJECT_NAME}}

Positioning, business goals, and the 5W live in `docs/PRODUCT_VISION.md` (the
north star); this file owns the current iteration: criteria, stack, constraints.

## What

{{PROJECT_GOAL}}

## Why

{{CORE_PROBLEM}}

## Who

**Primary user:** {{PRIMARY_USER}}

Other potential users (deferred to later iterations):
{{OTHER_USERS}}

## Core user flow (MVP) -- the heart of the project

The single flow this project must support well in the first iteration:

{{CORE_JOURNEY}}

**Success looks like:** {{SUCCESS_MEASURE}}

**Riskiest assumption** (test this first): {{RISKIEST_ASSUMPTION}}

## Acceptance criteria (MVP)

Derived from the core flow above. Numbered and observable -- these are the
**iteration-level** contract (REQ-AC1, REQ-AC2, ...). A slice's
`docs/current-task/task.md` has its own slice-scoped `AC1..n` that each cite the
`REQ-AC` they advance, and a test proves each. (Distinct numbering avoids confusing
iteration criteria with a slice's.)

{{REQ_AC_LIST}}

## Stack

- **Language:** {{LANGUAGE}} {{LANGUAGE_VERSION}}
- **Package manager:** {{PACKAGE_MANAGER}}
- **Quality-gate command:** {{QA_COMMAND}}
- **Test runner:** {{TEST_RUNNER}}
- **Lint / format / type-check tools:** {{LINT_TOOL}} / {{FORMAT_TOOL}} / {{TYPE_TOOL}}
- **Frontend:** {{HAS_FRONTEND}}
- **Backend framework:** {{BACKEND_FRAMEWORK}}
- **Database / persistence:** {{DATABASE}}
- **Vector store:** {{VECTOR_DB}}
- **LLM provider:** {{LLM_PROVIDER}}
- **Embeddings model:** {{EMBEDDINGS_MODEL}}
- **Dev container:** {{USES_DEVCONTAINER}}
- **Deployment target:** {{DEPLOYMENT_TARGET}}
- **Scale expectations (first iteration):** {{SCALE_EXPECTATIONS}}
- **External systems / integrations (each requires a reality probe -- see `docs/probes/`):**
{{INTEGRATIONS}}
- **CI:** GitHub Actions (`.github/workflows/qa.yml`)

Language- and tool-specific conventions are in `docs/language-standards.md`.

<!-- AI-FEATURES-START -->
## AI features in scope

{{AI_FEATURES}}

Describe the approach per feature as it is designed -- each AI feature's design
lands in its slice's design memo (`docs/designs/`), and this section links them.
<!-- AI-FEATURES-END -->

## Security profile (threat model)

From the setup interview (Q14). Drives `docs/SECURITY.md` and the red-team tests.

- **Reads untrusted content** (web, uploads, third-party/tool results, inbound messages): {{READS_UNTRUSTED}}
- **Holds private data** (user records, secrets, anything non-public): {{HOLDS_PRIVATE_DATA}}
- **Acts on the outside world** (sends, writes externally, side-effecting tools): {{ACTS_OUTWARD}}

If all three are true for a single LLM agent, the **lethal trifecta** is present. State here how the project breaks one leg (split the agent, drop a capability, or gate the action behind a human). Full threat model and defenses: `docs/SECURITY.md`.

## Out of scope (for now)

Things explicitly NOT in this iteration. Move from here to `proposals-ideas.md` if they become live ideas:

{{NON_GOALS}}

## Constraints

- Time: {{CONSTRAINT_TIME}}
- Cost: {{CONSTRAINT_COST}}
- Data: {{CONSTRAINT_DATA}}

## Open questions

Track unresolved questions here. Resolve and move out as decisions get made.

- none yet -- add them as they appear; resolve and move out as decisions get made

---

*Last updated: {{DATE}}*
