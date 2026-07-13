//go:build e2e

package e2e

// Placeholder for end-to-end tests. There is no real test yet, so the normal
// `go test ./...` ignores this file entirely (the `e2e` build tag above keeps
// it out of the fast gate), and `go test -tags e2e ./...` simply reports no
// tests to run. Add the first end-to-end test here and run it via
// scripts/e2e.sh.
