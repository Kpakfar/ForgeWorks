<!-- FW-BLOCK: project v5.0.0 -->
<project>
Chunkline -- A Rust library that splits large text files into stable, overlap-aware chunks for indexing pipelines.
Primary user: A backend developer building document indexing who needs deterministic chunk boundaries.. Stack: Rust; frontend: no; AI features: none; dev container: no.
What `ls` does not tell you:
- `docs/features.json` is the spec AND the loop's state: one entry per feature with `acceptance`, `tests`, `status`, and, while in progress, `phase` and `next`. Read one entry with `python3 scripts/feature.py <id>`; never the whole file. `docs/BACKLOG.md` is its generated view. `docs/PRD.md` is what every entry's `serves:` points at.
- `docs/plans/<id>.md` holds the decisions for the feature being built and is deleted at merge.
- `docs/gotchas.md` lists pitfalls this codebase paid for. Read it before working in the same area.
- `docs/SECURITY.md` (threat model + red-team checklist), `docs/design/` (frontend only: tokens, rubric, approved mockups), `docs/language-standards.md`, `docs/documentation.md` (Context7 is wired: verify unfamiliar APIs there, not from memory).

Code style anchor: <!-- No positive reference yet. Add one to this block when you choose one. --> 
</project>
<!-- /FW-BLOCK: project -->

<!-- FW-BLOCK: commands v5.0.0 -->
<commands>
- Quality gate (verify only): `bash scripts/qa.sh` | auto-fix: `bash scripts/fix.sh` | e2e: `bash scripts/e2e.sh`
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

<!-- FW-BLOCK: roster v5.0.0 -->
<roster>
Skills: `iteration` (the per-feature loop), `security-review` (trigger + checklist), `tech-debt` (on-demand sweep); upstream `tdd` and `grill-me` when installed. One copy per process skill: `python3 scripts/skills_doctor.py` lists collisions.
Subagents: `@reviewer` (the single REVIEW pass: plan conformance, correctness, design fidelity, security), `@utility` (mechanical chores on the cheapest tier). Dispatch rules and model tiers: the `iteration` skill's dispatch reference and `docs/agents.json`. Without subagents, run the same passes as fresh sessions.
</roster>
<!-- /FW-BLOCK: roster -->

<!-- ForgeWorks: Chunkline | Rust | bootstrapped 2026-07-12 -->
