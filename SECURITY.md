# Security Policy

This policy covers **ForgeWorks the tooling** — the bootstrapper, the
`/init-project` and `/upgrade-project` skills, and the template files. For the
security of a *generated* project, see the `docs/SECURITY.md` threat model that
ships into every project ForgeWorks creates.

## Reporting a vulnerability

If you find a vulnerability in ForgeWorks itself, please report it **privately**:
open a private security advisory from the repository's **Security** tab on GitHub
(`Security` → `Advisories` → `Report a vulnerability`). Private vulnerability
reporting is enabled, so this channel is always available.

Please do **not** open a public issue for an undisclosed vulnerability, and don't
disclose publicly until a fix is available.

## Scope and limitations

- The dependency-install guard (the `deps-guard` `PreToolUse` hook) is
  **best-effort** — it reduces risk during agent-driven installs but is **not a
  sandbox** and is not a complete control. The real controls are **lockfile
  review** and **CI dependency scanning**.
- Generated projects carry their own `docs/SECURITY.md` threat model (access
  control / IDOR, secrets, supply chain, and — for AI apps — prompt-injection
  defenses). Report issues in a generated project to that project, not here.
- Heavier supply-chain hardening (SHA-pinning Actions and images, pinning the
  Context7 MCP package, verifying installers by checksum) is on the roadmap — see
  `docs/ROADMAP.md`.
