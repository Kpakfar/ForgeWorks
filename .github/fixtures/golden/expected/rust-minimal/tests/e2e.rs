//! End-to-end tests. Every test here is `#[ignore]`-tagged, so the fast gate
//! (`cargo test`, run by scripts/qa.sh) compiles but never runs them; the slow
//! gate (scripts/e2e.sh) runs them via `cargo test --test e2e -- --ignored`.

use app::greet;

/// Placeholder e2e test proving the e2e runner works end to end. Replace it
/// with the full request -> response -> persisted-state path for an API or CLI
/// project; add a browser driver only if the project grows a UI surface.
#[test]
#[ignore = "e2e: excluded from the fast gate; run via scripts/e2e.sh"]
fn e2e_greet_full_flow() {
    assert_eq!(greet("e2e"), "Hello, e2e!");
}
