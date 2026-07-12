import js from '@eslint/js';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  { ignores: ['dist', 'coverage', 'node_modules', '.claude'] },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    // Mechanical line-cap gate (AGENTS.md <architecture-discipline>): hard cap
    // 200 lines per file, counted strictly (blank lines and comments included).
    // For a generated/vendored exception, add a config object AFTER this one
    // with `files: ['src/generated/**']` and `'max-lines': 'off'`.
    rules: {
      'max-lines': ['error', { max: 200, skipBlankLines: false, skipComments: false }],
    },
  },
);
