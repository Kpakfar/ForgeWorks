# Requirements: {{PROJECT_NAME}}

## What

{{PROJECT_GOAL}}

## Why

{{CORE_PROBLEM}}

## Who

**Primary user:** {{PRIMARY_USER}}

Other potential users (deferred to later iterations):
- TODO: list other user segments mentioned during interview

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

- [ ] **REQ-AC1:** TODO
- [ ] **REQ-AC2:** TODO
- [ ] **REQ-AC3:** TODO

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
- **CI:** GitHub Actions (`.github/workflows/qa.yml`)

Language- and tool-specific conventions are in `docs/language-standards.md`.

<!-- AI-FEATURES-START -->
## AI features in scope

{{AI_FEATURES}}

Specifically:
- TODO: describe RAG approach (chunking strategy, retrieval method, generation pattern)
- TODO: describe agent loop if applicable
- TODO: describe evals if applicable
<!-- AI-FEATURES-END -->

## Security profile (threat model)

From the setup interview (Q14). Drives `docs/SECURITY.md` and the red-team tests.

- **Reads untrusted content** (web, uploads, third-party/tool results, inbound messages): TODO yes/no
- **Holds private data** (user records, secrets, anything non-public): TODO yes/no
- **Acts on the outside world** (sends, writes externally, side-effecting tools): TODO yes/no

If all three are true for a single LLM agent, the **lethal trifecta** is present. State here how the project breaks one leg (split the agent, drop a capability, or gate the action behind a human). Full threat model and defenses: `docs/SECURITY.md`.

## Out of scope (for now)

Things explicitly NOT in this iteration. Move from here to `proposals-ideas.md` if they become live ideas:

{{NON_GOALS}}

## Constraints

- Time: TODO (e.g., 2-week sprint, hackathon, side project)
- Cost: TODO (e.g., LLM API budget)
- Data: TODO (corpus size, allowed sources, licensing)

## Open questions

Track unresolved questions here. Resolve and move out as decisions get made.

- TODO

---

*Last updated: {{DATE}}*
