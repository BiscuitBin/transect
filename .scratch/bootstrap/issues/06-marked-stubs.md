# 06: Marked stubs for the unimplemented areas

**What to build:** Someone opening the core crate sees where each future part of the client will live and can tell at a glance which parts are waiting on a design decision, without any design having been implied. The core gains four placeholder modules that contain only documentation: the ingest queue, the local database and schema evolution, each clearly marked UNDECIDED, and the data writer, marked not yet implemented (its role, a background thread draining the queue into local databases, is settled; what it drains from and writes to is not).

This ticket must not choose or hint at a queue mechanism, a database format or a schema-evolution approach: no types, traits, function signatures, dependencies or feature flags. The lint policy rejects the todo and unimplemented macros, so the stubs are documentation only.

**Adversarial review:** Key moments: at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: whether any wording, name or structure implies a queue mechanism, database format or schema-evolution design; whether anything other than documentation was added.

**Blocked by:** 01

**Status:** ready-for-agent

- [x] The core has one placeholder module each for ingest queue, local database, schema evolution and data writer
- [x] Each of the three undecided modules opens with the same greppable UNDECIDED marker and one or two sentences on the module's responsibility, with no design content
- [x] The data writer module carries a distinct not-yet-implemented marker and states which undecided areas it waits on
- [x] The modules contain no items: no types, traits, functions, constants or re-exports, and the core's public API is unchanged
- [x] The Rust client crate and the Python package gain nothing
- [x] No dependency or feature is added
- [x] API docs build without warnings and the check command ends green
- [x] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model

## Hand-back

Commit `2ef07c7` on `complete-bootstrap` (draft PR #2). This hand-back is committed with ticket 07's first commit.

### What was built

- **Four private flat modules in `crates/libtransect/src/`**: `ingest_queue.rs`, `local_database.rs`, `schema_evolution.rs` and `data_writer.rs`. Each is declared `mod …;` in `lib.rs` and holds only `//!` documentation.
- **Markers.**
  - The three undecided modules open with `//! UNDECIDED: <area>.` and one or two sentences of responsibility, with no mechanism, format or approach.
  - `data_writer.rs` opens with `//! NOT YET IMPLEMENTED: the data writer.` It states the settled role (a background thread draining the ingest queue into local databases) and the three undecided areas it waits on.
- **The register.** Each stub points to `docs/project/open-decisions.md`, which ticket 07 creates as the register.
- **Crate docs.** The core's crate docs gained one paragraph explaining the markers.

### Evidence

Everything below is in `ai_tmp/evidence/06/stubs.txt`.

- **Documentation only.** `grep -vc '^//!'` gives 0 non-documentation lines in each stub. `rg "^//! UNDECIDED:"` finds exactly the three undecided modules.
- **No warnings.**
  - `RUSTDOCFLAGS="-D warnings" cargo doc -p libtransect --document-private-items` generated cleanly.
  - `just clippy`, `just doc` (public docs, `-D warnings`), `just metrics` and `just features` passed. Private item-less modules raise no dead-code or doc warnings.
- **Nothing else changed.** `git diff --stat` over `Cargo.toml`, `Cargo.lock`, `crates/transect`, `crates/transectpy` and `crates/libtransect/Cargo.toml` is empty: no dependency, feature, client or Python change, and the public API is still `version()`.
- **Checks.** `just check` ends `All checks passed and the worktree is unchanged.` CI run 43000052985 (`2ef07c7`) was green on every job.

### Adversarial review (Codex `gpt-6-astra`)

End of ticket, round 1. Both the conformance and breakage lenses reported no findings, including on the design-leak question. With nothing to judge, no triage was needed.

### Open points

- Until ticket 07 lands, the stubs name `docs/project/open-decisions.md` before it exists.

### Maintainer steps

None for this ticket.
