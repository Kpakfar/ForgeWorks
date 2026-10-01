<!-- FW-BLOCK: project v5.0.0 -->
<project>
Briefly -- A web app that turns a team's weekly activity into a two-paragraph stakeholder brief.
Primary user: An engineering manager who writes the same status update every Friday.. Stack: TypeScript; frontend: yes-spa; AI features: agents, evals; dev container: no.
What `ls` does not tell you:
- `docs/features.json` is the spec AND the loop's state: one entry per feature with `acceptance`, `tests`, `status`, and, while in progress, `phase` and `next`. Read one entry with `python3 scripts/feature.py <id>`; never the whole file. `docs/BACKLOG.md` is its generated view. `docs/PRD.md` is what every entry's `serves:` points at.
- `docs/plans/<id>.md` holds the decisions for the feature being built and is deleted at merge.
- `docs/gotchas.md` lists pitfalls this codebase paid for. Read it before working in the same area.
- `docs/SECURITY.md` (threat model + red-team checklist), `docs/design/` (frontend only: tokens, rubric, approved mockups), `docs/language-standards.md`, `docs/documentation.md` (Context7 is wired: verify unfamiliar APIs there, not from memory).
- `docs/memory.md` -- memory scopes (User, Session, Agent), what is stored, what is not.

Code style anchor: Pattern-match every file you write or modify to the clean SPA structure of excalidraw/excalidraw. Reference material: https://github.com/excalidraw/excalidraw. 
</project>
<!-- /FW-BLOCK: project -->

<!-- FW-BLOCK: commands v5.0.0 -->
<commands>
- Quality gate (verify only): `npm run qa` | auto-fix: `npm run fix` | e2e: `npm run e2e`
- One feature entry: `python3 scripts/feature.py <id>` (add `key=value` to update it) | resume brief (`go`): `python3 scripts/resume.py` | feature list check: `python3 scripts/features_check.py` | duplication gate: `python3 scripts/dup_check.py` | merge cleanup: `python3 scripts/prune.py` | doctor (stale worktrees, merged branches, skill collisions): `bash scripts/factory_doctor.sh`
- New dependencies go through the manifest and the deps-guard hook (`DEPS_VETTED=1` once vetted); details in `docs/language-standards.md`.
</commands>
<!-- /FW-BLOCK: commands -->

<!-- FW-BLOCK: etiquette v5.1.0 -->
<etiquette>
Conventional Commits. One branch per feature; CI green before merge. One writer per branch, one session per working tree. When the tree-claim hook blocks a write, do not ask and do not write elsewhere: move into your own worktree (`EnterWorktree`), continue there, and land with `bash scripts/land.sh`. Work inside this repo only unless asked.
</etiquette>
<!-- /FW-BLOCK: etiquette -->

<!-- FW-BLOCK: hard-rules v5.0.0 -->
<hard-rules>
Few and absolute:
- Never weaken, skip, or delete a failing test to make a gate pass. A change to an existing test, fixture, or gate config states its reason in a `test-change:` line of the commit body; the tamper guard checks.
- Never commit secrets. Env or a secret store only.
- Never set a feature `done` unless its cited tests exist and pass. Never delete an entry: `status: dropped` with the reason in `notes`.
- Work matching the `security-review` skill's trigger merges only after its security lens ran.
- No state change without evidence: test output, the command run, or a screenshot path.
</hard-rules>
<!-- /FW-BLOCK: hard-rules -->

<!-- FW-BLOCK: tiers v5.0.0 -->
<tiers>
- **Chore** (the diff fits in one sentence, no behavior change): build, gate green, commit.
- **Feature** (any new or changed behavior): the `iteration` skill, GRILL -> RED -> GREEN -> REVIEW -> MERGE. Unsure? It is a feature.
The owner approves once, at GRILL. A cap hit stops and asks. Everything else proceeds with the conservative choice, noted in the feature's `notes`.
</tiers>
<!-- /FW-BLOCK: tiers -->

<!-- FW-BLOCK: communication v5.0.0 -->
<communication>
Write to `docs/writing.md`: short sentences, active voice, no hedging in instructions. Lead with the point. Do not repeat what the owner knows or what a gate already printed. Three fixed shapes. GRILL: what I will build / decisions I need (numbered) / top risks with my answer. Cap hit: one paragraph (state, rounds used, what is stuck, recommendation). Merge report: three lines (shipped, evidence, next up). Ask the fewest questions that unblock the work, batch independent ones, and offer choices when they exist.
</communication>
<!-- /FW-BLOCK: communication -->

<!-- FW-BLOCK: context v5.0.0 -->
<context>
This file is the only always-loaded doc. Everything else is read on demand, by section. `go` in a fresh session means: run `python3 scripts/resume.py`, then read the one feature entry and plan it names, plus the `iteration` skill. That is the whole memory between sessions. Harness memory holds preferences and paid-for gotchas, never session state. The `docs-budget` and `checkpoint-budget` CI jobs own every cap number; `scripts/prune.py` deletes what closed features leave behind. At a cap, delete whole stale entries; never rewrite one. Subagent briefs name exact files and sections, never "read the docs".
</context>
<!-- /FW-BLOCK: context -->

<!-- FW-BLOCK: learning v5.0.0 -->
<learning>
Reality surprised you (API differs from docs, gate green but feature dead)? One four-line entry in `docs/gotchas.md`. Delete any entry the code has since made impossible. Working notes die once their finding lands in a gotcha, a fixture, or a test.
</learning>
<!-- /FW-BLOCK: learning -->

<!-- FW-BLOCK: memory v3.0.0 -->
<memory>
This project wires **mem0** for persistent memory across sessions, scoped to user (facts about the human), session (the current interaction), and agent (facts the agent itself confirmed) -- schema and stored fields live in `docs/memory.md`.
Read relevant memories at session start; write one only when the fact is durable and its scope is unambiguous (if you cannot say which scope, do not store it), and update `docs/memory.md` in the same change. Verify the API against Context7 for the pinned `mem0ai` version before writing memory code.
</memory>
<!-- /FW-BLOCK: memory -->

<!-- FW-BLOCK: roster v5.0.0 -->
<roster>
Skills: `iteration` (the per-feature loop), `security-review` (trigger + checklist), `tech-debt` (on-demand sweep); upstream `tdd` and `grill-me` when installed. One copy per process skill: `python3 scripts/skills_doctor.py` lists collisions.
Subagents: `@reviewer` (the single REVIEW pass: plan conformance, correctness, design fidelity, security), `@utility` (mechanical chores on the cheapest tier). Dispatch rules and model tiers: the `iteration` skill's dispatch reference and `docs/agents.json`. Without subagents, run the same passes as fresh sessions.
</roster>
<!-- /FW-BLOCK: roster -->
<!-- FW-BLOCK: ai-discipline v3.0.0 -->
<ai-discipline>
This project uses prompts, LLMs, or agentic flows.

- Prompts live as plain text files under `prompts/`; variants are separate files selected by name. Prompt or persona text is runtime behavior -- change it through the normal tier path (it usually matches the security trigger), not as a doc edit.
- Schema-validate every LLM response downstream code depends on; fail closed on mismatch. Treat model output and ingested content as untrusted; an agent that reads untrusted input and holds private data doesn't also act outward -- break one leg or gate the action behind a human (see `docs/SECURITY.md`).
- In tests, key LLM fakes off rendered state, not call ordinal. Bound every model loop or retry with a spend cap.
</ai-discipline>
<!-- /FW-BLOCK: ai-discipline -->
<!-- ForgeWorks: Briefly | TypeScript | bootstrapped 2026-07-12 -->
