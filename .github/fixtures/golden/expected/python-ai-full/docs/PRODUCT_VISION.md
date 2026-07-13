# Product Vision: Recipe Radar

The north star for this project. Captures the *what* and *why*. Stable across iterations.

For the *how* (current sprint scope, stack, acceptance criteria), see `requirements.md`.
For the *when* (active queued work), see `backlog.md`.

---

## Positioning (Geoffrey Moore)

For **A busy home cook who stares at a full fridge with no dinner idea.**
who **stares at a full fridge with no dinner idea**,
Recipe Radar is a **inventory-to-recipe assistant**
that **turns what you have into what you can cook tonight**.
Unlike **scrolling recipe sites and guessing what matches the fridge**,
we **start from a photo of the actual fridge, not from a search box**.

## 5W answers

- **Who:** A busy home cook who stares at a full fridge with no dinner idea.
- **What:** Turn a photo of a fridge into three cookable dinner suggestions for busy home cooks.
- **Why:** Recipe sites answer 'what can I cook in general', not 'what can I cook right now with what I have'; the gap between inventory and inspiration stays manual.
- **When:** 2026-08-09
- **Where:** Public web app (mobile-first), hosted on a single VPS first.
- **How:** see the core flow in `docs/requirements.md`

## Scope

**In scope** -- what v1 will do:

- Fridge-photo upload and ingredient extraction with one-tap correction.
- Three recipe suggestions adapted to the confirmed inventory.
- Step-by-step cooking view with serving scaling.
- Helpful empty/error states for unusable photos.

**Out of scope (non-goals)** -- what it deliberately will NOT do:

- No meal planning across multiple days; one dinner at a time.
- No grocery ordering or shopping-list integration in the first iteration.
- No user accounts beyond a device-local profile.

## Business goals

Outcome + metric + target. Cap at three.

- photo-to-recipe time -- p95 under 2 minutes
- ingredient extraction accuracy -- fewer than 2 manual corrections per photo
- suggestion acceptance -- at least 1 of 3 suggestions chosen in 60% of sessions

## Success looks like

> A first-time user goes from photo to a chosen, cookable recipe in under two minutes without editing more than two ingredients.

---

*Last updated: 2026-07-12*
