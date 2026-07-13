### Second opinion (Codex)

For non-trivial or security-sensitive changes, run an independent review with the Codex CLI and reconcile its findings with your own:

```bash
codex exec "Review the staged diff for correctness, security, and architecture. List concrete issues with file:line."
```

Treat Codex as a peer, not an oracle: verify each finding against the code before acting on it, and note in the review where you and Codex disagreed and why. Do not block APPROVE on Codex alone; the quality gate is still the gate.
