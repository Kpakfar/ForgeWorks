import { defineConfig } from 'vitest/config';

// The fast gate: unit + functional tests only. End-to-end specs live under
// tests/e2e/ and run separately via `npm run e2e` (Playwright), so `vitest run`
// stays quick for the inner loop.
export default defineConfig({
  test: {
    exclude: ['tests/e2e/**', 'node_modules/**', 'dist/**'],
  },
});
