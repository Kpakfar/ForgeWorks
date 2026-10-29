# Recipe Radar -- PRD

> The one-page picture of the finished product. Owner-approved at bootstrap.
> Every feature's `serves:` line points here. If a feature cannot say which
> part of this page it serves, question the feature.

## What and for whom

Turn a photo of a fridge into three cookable dinner suggestions for busy home cooks.

Primary user: A busy home cook who stares at a full fridge with no dinner idea. Problem: Recipe sites answer 'what can I cook in general', not 'what can I cook right now with what I have'; the gap between inventory and inspiration stays manual.
Today's alternative: scrolling recipe sites and guessing what matches the fridge. Why this wins: start from a photo of the actual fridge, not from a search box

## The journey (end to end)

1. The cook photographs the open fridge.
2. The app extracts an ingredient list and shows it for one-tap correction.
3. The app retrieves three matching recipes and adapts each to the confirmed inventory.
4. The cook picks one and gets a step-by-step cooking view.

## Surfaces

- Ingredient review
- Recipe suggestions
- Cooking view

## v1 includes

- Fridge-photo upload and ingredient extraction with one-tap correction.
- Three recipe suggestions adapted to the confirmed inventory.
- Step-by-step cooking view with serving scaling.
- Helpful empty/error states for unusable photos.

## v1 excludes

- No meal planning across multiple days; one dinner at a time.
- No grocery ordering or shopping-list integration in the first iteration.
- No user accounts beyond a device-local profile.

## Success looks like

- photo-to-recipe time -- p95 under 2 minutes
- ingredient extraction accuracy -- fewer than 2 manual corrections per photo
- suggestion acceptance -- at least 1 of 3 suggestions chosen in 60% of sessions
