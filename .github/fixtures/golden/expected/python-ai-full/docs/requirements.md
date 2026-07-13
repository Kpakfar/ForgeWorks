# Requirements: Recipe Radar

Positioning, business goals, and the 5W live in `docs/PRODUCT_VISION.md` (the
north star); this file owns the current iteration: criteria, stack, constraints.

## What

Turn a photo of a fridge into three cookable dinner suggestions for busy home cooks.

## Why

Recipe sites answer 'what can I cook in general', not 'what can I cook right now with what I have'; the gap between inventory and inspiration stays manual.

## Who

**Primary user:** A busy home cook who stares at a full fridge with no dinner idea.

Other potential users (deferred to later iterations):
- Meal-prep enthusiasts planning several dinners at once (deferred).
- Dietitians reviewing a client's typical inventory (deferred).

## Core user flow (MVP) -- the heart of the project

The single flow this project must support well in the first iteration:

1. The cook photographs the open fridge.
2. The app extracts an ingredient list and shows it for one-tap correction.
3. The app retrieves three matching recipes and adapts each to the confirmed inventory.
4. The cook picks one and gets a step-by-step cooking view.

**Success looks like:** A first-time user goes from photo to a chosen, cookable recipe in under two minutes without editing more than two ingredients.

**Riskiest assumption** (test this first): Vision-model ingredient extraction is accurate enough on real, messy fridge photos to need at most two corrections.

## Acceptance criteria (MVP)

Derived from the core flow above. Numbered and observable -- these are the
**iteration-level** contract (REQ-AC1, REQ-AC2, ...). A slice's
`docs/current-task/task.md` has its own slice-scoped `AC1..n` that each cite the
`REQ-AC` they advance, and a test proves each. (Distinct numbering avoids confusing
iteration criteria with a slice's.)

- [ ] **REQ-AC1:** Uploading a clear fridge photo yields an editable ingredient list within 15 seconds.
- [ ] **REQ-AC2:** Confirming the list yields exactly three recipe suggestions, each cookable with the confirmed ingredients plus pantry staples.
- [ ] **REQ-AC3:** Choosing a suggestion opens a step-by-step cooking view with servings scaled to the household size.
- [ ] **REQ-AC4:** A photo with no recognizable food produces a helpful empty state, not a crash or a hallucinated list.

## Stack

- **Language:** Python 3.12+
- **Package manager:** uv
- **Quality-gate command:** uv run qa
- **Test runner:** pytest
- **Lint / format / type-check tools:** ruff / ruff format / mypy
- **Frontend:** yes-minimal
- **Backend framework:** FastAPI
- **Database / persistence:** SQLite
- **Vector store:** Chroma
- **LLM provider:** OpenAI
- **Embeddings model:** text-embedding-3-small
- **Dev container:** yes
- **Deployment target:** Public web app (mobile-first), hosted on a single VPS first.
- **Scale expectations (first iteration):** Tens of users, low hundreds of photos per week in the first iteration; p95 photo-to-suggestions under 15 seconds.
- **External systems / integrations (each requires a reality probe -- see `docs/probes/`):**
- OpenAI vision + embeddings API (extraction, retrieval).
- Chroma vector store (local, embedded).
- **CI:** GitHub Actions (`.github/workflows/qa.yml`)

Language- and tool-specific conventions are in `docs/language-standards.md`.

## AI features in scope

rag, agents, evals, streaming

Describe the approach per feature as it is designed -- each AI feature's design
lands in its slice's design memo (`docs/designs/`), and this section links them.

## Security profile (threat model)

From the setup interview (B8). Drives `docs/SECURITY.md` and the red-team tests.

- **Reads untrusted content** (web, uploads, third-party/tool results, inbound messages): yes
- **Holds private data** (user records, secrets, anything non-public): yes
- **Acts on the outside world** (sends, writes externally, side-effecting tools): yes

If all three are true for a single LLM agent, the **lethal trifecta** is present. State here how the project breaks one leg (split the agent, drop a capability, or gate the action behind a human). Full threat model and defenses: `docs/SECURITY.md`.

**Lethal trifecta: PRESENT.** All three answers above are yes for a single LLM agent. Break one leg -- split the agent, drop a capability, or gate the action behind a human -- and record the break here and in `docs/SECURITY.md`.

## Out of scope (for now)

Things explicitly NOT in this iteration. Move from here to `proposals-ideas.md` if they become live ideas:

- No meal planning across multiple days; one dinner at a time.
- No grocery ordering or shopping-list integration in the first iteration.
- No user accounts beyond a device-local profile.

## Constraints

- Time: 8-week side project; first demo at week 4.
- Cost: LLM/API budget capped at USD 30/month during development; each photo-to-recipes flow must cost under USD 0.05.
- Data: Recipes from a licensed open dataset (Recipe1M subset); user photos never leave the pipeline and are deleted after extraction.

## Open questions

Track unresolved questions here. Resolve and move out as decisions get made.

- none yet -- add them as they appear; resolve and move out as decisions get made

---

*Last updated: 2026-07-12*
