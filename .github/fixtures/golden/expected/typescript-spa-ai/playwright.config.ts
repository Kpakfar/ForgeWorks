import { defineConfig } from '@playwright/test';

// The slow gate: end-to-end tests, kept OUT of the fast `vitest run` gate so the
// TDD inner loop stays fast. Runs in CI and pre-merge via `npm run e2e`. The
// `--pass-with-no-tests` flag in package.json keeps this green until the first
// e2e spec is written.
export default defineConfig({
  testDir: 'tests/e2e',
  use: {
    headless: true,
  },
});
