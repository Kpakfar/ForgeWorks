<!-- FW-BLOCK: ai-discipline v2.1.0 -->
<ai-discipline>
These rules apply because this project uses prompts, LLMs, or agentic flows.

- **Prompts as plain text files.** Store every system prompt as a `.md` (or `.txt`) file under a `prompts/` directory. Load them with short helpers. Substitute variables with plain string `.replace("{{placeholder}}", value)` (or the language's equivalent). Do NOT build template-engine-style, ORM-style, or class-based prompt builders. The loader module should be small.

- **Prompt variants are files, not classes.** If you need multiple versions of the same prompt (zero-shot, few-shot, chain-of-thought, persona A, persona B), save them as separate files and switch by filename via a config or session-state value. No strategy pattern, no registry, no factory.

- **Prompt text is runtime behavior, never a trivial edit.** Changing a system prompt, persona, or tool description changes what the product does: it goes through the normal slice path (task note, regression check, security-trigger test), not the trivial-task bypass (`<exceptional-cases>`). LLM output a downstream step depends on is "untrusted generated output" in the canonical security trigger (`<delivery-evidence>`).

- **Validate every LLM response.** Use the language's structured-output validation on every LLM response that downstream code depends on. Fail closed on schema mismatch.

- **Model cost is an engineering variable.** Pick each call's model against a measured quality check (an eval, a scored sample -- not vibes), starting from the cheapest plausible tier and escalating on evidence; record the chosen model and cost-per-call next to the probe or eval that justified it, and bound every loop or retry with a spend cap (`<token-discipline>` holds for product code too).

- **AI-shaped modules each in their own file.** If this project has an LLM client, a prompt loader, a retriever, an ingestion pipeline, tools, or a safety check, each is its own file. Same ~100 / 200 line caps as the core rule.

- **Security (LLM/agent).** This project can be prompt-injected. Never let one agent read untrusted content, hold private data, AND act on the outside world (the lethal trifecta) -- break one leg: split the agent, drop a capability, or gate the action behind a human. Treat every ingested input and every model response as untrusted: sanitize at ingest, fence untrusted text as data (never as instructions), validate each response against a schema and fail closed, and filter output before it is shown or stored. No tool may act on an attacker-chosen id; bind tools to the session owner. Full threat model and red-team checklist: `docs/SECURITY.md`.
</ai-discipline>
<!-- /FW-BLOCK: ai-discipline -->
