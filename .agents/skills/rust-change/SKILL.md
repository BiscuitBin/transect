---
name: rust-change
description: Implement or review a change to the core, the Rust client or the binding crate with the layering, tests and documentation evidence the invariants require.
---

# Change a crate

1. Read `AGENTS.md` and `docs/explanation/architecture.md`. Identify the crate:
   `crates/libtransect` holds every behaviour; `crates/transect` is the Rust client API
   over it; `crates/transectpy` is the PyO3 binding over the Rust client. Cargo enforces
   `transectpy` → `transect` → `libtransect`, never the reverse; PyO3 appears only in
   `crates/transectpy` (invariant 3).
2. Hold every public entry point to decision 0001: no panic path, no wait on storage,
   the network or the data writer. A Rust panic becomes a Python exception at the
   binding, so the lint policy is the enforcement: never weaken it.
3. Do not add a type, trait, function, dependency or feature to the placeholder modules
   (`ingest_queue`, `local_database`, `schema_evolution`, `data_writer`) without the
   decision that settles them.
4. Keep the lint boundary: the pure-Rust crates inherit `[workspace.lints]`; the binding
   and the fuzz crate carry verbatim copies, which change together with the workspace
   table. Unsafe code stays forbidden everywhere.
5. Write the test first and watch it fail. Unit tests live in the module they test under
   `#[cfg(test)]`, whose test module carries the reasoned
   `#[expect(clippy::disallowed_macros, ...)]`; public items carry asserting doctests.
   The binding crate has no Rust tests: an item it exposes needs a pytest case, with the
   stub and the binding changed together (`python-change`).
6. Silence an item lint only with `#[expect(lint, reason = "...")]` on the item; an
   inner `#![allow` fails `just clippy`.
7. A new dependency needs a reason beside its caret range in `[workspace.dependencies]`;
   a dependency of the excluded fuzz crate goes in `fuzz/Cargo.toml` instead, with its
   reason, pinned by `fuzz/Cargo.lock` (decision 0005).
8. Run `just fmt-check`, `just clippy`, `just test`, `just coverage` and, for public
   documentation, `just doc`, then `just check`. After a change to the core, read
   `just mutants`: a missed mutant is a missing test.
9. Report by `file:line`: what changed, and which test proves it.
