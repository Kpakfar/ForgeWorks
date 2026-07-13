# Explanations

One plain-English memo per shipped slice. Lives at `docs/explanations/NN-<slug>.md` where `NN` is a zero-padded sequence number.

The goal: anyone reading these in order can understand what was built, why, and how -- without reading the code first.

## When to write one

When a slice ships (vertical slice merges or commits as done). Not mid-slice. Not for trivial fixes.

## Required sections

1. **What this slice does** -- one paragraph, no jargon.
2. **Walk-through** -- the new code in dependency order, with file paths and line ranges.
3. **New terms** -- every concept the reader has not seen before, with a one-paragraph definition. Link to a primary source where helpful.
4. **What we deliberately did NOT do** -- simplifications, deferred features.
5. **What could break / how to extend** -- failure modes and the obvious next step.

## Style

Plain English. No emoji. No bullet salad. If a sentence does not survive being read aloud, rewrite it.

## Naming

`NN-<slug>.md`, zero-padded sequence. Examples:

```
01-first-slice-name.md
02-second-slice-name.md
```

## Generating with a cheaper model

The orchestrator can spawn a subagent at the cheapest tier (e.g. `haiku`) for the prose. Sample invocation:

```
Agent({
  subagent_type: "general-purpose",
  model: "haiku",
  description: "Explanation memo for slice <N>",
  prompt: "Write docs/explanations/NN-<slug>.md following the template
   in docs/explanations/README.md. The slice shipped: <one-line>.
   Files touched: <list>. Define every new term. End with 'what could
   break' and 'how to extend'."
})
```
